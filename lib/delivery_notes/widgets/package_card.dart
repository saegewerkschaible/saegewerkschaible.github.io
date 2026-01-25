// lib/screens/DeliveryNotes/widgets/package_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

import '../../services/icon_helper.dart';
import 'info_chips.dart';

class PackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final String packageId;
  final Map<String, dynamic>? matchingItem;
  final int index;
  final bool isEven;
  final VoidCallback onDelete;

  const PackageCard({
    Key? key,
    required this.package,
    required this.packageId,
    required this.matchingItem,
    required this.index,
    required this.isEven,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    if (matchingItem == null) {
      return const SizedBox.shrink();
    }

    final String woodType = matchingItem!['holzart']?.toString() ?? 'Unbekannt';
    final positions = matchingItem!['positions'] as List<dynamic>? ?? [];
    final backgroundColor = isEven ? colors.surface : colors.background;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border, width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Index Badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: colors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Package ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primary.withOpacity(0.15),
                            colors.primary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        packageId,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Wood Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          getAdaptiveIcon(
                            iconName: 'park',
                            defaultIcon: Icons.park,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            woodType,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Delete Button
                IconButton(
                  icon: getAdaptiveIcon(
                    iconName: 'delete',
                    defaultIcon: Icons.delete,
                    color: colors.error,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 16),

            // Positions
            for (var i = 0; i < positions.length; i++) ...[
              if (positions.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Position ${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              _buildPositionInfo(context, colors, positions[i] as Map<String, dynamic>),
              if (i < positions.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: colors.border, height: 1),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPositionInfo(
      BuildContext context,
      dynamic colors,
      Map<String, dynamic> pos,
      ) {
    final double width = (pos['B'] as num?)?.toDouble() ?? 0.0;
    final double height = (pos['H'] as num?)?.toDouble() ?? 0.0;
    final double length = (pos['L'] as num?)?.toDouble() ?? 0.0;
    final int quantity = (pos['Stk'] as num?)?.toInt() ?? 0;
    final double volume = (pos['volume'] as num?)?.toDouble() ?? 0.0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PackageInfoChip(
          icon: Icons.straighten,
          iconName: 'straighten',
          label: '${length.toStringAsFixed(1)} × ${width.round()} × ${height.round()}',
        ),
        PackageInfoChip(
          icon: Icons.format_list_numbered,
          iconName: 'format_list_numbered',
          label: '$quantity Stk',
        ),
        PackageInfoChip(
          icon: Icons.view_in_ar,
          iconName: 'view_in_ar',
          label: '${volume.toStringAsFixed(2)} m³',
        ),
      ],
    );
  }
}