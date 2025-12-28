// ═══════════════════════════════════════════════════════════════════════════
// lib/shared/fields/input_field.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/services/icon_helper.dart';
import '../../core/theme/theme_provider.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String iconName;
  final bool isNumberKeyboard;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.iconName,
    this.isNumberKeyboard = false,
    this.readOnly = false,
    this.onChanged,
  });

  bool get _isIOS => Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);  // ← Geändert

    return Container(
      decoration: BoxDecoration(
        color: theme.background,      // ← colors → theme
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),  // ← colors → theme
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(theme),         // ← colors → theme
          _buildTextField(theme),     // ← colors → theme
        ],
      ),
    );
  }

  Widget _buildLabel(ThemeProvider theme) {  // ← Typ geändert
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          getAdaptiveIcon(
            iconName: iconName,
            defaultIcon: icon,
            size: 16,
            color: theme.textSecondary,  // ← colors → theme
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textSecondary,  // ← colors → theme
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(ThemeProvider theme) {  // ← Typ geändert
    return TextFormField(
      keyboardType: isNumberKeyboard
          ? _isIOS
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number
          : TextInputType.text,
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      inputFormatters: isNumberKeyboard
          ? [
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.contains(',')) {
            return TextEditingValue(
              text: newValue.text.replaceAll(',', '-'),
              selection: newValue.selection,
            );
          }
          return newValue;
        }),
      ]
          : null,
      style: TextStyle(
        fontSize: 14,
        color: theme.textPrimary,  // ← colors → theme
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 12),
        border: InputBorder.none,
        fillColor: Colors.transparent,
        filled: true,
      ),
    );
  }
}