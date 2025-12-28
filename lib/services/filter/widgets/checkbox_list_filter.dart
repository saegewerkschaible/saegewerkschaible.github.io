// lib/services/filter/widgets/checkbox_list_filter.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

/// Generisches Widget für Checkbox-Listen-Filter
/// Verwendbar für: Holzarten, Zustände, Dimensionen, Lagerort, Status, etc.
class CheckboxListFilter extends StatelessWidget {
  final List<String> options;
  final Set<String> activeOptions;
  final ValueChanged<String> onToggle;
  final Map<String, Color>? colorMap;
  final bool showColorIndicator;

  const CheckboxListFilter({
    Key? key,
    required this.options,
    required this.activeOptions,
    required this.onToggle,
    this.colorMap,
    this.showColorIndicator = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Column(
      children: options.asMap().entries.map((entry) {
        int index = entry.key;
        String option = entry.value;
        bool isActive = activeOptions.contains(option);
        Color? indicatorColor = colorMap?[option];

        return Container(
          color: index % 2 == 0 ? colors.surface : colors.background,
          child: CheckboxListTile(
            title: Row(
              children: [
                if (showColorIndicator && indicatorColor != null) ...[
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
                Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            value: isActive,
            onChanged: (bool? value) => onToggle(option),
            activeColor: showColorIndicator && indicatorColor != null
                ? indicatorColor
                : colors.primary,
            checkColor: colors.textOnPrimary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );
      }).toList(),
    );
  }
}

/// Spezialisiertes Widget für Text-Suche (Auftragsnummer, Kunde Freitext)
class TextSearchFilter extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? currentValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final IconData icon;
  final String iconName;

  const TextSearchFilter({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.currentValue,
    required this.onChanged,
    required this.onClear,
    this.icon = Icons.search,
    this.iconName = 'search',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            color: colors.textHint,
          ),
          filled: true,
          fillColor: colors.surface,
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
          prefixIcon: Icon(
            icon,
            size: 18,
            color: colors.primary,
          ),
          suffixIcon: currentValue != null && currentValue!.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              size: 16,
              color: colors.textSecondary,
            ),
            onPressed: onClear,
          )
              : null,
        ),
        onChanged: onChanged,
      ),
    );
  }
}