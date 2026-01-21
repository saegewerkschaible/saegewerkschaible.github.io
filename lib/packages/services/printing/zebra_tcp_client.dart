// lib/services/printing/zebra_tcp_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Zebra Drucker-Einstellungen
class ZebraPrinterSettings {
  final double darkness;
  final double printSpeed;
  final int printWidth;


  const ZebraPrinterSettings({
    this.darkness = 15.0,
    this.printSpeed = 4.0,
    this.printWidth = 1200,

  });

  /// 300 DPI: 12 dots = 1mm
  double get printWidthMm => printWidth / 12.0;

  ZebraPrinterSettings copyWith({
    double? darkness,
    double? printSpeed,
    int? printWidth,

  }) => ZebraPrinterSettings(
    darkness: darkness ?? this.darkness,
    printSpeed: printSpeed ?? this.printSpeed,
    printWidth: printWidth ?? this.printWidth,

  );

  Map<String, dynamic> toMap() => {
    'darkness': darkness,
    'printSpeed': printSpeed,
    'printWidth': printWidth,

  };

  factory ZebraPrinterSettings.fromMap(Map<String, dynamic> map) => ZebraPrinterSettings(
    darkness: (map['darkness'] ?? 15.0).toDouble(),
    printSpeed: (map['printSpeed'] ?? 4.0).toDouble(),
    printWidth: map['printWidth'] ?? 1200,

  );

  @override
  String toString() => 'ZebraPrinterSettings(darkness: $darkness, speed: $printSpeed, width: ${printWidthMm.toStringAsFixed(1)}mm)';
}

/// Drucker-Status
class PrinterStatus {
  final bool isOnline;
  final bool isPaused;
  final bool hasPaperOut;
  final bool hasError;
  final String? errorMessage;

  const PrinterStatus({
    required this.isOnline,
    this.isPaused = false,
    this.hasPaperOut = false,
    this.hasError = false,
    this.errorMessage,
  });

  bool get isReady => isOnline && !isPaused && !hasPaperOut && !hasError;

  factory PrinterStatus.offline([String? error]) => PrinterStatus(
    isOnline: false,
    hasError: error != null,
    errorMessage: error,
  );

  factory PrinterStatus.online() => const PrinterStatus(isOnline: true);
}

/// TCP Client für Zebra Drucker
class ZebraTcpClient {
  final String ipAddress;
  final int port;
  final Duration timeout;

  ZebraTcpClient({
    required this.ipAddress,
    this.port = 9100,
    this.timeout = const Duration(seconds: 10),
  });

  // ==================== VERBINDUNG ====================

  /// Schneller Verbindungstest
  Future<bool> isOnline() async {
    Socket? socket;
    try {
      socket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 3));
      return true;
    } catch (e) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  /// Detaillierter Status
  Future<PrinterStatus> getStatus() async {
    try {
      final response = await _sendWithResponse('~HS');
      if (response == null) return PrinterStatus.offline('Keine Antwort');
      return _parseStatus(response);
    } catch (e) {
      return PrinterStatus.offline(e.toString());
    }
  }

  PrinterStatus _parseStatus(String response) {
    try {
      final cleaned = response.replaceAll('\x02', '').replaceAll('\x03', '').trim();
      final parts = cleaned.split(',');
      return PrinterStatus(
        isOnline: true,
        isPaused: parts.length > 1 && parts[1].trim() == '1',
        hasPaperOut: parts.length > 2 && parts[2].trim() == '1',
      );
    } catch (e) {
      return const PrinterStatus(isOnline: true);
    }
  }

  // ==================== DRUCKEN ====================

  /// Sendet Bytes an Drucker
  Future<bool> _send(Uint8List bytes) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ipAddress, port, timeout: timeout);
      socket.add(bytes);
      await socket.flush();
      return true;
    } catch (e) {
      print('ZebraTCP: Senden fehlgeschlagen: $e');
      return false;
    } finally {
      socket?.destroy();
    }
  }

  /// Sendet String an Drucker
  Future<bool> _sendString(String data) async {
    return await _send(Uint8List.fromList(utf8.encode(data)));
  }

  /// Sendet ZPL-Code zum Drucker
  Future<bool> printZpl(String zpl) async {
    return await _sendString(zpl);
  }

  /// Sendet PDF-Datei zum Drucker
  Future<bool> printPdf(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      return await _send(bytes);
    } catch (e) {
      print('ZebraTCP: PDF-Druck fehlgeschlagen: $e');
      return false;
    }
  }

  /// Sendet beliebige Datei zum Drucker
  Future<bool> printFile(File file) async {
    return await printPdf(file);
  }

  /// Test-Label drucken
  Future<bool> printTestLabel() async {
    final zpl = '''
^XA
^FO50,50^ADN,36,20^FDZebra Test^FS
^FO50,100^ADN,20,12^FD$ipAddress:$port^FS
^FO50,150^BY2^BCN,60,Y,N,N^FDTEST123^FS
^FO50,230^ADN,18,10^FD${DateTime.now().toString().substring(0, 16)}^FS
^XZ
''';
    return await printZpl(zpl);
  }

  // ==================== EINSTELLUNGEN ====================

  /// Liest Drucker-Einstellungen direkt vom Gerät
  Future<ZebraPrinterSettings?> readSettings() async {
    try {
      final darkness = await _getVar('print.tone');
      final speed = await _getVar('media.speed');
      final width = await _getVar('ezpl.print_width');


      return ZebraPrinterSettings(
        darkness: (double.tryParse(darkness ?? '15') ?? 15).clamp(0, 30).toDouble(),
        printSpeed: (double.tryParse(speed ?? '4') ?? 4).clamp(2, 6).toDouble(),
        printWidth: (int.tryParse(width ?? '1200') ?? 1200).clamp(200, 1280),

      );
    } catch (e) {
      print('ZebraTCP: Einstellungen lesen fehlgeschlagen: $e');
      return null;
    }
  }

  /// Speichert Einstellungen auf dem Drucker
  Future<bool> saveSettings(ZebraPrinterSettings settings) async {
    try {
      await _setVar('print.tone', settings.darkness.round().toString());
      await _setVar('media.speed', settings.printSpeed.round().toString());
      await _setVar('ezpl.print_width', settings.printWidth.toString());

      // Permanent speichern
      await _sendString('^XA^JUS^XZ');
      return true;
    } catch (e) {
      print('ZebraTCP: Einstellungen speichern fehlgeschlagen: $e');
      return false;
    }
  }

  Future<String?> _getVar(String name) async {
    final response = await _sendWithResponse('! U1 getvar "$name"\r\n');
    if (response == null || response.contains('?')) return null;
    return response.replaceAll('"', '').trim();
  }

  Future<void> _setVar(String name, String value) async {
    await _sendString('! U1 setvar "$name" "$value"\r\n');
  }

  // ==================== WARTUNG ====================

  Future<bool> calibrate() => _sendString('~JC');
  Future<bool> printConfigLabel() => _sendString('~WC');
  Future<bool> reset() => _sendString('~JR');
  Future<bool> cancelJob() => _sendString('~JA');

  // ==================== HILFSMETHODEN ====================

  Future<String?> _sendWithResponse(String data) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ipAddress, port, timeout: timeout);
      socket.write(data);
      await socket.flush();

      final completer = Completer<String>();
      final buffer = StringBuffer();

      socket.listen(
            (bytes) => buffer.write(utf8.decode(bytes, allowMalformed: true)),
        onDone: () { if (!completer.isCompleted) completer.complete(buffer.toString()); },
        onError: (e) { if (!completer.isCompleted) completer.completeError(e); },
      );

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => buffer.toString(),
      );
    } catch (e) {
      return null;
    } finally {
      socket?.destroy();
    }
  }
}