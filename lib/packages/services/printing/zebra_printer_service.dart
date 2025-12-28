// lib/services/printing/zebra_printer_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'zebra_tcp_client.dart';
import 'zebra_label_generator.dart';

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

  const PrintResult({
    required this.success,
    required this.message,
    this.error,
  });

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

  // Firestore Pfade
  CollectionReference get _printersCollection =>
      _db.collection('zebra_printers');

  DocumentReference get _userDoc =>
      _db.collection('users').doc(_auth.currentUser!.uid);

  // ==================== DRUCKER VERWALTUNG ====================

  /// Stream aller Zebra-Drucker
  Stream<List<ZebraPrinter>> watchPrinters() {
    return _printersCollection.orderBy('nickname').snapshots().map(
          (snap) => snap.docs.map((doc) => ZebraPrinter.fromFirestore(doc)).toList(),
    );
  }

  /// Alle Drucker laden
  Future<List<ZebraPrinter>> getPrinters() async {
    final snap = await _printersCollection.orderBy('nickname').get();
    return snap.docs.map((doc) => ZebraPrinter.fromFirestore(doc)).toList();
  }

  /// Drucker hinzufügen
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

  /// Drucker aktualisieren
  Future<void> updatePrinter(String id, Map<String, dynamic> data) async {
    await _printersCollection.doc(id).update(data);
  }

  /// Drucker löschen
  Future<void> deletePrinter(String id) async {
    await _printersCollection.doc(id).delete();
  }

  // ==================== STANDARD-DRUCKER ====================

  /// Standard-Drucker IP laden
  Future<String?> getDefaultPrinterIp() async {
    final doc = await _userDoc.get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['defaultZebraPrinter'] as String?;
  }

  /// Standard-Drucker setzen
  Future<void> setDefaultPrinter(String ipAddress) async {
    await _userDoc.set({'defaultZebraPrinter': ipAddress}, SetOptions(merge: true));
  }

  /// Standard-Drucker als Objekt laden
  Future<ZebraPrinter?> getDefaultPrinter() async {
    final ip = await getDefaultPrinterIp();
    if (ip == null) return null;

    final snap = await _printersCollection.where('ipAddress', isEqualTo: ip).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return ZebraPrinter.fromFirestore(snap.docs.first);
  }

  // ==================== DRUCKEN ====================

  /// Paket-Etikett drucken
  Future<PrintResult> printPackageLabel(
      BuildContext context,
      Map<String, dynamic> packageData,
      ) async {
    try {
      final printer = await _selectPrinter(context);
      if (printer == null) {
        return PrintResult.failure('Kein Drucker ausgewählt');
      }

      // ZPL generieren
      final produkt = packageData['Produkt']?.toString() ?? '';
      final zpl = produkt == 'Lamelle'
          ? ZebraLabelGenerator.generateLamellenLabel(packageData)
          : ZebraLabelGenerator.generatePackageLabel(packageData);

      // Drucken
      final success = await printer.client.printZpl(zpl);

      if (success) {
        return PrintResult.success('Etikett gedruckt auf ${printer.nickname}');
      } else {
        return PrintResult.failure('Drucker ${printer.nickname} nicht erreichbar');
      }
    } catch (e) {
      return PrintResult.failure(e.toString());
    }
  }


  /// Einfaches Barcode-Label drucken
  Future<PrintResult> printBarcodeLabel(
      BuildContext context,
      String barcode, {
        String? title,
      }) async {
    try {
      final printer = await _selectPrinter(context);
      if (printer == null) {
        return PrintResult.failure('Kein Drucker ausgewählt');
      }

      final zpl = ZebraLabelGenerator.generateBarcodeLabel(barcode, title: title);
      final success = await printer.client.printZpl(zpl);

      return success
          ? PrintResult.success('Barcode gedruckt')
          : PrintResult.failure('Druckfehler');
    } catch (e) {
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

  /// Wählt Drucker aus (Standard oder Dialog)
  Future<ZebraPrinter?> _selectPrinter(BuildContext context) async {
    // Erst Standard-Drucker versuchen
    final defaultPrinter = await getDefaultPrinter();

    if (defaultPrinter != null) {
      // Prüfen ob online
      final isOnline = await defaultPrinter.client.isOnline();
      if (isOnline) return defaultPrinter;
    }

    // Sonst Dialog zeigen
    if (!context.mounted) return null;
    return await showPrinterSelectionDialog(context);
  }

  /// Dialog zur Drucker-Auswahl
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

    if (printers.length == 1) {
      return printers.first;
    }

    if (!context.mounted) return null;

    return showDialog<ZebraPrinter>(
      context: context,
      builder: (ctx) => _PrinterSelectionDialog(printers: printers),
    );
  }

  // ==================== STATUS & EINSTELLUNGEN ====================

  /// Drucker-Status prüfen
  Future<PrinterStatus> checkStatus(ZebraPrinter printer) {
    return printer.client.getStatus();
  }

  /// Einstellungen lesen
  Future<ZebraPrinterSettings?> readSettings(ZebraPrinter printer) {
    return printer.client.readSettings();
  }

  /// Einstellungen speichern
  Future<bool> saveSettings(ZebraPrinter printer, ZebraPrinterSettings settings) {
    return printer.client.saveSettings(settings);
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