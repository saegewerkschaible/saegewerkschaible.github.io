// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/sections/dimensions_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/packages/fields/number_field_calc.dart';
import 'package:saegewerk/packages/fields/read_only_field.dart';
import 'package:saegewerk/packages/services/dimensions_service.dart';
import '../../core/theme/theme_provider.dart';

class DimensionsSection extends StatefulWidget {
  final TextEditingController hController;
  final TextEditingController bController;
  final TextEditingController lController;
  final TextEditingController stkController;
  final TextEditingController mengeController;
  // NEU: Abzug Controller
  final TextEditingController? abzugStkController;
  final TextEditingController? abzugLaengeController;

  final Map<String, bool> invalidFields;
  final VoidCallback onRecalculateVolume;
  final VoidCallback onStkFieldTap;
  final VoidCallback? onAbzugStkFieldTap;
  final Function(String label, TextEditingController controller, List<String> options) onSelectFieldTap;

  // Pin-Properties
  final bool pinStaerke;
  final bool pinBreite;
  final bool pinLaenge;
  final bool pinAbzugLaenge;  // <-- NEU
  final Function(String)? onTogglePin;
  final Function(String, String)? onPinnedValueChanged;
  static const String labelStaerke = 'Stärke [mm]';
  static const String labelBreite = 'Breite [mm]';
  static const String labelLaenge = 'Länge [m]';
  static const String labelStueckzahl = 'Stückzahl';
  static const String labelAbzugStk = 'Abzug Stk';
  static const String labelAbzugLaenge = 'Abzug Länge [m]';

  const DimensionsSection({
    super.key,
    required this.hController,
    required this.bController,
    required this.lController,
    required this.stkController,
    required this.mengeController,
    this.abzugStkController,
    this.abzugLaengeController,
    required this.invalidFields,
    required this.onRecalculateVolume,
    required this.onStkFieldTap,
    this.onAbzugStkFieldTap,
    required this.onSelectFieldTap,
    this.pinStaerke = false,
    this.pinBreite = false,
    this.pinLaenge = false,
    this.pinAbzugLaenge = false,  // <-- NEU
    this.onTogglePin,
    this.onPinnedValueChanged,
  });

  @override
  State<DimensionsSection> createState() => _DimensionsSectionState();
}

class _DimensionsSectionState extends State<DimensionsSection> {
  final _dimensionsService = DimensionsService();

  List<String> _heightOptions = [];
  List<String> _widthOptions = [];
  List<String> _lengthOptions = [];
  bool _isLoading = true;

  // Feste Abzug-Längen Optionen
  static const List<String> _abzugLaengeOptions = ['0.5', '1', '1.5', '2'];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final heights = await _dimensionsService.getHeightOptions();
    final widths = await _dimensionsService.getWidthOptions();
    final lengths = await _dimensionsService.getLengthOptions();

    if (mounted) {
      setState(() {
        _heightOptions = heights.map(_formatValue).toList();
        _widthOptions = widths.map(_formatValue).toList();
        _lengthOptions = lengths.map(_formatValue).toList();
        _isLoading = false;
      });
    }
  }

  String _formatValue(double value) {
    return value == value.toInt() ? value.toInt().toString() : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CircularProgressIndicator(color: theme.primary),
        ),
      );
    }

    return Column(
      children: [
        // Stärke & Breite
        Row(
          children: [
            Expanded(
              child: _buildPinnableSelectField(
                context: context,
                theme: theme,
                label: DimensionsSection.labelStaerke,
                controller: widget.hController,
                options: _heightOptions,
                icon: Icons.height,
                isRequired: true,
                isInvalid: widget.invalidFields[DimensionsSection.labelStaerke] == true,
                isPinned: widget.pinStaerke,
                pinField: 'staerke',
                onTap: () => widget.onSelectFieldTap(
                  DimensionsSection.labelStaerke,
                  widget.hController,
                  _heightOptions,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPinnableSelectField(
                context: context,
                theme: theme,
                label: DimensionsSection.labelBreite,
                controller: widget.bController,
                options: _widthOptions,
                icon: Icons.width_normal,
                isRequired: true,
                isInvalid: widget.invalidFields[DimensionsSection.labelBreite] == true,
                isPinned: widget.pinBreite,
                pinField: 'breite',
                onTap: () => widget.onSelectFieldTap(
                  DimensionsSection.labelBreite,
                  widget.bController,
                  _widthOptions,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Länge & Stückzahl
        Row(
          children: [
            Expanded(
              child: _buildPinnableSelectField(
                context: context,
                theme: theme,
                label: DimensionsSection.labelLaenge,
                controller: widget.lController,
                options: _lengthOptions,
                icon: Icons.square_foot,
                isRequired: true,
                isInvalid: widget.invalidFields[DimensionsSection.labelLaenge] == true,
                isPinned: widget.pinLaenge,
                pinField: 'laenge',
                onTap: () => widget.onSelectFieldTap(
                  DimensionsSection.labelLaenge,
                  widget.lController,
                  _lengthOptions,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NumberFieldCalc(
                label: DimensionsSection.labelStueckzahl,
                controller: widget.stkController,
                icon: Icons.format_list_numbered,
                iconName: 'format_list_numbered',
                isRequired: true,
                isInvalid: widget.invalidFields[DimensionsSection.labelStueckzahl] == true,
                onTap: widget.onStkFieldTap,
                onChanged: (value) => widget.onRecalculateVolume(),
              ),
            ),
          ],
        ),

        // ═══════════════════════════════════════════════════════════════
        // ABZUG SECTION - nur wenn Controller übergeben wurden
        // ═══════════════════════════════════════════════════════════════
        if (widget.abzugStkController != null &&
            widget.abzugLaengeController != null) ...[
          const SizedBox(height: 16),
          _buildAbzugSection(theme),
        ],

        const SizedBox(height: 16),

        // Volumen (Brutto)
        ReadOnlyField(
          label: _hasAbzug() ? 'Brutto [m³]' : 'Volumen [m³]',
          value: widget.mengeController.text,
          icon: Icons.view_in_ar,
          iconName: 'view_in_ar',
        ),

        // Abzug + Netto anzeigen wenn Abzug vorhanden
        if (_hasAbzug()) ...[
          const SizedBox(height: 8),
          _buildAbzugVolumenField(theme),
          const SizedBox(height: 8),
          _buildNettoVolumenField(theme),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ABZUG SECTION
  // ═══════════════════════════════════════════════════════════════

  bool _hasAbzug() {
    final stk = int.tryParse(widget.abzugStkController?.text ?? '') ?? 0;
    return stk > 0;
  }

  Widget _buildAbzugSection(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 18, color: theme.error),
              const SizedBox(width: 8),
              Text(
                'Abzug (Ausschuss)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Abzug Felder
          Row(
            children: [
              // Abzug Stückzahl
              Expanded(
                child: _buildAbzugStkField(theme),
              ),
              const SizedBox(width: 12),
              // Abzug Länge
              Expanded(
                child: _buildAbzugLaengeField(theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbzugStkField(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.exposure_neg_1, size: 16, color: theme.textSecondary),
            const SizedBox(width: 6),
            Text(
              DimensionsSection.labelAbzugStk,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: widget.onAbzugStkFieldTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.abzugStkController!.text.isEmpty
                        ? '0'
                        : widget.abzugStkController!.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: widget.abzugStkController!.text.isEmpty
                          ? theme.textHint
                          : theme.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.calculate_outlined, color: theme.textSecondary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAbzugLaengeField(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.straighten, size: 16, color: theme.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                DimensionsSection.labelAbzugLaenge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // NEU: Pin-Button für Abzug Länge
            if (widget.onTogglePin != null)
              GestureDetector(
                onTap: () => widget.onTogglePin!('abzugLaenge'),
                child: Icon(
                  widget.pinAbzugLaenge ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 16,
                  color: widget.pinAbzugLaenge ? theme.primary : theme.textHint,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            widget.onSelectFieldTap(
              DimensionsSection.labelAbzugLaenge,
              widget.abzugLaengeController!,
              _abzugLaengeOptions,
            );
            // NEU: Gepinnten Wert aktualisieren
            Future.delayed(const Duration(milliseconds: 100), () {
              widget.onPinnedValueChanged?.call('abzugLaenge', widget.abzugLaengeController!.text);
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              // NEU: Pin-Styling
              color: widget.pinAbzugLaenge
                  ? theme.primary.withOpacity(0.05)
                  : theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.pinAbzugLaenge ? theme.primary : theme.border,
                width: widget.pinAbzugLaenge ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.abzugLaengeController!.text.isEmpty
                        ? '-'
                        : widget.abzugLaengeController!.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: widget.abzugLaengeController!.text.isEmpty
                          ? theme.textHint
                          : theme.textPrimary,
                      // NEU: Bold wenn gepinnt
                      fontWeight: widget.pinAbzugLaenge ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: theme.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
  double _calculateAbzugVolumen() {
    final h = double.tryParse(widget.hController.text) ?? 0;
    final b = double.tryParse(widget.bController.text) ?? 0;
    final abzugL = double.tryParse(widget.abzugLaengeController?.text ?? '') ?? 0;
    final abzugStk = int.tryParse(widget.abzugStkController?.text ?? '') ?? 0;
    return (h * b * abzugL * abzugStk) / 1000000;
  }

  Widget _buildAbzugVolumenField(ThemeProvider theme) {
    final abzugVolumen = _calculateAbzugVolumen();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.remove_circle, size: 16, color: theme.error),
          const SizedBox(width: 8),
          Text(
            'Abzug:',
            style: TextStyle(fontSize: 13, color: theme.error),
          ),
          const Spacer(),
          Text(
            '-${abzugVolumen.toStringAsFixed(3)} m³',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNettoVolumenField(ThemeProvider theme) {
    final brutto = double.tryParse(widget.mengeController.text) ?? 0;
    final abzug = _calculateAbzugVolumen();
    final netto = brutto - abzug;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primary, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: theme.primary),
          const SizedBox(width: 8),
          Text(
            'Netto:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          ),
          const Spacer(),
          Text(
            '${netto.toStringAsFixed(3)} m³',
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

  Widget _buildPinnableSelectField({
    required BuildContext context,
    required ThemeProvider theme,
    required String label,
    required TextEditingController controller,
    required List<String> options,
    required IconData icon,
    required bool isRequired,
    required bool isInvalid,
    required bool isPinned,
    required String pinField,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isRequired)
              Text(' *', style: TextStyle(color: theme.error, fontSize: 12)),
            const SizedBox(width: 4),
            if (widget.onTogglePin != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => widget.onTogglePin!(pinField),
                child: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 16,
                  color: isPinned ? theme.primary : theme.textHint,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            onTap();
            Future.delayed(const Duration(milliseconds: 100), () {
              widget.onPinnedValueChanged?.call(pinField, controller.text);
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isPinned ? theme.primary.withOpacity(0.05) : theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isInvalid
                    ? theme.error
                    : isPinned
                    ? theme.primary
                    : theme.border,
                width: isPinned ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? '-' : controller.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: controller.text.isEmpty ? theme.textHint : theme.textPrimary,
                      fontWeight: isPinned ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: theme.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}