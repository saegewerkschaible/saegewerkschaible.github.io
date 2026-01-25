// lib/services/filter/widgets/active_filters_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';


import '../../../services/icon_helper.dart';
import '../filter_settings.dart';

class ActiveFiltersBar extends StatelessWidget {
  final FilterSettings settings;
  final VoidCallback onResetAll;
  final Map<String, Color>? stateColors;
  final VoidCallback? onKundenFreitextClear;
  final VoidCallback? onAuftragsnrClear;
  final VoidCallback? onLaengeClear;

  const ActiveFiltersBar({
    Key? key,
    required this.settings,
    required this.onResetAll,
    this.stateColors,
    this.onKundenFreitextClear,
    this.onAuftragsnrClear,
    this.onLaengeClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final chips = _buildChips(context, colors);

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
                if (settings.hasActiveFilters)
                  TextButton(
                    onPressed: onResetAll,
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
  String _statusLabel(String status) {
    switch (status) {
      case 'im_lager': return 'Im Lager';
      case 'verkauft': return 'Verkauft';
      case 'verarbeitet': return 'Verarbeitet';
      case 'ausgebucht': return 'Ausgebucht';
      default: return status;
    }
  }
  List<Widget> _buildChips(BuildContext context, dynamic colors) {
    List<Widget> chips = [];
    final DateFormat formatter = DateFormat('dd.MM.yyyy');

    // Premiumkunden
    for (var kunde in settings.activePremiumkunden) {
      chips.add(_FilterChip(
        label: kunde,
        icon: Icons.person,
        iconName: 'person',
        onDelete: () {
          settings.activePremiumkunden.remove(kunde);
          settings.notifyListeners();
        },
      ));
    }

    // Holzarten
    for (var holzart in settings.activeHolzarten) {
      chips.add(_FilterChip(
        label: holzart,
        icon: Icons.forest,
        iconName: 'forest',
        onDelete: () {
          settings.activeHolzarten.remove(holzart);
          settings.notifyListeners();
        },
      ));
    }

    // Inventur
    for (var option in settings.activeInventoryFilter) {
      chips.add(_FilterChip(
        label: option,
        icon: Icons.inventory_2,
        iconName: 'inventory_2',
        onDelete: () {
          settings.activeInventoryFilter.remove(option);
          settings.notifyListeners();
        },
      ));
    }

    // Zustände
    for (var state in settings.activeStates) {
      chips.add(_FilterChip(
        label: state,
        icon: Icons.water_drop,
        iconName: 'water_drop',
        color: stateColors?[state],
        onDelete: () {
          settings.activeStates.remove(state);
          settings.notifyListeners();
        },
      ));
    }

    // Dimensionen
    for (var dimension in settings.activeDimensions) {
      if (dimension != 'andere') {
        chips.add(_FilterChip(
          label: '$dimension mm',
          icon: Icons.straighten,
          iconName: 'straighten',
          onDelete: () {
            settings.activeDimensions.remove(dimension);
            settings.notifyListeners();
          },
        ));
      }
    }

    // Lagerort
    for (var lagerort in settings.activeLagerort) {
      if (lagerort != 'andere') {
        chips.add(_FilterChip(
          label: lagerort,
          icon: Icons.location_on,
          iconName: 'location_on',
          onDelete: () {
            settings.activeLagerort.remove(lagerort);
            settings.notifyListeners();
          },
        ));
      }
    }

    // Status
    for (var status in settings.activeId23) {
      chips.add(_FilterChip(
        label: _statusLabel(status),
        icon: Icons.inventory,
        iconName: 'inventory',
        onDelete: () {
          settings.activeId23.remove(status);
          settings.notifyListeners();
        },
      ));
    }

    // Kunde Freitext
    if (settings.kundenFreitextFilter.isNotEmpty) {
      chips.add(_FilterChip(
        label: 'Kunde: ${settings.kundenFreitextFilter}',
        icon: Icons.person_search,
        iconName: 'person_search',
        onDelete: () {
          settings.kundenFreitextFilter = '';
          onKundenFreitextClear?.call();
          settings.notifyListeners();
        },
      ));
    }

    // Datumsfilter
    if (settings.dateRangeEnabled &&
        (settings.startDate != null || settings.endDate != null)) {
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
        chips.add(_FilterChip(
          label: dateLabel,
          icon: Icons.date_range,
          iconName: 'date_range',
          onDelete: () {
            settings.dateRangeEnabled = false;
            settings.startDate = null;
            settings.endDate = null;
            settings.notifyListeners();
          },
        ));
      }
    }

    // Dimensionsfilter (frei)
    if (settings.dimensionFilterEnabled) {
      List<String> dimensionParts = [];

      if (settings.minStaerkeEnabled || settings.maxStaerkeEnabled) {
        String staerkeLabel = '';
        if (settings.minStaerkeEnabled && settings.maxStaerkeEnabled) {
          staerkeLabel =
          'H: ${settings.staerkeRange.start.round()}-${settings.staerkeRange.end.round()}mm';
        } else if (settings.minStaerkeEnabled) {
          staerkeLabel = 'H: ≥${settings.staerkeRange.start.round()}mm';
        } else {
          staerkeLabel = 'H: ≤${settings.staerkeRange.end.round()}mm';
        }
        dimensionParts.add(staerkeLabel);
      }

      if (settings.minBreiteEnabled || settings.maxBreiteEnabled) {
        String breiteLabel = '';
        if (settings.minBreiteEnabled && settings.maxBreiteEnabled) {
          breiteLabel =
          'B: ${settings.breiteRange.start.round()}-${settings.breiteRange.end.round()}mm';
        } else if (settings.minBreiteEnabled) {
          breiteLabel = 'B: ≥${settings.breiteRange.start.round()}mm';
        } else {
          breiteLabel = 'B: ≤${settings.breiteRange.end.round()}mm';
        }
        dimensionParts.add(breiteLabel);
      }

      if (dimensionParts.isNotEmpty) {
        chips.add(_FilterChip(
          label: dimensionParts.join(' / '),
          icon: Icons.straighten,
          iconName: 'straighten',
          onDelete: () {
            settings.dimensionFilterEnabled = false;
            settings.minStaerkeEnabled = false;
            settings.maxStaerkeEnabled = false;
            settings.minBreiteEnabled = false;
            settings.maxBreiteEnabled = false;
            settings.notifyListeners();
          },
        ));
      }
    }

    // Längenfilter
    if (settings.laengeFilterEnabled) {
      if (settings.minLaengeEnabled || settings.maxLaengeEnabled) {
        String laengeLabel = '';
        if (settings.minLaengeEnabled && settings.maxLaengeEnabled) {
          laengeLabel =
          'L: ${settings.laengeRange.start.toStringAsFixed(1)}-${settings.laengeRange.end.toStringAsFixed(1)}m';
        } else if (settings.minLaengeEnabled) {
          laengeLabel =
          'L: ≥${settings.laengeRange.start.toStringAsFixed(1)}m';
        } else {
          laengeLabel = 'L: ≤${settings.laengeRange.end.toStringAsFixed(1)}m';
        }

        chips.add(_FilterChip(
          label: laengeLabel,
          icon: Icons.straighten,
          iconName: 'straighten',
          onDelete: () {
            settings.laengeFilterEnabled = false;
            settings.minLaengeEnabled = false;
            settings.maxLaengeEnabled = false;
            onLaengeClear?.call();
            settings.notifyListeners();
          },
        ));
      }
    }

    // Verkauft
    for (var verkauft in settings.activeId27) {
      chips.add(_FilterChip(
        label: verkauft,
        icon: Icons.shopping_cart,
        iconName: 'shopping_cart',
        onDelete: () {
          settings.activeId27.remove(verkauft);
          settings.notifyListeners();
        },
      ));
    }

    // Auftragsnummer
    if (settings.auftragsnrFilter.isNotEmpty) {
      chips.add(_FilterChip(
        label: 'Auftragsnr: ${settings.auftragsnrFilter}',
        icon: Icons.search,
        iconName: 'search',
        onDelete: () {
          settings.auftragsnrFilter = '';
          onAuftragsnrClear?.call();
          settings.notifyListeners();
        },
      ));
    }

    // Volumenfilter
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
        chips.add(_FilterChip(
          label: volumeLabel,
          icon: Icons.view_in_ar,
          iconName: 'view_in_ar',
          onDelete: () {
            settings.volumeFilterEnabled = false;
            settings.notifyListeners();
          },
        ));
      }
    }

    return chips;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String iconName;
  final Color? color;
  final VoidCallback onDelete;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.iconName,
    required this.onDelete,
    this.color,
  });

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