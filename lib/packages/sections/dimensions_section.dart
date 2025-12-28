// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/sections/dimensions_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/packages/fields/number_field_calc.dart';
import 'package:saegewerk/packages/fields/read_only_field.dart';
import 'package:saegewerk/packages/fields/select_field.dart';
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
              child: SelectField(
                label: DimensionsSection.labelStaerke,
                controller: widget.hController,
                options: _heightOptions,
                icon: Icons.height,
                iconName: 'height',
                isRequired: true,
                isInvalid: widget.invalidFields[DimensionsSection.labelStaerke] == true,
                onTap: () => widget.onSelectFieldTap(
                  DimensionsSection.labelStaerke,
                  widget.hController,
                  _heightOptions,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectField(
                label: DimensionsSection.labelBreite,
                controller: widget.bController,
                options: _widthOptions,
                icon: Icons.width_normal,
                iconName: 'width_normal',
                isRequired: true,
                isInvalid: widget.invalidFields[DimensionsSection.labelBreite] == true,
                onTap: () => widget.onSelectFieldTap(
                  DimensionsSection.labelBreite,
                  widget.bController,
                  _widthOptions,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Länge & Stückzahl
        Row(
          children: [
            Expanded(
              child: SelectField(
                label: DimensionsSection.labelLaenge,
                controller: widget.lController,
                options: _lengthOptions,
                icon: Icons.square_foot,
                iconName: 'square_foot',
                isRequired: true,
                isInvalid: widget.invalidFields[DimensionsSection.labelLaenge] == true,
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
}