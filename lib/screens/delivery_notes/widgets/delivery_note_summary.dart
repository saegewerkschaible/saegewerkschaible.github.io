// lib/screens/DeliveryNotes/widgets/delivery_note_summary.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/screens/delivery_notes/widgets/summary_card.dart' hide CompactSummaryItem;
import 'package:saegewerk/services/filter/filter_settings.dart';


import '../../../services/icon_helper.dart';

import '../models/layout_type.dart';
import 'info_chips.dart';

class DeliveryNoteSummary extends StatelessWidget {
  final LayoutType layoutType;
  final Stream<QuerySnapshot> deliveryNotesStream;

  const DeliveryNoteSummary({
    Key? key,
    required this.layoutType,
    required this.deliveryNotesStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final filterSettings = Provider.of<FilterSettings>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: deliveryNotesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final deliveryNotes = snapshot.data?.docs ?? [];
        final filteredNotes = _applyFilters(deliveryNotes, filterSettings);

        final totalCount = filteredNotes.length;
        final totalVolume = filteredNotes.fold<double>(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + ((data['totalVolume'] as num?)?.toDouble() ?? 0.0);
        });

        switch (layoutType) {
          case LayoutType.mobile:
            return _buildMobileSummary(context, colors, filteredNotes, totalCount, totalVolume);
          case LayoutType.tablet:
            return _buildTabletSummary(context, colors, totalCount, totalVolume);
          case LayoutType.desktop:
            return _buildDesktopSummary(context, colors, filteredNotes, totalCount, totalVolume);
        }
      },
    );
  }

  List<QueryDocumentSnapshot> _applyFilters(
      List<QueryDocumentSnapshot> notes,
      FilterSettings filterSettings,
      ) {
    return notes.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Customer filter
      if (filterSettings.activePremiumkunden.isNotEmpty ||
          filterSettings.kundenFreitextFilter.isNotEmpty) {
        final customerName = data['customerName'] as String? ?? '';

        if (filterSettings.activePremiumkunden.isNotEmpty) {
          if (!filterSettings.activePremiumkunden.contains(customerName)) {
            return false;
          }
        }

        if (filterSettings.kundenFreitextFilter.isNotEmpty) {
          if (!customerName.toLowerCase().contains(
              filterSettings.kundenFreitextFilter.toLowerCase())) {
            return false;
          }
        }
      }

      // Date range filter
      if (filterSettings.dateRangeEnabled) {
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          if (filterSettings.startDate != null) {
            final startOfDay = DateTime(
              filterSettings.startDate!.year,
              filterSettings.startDate!.month,
              filterSettings.startDate!.day,
            );
            if (createdAt.isBefore(startOfDay)) return false;
          }
          if (filterSettings.endDate != null) {
            final endOfDay = DateTime(
              filterSettings.endDate!.year,
              filterSettings.endDate!.month,
              filterSettings.endDate!.day,
              23, 59, 59,
            );
            if (createdAt.isAfter(endOfDay)) return false;
          }
        } else {
          return false;
        }
      }

      // Volume filter
      if (filterSettings.volumeFilterEnabled) {
        final volume = (data['totalVolume'] as num?)?.toDouble() ?? 0.0;
        if (filterSettings.minVolumeEnabled &&
            volume < filterSettings.volumeRange.start) {
          return false;
        }
        if (filterSettings.maxVolumeEnabled &&
            volume > filterSettings.volumeRange.end) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int _getTotalPackages(List<QueryDocumentSnapshot> notes) {
    return notes.fold<int>(0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return sum + items.length;
    });
  }

  Set<String> _getUniqueCustomers(List<QueryDocumentSnapshot> notes) {
    return notes.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['customerName'] as String? ?? '';
    }).toSet();
  }

  Widget _buildMobileSummary(
      BuildContext context,
      dynamic colors,
      List<QueryDocumentSnapshot> filteredNotes,
      int totalCount,
      double totalVolume,
      ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.05),
            colors.primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CompactSummaryItem(
              icon: Icons.receipt_long,
              iconName: 'receipt_long',
              value: '$totalCount',
              label: 'Lieferungen',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colors.border,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: CompactSummaryItem(
              icon: Icons.inventory_2,
              iconName: 'inventory_2',
              value: '${_getTotalPackages(filteredNotes)}',
              label: 'Pakete',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colors.border,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: CompactSummaryItem(
              icon: Icons.view_in_ar,
              iconName: 'view_in_ar',
              value: '${totalVolume.toStringAsFixed(1)} m³',
              label: 'Vol.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletSummary(
      BuildContext context,
      dynamic colors,
      int totalCount,
      double totalVolume,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Lieferungen',
              value: '$totalCount',
              icon: Icons.receipt_long,
              iconName: 'receipt_long',
              layoutType: LayoutType.tablet,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              label: 'Gesamtmenge',
              value: '${totalVolume.toStringAsFixed(1)} m³',
              icon: Icons.view_in_ar,
              iconName: 'view_in_ar',
              layoutType: LayoutType.tablet,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              label: 'Durchschnitt',
              value: totalCount > 0
                  ? '${(totalVolume / totalCount).toStringAsFixed(1)} m³'
                  : '0.0 m³',
              icon: Icons.analytics,
              iconName: 'analytics',
              layoutType: LayoutType.tablet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSummary(
      BuildContext context,
      dynamic colors,
      List<QueryDocumentSnapshot> filteredNotes,
      int totalCount,
      double totalVolume,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Übersicht',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Lieferungen',
                  value: '$totalCount',
                  icon: Icons.receipt_long,
                  iconName: 'receipt_long',
                  layoutType: LayoutType.desktop,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  label: 'Gesamtmenge',
                  value: '${totalVolume.toStringAsFixed(1)} m³',
                  icon: Icons.view_in_ar,
                  iconName: 'view_in_ar',
                  layoutType: LayoutType.desktop,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  label: 'Durchschnitt',
                  value: totalCount > 0
                      ? '${(totalVolume / totalCount).toStringAsFixed(1)} m³'
                      : '0.0 m³',
                  icon: Icons.analytics,
                  iconName: 'analytics',
                  layoutType: LayoutType.desktop,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  label: 'Kunden',
                  value: '${_getUniqueCustomers(filteredNotes).length}',
                  icon: Icons.group,
                  iconName: 'group',
                  layoutType: LayoutType.desktop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String iconName;
  final LayoutType layoutType;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconName,
    required this.layoutType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    double iconSize;
    double labelFontSize;
    double valueFontSize;
    EdgeInsets padding;

    switch (layoutType) {
      case LayoutType.mobile:
        iconSize = 20;
        labelFontSize = 12;
        valueFontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        break;
      case LayoutType.tablet:
        iconSize = 24;
        labelFontSize = 14;
        valueFontSize = 18;
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
        break;
      case LayoutType.desktop:
        iconSize = 28;
        labelFontSize = 16;
        valueFontSize = 22;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
        break;
    }

    return Container(
      constraints: BoxConstraints(
        minWidth: layoutType == LayoutType.mobile ? 120 : 160,
      ),
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          getAdaptiveIcon(
            iconName: iconName,
            defaultIcon: icon,
            size: iconSize,
            color: colors.primary,
          ),
          SizedBox(height: layoutType == LayoutType.mobile ? 8 : 12),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layoutType == LayoutType.mobile ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: valueFontSize,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}