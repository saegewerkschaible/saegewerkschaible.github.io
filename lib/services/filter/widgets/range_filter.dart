// lib/services/filter/widgets/range_filter.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';


import '../../../services/icon_helper.dart';
import '../filter_settings.dart';

/// Volumenfilter mit RangeSlider
class VolumeRangeFilter extends StatelessWidget {
  final FilterSettings settings;
  final VoidCallback onChanged;

  const VolumeRangeFilter({
    Key? key,
    required this.settings,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hauptschalter
        Row(
          children: [
            Checkbox(
              value: settings.volumeFilterEnabled,
              onChanged: (bool? value) {
                settings.volumeFilterEnabled = value ?? false;
                settings.notifyListeners();
                onChanged();
              },
              activeColor: colors.primary,
            ),
            Text(
              'Volumenfilter aktivieren',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),

        if (settings.volumeFilterEnabled) ...[
          // Min/Max Checkboxen
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _CheckboxRow(
                    label: 'Untere Grenze',
                    value: settings.minVolumeEnabled,
                    onChanged: (value) {
                      settings.minVolumeEnabled = value ?? false;
                      settings.notifyListeners();
                      onChanged();
                    },
                  ),
                ),
                Expanded(
                  child: _CheckboxRow(
                    label: 'Obere Grenze',
                    value: settings.maxVolumeEnabled,
                    onChanged: (value) {
                      settings.maxVolumeEnabled = value ?? false;
                      settings.notifyListeners();
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Slider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                RangeSlider(
                  min: 0,
                  max: 10,
                  divisions: 1000,
                  labels: RangeLabels(
                    settings.minVolumeEnabled
                        ? '${settings.volumeRange.start.toStringAsFixed(1)} m³'
                        : 'Min',
                    settings.maxVolumeEnabled
                        ? '${settings.volumeRange.end.toStringAsFixed(1)} m³'
                        : 'Max',
                  ),
                  values: settings.volumeRange,
                  onChanged: (RangeValues values) {
                    settings.volumeRange = values;
                    settings.notifyListeners();
                    onChanged();
                  },
                  activeColor: colors.primary,
                  inactiveColor: colors.border,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        settings.minVolumeEnabled
                            ? '${settings.volumeRange.start.toStringAsFixed(1)} m³'
                            : 'keine Untergrenze',
                        style: TextStyle(
                          color: settings.minVolumeEnabled
                              ? colors.textPrimary
                              : colors.textHint,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        settings.maxVolumeEnabled
                            ? '${settings.volumeRange.end.toStringAsFixed(1)} m³'
                            : 'keine Obergrenze',
                        style: TextStyle(
                          color: settings.maxVolumeEnabled
                              ? colors.textPrimary
                              : colors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Längenfilter mit Textfeldern
class LengthRangeFilter extends StatelessWidget {
  final FilterSettings settings;
  final TextEditingController minController;
  final TextEditingController maxController;
  final VoidCallback onChanged;

  const LengthRangeFilter({
    Key? key,
    required this.settings,
    required this.minController,
    required this.maxController,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: settings.laengeFilterEnabled,
              onChanged: (bool? value) {
                settings.laengeFilterEnabled = value ?? false;
                settings.notifyListeners();
                onChanged();
              },
              activeColor: colors.primary,
            ),
            Text(
              'Filter aktivieren',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        if (settings.laengeFilterEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _RangeInputField(
                    label: 'Min',
                    suffix: 'm',
                    controller: minController,
                    enabled: settings.minLaengeEnabled,
                    checkboxValue: settings.minLaengeEnabled,
                    onCheckboxChanged: (value) {
                      settings.minLaengeEnabled = value ?? false;
                      if (!settings.minLaengeEnabled) {
                        minController.clear();
                      }
                      settings.notifyListeners();
                      onChanged();
                    },
                    onTextChanged: (value) {
                      final newValue = double.tryParse(value) ?? 0.0;
                      settings.laengeRange = RangeValues(
                        newValue,
                        settings.laengeRange.end,
                      );
                      settings.notifyListeners();
                      onChanged();
                    },
                    allowDecimal: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RangeInputField(
                    label: 'Max',
                    suffix: 'm',
                    controller: maxController,
                    enabled: settings.maxLaengeEnabled,
                    checkboxValue: settings.maxLaengeEnabled,
                    onCheckboxChanged: (value) {
                      settings.maxLaengeEnabled = value ?? false;
                      if (!settings.maxLaengeEnabled) {
                        maxController.clear();
                      }
                      settings.notifyListeners();
                      onChanged();
                    },
                    onTextChanged: (value) {
                      final newValue = double.tryParse(value) ?? 0.0;
                      settings.laengeRange = RangeValues(
                        settings.laengeRange.start,
                        newValue,
                      );
                      settings.notifyListeners();
                      onChanged();
                    },
                    allowDecimal: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Freie Dimensionen Filter (Stärke/Breite)
class FreeDimensionsFilter extends StatelessWidget {
  final FilterSettings settings;
  final TextEditingController minStaerkeController;
  final TextEditingController maxStaerkeController;
  final TextEditingController minBreiteController;
  final TextEditingController maxBreiteController;
  final VoidCallback onChanged;

  const FreeDimensionsFilter({
    Key? key,
    required this.settings,
    required this.minStaerkeController,
    required this.maxStaerkeController,
    required this.minBreiteController,
    required this.maxBreiteController,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: settings.dimensionFilterEnabled,
              onChanged: (bool? value) {
                settings.dimensionFilterEnabled = value ?? false;
                settings.notifyListeners();
                onChanged();
              },
              activeColor: colors.primary,
            ),
            Text(
              'Filter aktivieren',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        if (settings.dimensionFilterEnabled) ...[
          // Stärke
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Stärke (mm)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _RangeInputField(
                    label: 'Min',
                    controller: minStaerkeController,
                    enabled: settings.minStaerkeEnabled,
                    checkboxValue: settings.minStaerkeEnabled,
                    onCheckboxChanged: (value) {
                      settings.minStaerkeEnabled = value ?? false;
                      settings.notifyListeners();
                      onChanged();
                    },
                    onTextChanged: (value) {
                      final newValue = int.tryParse(value) ?? 0;
                      settings.staerkeRange = RangeValues(
                        newValue.toDouble(),
                        settings.staerkeRange.end,
                      );
                      settings.notifyListeners();
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RangeInputField(
                    label: 'Max',
                    controller: maxStaerkeController,
                    enabled: settings.maxStaerkeEnabled,
                    checkboxValue: settings.maxStaerkeEnabled,
                    onCheckboxChanged: (value) {
                      settings.maxStaerkeEnabled = value ?? false;
                      settings.notifyListeners();
                      onChanged();
                    },
                    onTextChanged: (value) {
                      final newValue = int.tryParse(value) ?? 0;
                      settings.staerkeRange = RangeValues(
                        settings.staerkeRange.start,
                        newValue.toDouble(),
                      );
                      settings.notifyListeners();
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Breite
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Breite (mm)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _RangeInputField(
                    label: 'Min',
                    controller: minBreiteController,
                    enabled: settings.minBreiteEnabled,
                    checkboxValue: settings.minBreiteEnabled,
                    onCheckboxChanged: (value) {
                      settings.minBreiteEnabled = value ?? false;
                      settings.notifyListeners();
                      onChanged();
                    },
                    onTextChanged: (value) {
                      final newValue = int.tryParse(value) ?? 0;
                      settings.breiteRange = RangeValues(
                        newValue.toDouble(),
                        settings.breiteRange.end,
                      );
                      settings.notifyListeners();
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RangeInputField(
                    label: 'Max',
                    controller: maxBreiteController,
                    enabled: settings.maxBreiteEnabled,
                    checkboxValue: settings.maxBreiteEnabled,
                    onCheckboxChanged: (value) {
                      settings.maxBreiteEnabled = value ?? false;
                      settings.notifyListeners();
                      onChanged();
                    },
                    onTextChanged: (value) {
                      final newValue = int.tryParse(value) ?? 0;
                      settings.breiteRange = RangeValues(
                        settings.breiteRange.start,
                        newValue.toDouble(),
                      );
                      settings.notifyListeners();
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Combined Dimensions Filter mit Tabs
class CombinedDimensionsFilter extends StatelessWidget {
  final FilterSettings settings;
  final Widget standardFilter;
  final Widget freeFilter;

  const CombinedDimensionsFilter({
    Key? key,
    required this.settings,
    required this.standardFilter,
    required this.freeFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              indicator: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.primary.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      getAdaptiveIcon(
                        iconName: 'grid_4x4',
                        defaultIcon: Icons.grid_4x4,
                        size: 12,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: 2),
                      const Text('Standard'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      getAdaptiveIcon(
                        iconName: 'edit',
                        defaultIcon: Icons.edit,
                        size: 12,
                        color: colors.textPrimary,
                      ),
                      const SizedBox(width: 2),
                      const Text('Frei'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: TabBarView(
              children: [
                SingleChildScrollView(child: standardFilter),
                SingleChildScrollView(child: freeFilter),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _CheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: colors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RangeInputField extends StatelessWidget {
  final String label;
  final String? suffix;
  final TextEditingController controller;
  final bool enabled;
  final bool checkboxValue;
  final ValueChanged<bool?> onCheckboxChanged;
  final ValueChanged<String> onTextChanged;
  final bool allowDecimal;

  const _RangeInputField({
    required this.label,
    this.suffix,
    required this.controller,
    required this.enabled,
    required this.checkboxValue,
    required this.onCheckboxChanged,
    required this.onTextChanged,
    this.allowDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: checkboxValue,
            onChanged: onCheckboxChanged,
            activeColor: colors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: allowDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            inputFormatters: [
              allowDecimal
                  ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  : FilteringTextInputFormatter.digitsOnly,
            ],
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              hintText: label,
              hintStyle: TextStyle(color: colors.textHint),
              suffixText: suffix,
              suffixStyle: TextStyle(color: colors.textSecondary),
              filled: true,
              fillColor: enabled ? colors.surface : colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border.withOpacity(0.5)),
              ),
            ),
            onChanged: onTextChanged,
          ),
        ),
      ],
    );
  }
}