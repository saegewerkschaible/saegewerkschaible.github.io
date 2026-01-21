// lib/screens/delivery_notes/services/delivery_note_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'cart_provider.dart';

class DeliveryNoteService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Erstellt einen kompletten Lieferschein
  static Future<Map<String, dynamic>> createDeliveryNote({
    required List<CartItem> items,
    Map<String, dynamic>? customer,
  }) async {
    try {
      final number = await _getNextDeliveryNoteNumber();

      final pdfBytes = await generatePDF(
        items: items,
        customer: customer,
        number: number,
      );

      final pdfUrl = await _uploadPDF(pdfBytes, number);

      final jsonData = generateExportJson(
        items: items,
        customer: customer,
        number: number,
      );
      final jsonUrl = await _uploadJSON(jsonData, number);

      // Berechne Summen MIT Abzug
      final totalVolumeBrutto = items.fold<double>(0, (sum, item) => sum + item.menge);
      final totalAbzug = items.fold<double>(0, (sum, item) => sum + item.abzugVolumen);
      final totalVolumeNetto = items.fold<double>(0, (sum, item) => sum + item.nettoVolumen);

      final deliveryNoteData = {
        'number': number,
        'createdAt': FieldValue.serverTimestamp(),
        'customerName': customer?['name'] ?? 'Direktverkauf',
        'customerData': customer,
        'totalVolumeBrutto': totalVolumeBrutto,
        'totalAbzug': totalAbzug,
        'totalVolume': totalVolumeNetto,  // Netto als Hauptwert
        'totalQuantity': items.fold<int>(0, (sum, item) => sum + item.stueckzahl),
        'itemCount': items.length,
        'items': items.map((item) => item.toMap()).toList(),
        'pdfUrl': pdfUrl,
        'jsonUrl': jsonUrl,
        'status': 'completed',
      };

      final docRef = await _db.collection('delivery_notes').add(deliveryNoteData);

      await _markPackagesAsSold(items, number);
      await _clearTemporaryCart();

      return {
        'success': true,
        'id': docRef.id,
        'number': number,
        'pdfUrl': pdfUrl,
        'pdfBytes': pdfBytes,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<String> _getNextDeliveryNoteNumber() async {
    final counterRef = _db.collection('settings').doc('counters');

    return await _db.runTransaction<String>((transaction) async {
      final doc = await transaction.get(counterRef);

      int currentNumber = 1;
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentNumber = (data['lastDeliveryNoteNumber'] ?? 0) + 1;
      }

      transaction.set(counterRef, {
        'lastDeliveryNoteNumber': currentNumber,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return currentNumber.toString().padLeft(6, '0');
    });
  }

  static Future<String> _uploadPDF(Uint8List pdfBytes, String number) async {
    final now = DateTime.now();
    final ref = _storage
        .ref()
        .child('delivery_notes')
        .child(now.year.toString())
        .child(now.month.toString().padLeft(2, '0'))
        .child('LS_$number.pdf');

    await ref.putData(pdfBytes);
    return await ref.getDownloadURL();
  }

  static Future<void> _markPackagesAsSold(List<CartItem> items, String deliveryNoteNumber) async {
    final batch = _db.batch();
    final now = DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy').format(now);

    for (var item in items) {
      final ref = _db.collection('packages').doc(item.barcode);
      batch.update(ref, {
        'status': 'verkauft',
        'verkauftAm': dateStr,
        'lieferscheinNr': deliveryNoteNumber,
      });
    }

    await batch.commit();
  }

  static Future<void> _clearTemporaryCart() async {
    final batch = _db.batch();
    final docs = await _db.collection('temporary_cart').get();

    for (var doc in docs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Generiert das PDF für den Lieferschein
  static Future<Uint8List> generatePDF({
    required List<CartItem> items,
    Map<String, dynamic>? customer,
    required String number,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    // Prüfe ob Abzüge vorhanden sind
    final hasAbzug = items.any((item) => item.hasAbzug);

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(number, logo),
              pw.SizedBox(height: 24),
              _buildPdfCustomerSection(customer),
              pw.SizedBox(height: 24),
              _buildPdfTable(items, hasAbzug),
              pw.SizedBox(height: 24),
              _buildPdfSummary(items, hasAbzug),
              pw.Expanded(child: pw.SizedBox()),
              _buildPdfFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generiert den JSON-Export
  static Map<String, dynamic> generateExportJson({
    required List<CartItem> items,
    Map<String, dynamic>? customer,
    required String number,
  }) {
    final now = DateTime.now();

    return {
      'version': '1.0',
      'exportiertAm': now.toIso8601String(),
      'lieferschein': {
        'nummer': number,
        'datum': DateFormat('dd.MM.yyyy').format(now),
        'erstelltUm': now.toIso8601String(),
      },
      'absender': {
        'firma': 'Sägewerk Schaible',
        'strasse': 'Hagelenweg 1a',
        'plz': '78652',
        'ort': 'Deißlingen',
        'telefon': '07420-1332',
        'email': 'info@saegewerk-schaible.de',
      },
      'empfaenger': {
        'name': customer?['name'] ?? '',
        'strasse': customer?['street'] ?? '',
        'hausnummer': customer?['houseNumber'] ?? '',
        'plz': customer?['zipCode'] ?? '',
        'ort': customer?['city'] ?? '',
        'email': customer?['email'] ?? '',
      },
      'positionen': items.asMap().entries.map((entry) {
        final item = entry.value;
        return {
          'position': entry.key + 1,
          'barcode': item.barcode,
          'nrExt': item.nrExt,
          'holzart': item.holzart,
          'hoehe': item.hoehe,
          'breite': item.breite,
          'laenge': item.laenge,
          'stueckzahl': item.stueckzahl,
          'mengeBrutto': item.menge,
          'abzugStk': item.abzugStk,
          'abzugLaenge': item.abzugLaenge,
          'abzugVolumen': item.abzugVolumen,
          'mengeNetto': item.nettoVolumen,
          'zustand': item.zustand,
          'bemerkung': item.bemerkung,
        };
      }).toList(),
      'summen': {
        'anzahlPakete': items.length,
        'gesamtStueckzahl': items.fold<int>(0, (sum, item) => sum + item.stueckzahl),
        'gesamtVolumenBrutto': items.fold<double>(0, (sum, item) => sum + item.menge),
        'gesamtAbzug': items.fold<double>(0, (sum, item) => sum + item.abzugVolumen),
        'gesamtVolumenNetto': items.fold<double>(0, (sum, item) => sum + item.nettoVolumen),
      },
    };
  }

  static Future<String> _uploadJSON(Map<String, dynamic> jsonData, String number) async {
    final now = DateTime.now();
    final ref = _storage
        .ref()
        .child('delivery_notes')
        .child(now.year.toString())
        .child(now.month.toString().padLeft(2, '0'))
        .child('LS_$number.json');

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    await ref.putData(bytes, SettableMetadata(contentType: 'application/json'));
    return await ref.getDownloadURL();
  }

  static pw.Widget _buildPdfHeader(String number, pw.MemoryImage? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Lieferschein',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Nr.: LS-$number',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey600),
            ),
            pw.Text(
              'Datum: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey600),
            ),
          ],
        ),
        if (logo != null) pw.Image(logo, width: 150),
      ],
    );
  }

  static pw.Widget _buildPdfCustomerSection(Map<String, dynamic>? customer) {
    if (customer == null) {
      return pw.Text('', style: pw.TextStyle(fontWeight: pw.FontWeight.bold));
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            customer['name'] ?? '',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          if (customer['street'] != null)
            pw.Text('${customer['street']} ${customer['houseNumber'] ?? ''}'),
          if (customer['zipCode'] != null || customer['city'] != null)
            pw.Text('${customer['zipCode'] ?? ''} ${customer['city'] ?? ''}'.trim()),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfTable(List<CartItem> items, bool hasAbzug) {
    // Spaltenbreiten anpassen je nachdem ob Abzug vorhanden
    final columnWidths = hasAbzug
        ? {
      0: const pw.FlexColumnWidth(1.2), // Barcode
      1: const pw.FlexColumnWidth(1.2), // Holzart
      2: const pw.FlexColumnWidth(0.8), // H
      3: const pw.FlexColumnWidth(0.8), // B
      4: const pw.FlexColumnWidth(0.8), // L
      5: const pw.FlexColumnWidth(0.6), // Stk
      6: const pw.FlexColumnWidth(1),   // Brutto
      7: const pw.FlexColumnWidth(1.1), // Abzug (mit Details)
      8: const pw.FlexColumnWidth(1),   // Netto
    }
        : {
      0: const pw.FlexColumnWidth(1.5), // Barcode
      1: const pw.FlexColumnWidth(1.5), // Holzart
      2: const pw.FlexColumnWidth(1),   // H
      3: const pw.FlexColumnWidth(1),   // B
      4: const pw.FlexColumnWidth(1),   // L
      5: const pw.FlexColumnWidth(0.8), // Stk
      6: const pw.FlexColumnWidth(1.2), // m³
    };

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
      columnWidths: columnWidths,
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          children: [
            _tableHeader('Paket'),
            _tableHeader('Holzart'),
            _tableHeader('H'),
            _tableHeader('B'),
            _tableHeader('L'),
            _tableHeader('Stk'),
            if (hasAbzug) ...[
              _tableHeader('Brutto'),
              _tableHeader('Abzug'),
              _tableHeader('Netto'),
            ] else
              _tableHeader('m³'),
          ],
        ),
        // Datenzeilen
        ...items.map((item) => pw.TableRow(
          children: [
            _tableCell(item.barcode),
            _tableCell(item.holzart),
            _tableCell(item.hoehe.toStringAsFixed(0)),
            _tableCell(item.breite.toStringAsFixed(0)),
            _tableCell(item.laenge.toStringAsFixed(2)),
            _tableCell(item.stueckzahl.toString()),
            if (hasAbzug) ...[
              _tableCell(item.menge.toStringAsFixed(3)),
              // Abzug-Zelle mit Details
              _tableAbzugCell(item),
              _tableCell(item.nettoVolumen.toStringAsFixed(3)),
            ] else
              _tableCell(item.menge.toStringAsFixed(3)),
          ],
        )),
      ],
    );
  }

  static pw.Widget _tableAbzugCell(CartItem item) {
    if (!item.hasAbzug) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text('-', style: const pw.TextStyle(fontSize: 9)),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Volumen
          pw.Text(
            '-${item.abzugVolumen.toStringAsFixed(3)}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          // Details: Stk × Länge
          pw.Text(
            '${item.abzugStk} Stk × ${item.abzugLaenge}m',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _buildPdfSummary(List<CartItem> items, bool hasAbzug) {
    final totalBrutto = items.fold<double>(0, (sum, item) => sum + item.menge);
    final totalAbzug = items.fold<double>(0, (sum, item) => sum + item.abzugVolumen);
    final totalNetto = items.fold<double>(0, (sum, item) => sum + item.nettoVolumen);
    final totalQuantity = items.fold<int>(0, (sum, item) => sum + item.stueckzahl);

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.blueGrey50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text('Pakete: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('${items.length}'),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text('Gesamtstückzahl: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('$totalQuantity Stk'),
              ],
            ),
            pw.SizedBox(height: 4),
            if (hasAbzug) ...[
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Brutto: ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${totalBrutto.toStringAsFixed(3)} m³', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Abzug: ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('-${totalAbzug.toStringAsFixed(3)} m³', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('Netto: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${totalNetto.toStringAsFixed(3)} m³', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ] else
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Gesamtvolumen: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${totalNetto.toStringAsFixed(3)} m³'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.blueGrey200)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Sägewerk Schaible', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Hagelenweg 1a', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('78652 Deißlingen', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Tel: 07420-1332', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('info@saegewerk-schaible.de', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }
}