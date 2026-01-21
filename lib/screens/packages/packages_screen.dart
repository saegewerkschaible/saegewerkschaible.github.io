// ═══════════════════════════════════════════════════════════════════════════
// lib/screens/packages/packages_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/services/filter/filter_settings.dart';

import '../../core/theme/theme_provider.dart';

import '../../packages/services/package_service.dart';
import '../../packages/widgets/edit_package_widget.dart';
import '../../services/icon_helper.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HAUPT-SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class PackagesScreen extends StatefulWidget {
  final int userGroup;
  final bool showBackButton;

  const PackagesScreen({
    super.key,
    required this.userGroup,
    this.showBackButton = false,
  });

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final PackageService _packageService = PackageService();

  @override
  void initState() {
    super.initState();
    // Filter laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FilterSettings>(context, listen: false).loadAllFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final filterSettings = context.watch<FilterSettings>();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: _buildAppBar(theme, filterSettings),
      body: StreamBuilder<QuerySnapshot>(
        stream: _packageService.getPackagesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(theme);
          }

          // Pakete in Maps umwandeln
          final packages = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {...data, 'id': doc.id};
          }).toList();

          // Filter anwenden
          final filteredPackages = _applyFilters(packages, filterSettings);

          return Column(
            children: [
              // Aktive Filter anzeigen
              if (filterSettings.hasActiveFilters)
                _ActiveFiltersBar(
                  filterSettings: filterSettings,
                  onReset: () => filterSettings.resetFilters(),
                ),

              // Summary Cards
              _SummaryCards(packages: filteredPackages, theme: theme),

              // Paketliste
              Expanded(
                child: filteredPackages.isEmpty
                    ? _buildNoResultsState(theme)
                    : _PackageList(
                  packages: filteredPackages,
                  userGroup: widget.userGroup,
                  theme: theme,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(ThemeProvider theme, FilterSettings filterSettings) {
    return AppBar(
      backgroundColor: theme.surface,
      elevation: 0,
      automaticallyImplyLeading: widget.showBackButton,
      title: Text(
        'Lager',
        style: TextStyle(
          color: theme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Filter-Button
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.filter_list, color: theme.textPrimary),
              onPressed: () => _showFilterDialog(context),
            ),
            if (filterSettings.hasActiveFilters)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    final theme = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.filter_list, color: theme.primary),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        context.read<FilterSettings>().resetFilters();
                      },
                      child: Text('Zurücksetzen', style: TextStyle(color: theme.error)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.divider),
              // Filter-Content - hier FilterWidget einbinden wenn fertig
              Expanded(
                child: _SimpleFilterContent(theme: theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> packages,
      FilterSettings filters,
      ) {
    return packages.where((pkg) {
      // Status-Filter (default: im_lager)
      if (filters.activeStatus.isNotEmpty) {
        final status = pkg['status'] ?? PackageStatus.imLager;
        if (!filters.activeStatus.contains(status)) return false;
      }

      // Holzart-Filter
      if (filters.activeHolzarten.isNotEmpty) {
        final holzart = pkg['holzart'] ?? '';
        if (!filters.activeHolzarten.contains(holzart)) return false;
      }

      // Zustands-Filter
      if (filters.activeStates.isNotEmpty) {
        final zustand = pkg['zustand'] ?? '';
        if (!filters.activeStates.contains(zustand)) return false;
      }

      // Lagerort-Filter
      if (filters.activeLagerort.isNotEmpty) {
        final lagerort = pkg['lagerort'] ?? '';
        if (!filters.activeLagerort.contains(lagerort) &&
            !(filters.activeLagerort.contains('andere') &&
                !filters.lagerort.contains(lagerort))) {
          return false;
        }
      }

      // Kunden-Filter
      if (filters.activeKunden.isNotEmpty) {
        final kunde = pkg['kunde'] ?? '';
        if (!filters.activeKunden.contains(kunde)) return false;
      }

      // Kunden-Freitext
      if (filters.kundenFreitextFilter.isNotEmpty) {
        final kunde = (pkg['kunde'] ?? '').toString().toLowerCase();
        if (!kunde.contains(filters.kundenFreitextFilter.toLowerCase())) {
          return false;
        }
      }

      // Auftragsnummer-Filter
      if (filters.auftragsnrFilter.isNotEmpty) {
        final auftragsnr = (pkg['auftragsnr'] ?? '').toString().toLowerCase();
        if (!auftragsnr.contains(filters.auftragsnrFilter.toLowerCase())) {
          return false;
        }
      }

      // Volumen-Filter
      if (filters.volumeFilterEnabled) {
        final menge = (pkg['menge'] ?? 0).toDouble();
        if (filters.minVolumeEnabled && menge < filters.volumeRange.start) return false;
        if (filters.maxVolumeEnabled && menge > filters.volumeRange.end) return false;
      }

      // Dimensions-Filter
      if (filters.dimensionFilterEnabled) {
        final hoehe = (pkg['hoehe'] ?? 0).toDouble();
        final breite = (pkg['breite'] ?? 0).toDouble();
        if (filters.minStaerkeEnabled && hoehe < filters.staerkeRange.start) return false;
        if (filters.maxStaerkeEnabled && hoehe > filters.staerkeRange.end) return false;
        if (filters.minBreiteEnabled && breite < filters.breiteRange.start) return false;
        if (filters.maxBreiteEnabled && breite > filters.breiteRange.end) return false;
      }

      // Längen-Filter
      if (filters.laengeFilterEnabled) {
        final laenge = (pkg['laenge'] ?? 0).toDouble();
        if (filters.minLaengeEnabled && laenge < filters.laengeRange.start) return false;
        if (filters.maxLaengeEnabled && laenge > filters.laengeRange.end) return false;
      }

      // Datums-Filter
      if (filters.dateRangeEnabled) {
        final datumStr = pkg['datum']?.toString();
        if (datumStr != null && datumStr.isNotEmpty) {
          try {
            final datum = DateFormat('dd.MM.yyyy').parse(datumStr);
            if (filters.startDate != null && datum.isBefore(filters.startDate!)) return false;
            if (filters.endDate != null && datum.isAfter(filters.endDate!)) return false;
          } catch (_) {
            return false;
          }
        }
      }

      return true;
    }).toList()
      ..sort((a, b) => (b['createdAt'] as Timestamp?)
          ?.compareTo(a['createdAt'] as Timestamp? ?? Timestamp.now()) ?? 0);
  }

  Widget _buildEmptyState(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: theme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Noch keine Pakete',
            style: TextStyle(fontSize: 18, color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: theme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Keine Pakete gefunden',
            style: TextStyle(fontSize: 18, color: theme.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.read<FilterSettings>().resetFilters(),
            child: Text('Filter zurücksetzen', style: TextStyle(color: theme.primary)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUMMARY CARDS
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryCards extends StatelessWidget {
  final List<Map<String, dynamic>> packages;
  final ThemeProvider theme;

  const _SummaryCards({required this.packages, required this.theme});

  @override
  Widget build(BuildContext context) {
    final totalMenge = packages.fold<double>(
      0,
          (sum, pkg) => sum + ((pkg['menge'] ?? 0) as num).toDouble(),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              theme: theme,
              icon: Icons.inventory,
              label: 'Pakete',
              value: '${packages.length}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              theme: theme,
              icon: Icons.view_in_ar,
              label: 'Menge',
              value: '${totalMenge.toStringAsFixed(1)} m³',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ThemeProvider theme;
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: theme.textSecondary)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIVE FILTERS BAR
// ═══════════════════════════════════════════════════════════════════════════

class _ActiveFiltersBar extends StatelessWidget {
  final FilterSettings filterSettings;
  final VoidCallback onReset;

  const _ActiveFiltersBar({required this.filterSettings, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: theme.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Filter aktiv',
            style: TextStyle(fontSize: 13, color: theme.textSecondary),
          ),
          const Spacer(),
          TextButton(
            onPressed: onReset,
            child: Text(
              'Zurücksetzen',
              style: TextStyle(fontSize: 12, color: theme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PACKAGE LIST (gruppiert nach Holzart)
// ═══════════════════════════════════════════════════════════════════════════

class _PackageList extends StatelessWidget {
  final List<Map<String, dynamic>> packages;
  final int userGroup;
  final ThemeProvider theme;

  const _PackageList({
    required this.packages,
    required this.userGroup,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Nach Holzart gruppieren
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var pkg in packages) {
      final holzart = pkg['holzart']?.toString() ?? 'Unbekannt';
      grouped.putIfAbsent(holzart, () => []).add(pkg);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final holzart = sortedKeys[index];
        final holzartPackages = grouped[holzart]!;

        return _HolzartSection(
          holzart: holzart,
          packages: holzartPackages,
          userGroup: userGroup,
          theme: theme,
        );
      },
    );
  }
}

class _HolzartSection extends StatefulWidget {
  final String holzart;
  final List<Map<String, dynamic>> packages;
  final int userGroup;
  final ThemeProvider theme;

  const _HolzartSection({
    required this.holzart,
    required this.packages,
    required this.userGroup,
    required this.theme,
  });

  @override
  State<_HolzartSection> createState() => _HolzartSectionState();
}

class _HolzartSectionState extends State<_HolzartSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final totalMenge = widget.packages.fold<double>(
      0,
          (sum, pkg) => sum + ((pkg['menge'] ?? 0) as num).toDouble(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.border),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.forest, color: widget.theme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.holzart} (${widget.packages.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.theme.textPrimary,
                          ),
                        ),
                        Text(
                          '${totalMenge.toStringAsFixed(2)} m³',
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.theme.primary,
                  ),
                ],
              ),
            ),
          ),

          // Pakete
          if (_isExpanded) ...[
            Divider(height: 1, color: widget.theme.divider),
            ...widget.packages.map((pkg) => _PackageCard(
              package: pkg,
              userGroup: widget.userGroup,
              theme: widget.theme,
            )),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PACKAGE CARD
// ═══════════════════════════════════════════════════════════════════════════

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final int userGroup;
  final ThemeProvider theme;

  const _PackageCard({
    required this.package,
    required this.userGroup,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final zustand = package['zustand'] ?? 'frisch';
    final stateColor = theme.stateColors[zustand] ?? theme.info;

    return InkWell(
      onTap: () => _showPackageDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Zustand-Streifen vertikal
            Container(
              width: 24,
              height: 44,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: stateColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    zustand.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Barcode + Externe Nr
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${package['barcode']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (package['nrExt'] != null && package['nrExt'].toString().isNotEmpty)
                    Text(
                      package['nrExt'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Dimensionen
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatNum(package['hoehe'])} × ${_formatNum(package['breite'])} × ${_formatNum(package['laenge'])}',
                    style: TextStyle(fontSize: 13, color: theme.textPrimary),
                  ),
                  Text(
                    '${package['stueckzahl'] ?? 0} Stk',
                    style: TextStyle(fontSize: 12, color: theme.textSecondary),
                  ),
                ],
              ),
            ),

            // Menge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${((package['menge'] ?? 0) as num).toStringAsFixed(3)} m³',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.success,
                  ),
                ),
                if (package['lagerort'] != null && package['lagerort'].toString().isNotEmpty)
                  Text(
                    package['lagerort'],
                    style: TextStyle(fontSize: 11, color: theme.textSecondary),
                  ),
              ],
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: theme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatNum(dynamic value) {
    if (value == null) return '0';
    final num = value.toDouble();
    return num == num.roundToDouble() ? num.round().toString() : num.toStringAsFixed(1);
  }

  void _showPackageDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit, color: theme.primary),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '#${package['barcode']}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.divider),
              Expanded(
                child: EditPackageWidget(
                  packageData: package,
                  userGroup: userGroup,
                  isNewPackage: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIMPLE FILTER CONTENT (Platzhalter bis FilterWidget fertig)
// ═══════════════════════════════════════════════════════════════════════════

class _SimpleFilterContent extends StatelessWidget {
  final ThemeProvider theme;

  const _SimpleFilterContent({required this.theme});

  @override
  Widget build(BuildContext context) {
    final filterSettings = context.watch<FilterSettings>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status-Filter
        _FilterSection(
          theme: theme,
          title: 'Status',
          icon: Icons.inventory,
          child: Wrap(
            spacing: 8,
            children: ['im_lager', 'verkauft', 'verarbeitet', 'ausgebucht'].map((status) {
              final isActive = filterSettings.activeStatus.contains(status);
              return FilterChip(
                label: Text(_statusLabel(status)),
                selected: isActive,
                onSelected: (selected) {
                  if (selected) {
                    filterSettings.activeStatus.add(status);
                  } else {
                    filterSettings.activeStatus.remove(status);
                  }
                  filterSettings.notifyListeners();
                },
                selectedColor: theme.primary.withOpacity(0.2),
                checkmarkColor: theme.primary,
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Zustands-Filter
        _FilterSection(
          theme: theme,
          title: 'Zustand',
          icon: Icons.water_drop,
          child: Wrap(
            spacing: 8,
            children: ['frisch', 'trocken'].map((zustand) {
              final isActive = filterSettings.activeStates.contains(zustand);
              final color = theme.stateColors[zustand] ?? theme.primary;
              return FilterChip(
                label: Text(zustand),
                selected: isActive,
                onSelected: (selected) {
                  if (selected) {
                    filterSettings.activeStates.add(zustand);
                  } else {
                    filterSettings.activeStates.remove(zustand);
                  }
                  filterSettings.notifyListeners();
                },
                selectedColor: color.withOpacity(0.2),
                checkmarkColor: color,
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Holzarten-Filter
        if (filterSettings.holzarten.isNotEmpty)
          _FilterSection(
            theme: theme,
            title: 'Holzarten',
            icon: Icons.forest,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filterSettings.holzarten.map((holzart) {
                final isActive = filterSettings.activeHolzarten.contains(holzart);
                return FilterChip(
                  label: Text(holzart),
                  selected: isActive,
                  onSelected: (selected) {
                    if (selected) {
                      filterSettings.activeHolzarten.add(holzart);
                    } else {
                      filterSettings.activeHolzarten.remove(holzart);
                    }
                    filterSettings.notifyListeners();
                  },
                  selectedColor: theme.primary.withOpacity(0.2),
                  checkmarkColor: theme.primary,
                );
              }).toList(),
            ),
          ),
      ],
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
}

class _FilterSection extends StatelessWidget {
  final ThemeProvider theme;
  final String title;
  final IconData icon;
  final Widget child;

  const _FilterSection({
    required this.theme,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}