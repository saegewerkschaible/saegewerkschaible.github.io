// ═══════════════════════════════════════════════════════════════════════════
// lib/shared/fields/select_field.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/services/icon_helper.dart';
import '../../core/theme/theme_provider.dart';

class SelectField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> options;
  final IconData icon;
  final String iconName;
  final bool allowCustomInput;
  final ValueChanged<String>? onChanged;
  final bool isRequired;
  final bool isInvalid;
  final VoidCallback onTap;
  final String placeholder;

  const SelectField({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    required this.icon,
    required this.iconName,
    required this.onTap,
    this.allowCustomInput = false,
    this.onChanged,
    this.isRequired = false,
    this.isInvalid = false,
    this.placeholder = 'Wählen',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInvalid ? theme.error : theme.border,
          width: isInvalid ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(theme),
                    const SizedBox(height: 4),
                    _buildValue(theme),
                  ],
                ),
              ),
            ),
            if (isInvalid) _buildErrorText(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(ThemeProvider theme) {
    return Row(
      children: [
        getAdaptiveIcon(
          iconName: iconName,
          defaultIcon: icon,
          size: 16,
          color: isInvalid ? theme.error : theme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isInvalid ? theme.error : theme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildValue(ThemeProvider theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            controller.text.isEmpty ? placeholder : controller.text,
            style: TextStyle(
              fontSize: 14,
              color: controller.text.isEmpty
                  ? theme.textSecondary.withOpacity(0.5)  // textHint Ersatz
                  : theme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        getAdaptiveIcon(
          iconName: 'arrow_drop_down',
          defaultIcon: Icons.arrow_drop_down,
          color: theme.textSecondary,
        ),
      ],
    );
  }

  Widget _buildErrorText(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      child: Text(
        'Pflichtfeld',
        style: TextStyle(
          color: theme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}