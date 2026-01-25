// lib/packages/services/package_list_pdf_service.dart
// ═══════════════════════════════════════════════════════════════════════════
// PACKAGE LIST PDF SERVICE
// Generiert PDF-Listen aus gefilterten Lagerpaketen
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package_filter_service.dart';

class PackageListPdfService {
  /// Generiert eine PDF-Liste der Pakete
  static Future<Uint8List> generatePdf({
    required List<Map<String, dynamic>> packages,
    String? title,
    List<String>? activeFilters,
    bool groupByHolzart = true,
  }) async {
    final pdf = pw.Document();

    // Logo laden
    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    // Summary berechnen
    final filterService = PackageFilterService();
    final summary = filterService.generateSummary(packages);

    // Nach Holzart gruppieren
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    if (groupByHolzart) {
      for (var pkg in packages) {
        final holzart = pkg['holzart']?.toString() ?? 'Unbekannt';
        grouped.putIfAbsent(holzart, () => []).add(pkg);
      }
    } else {
      grouped['Alle Pakete'] = packages;
    }

    final sortedKeys = grouped.keys.toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(title ?? 'Lagerbestandsliste', logo),
        footer: (context) => _buildFooter(context),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Filter-Info
          if (activeFilters != null && activeFilters.isNotEmpty) {
            widgets.add(_buildFilterInfo(activeFilters));
            widgets.add(pw.SizedBox(height: 16));
          }

          // Summary
          widgets.add(_buildSummary(summary));
          widgets.add(pw.SizedBox(height: 24));

          // Pakete nach Gruppen
          for (int i = 0; i < sortedKeys.length; i++) {
            final holzart = sortedKeys[i];
            final holzartPackages = grouped[holzart]!;

            if (groupByHolzart && sortedKeys.length > 1) {
              widgets.add(_buildHolzartHeader(holzart, holzartPackages));
              widgets.add(pw.SizedBox(height: 8));
            }

            widgets.add(_buildPackageTable(holzartPackages));

            if (i < sortedKeys.length - 1) {
              widgets.add(pw.SizedBox(height: 20));
            }
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF KOMPONENTEN
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildHeader(String title, pw.MemoryImage? logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Erstellt am ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey600),
              ),
            ],
          ),
          if (logo != null) pw.Image(logo, width: 120),
        ],
      ),
    );
  }

  static pw.Widget _buildFilterInfo(List<String> filters) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),

      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Aktive Filter:',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,

            ),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: filters
                .map((text) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColors.grey),
              ),
              child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary(PackageSummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Pakete', '${summary.totalPackages}'),
          _summaryItem('Stückzahl', '${summary.totalStueck} Stk'),
          _summaryItem('Gesamtvolumen', '${summary.totalMenge.toStringAsFixed(3)} m³'),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey600)),
      ],
    );
  }

  static pw.Widget _buildHolzartHeader(String holzart, List<Map<String, dynamic>> packages) {
    final menge = packages.fold<double>(
      0,
          (sum, pkg) => sum + ((pkg['menge'] ?? 0) as num).toDouble(),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            holzart,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.Text(
            '${packages.length} Pakete · ${menge.toStringAsFixed(3)} m³',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPackageTable(List<Map<String, dynamic>> packages) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),  // Nr (schmaler)
        1: const pw.FlexColumnWidth(0.8),  // Ext.Nr
        2: const pw.FlexColumnWidth(1.5),  // Holzart (breiter)
        3: const pw.FlexColumnWidth(0.4),  // Z (nur F/T)
        4: const pw.FlexColumnWidth(0.6),  // H
        5: const pw.FlexColumnWidth(0.6),  // B
        6: const pw.FlexColumnWidth(0.6),  // L
        7: const pw.FlexColumnWidth(0.5),  // Stk
        8: const pw.FlexColumnWidth(0.9),  // m³
        9: const pw.FlexColumnWidth(1.0),  // Lagerort
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: [
            _tableHeader('Nr'),
            _tableHeader('Ext.Nr'),
            _tableHeader('Holzart'),
            _tableHeader('Z'),
            _tableHeader('H'),
            _tableHeader('B'),
            _tableHeader('L'),
            _tableHeader('Stk'),
            _tableHeader('m³'),
            _tableHeader('Lagerort'),
          ],
        ),
        // Daten
        ...packages.asMap().entries.map((entry) {
          final index = entry.key;
          final pkg = entry.value;
          final zustand = pkg['zustand'] ?? 'frisch';
          final zustandKurz = zustand == 'frisch' ? 'F' : 'T';
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.grey50,
            ),
            children: [
              _tableCell(pkg['barcode']?.toString() ?? '-'),
              _tableCell(pkg['nrExt']?.toString() ?? '-'),
              _tableCell(pkg['holzart']?.toString() ?? '-'),
              _tableCellCenter(zustandKurz),
              _tableCellRight(_formatNum(pkg['hoehe'])),
              _tableCellRight(_formatNum(pkg['breite'])),
              _tableCellRight(_formatNum(pkg['laenge'])),
              _tableCellRight((pkg['stueckzahl'] ?? 0).toString()),
              _tableCellRight(((pkg['menge'] ?? 0) as num).toStringAsFixed(3)),
              _tableCell(pkg['lagerort']?.toString() ?? '-'),
            ],
          );
        }),
        // Summenzeile
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: [
            _tableCellBold('Summe'),
            _tableCell(''),
            _tableCellBold('${packages.length} Pakete'),
            _tableCell(''),
            _tableCell(''),
            _tableCell(''),
            _tableCell(''),
            _tableCellRightBold(packages
                .fold<int>(0, (sum, pkg) => sum + ((pkg['stueckzahl'] ?? 0) as num).toInt())
                .toString()),
            _tableCellRightBold(packages
                .fold<double>(0, (sum, pkg) => sum + ((pkg['menge'] ?? 0) as num).toDouble())
                .toStringAsFixed(3)),
            _tableCell(''),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
          color: PdfColors.blueGrey800,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  static pw.Widget _tableCellCenter(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _tableCellRight(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
      ),
    );
  }

  static pw.Widget _tableCellBold(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCellRightBold(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
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
              pw.Text('Hagelenweg 1a · 78652 Deißlingen', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.Text(
            'Seite ${context.pageNumber} von ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey600),
          ),
        ],
      ),
    );
  }

  static String _formatNum(dynamic value) {
    if (value == null) return '0';
    final n = (value as num).toDouble();
    return n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(1);
  }
}