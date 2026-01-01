// lib/services/printing/zebra_printer_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saegewerk/packages/services/zebra_pdf_generator.dart';
import 'package:saegewerk/packages/services/zebra_settings_cache.dart';

import 'zebra_tcp_client.dart';


// Re-export für andere Dateien
export 'zebra_tcp_client.dart' show ZebraPrinterSettings;

/// Zebra Drucker Model
class ZebraPrinter {
  final String id;
  final String nickname;
  final String ipAddress;
  final int port;
  final String model;
  final DateTime? createdAt;

  const ZebraPrinter({
    required this.id,
    required this.nickname,
    required this.ipAddress,
    this.port = 9100,
    this.model = 'ZD421t',
    this.createdAt,
  });

  factory ZebraPrinter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ZebraPrinter(
      id: doc.id,
      nickname: data['nickname'] ?? 'Unbenannt',
      ipAddress: data['ipAddress'] ?? '',
      port: data['port'] ?? 9100,
      model: data['model'] ?? 'ZD421t',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nickname': nickname,
    'ipAddress': ipAddress,
    'port': port,
    'model': model,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
  };

  String get displayAddress => '$ipAddress:$port';

  ZebraTcpClient get client => ZebraTcpClient(ipAddress: ipAddress, port: port);
}

/// Ergebnis eines Druckvorgangs
class PrintResult {
  final bool success;
  final String message;
  final String? error;

  const PrintResult({required this.success, required this.message, this.error});

  factory PrintResult.success([String message = 'Erfolgreich gedruckt']) =>
      PrintResult(success: true, message: message);

  factory PrintResult.failure(String error) =>
      PrintResult(success: false, message: 'Druckfehler', error: error);
}

/// Hauptservice für Zebra-Drucker
class ZebraPrinterService {
  static final ZebraPrinterService _instance = ZebraPrinterService._internal();
  factory ZebraPrinterService() => _instance;
  ZebraPrinterService._internal();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _printersCollection => _db.collection('zebra_printers');
  DocumentReference get _userDoc => _db.collection('users').doc(_auth.currentUser!.uid);

  // ==================== DRUCKER VERWALTUNG ====================

  Stream<List<ZebraPrinter>> watchPrinters() {
    return _printersCollection.orderBy('nickname').snapshots().map(
          (snap) => snap.docs.map((doc) => ZebraPrinter.fromFirestore(doc)).toList(),
    );
  }

  Future<List<ZebraPrinter>> getPrinters() async {
    final snap = await _printersCollection.orderBy('nickname').get();
    return snap.docs.map((doc) => ZebraPrinter.fromFirestore(doc)).toList();
  }

  Future<String> addPrinter({
    required String nickname,
    required String ipAddress,
    int port = 9100,
    String model = 'ZD421t',
  }) async {
    final doc = await _printersCollection.add({
      'nickname': nickname,
      'ipAddress': ipAddress,
      'port': port,
      'model': model,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser?.email ?? 'unknown',
    });
    return doc.id;
  }

  Future<void> updatePrinter(String id, Map<String, dynamic> data) async {
    await _printersCollection.doc(id).update(data);
  }

  Future<void> deletePrinter(String id) async {
    await _printersCollection.doc(id).delete();
  }

  // ==================== STANDARD-DRUCKER ====================

  Future<String?> getDefaultPrinterIp() async {
    final doc = await _userDoc.get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['defaultZebraPrinter'] as String?;
  }

  Future<void> setDefaultPrinter(String ipAddress) async {
    await _userDoc.set({'defaultZebraPrinter': ipAddress}, SetOptions(merge: true));
  }

  Future<ZebraPrinter?> getDefaultPrinter() async {
    final ip = await getDefaultPrinterIp();
    if (ip == null) return null;

    final snap = await _printersCollection.where('ipAddress', isEqualTo: ip).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return ZebraPrinter.fromFirestore(snap.docs.first);
  }

  // ==================== DRUCKEN ====================

  /// Paket-Etikett drucken (PDF)
  Future<PrintResult> printPackageLabel(
      BuildContext context,
      Map<String, dynamic> packageData,
      ) async {
    try {
      debugPrint('=== PRINT PACKAGE LABEL ===');

      // 1. Drucker auswählen
      debugPrint('Selecting printer...');
      final printer = await _selectPrinter(context);
      if (printer == null) {
        debugPrint('No printer selected');
        return PrintResult.failure('Kein Drucker ausgewählt');
      }
      debugPrint('Printer: ${printer.nickname} (${printer.ipAddress})');

      // 2. Label-Breite aus Firebase-Cache laden
      debugPrint('Loading label width...');
      final labelWidthMm = await ZebraSettingsCache.getLabelWidthMm(
        printer.id,
        defaultWidth: 100.0,
      );
      debugPrint('Label width: $labelWidthMm mm');

      // 3. PDF generieren
      debugPrint('Generating PDF...');
      debugPrint('Package data: $packageData');
      final pdfFile = await ZebraPdfGenerator.generatePackageLabel(
        packageData,
        labelWidthMm,
      );
      debugPrint('PDF created: ${pdfFile.path}');

      // 4. An Drucker senden
      debugPrint('Sending to printer...');
      final success = await printer.client.printPdf(pdfFile);
      debugPrint('Send result: $success');

      if (success) {
        return PrintResult.success('Etikett gedruckt auf ${printer.nickname}');
      } else {
        return PrintResult.failure('Drucker ${printer.nickname} nicht erreichbar');
      }
    } catch (e, stack) {
      debugPrint('=== PRINT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      return PrintResult.failure(e.toString());
    }
  }

  /// Test-Label drucken
  Future<PrintResult> printTestLabel(ZebraPrinter printer) async {
    final success = await printer.client.printTestLabel();
    return success
        ? PrintResult.success('Test-Label gedruckt')
        : PrintResult.failure('Drucker nicht erreichbar');
  }

  // ==================== DRUCKER AUSWAHL ====================

  Future<ZebraPrinter?> _selectPrinter(BuildContext context) async {
    debugPrint('_selectPrinter: START');

    // Context-Check VOR dem async Call
    if (!context.mounted) {
      debugPrint('_selectPrinter: Context not mounted at start');
      return null;
    }

    final defaultPrinter = await getDefaultPrinter();
    debugPrint('_selectPrinter: defaultPrinter = ${defaultPrinter?.nickname ?? "NULL"}');

    if (defaultPrinter != null) {
      final isOnline = await defaultPrinter.client.isOnline();
      debugPrint('_selectPrinter: isOnline = $isOnline');
      if (isOnline) return defaultPrinter;
    }

    // Kein Default oder offline - Dialog zeigen
    if (!context.mounted) {
      debugPrint('_selectPrinter: Context not mounted before dialog');
      return null;
    }

    // Printers direkt laden und Dialog sofort zeigen (ohne weiteren async Call dazwischen)
    final printers = await getPrinters();

    if (printers.isEmpty) {
      debugPrint('_selectPrinter: No printers configured');
      return null;
    }

    if (printers.length == 1) {
      debugPrint('_selectPrinter: Only one printer, using it');
      return printers.first;
    }

    if (!context.mounted) {
      debugPrint('_selectPrinter: Context not mounted before dialog');
      return null;
    }

    return showDialog<ZebraPrinter>(
      context: context,
      builder: (ctx) => _PrinterSelectionDialog(printers: printers),
    );
  }
  Future<ZebraPrinter?> showPrinterSelectionDialog(BuildContext context) async {
    final printers = await getPrinters();

    if (printers.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Zebra-Drucker konfiguriert')),
        );
      }
      return null;
    }

    if (printers.length == 1) return printers.first;

    if (!context.mounted) return null;

    return showDialog<ZebraPrinter>(
      context: context,
      builder: (ctx) => _PrinterSelectionDialog(printers: printers),
    );
  }

  // ==================== EINSTELLUNGEN ====================

  /// Einstellungen vom Drucker lesen
  Future<ZebraPrinterSettings?> readSettings(ZebraPrinter printer) async {
    // Erst aus Cache versuchen
    final cached = await ZebraSettingsCache.getSettingsRaw(printer.id);
    if (cached != null) {
      return ZebraPrinterSettings(
        darkness: cached['darkness'] as double,
        printSpeed: cached['printSpeed'] as double,
        printWidth: cached['printWidth'] as int,
        tearOff: cached['tearOff'] as int,
        mediaType: cached['mediaType'] as String,
      );
    }

    // Sonst vom Drucker laden
    return await printer.client.readSettings();
  }

  /// Einstellungen speichern (Firebase + Drucker)
  Future<bool> saveSettings(ZebraPrinter printer, ZebraPrinterSettings settings) async {
    try {
      // 1. In Firebase speichern
      await ZebraSettingsCache.saveSettingsRaw(printer.id, {
        'darkness': settings.darkness,
        'printSpeed': settings.printSpeed,
        'printWidth': settings.printWidth,
        'tearOff': settings.tearOff,
        'mediaType': settings.mediaType,
      });

      // 2. An Drucker senden (wenn online)
      final isOnline = await printer.client.isOnline();
      if (isOnline) {
        await printer.client.saveSettings(settings);
      }

      return true;
    } catch (e) {
      print('Fehler beim Speichern: $e');
      return false;
    }
  }

  /// Kalibrierung starten
  Future<bool> calibrate(ZebraPrinter printer) {
    return printer.client.calibrate();
  }

  /// Config-Label drucken
  Future<bool> printConfigLabel(ZebraPrinter printer) {
    return printer.client.printConfigLabel();
  }
}

// ==================== DIALOGS ====================

class _PrinterSelectionDialog extends StatefulWidget {
  final List<ZebraPrinter> printers;

  const _PrinterSelectionDialog({required this.printers});

  @override
  State<_PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<_PrinterSelectionDialog> {
  Map<String, bool> _onlineStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAllPrinters();
  }

  Future<void> _checkAllPrinters() async {
    final futures = widget.printers.map((p) async {
      final online = await p.client.isOnline();
      return MapEntry(p.id, online);
    });

    final results = await Future.wait(futures);
    if (mounted) {
      setState(() {
        _onlineStatus = Map.fromEntries(results);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Drucker auswählen'),
      content: SizedBox(
        width: 300,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          shrinkWrap: true,
          itemCount: widget.printers.length,
          itemBuilder: (ctx, i) {
            final printer = widget.printers[i];
            final isOnline = _onlineStatus[printer.id] ?? false;

            return ListTile(
              leading: Icon(
                Icons.print,
                color: isOnline ? Colors.green : Colors.grey,
              ),
              title: Text(printer.nickname),
              subtitle: Text(printer.displayAddress),
              trailing: isOnline
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                  : const Icon(Icons.error_outline, color: Colors.red, size: 18),
              onTap: isOnline ? () => Navigator.pop(context, printer) : null,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}