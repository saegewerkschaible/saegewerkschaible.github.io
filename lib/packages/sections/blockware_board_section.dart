// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/sections/blockware_board_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/packages/dialogs/dimension_input_dialog.dart';
import '../../core/theme/theme_provider.dart';
import '../fields/read_only_field.dart';
import '../sections/section_container.dart';

/// Ein einzelnes Brett in einem Blockware-Paket
class BrettEntry {
  double breite; // in mm
  double laenge; // in m
  final TextEditingController breiteController;
  final TextEditingController laengeController;

  BrettEntry({
    this.breite = 0,
    this.laenge = 5.0,
  })  : breiteController = TextEditingController(
    text: breite > 0 ? breite.toStringAsFixed(0) : '',
  ),
        laengeController = TextEditingController(
          text: laenge.toString(),
        );

  void dispose() {
    breiteController.dispose();
    laengeController.dispose();
  }

  /// Volumen dieses Bretts in m³ (Stärke kommt von außen)
  double volumen(double staerke) {
    return (staerke * breite * laenge) / 1000000;
  }

  /// Ist dieses Brett ausgefüllt?
  bool get isFilled => breite > 0;

  /// Konvertiert zu Map für Firestore
  Map<String, dynamic> toMap() {
    return {
      'breite': breite,
      'laenge': laenge,
    };
  }

  /// Erstellt aus Firestore-Map
  factory BrettEntry.fromMap(Map<String, dynamic> map) {
    return BrettEntry(
      breite: (map['breite'] as num?)?.toDouble() ?? 0,
      laenge: (map['laenge'] as num?)?.toDouble() ?? 5.0,
    );
  }
}

/// Section für die Brettliste in einem Blockware-Paket
class BlockwareBoardSection extends StatefulWidget {
  final List<BrettEntry> bretter;
  final double staerke; // Fix für ganzes Paket
  final VoidCallback onChanged;

  const BlockwareBoardSection({
    super.key,
    required this.bretter,
    required this.staerke,
    required this.onChanged,
  });

  @override
  State<BlockwareBoardSection> createState() => _BlockwareBoardSectionState();
}

class _BlockwareBoardSectionState extends State<BlockwareBoardSection> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _lastBreiteFocus = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _lastBreiteFocus.dispose();
    super.dispose();
  }

// Helfer zum Öffnen des Dialogs (macht den Code sauberer)
  Future<void> _showBreiteInput(int index) async {
    if (!mounted || index >= widget.bretter.length) return;

    // 1. Maße aus Firestore laden
    final snapshot = await FirebaseFirestore.instance
        .collection('settings')
        .doc('dimensions')
        .get();

    final data = snapshot.data();
    List<String> options = [];

    if (data != null && data['blockware_widths'] != null) {
      // Werte laden, sortieren und als String-Liste formatieren
      final List<dynamic> rawValues = data['blockware_widths'];
      final List<double> sortedValues = rawValues.map((e) => (e as num).toDouble()).toList();
      sortedValues.sort();

      options = sortedValues.map((v) => v == v.toInt() ? v.toInt().toString() : v.toString()).toList();
    }

    // Falls Firebase leer ist, Fallback auf deine Standardwerte
    if (options.isEmpty) {
      options = List.generate(21, (i) => (40 + i).toString());
    }

    final brett = widget.bretter[index];

    if (!mounted) return;

    showDimensionInputDialog(
      context: context,
      controller: brett.breiteController,
      title: 'Breite [mm] (Brett ${index + 1})',
      quickOptions: options, // <--- Jetzt dynamisch aus Firebase
      onValueChanged: () => _onBreiteChanged(index, brett.breiteController.text),
    );
  }

  void _onBreiteChanged(int index, String value) {
    final parsed = double.tryParse(value) ?? 0;

    setState(() {
      widget.bretter[index].breite = parsed;

      // Wenn das letzte Brett ausgefüllt wurde -> neue Zeile erstellen
      if (index == widget.bretter.length - 1 && parsed > 0) {
        widget.bretter.add(BrettEntry());

        // AUTO-NEXT LOGIK:
        // Wir warten einen kurzen Moment (250ms), bis der aktuelle Dialog
        // komplett geschlossen ist, und öffnen dann sofort den nächsten.
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) _showBreiteInput(index + 1);
        });
      }
    });

    widget.onChanged(); // Volumen im Haupt-Widget aktualisieren
  }

  void _onLaengeChanged(int index, String value) {
    final parsed = double.tryParse(value) ?? 5.0;
    widget.bretter[index].laenge = parsed;
    widget.onChanged();
  }

  void _removeBrett(int index) {
    // Letztes leeres Brett nicht löschen
    if (widget.bretter.length <= 1) return;

    widget.bretter[index].dispose();
    widget.bretter.removeAt(index);
    widget.onChanged();
  }

  double _calculateTotalVolume() {
    double total = 0;
    for (final brett in widget.bretter) {
      if (brett.isFilled) {
        total += brett.volumen(widget.staerke);
      }
    }
    return total;
  }

  int _getFilledCount() {
    return widget.bretter.where((b) => b.isFilled).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return SectionContainer(
      children: [
        // Header mit Zusammenfassung
        _buildSummaryRow(theme),
        const SizedBox(height: 12),

        // Tabellen-Header
        _buildTableHeader(theme),

        // Brett-Liste
        ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.bretter.length,
          itemBuilder: (context, index) {
            return _buildBrettRow(theme, index);
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(ThemeProvider theme) {
    final count = _getFilledCount();
    final volume = _calculateTotalVolume();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.view_column, size: 18, color: theme.primary),
          const SizedBox(width: 8),
          Text(
            '$count Bretter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          ),
          const Spacer(),
          Text(
            '${volume.toStringAsFixed(3)} m³',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              'Nr.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Breite [mm]',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              'Länge [m]',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              'Vol. [m³]',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
          ),
          // Platz für Delete-Button
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBrettRow(ThemeProvider theme, int index) {
    final brett = widget.bretter[index];
    final isLast = index == widget.bretter.length - 1;
    final isEmpty = !brett.isFilled;
    final rowNumber = index + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.border.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Nummer
          SizedBox(
            width: 36,
            child: Text(
              isEmpty && isLast ? '' : '$rowNumber',
              style: TextStyle(fontSize: 13, color: theme.textSecondary),
            ),
          ),

          // 2. Breite (Tipp-Feld)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _showBreiteInput(index),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isLast && isEmpty ? theme.primary.withOpacity(0.03) : theme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isLast && isEmpty ? theme.primary.withOpacity(0.3) : theme.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  brett.breiteController.text.isEmpty && isLast ? '+ Breite' : brett.breiteController.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: brett.breiteController.text.isEmpty ? theme.textHint : theme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 3. Länge (Tipp-Feld)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                showDimensionInputDialog(
                  context: context,
                  controller: brett.laengeController,
                  title: 'Länge [m]',
                  quickOptions: const ['3', '3.5', '4', '4.5', '5'],
                  onValueChanged: () => _onLaengeChanged(index, brett.laengeController.text),
                );
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  brett.laengeController.text,
                  style: TextStyle(fontSize: 15, color: theme.textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 4. Volumen (Nur Text)
          Expanded(
            flex: 2,
            child: Text(
              brett.isFilled ? brett.volumen(widget.staerke).toStringAsFixed(4) : '-',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: theme.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),

          // 5. Löschen Button
          SizedBox(
            width: 40,
            child: (isEmpty && isLast) || widget.bretter.length <= 1
                ? const SizedBox()
                : IconButton(
              icon: Icon(Icons.close, size: 18, color: theme.error.withOpacity(0.7)),
              onPressed: () => _removeBrett(index),
            ),
          ),
        ],
      ),
    );
  }
}