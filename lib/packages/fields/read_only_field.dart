// ═══════════════════════════════════════════════════════════════════════════
// lib/shared/fields/read_only_field.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/services/icon_helper.dart';
import '../../core/theme/theme_provider.dart';


class ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String iconName;
  final VoidCallback? onTap;
  final String? message;
  final Function(String message)? onShowMessage;

  const ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconName,
    this.onTap,
    this.message,
    this.onShowMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),  // primaryLight gibt's nicht
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap ?? (message != null && onShowMessage != null
            ? () => onShowMessage!(message!)
            : null),
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
    );
  }

  Widget _buildLabel(ThemeProvider theme) {
    return Row(
      children: [
        getAdaptiveIcon(
          iconName: iconName,
          defaultIcon: icon,
          size: 16,
          color: theme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildValue(ThemeProvider theme) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.textPrimary,
      ),
    );
  }
}