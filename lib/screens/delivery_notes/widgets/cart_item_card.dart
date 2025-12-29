// lib/screens/delivery_notes/widgets/cart_item_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_provider.dart';
import '../services/cart_provider.dart';
import 'info_chips.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Barcode + Holzart + Delete
            Row(
              children: [
                // Barcode Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primary.withOpacity(0.15),
                        theme.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code, size: 14, color: theme.primary),
                      const SizedBox(width: 6),
                      Text(
                        item.barcode,
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Holzart Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.park, size: 14, color: theme.success),
                      const SizedBox(width: 4),
                      Text(
                        item.holzart,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.success,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Delete Button
                IconButton(
                  onPressed: () => _showRemoveDialog(context, theme),
                  icon: Icon(Icons.delete_outline, color: theme.error),
                  tooltip: 'Entfernen',
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: theme.border, height: 1),
            const SizedBox(height: 12),

            // Info Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PackageInfoChip(
                  icon: Icons.straighten,
                  label: item.dimensionsString,
                  iconName: 'straighten',
                ),
                PackageInfoChip(
                  icon: Icons.format_list_numbered,
                  iconName: 'format_list_numbered',
                  label: '${item.stueckzahl} Stk',
                ),
                PackageInfoChip(
                  icon: Icons.view_in_ar,
                  label: '${item.menge.toStringAsFixed(3)} m³', iconName: 'view_in_ar',
                ),
              ],
            ),

            // Zustand Badge
            if (item.zustand.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildZustandBadge(theme),
            ],

            // Bemerkung
            if (item.bemerkung != null && item.bemerkung!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 16, color: theme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.bemerkung!,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZustandBadge(ThemeProvider theme) {
    Color bgColor;
    Color textColor;

    switch (item.zustand.toLowerCase()) {
      case 'frisch':
        bgColor = theme.info.withOpacity(0.1);
        textColor = theme.info;
        break;
      case 'trocken':
        bgColor = theme.success.withOpacity(0.1);
        textColor = theme.success;
        break;
      case 'verarbeitet':
        bgColor = theme.warning.withOpacity(0.1);
        textColor = theme.warning;
        break;
      default:
        bgColor = theme.textSecondary.withOpacity(0.1);
        textColor = theme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.zustand,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, ThemeProvider theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Paket entfernen', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          'Möchtest du Paket ${item.barcode} aus dem Warenkorb entfernen?',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRemove();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}