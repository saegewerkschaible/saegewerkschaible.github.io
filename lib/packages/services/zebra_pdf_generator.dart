// lib/services/printing/zebra_pdf_generator.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// PDF-Generator für Zebra-Paketzettel
class ZebraPdfGenerator {

  /// Generiert PDF für Standard-Paketzettel
  static Future<File> generatePackageLabel(
      Map<String, dynamic> data,
      double labelWidthMm,
      ) async {
    final pdf = pw.Document();

    // Logo laden
    final ByteData logoData = await rootBundle.load('assets/images/logo_sw.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final image = pw.MemoryImage(logoBytes);

    // Berechne dynamische Höhe
    int printLength = 180;
    bool isLamelle = data['Produkt'] == 'Lamelle';
    if (isLamelle) printLength += 60;

    String bemerkung = data['Bemerkung']?.toString() ?? '';
    if (bemerkung.isNotEmpty) {
      const int charsPerLine = 40;
      int lines = (bemerkung.length / charsPerLine).ceil();
      printLength += 8 + (lines * 6);
    }

    String nrExt = data['Nr_ext']?.toString() ?? '';
    if (nrExt.isNotEmpty) printLength += 8;

    // Volumen berechnen
    double totalVolume = _calculateVolume(data, isLamelle);

    // Seitenformat
    final pageFormat = PdfPageFormat(
      labelWidthMm * PdfPageFormat.mm,
      printLength * PdfPageFormat.mm,
      marginLeft: 8 * PdfPageFormat.mm,
      marginRight: 8 * PdfPageFormat.mm,
      marginTop: 8 * PdfPageFormat.mm,
      marginBottom: 8 * PdfPageFormat.mm,
    );

    // Content aufbauen
    final List<pw.Widget> content = [
      // Logo
      pw.Image(image, height: 40, fit: pw.BoxFit.fitHeight),
      pw.SizedBox(height: 4),

      // Barcode-Box
      _buildBarcodeBox(data, pageFormat),

      // Lamelle-Banner
      if (isLamelle) _buildLamelleBanner(),

      // Hauptinfos
      _buildRow('Kunde', _getCustomerName(data)),
      _buildRow('Auftrag', data['Auftragsnr']?.toString() ?? '-'),
      _buildRow('Holzart', data['Holzart']?.toString() ?? '-'),
      _buildRow('D [mm]', data['H']?.toString() ?? '-'),
      _buildRow('B [mm]', data['B']?.toString() ?? '-'),
    ];

    // Länge & Stückzahl oder Lamellen-Details
    if (!isLamelle) {
      content.add(_buildRow('L [m]', data['L']?.toString() ?? '-'));
      content.add(_buildRow('Stk', data['Stk']?.toString() ?? '-'));
    } else {
      content.addAll(_buildLamellenRows(data));
    }

    // Zusatzinfos
    content.addAll([
      _buildRow('Menge', '${totalVolume.toStringAsFixed(2)} m³'),
      if (bemerkung.isNotEmpty) _buildRow('Info', bemerkung),
      if (nrExt.isNotEmpty) _buildRow('Nr. ext.', nrExt),

    ]);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: content,
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Paketzettel_${data['Barcode']}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ==================== HELPER ====================

  static pw.Widget _buildRow(String label, String value) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(flex: 3, child: pw.Text(label, style: pw.TextStyle(fontSize: 14))),
          pw.Expanded(flex: 6, child: pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _buildBarcodeBox(Map<String, dynamic> data, PdfPageFormat format) {
    final barcode = data['Barcode']?.toString() ?? '';
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(width: 2, color: PdfColors.black),
      ),
      padding: const pw.EdgeInsets.all(4),
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        children: [
          pw.Text(barcode, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20),
            color: PdfColors.white,
            child: pw.BarcodeWidget(
              data: barcode,
              barcode: pw.Barcode.code128(useCode128B: false),
              width: format.availableWidth * 0.8,
              height: 60,
              drawText: false,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLamelleBanner() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      decoration: pw.BoxDecoration(color: PdfColors.black),
      child: pw.Center(
        child: pw.Text('LAMELLE', style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
      ),
    );
  }

  static String _getCustomerName(Map<String, dynamic> data) {
    String name = data['Kunde']?.toString() ?? '-';
    if (data['useKundeAlias'] == true && (data['kundeAlias']?.toString() ?? '').isNotEmpty) {
      name = data['kundeAlias'].toString();
    }
    return name.length > 16 ? '${name.substring(0, 14)}...' : name;
  }

  static double _calculateVolume(Map<String, dynamic> data, bool isLamelle) {
    double parseDouble(String? v) => double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0.0;
    int parseInt(String? v) => int.tryParse(v ?? '') ?? 0;

    if (isLamelle) {
      final lam = data['Lamellen'] as Map<String, dynamic>? ?? {};
      double h = parseDouble(data['H']?.toString());
      double b = parseDouble(data['B']?.toString());

      double vol = 0.0;
      vol += 5.0 * (parseInt(lam['5.0']?.toString())) * h * b;
      vol += 4.5 * (parseInt(lam['4.5']?.toString())) * h * b;
      vol += 4.0 * (parseInt(lam['4.0']?.toString())) * h * b;
      vol += 3.5 * (parseInt(lam['3.5']?.toString())) * h * b;
      vol += 3.0 * (parseInt(lam['3.0']?.toString())) * h * b;
      return vol / 1000000.0;
    }

    double b = parseDouble(data['B']?.toString());
    double h = parseDouble(data['H']?.toString());
    double l = parseDouble(data['L']?.toString());
    int stk = parseInt(data['Stk']?.toString());
    return (b * h * l * stk) / 1000000.0;
  }

  static List<pw.Widget> _buildLamellenRows(Map<String, dynamic> data) {
    final lam = data['Lamellen'] as Map<String, dynamic>? ?? {};
    int parseInt(String? v) => int.tryParse(v ?? '') ?? 0;

    final lengths = [
      {'display': '5,0 m', 'key': '5.0'},
      {'display': '4,5 m', 'key': '4.5'},
      {'display': '4,0 m', 'key': '4.0'},
      {'display': '3,5 m', 'key': '3.5'},
      {'display': '3,0 m', 'key': '3.0'},
    ];

    final rows = <pw.Widget>[];
    for (var l in lengths) {
      rows.add(_buildRow(l['display']!, '${parseInt(lam[l['key']]?.toString())}'));
    }
    rows.add(_buildRow('Stk gesamt', data['Stk']?.toString() ?? '0'));
    return rows;
  }
}