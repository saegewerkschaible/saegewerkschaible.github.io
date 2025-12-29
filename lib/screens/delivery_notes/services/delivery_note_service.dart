// lib/screens/delivery_notes/services/delivery_note_service.dart

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
      // 1. Lieferschein-Nummer generieren
      final number = await _getNextDeliveryNoteNumber();

      // 2. PDF generieren
      final pdfBytes = await generatePDF(
        items: items,
        customer: customer,
        number: number,
      );

      // 3. PDF in Storage hochladen
      final pdfUrl = await _uploadPDF(pdfBytes, number);

      // 4. Lieferschein in Firestore speichern
      final deliveryNoteData = {
        'number': number,
        'createdAt': FieldValue.serverTimestamp(),
        'customerName': customer?['name'] ?? 'Direktverkauf',
        'customerData': customer,
        'totalVolume': items.fold<double>(0, (sum, item) => sum + item.menge),
        'totalQuantity': items.fold<int>(0, (sum, item) => sum + item.stueckzahl),
        'itemCount': items.length,
        'items': items.map((item) => item.toMap()).toList(),
        'pdfUrl': pdfUrl,
        'status': 'completed',
      };

      final docRef = await _db.collection('delivery_notes').add(deliveryNoteData);

      // 5. Pakete als verkauft markieren
      await _markPackagesAsSold(items, number);

      // 6. Temporären Warenkorb leeren
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

  /// Generiert die nächste Lieferschein-Nummer
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

  /// Lädt PDF in Firebase Storage hoch
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

  /// Markiert alle Pakete als verkauft
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

  /// Leert den temporären Warenkorb
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

    // Logo laden (optional)
    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      // Logo nicht verfügbar
    }

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildPdfHeader(number, logo),
              pw.SizedBox(height: 24),

              // Kundenadresse
              _buildPdfCustomerSection(customer),
              pw.SizedBox(height: 24),

              // Pakettabelle
              _buildPdfTable(items),
              pw.SizedBox(height: 24),

              // Summen
              _buildPdfSummary(items),

              // Footer
              pw.Expanded(child: pw.SizedBox()),
              _buildPdfFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
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

  static pw.Widget _buildPdfTable(List<CartItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5), // Barcode
        1: const pw.FlexColumnWidth(1.5), // Holzart
        2: const pw.FlexColumnWidth(1),   // H
        3: const pw.FlexColumnWidth(1),   // B
        4: const pw.FlexColumnWidth(1),   // L
        5: const pw.FlexColumnWidth(0.8), // Stk
        6: const pw.FlexColumnWidth(1.2), // m³
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          children: [
            _tableHeader('Paket-Nr.'),
            _tableHeader('Holzart'),
            _tableHeader('H [mm]'),
            _tableHeader('B [mm]'),
            _tableHeader('L [m]'),
            _tableHeader('Stk'),
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
            _tableCell(item.menge.toStringAsFixed(3)),
          ],
        )),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static pw.Widget _buildPdfSummary(List<CartItem> items) {
    final totalVolume = items.fold<double>(0, (sum, item) => sum + item.menge);
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
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text('Gesamtvolumen: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('${totalVolume.toStringAsFixed(3)} m³'),
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