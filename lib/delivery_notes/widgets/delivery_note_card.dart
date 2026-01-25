// lib/screens/DeliveryNotes/widgets/delivery_note_card.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

import '../../services/icon_helper.dart';
import '../models/layout_type.dart';
import '../delivery_note_detail_screen.dart';

class DeliveryNoteCard extends StatelessWidget {
  final Map<String, dynamic> noteData;
  final LayoutType layoutType;
  final bool isEven;

  const DeliveryNoteCard({
    Key? key,
    required this.noteData,
    required this.layoutType,
    this.isEven = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (layoutType == LayoutType.mobile) {
      return _MobileDeliveryNoteCard(noteData: noteData, isEven: isEven);
    } else {
      return _DesktopDeliveryNoteCard(noteData: noteData, layoutType: layoutType);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE CARD (Kompakt)
// ══════════════════════════════════════════════════════════════════════════════
class _MobileDeliveryNoteCard extends StatelessWidget {
  final Map<String, dynamic> noteData;
  final bool isEven;

  const _MobileDeliveryNoteCard({
    required this.noteData,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final DateFormat formatter = DateFormat('dd.MM.yy');

    final DateTime? createdAt =
    (noteData['createdAt'] as Timestamp?)?.toDate();
    final String number = noteData['number'] ?? '';
    final String customerName = noteData['customerName'] ?? '';
    final double totalVolume =
        (noteData['totalVolume'] as num?)?.toDouble() ?? 0.0;
    final int totalQuantity = noteData['totalQuantity'] as int? ?? 0;
    final int packageCount =
        (noteData['items'] as List<dynamic>?)?.length ?? 0;

    final backgroundColor = isEven ? colors.surface : colors.background;

    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border, width: 1),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryNoteDetailScreen(
                deliveryNote: noteData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Nummer Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Kunde + Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildMiniChip(
                          colors,
                          '$packageCount Pkt',
                          Icons.inventory_2,
                        ),
                        const SizedBox(width: 6),
                        _buildMiniChip(
                          colors,
                          '$totalQuantity Stk',
                          Icons.format_list_numbered,
                        ),
                        const SizedBox(width: 6),
                        _buildMiniChip(
                          colors,
                          '${totalVolume.toStringAsFixed(1)} m³',
                          Icons.view_in_ar,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Datum
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    createdAt != null ? formatter.format(createdAt) : '',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(dynamic colors, String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: colors.textSecondary),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP/TABLET CARD (Kompakt)
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopDeliveryNoteCard extends StatelessWidget {
  final Map<String, dynamic> noteData;
  final LayoutType layoutType;

  const _DesktopDeliveryNoteCard({
    required this.noteData,
    required this.layoutType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final DateFormat formatter = DateFormat('dd.MM.yyyy');

    final DateTime? createdAt =
    (noteData['createdAt'] as Timestamp?)?.toDate();
    final String number = noteData['number'] ?? '';
    final String customerName = noteData['customerName'] ?? '';
    final double totalVolume =
        (noteData['totalVolume'] as num?)?.toDouble() ?? 0.0;
    final int totalQuantity = noteData['totalQuantity'] as int? ?? 0;
    final int packageCount =
        (noteData['items'] as List<dynamic>?)?.length ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryNoteDetailScreen(
                deliveryNote: noteData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nummer + Datum
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Nr. $number',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    createdAt != null ? formatter.format(createdAt) : '',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Kunde
              Row(
                children: [
                  getAdaptiveIcon(
                    iconName: 'person',
                    defaultIcon: Icons.person,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stats
              Row(
                children: [
                  _buildStatChip(colors, '$packageCount Pkt', Icons.inventory_2),
                  const SizedBox(width: 6),
                  _buildStatChip(colors, '$totalQuantity Stk', Icons.format_list_numbered),
                  const SizedBox(width: 6),
                  _buildStatChip(colors, '${totalVolume.toStringAsFixed(1)} m³', Icons.view_in_ar),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(dynamic colors, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colors.textSecondary),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}