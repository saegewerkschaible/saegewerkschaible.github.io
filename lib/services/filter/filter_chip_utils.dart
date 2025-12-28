// lib/services/filter/filter_chip_utils.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';


import '../../services/icon_helper.dart';

/// Utility-Funktion zum Erstellen von Filter-Chips
/// (Falls du die alte buildFilterChip Funktion noch brauchst)
Widget buildFilterChip({
  required String label,
  required VoidCallback onDelete,
  required IconData icon,
  required String iconName,
  Color? color,
}) {
  return Builder(
    builder: (context) {
      final colors = Provider.of<ThemeProvider>(context).colors;
      final chipColor = color ?? colors.primary;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            getAdaptiveIcon(
              iconName: iconName,
              defaultIcon: icon,
              size: 14,
              color: chipColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: chipColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                size: 14,
                color: chipColor,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Stateless Widget Version für bessere Performance
class FilterChipWidget extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  final IconData icon;
  final String iconName;
  final Color? color;

  const FilterChipWidget({
    Key? key,
    required this.label,
    required this.onDelete,
    required this.icon,
    required this.iconName,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final chipColor = color ?? colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          getAdaptiveIcon(
            iconName: iconName,
            defaultIcon: icon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              size: 14,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}