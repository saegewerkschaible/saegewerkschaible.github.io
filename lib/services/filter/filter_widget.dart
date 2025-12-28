// lib/services/filter/filter_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

// stateColors kommt jetzt aus ThemeProvider
import 'filter_settings.dart';
import 'widgets/active_filters_bar.dart';
import 'widgets/filter_category_tile.dart';
import 'widgets/checkbox_list_filter.dart';
import 'widgets/date_range_filter.dart';
import 'widgets/range_filter.dart';

class FilterWidget extends StatefulWidget {
  final bool isDeliveryNoteScreen;

  const FilterWidget({
    Key? key,
    this.isDeliveryNoteScreen = false,
  }) : super(key: key);

  @override
  _FilterWidgetState createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  // Controller für Textfelder
  late TextEditingController minStaerkeController;
  late TextEditingController maxStaerkeController;
  late TextEditingController minBreiteController;
  late TextEditingController maxBreiteController;
  late TextEditingController minLaengeController;
  late TextEditingController maxLaengeController;
  late TextEditingController auftragsnrController;
  late TextEditingController kundenFreitextController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<FilterSettings>(context, listen: false);

    minStaerkeController = TextEditingController(
      text: settings.minStaerkeEnabled
          ? settings.staerkeRange.start.round().toString()
          : '',
    );
    maxStaerkeController = TextEditingController(
      text: settings.maxStaerkeEnabled
          ? settings.staerkeRange.end.round().toString()
          : '',
    );
    minBreiteController = TextEditingController(
      text: settings.minBreiteEnabled
          ? settings.breiteRange.start.round().toString()
          : '',
    );
    maxBreiteController = TextEditingController(
      text: settings.maxBreiteEnabled
          ? settings.breiteRange.end.round().toString()
          : '',
    );
    minLaengeController = TextEditingController(
      text: settings.minLaengeEnabled
          ? settings.laengeRange.start.toString()
          : '',
    );
    maxLaengeController = TextEditingController(
      text: settings.maxLaengeEnabled
          ? settings.laengeRange.end.toString()
          : '',
    );
    auftragsnrController =
        TextEditingController(text: settings.auftragsnrFilter);
    kundenFreitextController =
        TextEditingController(text: settings.kundenFreitextFilter);
  }

  @override
  void dispose() {
    minStaerkeController.dispose();
    maxStaerkeController.dispose();
    minBreiteController.dispose();
    maxBreiteController.dispose();
    minLaengeController.dispose();
    maxLaengeController.dispose();
    auftragsnrController.dispose();
    kundenFreitextController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final settings = Provider.of<FilterSettings>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Aktive Filter Chips
          ActiveFiltersBar(
            settings: settings,
            stateColors: colors.stateColors,
            onResetAll: () {
              settings.resetFilters();
              auftragsnrController.clear();
              kundenFreitextController.clear();
              minLaengeController.clear();
              maxLaengeController.clear();
              _refresh();
            },
            onKundenFreitextClear: () => kundenFreitextController.clear(),
            onAuftragsnrClear: () => auftragsnrController.clear(),
            onLaengeClear: () {
              minLaengeController.clear();
              maxLaengeController.clear();
            },
          ),

          // Filter-Container
          Container(
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
            child: Theme(
              data: ThemeData(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  // Datum
                  FilterCategoryTile(
                    icon: Icons.date_range,
                    iconName: 'date_range',
                    title: widget.isDeliveryNoteScreen
                        ? 'Datum Lieferschein'
                        : 'Produktionszeit',
                    hasActiveFilters: settings.hasActiveDateFilter,
                    showQuickFilterStar: true,
                    isQuickFilterActive: settings.showQuickFilterDate,
                    onQuickFilterToggle: () async {
                      settings.showQuickFilterDate =
                      !settings.showQuickFilterDate;
                      await settings.saveQuickFilterSettings();
                      settings.notifyListeners();
                      _refresh();
                    },
                    child: DateRangeFilter(
                      settings: settings,
                      onChanged: _refresh,
                    ),
                  ),

                  // Auftragsnummer
                  FilterCategoryTile(
                    icon: Icons.search,
                    iconName: 'search',
                    title: 'Auftragsnummer',
                    hasActiveFilters: settings.auftragsnrFilter.isNotEmpty,
                    child: TextSearchFilter(
                      controller: auftragsnrController,
                      hintText: '...',
                      currentValue: settings.auftragsnrFilter,
                      onChanged: (value) {
                        settings.auftragsnrFilter = value.trim();
                        settings.notifyListeners();
                        _refresh();
                      },
                      onClear: () {
                        settings.auftragsnrFilter = '';
                        auftragsnrController.clear();
                        settings.notifyListeners();
                        _refresh();
                      },
                    ),
                  ),

                  // Holzarten (nicht bei Lieferschein)
                  if (!widget.isDeliveryNoteScreen)
                    FilterCategoryTile(
                      icon: Icons.forest,
                      iconName: 'forest',
                      title: 'Holzarten',
                      hasActiveFilters: settings.activeHolzarten.isNotEmpty,
                      child: CheckboxListFilter(
                        options: settings.holzarten,
                        activeOptions: settings.activeHolzarten,
                        onToggle: (option) {
                          if (settings.activeHolzarten.contains(option)) {
                            settings.activeHolzarten.remove(option);
                          } else {
                            settings.activeHolzarten.add(option);
                          }
                          settings.notifyListeners();
                          _refresh();
                        },
                      ),
                    ),

                  // Premiumkunden
                  FilterCategoryTile(
                    icon: Icons.person,
                    iconName: 'person',
                    title: 'Premiumkunden',
                    hasActiveFilters: settings.activePremiumkunden.isNotEmpty,
                    child: CheckboxListFilter(
                      options: settings.premiumkunden,
                      activeOptions: settings.activePremiumkunden,
                      onToggle: (option) {
                        if (settings.activePremiumkunden.contains(option)) {
                          settings.activePremiumkunden.remove(option);
                        } else {
                          settings.activePremiumkunden.add(option);
                        }
                        settings.notifyListeners();
                        _refresh();
                      },
                    ),
                  ),

                  // Kunde Freitext
                  FilterCategoryTile(
                    icon: Icons.person_search,
                    iconName: 'person_search',
                    title: 'Kunde (Freitext)',
                    hasActiveFilters: settings.kundenFreitextFilter.isNotEmpty,
                    showQuickFilterStar: true,
                    isQuickFilterActive: settings.showQuickFilterCustomer,
                    onQuickFilterToggle: () async {
                      settings.showQuickFilterCustomer =
                      !settings.showQuickFilterCustomer;
                      await settings.saveQuickFilterSettings();
                      settings.notifyListeners();
                      _refresh();
                    },
                    child: TextSearchFilter(
                      controller: kundenFreitextController,
                      hintText: 'Kundenname eingeben...',
                      currentValue: settings.kundenFreitextFilter,
                      icon: Icons.person_search,
                      iconName: 'person_search',
                      onChanged: (value) {
                        settings.kundenFreitextFilter = value.trim();
                        settings.notifyListeners();
                        _refresh();
                      },
                      onClear: () {
                        settings.kundenFreitextFilter = '';
                        kundenFreitextController.clear();
                        settings.notifyListeners();
                        _refresh();
                      },
                    ),
                  ),

                  // Volumen
                  FilterCategoryTile(
                    icon: Icons.view_in_ar,
                    iconName: 'view_in_ar',
                    title: 'Volumen',
                    hasActiveFilters: settings.volumeFilterEnabled,
                    child: VolumeRangeFilter(
                      settings: settings,
                      onChanged: _refresh,
                    ),
                  ),

                  // Zustände (nicht bei Lieferschein)
                  if (!widget.isDeliveryNoteScreen)
                    FilterCategoryTile(
                      icon: Icons.water_drop,
                      iconName: 'water_drop',
                      title: 'Zustände',
                      hasActiveFilters: settings.activeStates.isNotEmpty,
                      child: CheckboxListFilter(
                        options: settings.states,
                        activeOptions: settings.activeStates,
                        colorMap: colors.stateColors,
                        showColorIndicator: true,
                        onToggle: (option) {
                          if (settings.activeStates.contains(option)) {
                            settings.activeStates.remove(option);
                          } else {
                            settings.activeStates.add(option);
                          }
                          settings.notifyListeners();
                          _refresh();
                        },
                      ),
                    ),

                  // Lagerort (nicht bei Lieferschein)
                  if (!widget.isDeliveryNoteScreen)
                    FilterCategoryTile(
                      icon: Icons.location_on,
                      iconName: 'location_on',
                      title: 'Lagerort',
                      hasActiveFilters: settings.activeLagerort.isNotEmpty,
                      child: CheckboxListFilter(
                        options: settings.lagerort,
                        activeOptions: settings.activeLagerort,
                        onToggle: (option) {
                          if (settings.activeLagerort.contains(option)) {
                            settings.activeLagerort.remove(option);
                          } else {
                            settings.activeLagerort.add(option);
                          }
                          settings.notifyListeners();
                          _refresh();
                        },
                      ),
                    ),

                  // Dimensionen (nicht bei Lieferschein)
                  if (!widget.isDeliveryNoteScreen)
                    FilterCategoryTile(
                      icon: Icons.architecture,
                      iconName: 'architecture',
                      title: 'Dimensionen',
                      hasActiveFilters: settings.activeDimensions.isNotEmpty ||
                          settings.dimensionFilterEnabled,
                      child: CombinedDimensionsFilter(
                        settings: settings,
                        standardFilter: CheckboxListFilter(
                          options: settings.dimensions,
                          activeOptions: settings.activeDimensions,
                          onToggle: (option) {
                            if (settings.activeDimensions.contains(option)) {
                              settings.activeDimensions.remove(option);
                            } else {
                              settings.activeDimensions.add(option);
                            }
                            settings.notifyListeners();
                            _refresh();
                          },
                        ),
                        freeFilter: FreeDimensionsFilter(
                          settings: settings,
                          minStaerkeController: minStaerkeController,
                          maxStaerkeController: maxStaerkeController,
                          minBreiteController: minBreiteController,
                          maxBreiteController: maxBreiteController,
                          onChanged: _refresh,
                        ),
                      ),
                    ),

                  // Länge (nicht bei Lieferschein)
                  if (!widget.isDeliveryNoteScreen)
                    FilterCategoryTile(
                      icon: Icons.straighten,
                      iconName: 'straighten',
                      title: 'Länge',
                      hasActiveFilters: settings.laengeFilterEnabled,
                      child: LengthRangeFilter(
                        settings: settings,
                        minController: minLaengeController,
                        maxController: maxLaengeController,
                        onChanged: _refresh,
                      ),
                    ),

                  // Status + Verkauft + Inventur (nicht bei Lieferschein, nur userGroup != 1)
                  if (!widget.isDeliveryNoteScreen &&
                      settings.userGroup != 1) ...[
                    FilterCategoryTile(
                      icon: Icons.inventory,
                      iconName: 'inventory',
                      title: 'Status',
                      hasActiveFilters: settings.activeId23.isNotEmpty,
                      child: CheckboxListFilter(
                        options: settings.id23Options,
                        activeOptions: settings.activeId23,
                        onToggle: (option) {
                          if (settings.activeId23.contains(option)) {
                            settings.activeId23.remove(option);
                          } else {
                            settings.activeId23.add(option);
                          }
                          settings.notifyListeners();
                          _refresh();
                        },
                      ),
                    ),
                    FilterCategoryTile(
                      icon: Icons.shopping_cart,
                      iconName: 'shopping_cart',
                      title: 'Verkauft',
                      hasActiveFilters: settings.activeId27.isNotEmpty,
                      child: CheckboxListFilter(
                        options: settings.id27Options,
                        activeOptions: settings.activeId27,
                        onToggle: (option) {
                          if (settings.activeId27.contains(option)) {
                            settings.activeId27.remove(option);
                          } else {
                            settings.activeId27.add(option);
                          }
                          settings.notifyListeners();
                          _refresh();
                        },
                      ),
                    ),
                    if (settings.hasActiveInventory)
                      FilterCategoryTile(
                        icon: Icons.inventory_2,
                        iconName: 'inventory_2',
                        title: 'Aktuelle Inventur',
                        hasActiveFilters:
                        settings.activeInventoryFilter.isNotEmpty,
                        child: CheckboxListFilter(
                          options: settings.inventoryFilterOptions,
                          activeOptions: settings.activeInventoryFilter,
                          onToggle: (option) {
                            if (settings.activeInventoryFilter
                                .contains(option)) {
                              settings.activeInventoryFilter.remove(option);
                            } else {
                              settings.activeInventoryFilter.add(option);
                            }
                            settings.notifyListeners();
                            _refresh();
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}