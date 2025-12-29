// lib/screens/DeliveryNotes/widgets/delivery_note_card.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/icon_helper.dart';
import '../models/layout_type.dart';
import '../delivery_note_detail_screen.dart';
import 'info_chips.dart';

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

class _MobileDeliveryNoteCard extends StatelessWidget {
  final Map<String, dynamic> noteData;
  final bool isEven;

  const _MobileDeliveryNoteCard({
    required this.noteData,
    required this.isEven,
  });

  Future<void> _downloadPdf(BuildContext context, String pdfUrl) async {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;

    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keine PDF-URL verfügbar'),
          backgroundColor: colors.error,
        ),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(pdfUrl);
      await launchUrl(url, mode: LaunchMode.externalApplication);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download gestartet'),
          backgroundColor: colors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Download: $e'),
          backgroundColor: colors.error,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    final DateFormat timeFormatter = DateFormat('HH:mm');

    final DateTime? createdAt =
    (noteData['createdAt'] as Timestamp?)?.toDate();
    final String number = noteData['number'] ?? '';
    final String customerName = noteData['customerName'] ?? '';
    final double totalVolume =
        (noteData['totalVolume'] as num?)?.toDouble() ?? 0.0;
    final int totalQuantity = noteData['totalQuantity'] as int? ?? 0;
    final String pdfUrl = noteData['pdfUrl'] ?? '';

    final backgroundColor = isEven ? colors.surface : colors.background;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nummer + Datum
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        getAdaptiveIcon(
                          iconName: 'receipt',
                          defaultIcon: Icons.receipt,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          number,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (createdAt != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatter.format(createdAt),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          timeFormatter.format(createdAt),
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 8),

              // Kunde mit Download-Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: getAdaptiveIcon(
                      iconName: 'person',
                      defaultIcon: Icons.person,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kunde',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: getAdaptiveIcon(
                      iconName: 'download',
                      defaultIcon: Icons.download,
                      color: colors.primary,
                      size: 22,
                    ),
                    onPressed: () => _downloadPdf(context, pdfUrl),
                    tooltip: 'PDF herunterladen',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Volumen, Anzahl & Pakete
              Row(
                children: [
                  Expanded(
                    child: MobileInfoTile(
                      icon: Icons.inventory_2,
                      iconName: 'inventory_2',
                      label: 'Pakete',
                      value:
                      '${(noteData['items'] as List<dynamic>?)?.length ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MobileInfoTile(
                      icon: Icons.format_list_numbered,
                      iconName: 'format_list_numbered',
                      label: 'Stk.',
                      value: '$totalQuantity',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MobileInfoTile(
                      icon: Icons.view_in_ar,
                      iconName: 'view_in_ar',
                      label: 'Vol.',
                      value: '${totalVolume.toStringAsFixed(1)} m³',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopDeliveryNoteCard extends StatelessWidget {
  final Map<String, dynamic> noteData;
  final LayoutType layoutType;

  const _DesktopDeliveryNoteCard({
    required this.noteData,
    required this.layoutType,
  });

  Future<void> _downloadPdf(BuildContext context, String pdfUrl) async {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;

    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keine PDF-URL verfügbar'),
          backgroundColor: colors.error,
        ),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Download gestartet'),
            backgroundColor: colors.success,
          ),
        );
      } else {
        throw 'URL kann nicht geöffnet werden';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Download: $e'),
          backgroundColor: colors.error,
        ),
      );
    }
  }

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
    final String pdfUrl = noteData['pdfUrl'] ?? '';

    double borderRadius;
    double padding;
    double titleFontSize;

    switch (layoutType) {
      case LayoutType.mobile:
        borderRadius = 12;
        padding = 16;
        titleFontSize = 16;
        break;
      case LayoutType.tablet:
        borderRadius = 14;
        padding = 18;
        titleFontSize = 18;
        break;
      case LayoutType.desktop:
        borderRadius = 16;
        padding = 20;
        titleFontSize = 18;
        break;
    }

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: colors.border),
      ),
      elevation: 2,
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
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Nr. $number',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    createdAt != null ? formatter.format(createdAt) : '',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  getAdaptiveIcon(
                    iconName: 'person',
                    defaultIcon: Icons.person,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customerName,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  DeliveryInfoChip(
                    icon: Icons.view_in_ar,
                    iconName: 'view_in_ar',
                    label: '${totalVolume.toStringAsFixed(2)} m³',
                  ),
                  const SizedBox(width: 8),
                  DeliveryInfoChip(
                    icon: Icons.format_list_numbered,
                    iconName: 'format_list_numbered',
                    label: '$totalQuantity Stk',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: getAdaptiveIcon(
                      iconName: 'download',
                      defaultIcon: Icons.download,
                      color: colors.textSecondary,
                    ),
                    onPressed: () => _downloadPdf(context, pdfUrl),
                    tooltip: 'Herunterladen',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}