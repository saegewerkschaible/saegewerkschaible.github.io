// lib/screens/DeliveryNotes/widgets/delivery_note_filters.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/services/filter/filter_chip_utils.dart';
import 'package:saegewerk/services/filter/filter_settings.dart';

import '../../services/icon_helper.dart';

import '../models/layout_type.dart';

/// Desktop Filter-Sidebar
class DesktopFilterSidebar extends StatelessWidget {
  final VoidCallback onFilterTap;

  const DesktopFilterSidebar({
    Key? key,
    required this.onFilterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final filterSettings = Provider.of<FilterSettings>(context);

    return Container(
      width: 300,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(1, 0),
          ),
        ],
        border: Border(
          right: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: Row(
              children: [
                getAdaptiveIcon(
                  iconName: 'filter_alt',
                  defaultIcon: Icons.filter_alt,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const Spacer(),
                if (filterSettings.hasActiveFilters)
                  TextButton(
                    onPressed: () => filterSettings.resetFilters(),
                    child: Text(
                      'Zurücksetzen',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kunden Filter
                  if (filterSettings.activeKunden.isNotEmpty) ...[
                    Text(
                      'Kunden',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...filterSettings.activeKunden.map((kunde) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: buildFilterChip(
                          context: context,
                          label: kunde,
                          onDelete: () {
                            filterSettings.activeKunden.remove(kunde);
                            filterSettings.notifyListeners();
                          },
                          icon: Icons.person,
                          iconName: 'person',
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Volumen Filter
                  if (filterSettings.volumeFilterEnabled) ...[
                    Text(
                      'Volumen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _VolumeFilterChip(filterSettings: filterSettings),
                    const SizedBox(height: 16),
                  ],

                  // Datum Filter
                  if (filterSettings.dateRangeEnabled &&
                      (filterSettings.startDate != null ||
                          filterSettings.endDate != null)) ...[
                    Text(
                      'Datum Lieferschein',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DateRangeFilterCard(filterSettings: filterSettings),
                    const SizedBox(height: 16),
                  ],

                  // Filter Button
                  ElevatedButton.icon(
                    onPressed: onFilterTap,
                    icon: getAdaptiveIcon(
                      iconName: 'tune',
                      defaultIcon: Icons.tune,
                      color: colors.textOnPrimary,
                    ),
                    label: const Text('Filter anpassen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Active Filters Anzeige (Mobile/Tablet)
class ActiveFiltersBar extends StatelessWidget {
  final LayoutType layoutType;

  const ActiveFiltersBar({
    Key? key,
    required this.layoutType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nur für Mobile/Tablet anzeigen
    if (layoutType == LayoutType.desktop) {
      return const SizedBox.shrink();
    }

    final colors = Provider.of<ThemeProvider>(context).colors;
    final filterSettings = Provider.of<FilterSettings>(context);

    final chips = _buildFilterChips(filterSettings,context);

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                getAdaptiveIcon(
                  iconName: 'filter_alt',
                  defaultIcon: Icons.filter_alt,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aktive Filter',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (filterSettings.hasActiveFilters)
                  TextButton(
                    onPressed: () => filterSettings.resetFilters(),
                    child: Text(
                      'Alle zurücksetzen',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                for (var chip in chips) ...[
                  chip,
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips(FilterSettings settings,BuildContext context) {
    List<Widget> chips = [];

    // Premiumkunden
    for (var kunde in settings.activePremiumkunden) {
      chips.add(buildFilterChip(
        context: context,
        label: kunde,
        onDelete: () {
          settings.activePremiumkunden.remove(kunde);
          settings.notifyListeners();
        },
        icon: Icons.person,
        iconName: 'person',
      ));
    }

    // Datumsfilter
    if (settings.dateRangeEnabled &&
        (settings.startDate != null || settings.endDate != null)) {
      final DateFormat formatter = DateFormat('dd.MM.yyyy');
      String dateLabel = '';

      if (settings.startDate != null && settings.endDate != null) {
        dateLabel =
        '${formatter.format(settings.startDate!)} - ${formatter.format(settings.endDate!)}';
      } else if (settings.startDate != null) {
        dateLabel = 'ab ${formatter.format(settings.startDate!)}';
      } else if (settings.endDate != null) {
        dateLabel = 'bis ${formatter.format(settings.endDate!)}';
      }

      if (dateLabel.isNotEmpty) {
        chips.add(buildFilterChip(
          context: context,
          label: dateLabel,
          onDelete: () {
            settings.dateRangeEnabled = false;
            settings.startDate = null;
            settings.endDate = null;
            settings.notifyListeners();
          },
          icon: Icons.date_range,
          iconName: 'date_range',
        ));
      }
    }

    // Volume Filter
    if (settings.volumeFilterEnabled) {
      String volumeLabel = '';
      if (settings.minVolumeEnabled && settings.maxVolumeEnabled) {
        volumeLabel =
        '${settings.volumeRange.start.toStringAsFixed(1)} - ${settings.volumeRange.end.toStringAsFixed(1)} m³';
      } else if (settings.minVolumeEnabled) {
        volumeLabel = '> ${settings.volumeRange.start.toStringAsFixed(1)} m³';
      } else if (settings.maxVolumeEnabled) {
        volumeLabel = '< ${settings.volumeRange.end.toStringAsFixed(1)} m³';
      }

      if (volumeLabel.isNotEmpty) {
        chips.add(buildFilterChip(
          context: context,
          label: volumeLabel,
          onDelete: () {
            settings.volumeFilterEnabled = false;
            settings.notifyListeners();
          },
          icon: Icons.view_in_ar,
          iconName: 'view_in_ar',
        ));
      }
    }

    return chips;
  }
}

class _VolumeFilterChip extends StatelessWidget {
  final FilterSettings filterSettings;

  const _VolumeFilterChip({required this.filterSettings});

  @override
  Widget build(BuildContext context) {
    String volumeLabel = '';
    if (filterSettings.minVolumeEnabled && filterSettings.maxVolumeEnabled) {
      volumeLabel =
      '${filterSettings.volumeRange.start.toStringAsFixed(1)} - ${filterSettings.volumeRange.end.toStringAsFixed(1)} m³';
    } else if (filterSettings.minVolumeEnabled) {
      volumeLabel =
      '> ${filterSettings.volumeRange.start.toStringAsFixed(1)} m³';
    } else if (filterSettings.maxVolumeEnabled) {
      volumeLabel =
      '< ${filterSettings.volumeRange.end.toStringAsFixed(1)} m³';
    }

    if (volumeLabel.isEmpty) {
      return const SizedBox.shrink();
    }

    return buildFilterChip(
      context: context,
      label: volumeLabel,
      onDelete: () {
        filterSettings.volumeFilterEnabled = false;
        filterSettings.notifyListeners();
      },
      icon: Icons.view_in_ar,
      iconName: 'view_in_ar',
    );
  }
}

class _DateRangeFilterCard extends StatelessWidget {
  final FilterSettings filterSettings;

  const _DateRangeFilterCard({required this.filterSettings});

  String _formatDateRange() {
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    if (filterSettings.startDate != null && filterSettings.endDate != null) {
      return '${formatter.format(filterSettings.startDate!)} - ${formatter.format(filterSettings.endDate!)}';
    } else if (filterSettings.startDate != null) {
      return 'ab ${formatter.format(filterSettings.startDate!)}';
    } else if (filterSettings.endDate != null) {
      return 'bis ${formatter.format(filterSettings.endDate!)}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          getAdaptiveIcon(
            iconName: 'date_range',
            defaultIcon: Icons.date_range,
            size: 16,
            color: colors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatDateRange(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: getAdaptiveIcon(
              iconName: 'close',
              defaultIcon: Icons.close,
              color: colors.textSecondary,
            ),
            onPressed: () {
              filterSettings.dateRangeEnabled = false;
              filterSettings.startDate = null;
              filterSettings.endDate = null;
              filterSettings.notifyListeners();
            },
          ),
        ],
      ),
    );
  }
}