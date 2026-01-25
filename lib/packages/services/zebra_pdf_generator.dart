// lib/services/printing/zebra_pdf_generator.dart
// ═══════════════════════════════════════════════════════════════════════════
// AKTUALISIERT: Mit Design-Einstellungen aus Firestore
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:saegewerk/screens/admin/paketzettel_design_screen.dart';


/// PDF-Generator für Zebra-Paketzettel
class ZebraPdfGenerator {

  /// Lädt die Design-Einstellungen aus Firestore
  static Future<PaketzettelDesignSettings> _loadDesignSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('paketzettel_design')
          .get();

      if (doc.exists) {
        return PaketzettelDesignSettings.fromMap(doc.data()!);
      }
    } catch (e) {
      print('⚠️ Design-Einstellungen konnten nicht geladen werden: $e');
    }
    return const PaketzettelDesignSettings();
  }

  /// Lädt ein Bild von einer URL
  static Future<pw.MemoryImage?> _loadImageFromUrl(String? url) async {
    if (url == null || url.isEmpty) return null;

    try {
      print("🌐 Lade Bild von: $url");
      final response = await http.get(Uri.parse(url));
      print("📥 HTTP Status: ${response.statusCode}, Bytes: ${response.bodyBytes.length}");

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print("❌ Fehler beim Laden des Bildes: $e");
    }
    return null;
  }

  /// Lädt das Kundenlogo aus Firestore über die Kunden-ID
  static Future<pw.MemoryImage?> _loadCustomerLogo(String? kundeId) async {
    if (kundeId == null || kundeId.isEmpty) {
      print("❌ kundeId ist null oder leer");
      return null;
    }

    try {
      print("🔍 Lade Kunde mit ID: $kundeId");

      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(kundeId)
          .get();

      if (!doc.exists) {
        print("❌ Kunde $kundeId existiert nicht in Firestore");
        return null;
      }

      final data = doc.data();
      final logoUrl = data?['logoBwUrl']?.toString();

      print("📎 logoBwUrl: $logoUrl");

      if (logoUrl == null || logoUrl.isEmpty) {
        print("❌ logoBwUrl ist leer");
        return null;
      }

      final image = await _loadImageFromUrl(logoUrl);
      print("🖼️ Bild geladen: ${image != null ? 'JA' : 'NEIN'}");

      return image;
    } catch (e) {
      print("❌ Fehler beim Laden des Kundenlogos: $e");
      return null;
    }
  }

  /// Generiert PDF für Standard-Paketzettel
  static Future<File> generatePackageLabel(
      Map<String, dynamic> data,
      double labelWidthMm,
      ) async {
    final pdf = pw.Document();

    // Design-Einstellungen laden
    final settings = await _loadDesignSettings();
    print("📐 Design-Einstellungen geladen: logoPosition=${settings.logoPosition}");

    // Firmenlogo laden
    final ByteData logoData = await rootBundle.load('assets/images/logo_sw.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final companyLogo = pw.MemoryImage(logoBytes);

    // Kundenlogo über Kunden-ID aus Firestore laden
    final kundeId = data['kundeId']?.toString();
    print("k:$kundeId");
    pw.MemoryImage? customerLogo = await _loadCustomerLogo(kundeId);

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

    // Abzug prüfen - extra Höhe wenn vorhanden
    final abzugStk = _parseInt(data['AbzugStk']?.toString());
    final hasAbzug = abzugStk > 0;
    if (hasAbzug) printLength += 24;

    // Kundenlogo: extra Höhe wenn beide Logos untereinander
    if (customerLogo != null && settings.logoPosition == 'stacked') {
      printLength += 16;
    }

    // Volumen berechnen
    double bruttoVolume = _calculateVolume(data, isLamelle);
    double abzugVolume = 0;
    double nettoVolume = bruttoVolume;

    if (hasAbzug) {
      abzugVolume = _calculateAbzugVolume(data);
      nettoVolume = bruttoVolume - abzugVolume;
    }

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
      // Logo-Header mit Design-Einstellungen
      _buildLogoHeader(companyLogo, customerLogo, settings),
      pw.SizedBox(height: settings.sectionSpacing),

      // Barcode-Box
      _buildBarcodeBox(data, pageFormat, settings),

      // Lamelle-Banner
      if (isLamelle) _buildLamelleBanner(settings),

      // Hauptinfos
      _buildRow('Kunde', _getCustomerName(data), settings),
      _buildRow('Auftrag', data['Auftragsnr']?.toString() ?? '-', settings),
      _buildRow('Holzart', data['Holzart']?.toString() ?? '-', settings),
      _buildRow('D [mm]', data['H']?.toString() ?? '-', settings),
      _buildRow('B [mm]', data['B']?.toString() ?? '-', settings),
    ];

    // Länge & Stückzahl oder Lamellen-Details
    if (!isLamelle) {
      content.add(_buildRow('L [m]', data['L']?.toString() ?? '-', settings));
      content.add(_buildRow('Stk', data['Stk']?.toString() ?? '-', settings));
    } else {
      content.addAll(_buildLamellenRows(data, settings));
    }

    // Volumen-Bereich
    if (hasAbzug) {
      content.add(_buildRow('Brutto', '${bruttoVolume.toStringAsFixed(3)} m³', settings));
      content.add(_buildAbzugRow(data, abzugVolume, settings));
      content.add(_buildNettoRow(nettoVolume, settings));
    } else {
      content.add(_buildRow('Menge', '${bruttoVolume.toStringAsFixed(3)} m³', settings));
    }

    // Zusatzinfos
    if (bemerkung.isNotEmpty) content.add(_buildRow('Info', bemerkung, settings));
    if (nrExt.isNotEmpty) content.add(_buildRow('Nr. ext.', nrExt, settings));

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

  static double _parseDouble(String? v) => double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0.0;
  static int _parseInt(String? v) => int.tryParse(v ?? '') ?? 0;

  /// Logo-Header mit Design-Einstellungen
  static pw.Widget _buildLogoHeader(
      pw.MemoryImage companyLogo,
      pw.MemoryImage? customerLogo,
      PaketzettelDesignSettings settings,
      ) {
    print("🎨 _buildLogoHeader: position=${settings.logoPosition}, customerLogo=${customerLogo != null ? 'JA' : 'NEIN'}");

    switch (settings.logoPosition) {
      case 'company_only':
      // Nur Firmenlogo zentriert
        return pw.Center(
          child: pw.Image(companyLogo, height: settings.companyLogoHeight, fit: pw.BoxFit.fitHeight),
        );

      case 'customer_only':
      // Nur Kundenlogo (falls vorhanden)
        if (customerLogo == null) {
          return pw.Center(
            child: pw.Image(companyLogo, height: settings.companyLogoHeight, fit: pw.BoxFit.fitHeight),
          );
        }
        return pw.Center(
          child: pw.Container(
            height: settings.customerLogoHeight,
            width: settings.customerLogoWidth,
            child: pw.Image(customerLogo, fit: pw.BoxFit.contain),
          ),
        );

      case 'stacked':
      // Logos untereinander
        return pw.Column(
          children: [
            pw.Image(companyLogo, height: settings.companyLogoHeight, fit: pw.BoxFit.fitHeight),
            if (customerLogo != null) ...[
              pw.SizedBox(height: 4),
              pw.Container(
                height: settings.customerLogoHeight,
                width: settings.customerLogoWidth,
                child: pw.Image(customerLogo, fit: pw.BoxFit.contain),
              ),
            ],
          ],
        );

      case 'split':
      default:
      // Standard: Firma links, Kunde rechts
        if (customerLogo == null) {
          return pw.Center(
            child: pw.Image(companyLogo, height: settings.companyLogoHeight, fit: pw.BoxFit.fitHeight),
          );
        }

        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Firmenlogo links
            pw.Container(
              height: settings.companyLogoHeight,
              child: pw.Image(companyLogo, fit: pw.BoxFit.contain),
            ),

            // Kundenlogo rechts
            pw.Container(
              height: settings.customerLogoHeight,
              width: settings.customerLogoWidth,
              child: pw.Image(customerLogo, fit: pw.BoxFit.contain),
            ),
          ],
        );
    }
  }

  static pw.Widget _buildRow(String label, String value, PaketzettelDesignSettings settings) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      padding: pw.EdgeInsets.symmetric(vertical: settings.rowPadding),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(label, style: pw.TextStyle(fontSize: settings.labelFontSize)),
          ),
          pw.Expanded(
            flex: 6,
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: settings.valueFontSize, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAbzugRow(Map<String, dynamic> data, double abzugVolume, PaketzettelDesignSettings settings) {
    final abzugStk = _parseInt(data['AbzugStk']?.toString());
    final abzugL = _parseDouble(data['AbzugLaenge']?.toString());

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      padding: pw.EdgeInsets.symmetric(vertical: settings.rowPadding),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text('Abzug', style: pw.TextStyle(fontSize: settings.labelFontSize)),
          ),
          pw.Expanded(
            flex: 6,
            child: pw.Text(
              '-$abzugStk x ${abzugL}m = -${abzugVolume.toStringAsFixed(3)} m³',
              style: pw.TextStyle(fontSize: settings.labelFontSize, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNettoRow(double nettoVolume, PaketzettelDesignSettings settings) {
    return _buildRow('Netto', '${nettoVolume.toStringAsFixed(3)} m³', settings);
  }

  static pw.Widget _buildBarcodeBox(Map<String, dynamic> data, PdfPageFormat format, PaketzettelDesignSettings settings) {
    final barcode = data['Barcode']?.toString() ?? '';
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(width: 2, color: PdfColors.black),
      ),
      padding: const pw.EdgeInsets.all(4),
      margin: pw.EdgeInsets.symmetric(vertical: settings.sectionSpacing),
      child: pw.Column(
        children: [
          pw.Text(
            barcode,
            style: pw.TextStyle(fontSize: settings.barcodeNumberSize, fontWeight: pw.FontWeight.bold),
          ),
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

  static pw.Widget _buildLamelleBanner(PaketzettelDesignSettings settings) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      decoration: pw.BoxDecoration(color: PdfColors.black),
      child: pw.Center(
        child: pw.Text(
          'LAMELLE',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: settings.headerFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static String _getCustomerName(Map<String, dynamic> data) {
    String name = data['Kunde']?.toString() ?? '-';
    if (data['useKundeAlias'] == true && (data['kundeAlias']?.toString() ?? '').isNotEmpty) {
      name = data['kundeAlias'].toString();
    }
    return name.length > 19 ? '${name.substring(0, 19)}...' : name;
  }

  static double _calculateVolume(Map<String, dynamic> data, bool isLamelle) {
    if (isLamelle) {
      final lam = data['Lamellen'] as Map<String, dynamic>? ?? {};
      double h = _parseDouble(data['H']?.toString());
      double b = _parseDouble(data['B']?.toString());

      double vol = 0.0;
      vol += 5.0 * (_parseInt(lam['5.0']?.toString())) * h * b;
      vol += 4.5 * (_parseInt(lam['4.5']?.toString())) * h * b;
      vol += 4.0 * (_parseInt(lam['4.0']?.toString())) * h * b;
      vol += 3.5 * (_parseInt(lam['3.5']?.toString())) * h * b;
      vol += 3.0 * (_parseInt(lam['3.0']?.toString())) * h * b;
      return vol / 1000000.0;
    }

    double b = _parseDouble(data['B']?.toString());
    double h = _parseDouble(data['H']?.toString());
    double l = _parseDouble(data['L']?.toString());
    int stk = _parseInt(data['Stk']?.toString());
    return (b * h * l * stk) / 1000000.0;
  }

  static double _calculateAbzugVolume(Map<String, dynamic> data) {
    double h = _parseDouble(data['H']?.toString());
    double b = _parseDouble(data['B']?.toString());
    double abzugL = _parseDouble(data['AbzugLaenge']?.toString());
    int abzugStk = _parseInt(data['AbzugStk']?.toString());
    return (h * b * abzugL * abzugStk) / 1000000.0;
  }

  static List<pw.Widget> _buildLamellenRows(Map<String, dynamic> data, PaketzettelDesignSettings settings) {
    final lam = data['Lamellen'] as Map<String, dynamic>? ?? {};

    final lengths = [
      {'display': '5,0 m', 'key': '5.0'},
      {'display': '4,5 m', 'key': '4.5'},
      {'display': '4,0 m', 'key': '4.0'},
      {'display': '3,5 m', 'key': '3.5'},
      {'display': '3,0 m', 'key': '3.0'},
    ];

    final rows = <pw.Widget>[];
    for (var l in lengths) {
      rows.add(_buildRow(l['display']!, '${_parseInt(lam[l['key']]?.toString())}', settings));
    }
    rows.add(_buildRow('Stk gesamt', data['Stk']?.toString() ?? '0', settings));
    return rows;
  }
}