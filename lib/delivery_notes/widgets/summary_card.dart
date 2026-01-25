import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

import 'package:saegewerk/services/icon_helper.dart';

// Summary Card für verschiedene Layouts
class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isCompact;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    final iconSize = isCompact ? 20.0 : 28.0;
    final labelSize = isCompact ? 12.0 : 14.0;
    final valueSize = isCompact ? 16.0 : 22.0;
    final padding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 20);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: theme.primary),
          SizedBox(height: isCompact ? 8 : 12),
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              color: theme.textSecondary,
            ),
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: valueSize,
              color: theme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}