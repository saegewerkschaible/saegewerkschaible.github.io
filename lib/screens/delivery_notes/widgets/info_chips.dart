// lib/screens/DeliveryNotes/widgets/info_chips.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';


import '../../../services/icon_helper.dart';

/// Info-Chip für Lieferschein-Karten (Tablet/Desktop)
class DeliveryInfoChip extends StatelessWidget {
  final IconData icon;
  final String iconName;
  final String label;

  const DeliveryInfoChip({
    Key? key,
    required this.icon,
    required this.iconName,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          getAdaptiveIcon(
            iconName: iconName,
            defaultIcon: icon,
            size: 16,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info-Chip für Paket-Details
class PackageInfoChip extends StatelessWidget {
  final IconData icon;
  final String iconName;
  final String label;

  const PackageInfoChip({
    Key? key,
    required this.icon,
    required this.iconName,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          getAdaptiveIcon(
            iconName: iconName,
            defaultIcon: icon,
            color: colors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile Info-Tile (größer, für Touch)
class MobileInfoTile extends StatelessWidget {
  final IconData icon;
  final String iconName;
  final String label;
  final String value;

  const MobileInfoTile({
    Key? key,
    required this.icon,
    required this.iconName,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              getAdaptiveIcon(
                iconName: iconName,
                defaultIcon: icon,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kompaktes Summary-Item für Mobile
class CompactSummaryItem extends StatelessWidget {
  final IconData icon;
  final String iconName;
  final String value;
  final String label;

  const CompactSummaryItem({
    Key? key,
    required this.icon,
    required this.iconName,
    required this.value,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getAdaptiveIcon(
              iconName: iconName,
              defaultIcon: icon,
              size: 18,
              color: colors.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}