// ═══════════════════════════════════════════════════════════════════════════
// lib/roundwood/widgets/filter_chip_widget.dart
// Wiederverwendbares Filter-Chip Widget mit ThemeProvider-Integration
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

import 'package:saegewerk/services/icon_helper.dart';

/// Filter-Chip für die Anzeige aktiver Filter
///
/// Zeigt einen Filter mit Icon, Label und Close-Button
/// Verwendet automatisch die Farben aus dem aktiven Theme
Widget buildFilterChip({
  required BuildContext context,
  required String label,
  required VoidCallback onDelete,
  required IconData icon,
  required String iconName,
  Color? color,
}) {
  final colors = Provider.of<ThemeProvider>(context, listen: false).colors;
  final chipColor = color ?? colors.primary;

  return Container(
    decoration: BoxDecoration(
      color: chipColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: chipColor.withOpacity(0.2),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          getAdaptiveIcon(
            iconName: iconName,
            defaultIcon: icon,
            size: 16,
            color: chipColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: chipColor,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: getAdaptiveIcon(
                iconName: 'close',
                defaultIcon: Icons.close,
                size: 16,
                color: chipColor,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}