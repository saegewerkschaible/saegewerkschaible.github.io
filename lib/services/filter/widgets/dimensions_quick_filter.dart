// lib/services/filter/widgets/dimensions_quick_filter.dart
// ═══════════════════════════════════════════════════════════════════════════
// DIMENSIONS QUICK FILTER
// Schnellauswahl-Filter für Dimensionen aus Settings
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

import '../../../packages/services/dimensions_service.dart';

/// Widget für Dimensions-Schnellauswahl (aus settings/dimensions)
/// Kann im FilterWidget verwendet werden für exakte Filterung
class DimensionsQuickFilter extends StatelessWidget {
  final Set<double> selectedHeights;
  final Set<double> selectedWidths;
  final Set<double> selectedLengths;
  final Function(Set<double>) onHeightsChanged;
  final Function(Set<double>) onWidthsChanged;
  final Function(Set<double>) onLengthsChanged;

  const DimensionsQuickFilter({
    Key? key,
    required this.selectedHeights,
    required this.selectedWidths,
    required this.selectedLengths,
    required this.onHeightsChanged,
    required this.onWidthsChanged,
    required this.onLengthsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return StreamBuilder<Map<String, List<double>>>(
      stream: DimensionsService().watchDimensions(),
      builder: (context, snapshot) {
        final dimensions = snapshot.data ?? {};
        final heights = dimensions['height'] ?? [];
        final widths = dimensions['width'] ?? [];
        final lengths = dimensions['length'] ?? [];

        final hasAnyOptions = heights.isNotEmpty || widths.isNotEmpty || lengths.isNotEmpty;
        final hasSelections = selectedHeights.isNotEmpty ||
            selectedWidths.isNotEmpty ||
            selectedLengths.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Reset-Button
            if (hasSelections)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_countSelections()} ausgewählt',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        onHeightsChanged({});
                        onWidthsChanged({});
                        onLengthsChanged({});
                      },
                      icon: Icon(Icons.clear_all, size: 16, color: colors.error),
                      label: Text(
                        'Alle löschen',
                        style: TextStyle(fontSize: 12, color: colors.error),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),

            // Stärke/Höhe
            if (heights.isNotEmpty) ...[
              _buildDimensionSection(
                context: context,
                colors: colors,
                label: 'Stärke',
                unit: 'mm',
                icon: Icons.height,
                values: heights,
                selected: selectedHeights,
                onChanged: onHeightsChanged,
              ),
              const SizedBox(height: 16),
            ],

            // Breite
            if (widths.isNotEmpty) ...[
              _buildDimensionSection(
                context: context,
                colors: colors,
                label: 'Breite',
                unit: 'mm',
                icon: Icons.swap_horiz,
                values: widths,
                selected: selectedWidths,
                onChanged: onWidthsChanged,
              ),
              const SizedBox(height: 16),
            ],

            // Länge
            if (lengths.isNotEmpty)
              _buildDimensionSection(
                context: context,
                colors: colors,
                label: 'Länge',
                unit: 'm',
                icon: Icons.straighten,
                values: lengths,
                selected: selectedLengths,
                onChanged: onLengthsChanged,
              ),

            // Keine Optionen konfiguriert
            if (!hasAnyOptions)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keine Schnellauswahl-Werte konfiguriert.\n'
                            'Gehe zu Einstellungen → Dimensionen um Werte hinzuzufügen.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  int _countSelections() {
    return selectedHeights.length + selectedWidths.length + selectedLengths.length;
  }

  Widget _buildDimensionSection({
    required BuildContext context,
    required dynamic colors,
    required String label,
    required String unit,
    required IconData icon,
    required List<double> values,
    required Set<double> selected,
    required Function(Set<double>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label mit Icon und Badge
        Row(
          children: [
            Icon(icon, size: 16, color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selected.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = selected.contains(value);
            final displayValue = value == value.toInt()
                ? value.toInt().toString()
                : value.toString();

            return FilterChip(
              label: Text('$displayValue $unit'),
              selected: isSelected,
              onSelected: (sel) {
                final newSet = Set<double>.from(selected);
                if (sel) {
                  newSet.add(value);
                } else {
                  newSet.remove(value);
                }
                onChanged(newSet);
              },
              selectedColor: colors.primary.withOpacity(0.2),
              checkmarkColor: colors.primary,
              backgroundColor: colors.surface,
              side: BorderSide(
                color: isSelected ? colors.primary : colors.border,
              ),
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Kompaktes Widget für die Anzeige in der ActiveFiltersBar
class DimensionsQuickFilterChips extends StatelessWidget {
  final Set<double> selectedHeights;
  final Set<double> selectedWidths;
  final Set<double> selectedLengths;
  final VoidCallback onClear;

  const DimensionsQuickFilterChips({
    Key? key,
    required this.selectedHeights,
    required this.selectedWidths,
    required this.selectedLengths,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final parts = <String>[];

    if (selectedHeights.isNotEmpty) {
      parts.add('H: ${selectedHeights.map((h) => "${h.toInt()}").join(", ")} mm');
    }
    if (selectedWidths.isNotEmpty) {
      parts.add('B: ${selectedWidths.map((w) => "${w.toInt()}").join(", ")} mm');
    }
    if (selectedLengths.isNotEmpty) {
      parts.add('L: ${selectedLengths.map((l) => "$l").join(", ")} m');
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.straighten, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            parts.join(' | '),
            style: TextStyle(
              fontSize: 12,
              color: colors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 14, color: colors.primary),
          ),
        ],
      ),
    );
  }
}