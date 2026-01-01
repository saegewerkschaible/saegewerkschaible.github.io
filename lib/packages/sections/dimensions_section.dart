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
  final Map<String, bool> invalidFields;
  final VoidCallback onRecalculateVolume;
  final VoidCallback onStkFieldTap;
  final Function(String label, TextEditingController controller, List<String> options) onSelectFieldTap;

  // NEU: Pin-Properties
  final bool pinStaerke;
  final bool pinBreite;
  final bool pinLaenge;
  final Function(String) onTogglePin;
  final Function(String, String) onPinnedValueChanged;

  static const String labelStaerke = 'Stärke [mm]';
  static const String labelBreite = 'Breite [mm]';
  static const String labelLaenge = 'Länge [m]';
  static const String labelStueckzahl = 'Stückzahl';

  const DimensionsSection({
    super.key,
    required this.hController,
    required this.bController,
    required this.lController,
    required this.stkController,
    required this.mengeController,
    required this.invalidFields,
    required this.onRecalculateVolume,
    required this.onStkFieldTap,
    required this.onSelectFieldTap,
    // NEU: Pin-Props
    this.pinStaerke = false,
    this.pinBreite = false,
    this.pinLaenge = false,
    required this.onTogglePin,
    required this.onPinnedValueChanged,
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
            // Stückzahl OHNE Pin (macht keinen Sinn zu pinnen)
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
        const SizedBox(height: 16),

        // Volumen (ReadOnly)
        ReadOnlyField(
          label: 'Volumen [m³]',
          value: widget.mengeController.text,
          icon: Icons.view_in_ar,
          iconName: 'view_in_ar',
        ),
      ],
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
        // Label-Zeile mit Pin
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
            // Pin-Button
            GestureDetector(
              onTap: () => widget.onTogglePin(pinField),
              child: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 16,
                color: isPinned ? theme.primary : theme.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Select Field
        GestureDetector(
          onTap: () {
            onTap();
            // Nach Auswahl den Wert aktualisieren
            Future.delayed(const Duration(milliseconds: 100), () {
              widget.onPinnedValueChanged(pinField, controller.text);
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