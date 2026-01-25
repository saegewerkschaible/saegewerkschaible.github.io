// ═══════════════════════════════════════════════════════════════════════════
// lib/screens/packages/packages_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/services/filter/filter_settings.dart';
import 'package:saegewerk/services/filter/filter_widget.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/theme_provider.dart';

import 'services/package_service.dart';
import 'widgets/edit_package_widget.dart';
import '../services/icon_helper.dart';
import 'services/package_filter_service.dart';
import 'services/package_list_pdf_service.dart';

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
  final PackageFilterService _filterService = PackageFilterService();

  // Suche nach Nummer
  final TextEditingController _nummerSucheController = TextEditingController();
  String _nummerSuche = '';

  // Dimensions-Schnellauswahl
  Set<double> _selectedHeights = {};
  Set<double> _selectedWidths = {};
  Set<double> _selectedLengths = {};

  // Sortierung
  PackageSortField _sortField = PackageSortField.createdAt;
  SortDirection _sortDirection = SortDirection.descending;

  // PDF Export Loading
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FilterSettings>(context, listen: false).loadAllFilters();
    });
  }

  @override
  void dispose() {
    _nummerSucheController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER: Alle Filter zurücksetzen
  // ═══════════════════════════════════════════════════════════════════════════

  void _resetAllFilters() {
    context.read<FilterSettings>().resetFilters();
    setState(() {
      _nummerSuche = '';
      _nummerSucheController.clear();
      _selectedHeights = {};
      _selectedWidths = {};
      _selectedLengths = {};
      _sortField = PackageSortField.createdAt;
      _sortDirection = SortDirection.descending;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTER
  // ═══════════════════════════════════════════════════════════════════════════

  bool get _hasExtraFilters =>
      _nummerSuche.isNotEmpty ||
          _selectedHeights.isNotEmpty ||
          _selectedWidths.isNotEmpty ||
          _selectedLengths.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

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

          final packages = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {...data, 'id': doc.id};
          }).toList();

          final filteredPackages = _applyFilters(packages, filterSettings);

          return Column(
            children: [
              if (filterSettings.hasActiveFilters || _hasExtraFilters)
                _ActiveFiltersBar(
                  filterSettings: filterSettings,
                  hasExtraFilters: _hasExtraFilters,
                  nummerSuche: _nummerSuche,
                  onReset: _resetAllFilters,
                ),

              _SummaryCards(packages: filteredPackages, theme: theme),

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

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  AppBar _buildAppBar(ThemeProvider theme, FilterSettings filterSettings) {
    return AppBar(
      backgroundColor: theme.surface,
      elevation: 0,
      automaticallyImplyLeading: widget.showBackButton,
      title: Text(
        'Lager',
        style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold),
      ),
      actions: [
        // Suche
        IconButton(
          icon: Icon(
            _nummerSuche.isNotEmpty ? Icons.search_off : Icons.search,
            color: _nummerSuche.isNotEmpty ? theme.primary : theme.textPrimary,
          ),
          onPressed: () => _showSearchDialog(context),
          tooltip: 'Suche nach Nummer',
        ),

        // Sortierung
        PopupMenuButton<PackageSortField>(
          icon: Icon(Icons.sort, color: theme.textPrimary),
          tooltip: 'Sortierung',
          onSelected: (field) {
            setState(() {
              if (_sortField == field) {
                _sortDirection = _sortDirection == SortDirection.ascending
                    ? SortDirection.descending
                    : SortDirection.ascending;
              } else {
                _sortField = field;
                _sortDirection = SortDirection.descending;
              }
            });
          },
          itemBuilder: (context) => PackageSortField.values.map((field) {
            final isSelected = _sortField == field;
            return PopupMenuItem<PackageSortField>(
              value: field,
              child: Row(
                children: [
                  Text(
                    PackageFilterService.getSortFieldLabel(field),
                    style: TextStyle(
                      color: isSelected ? theme.primary : theme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      _sortDirection == SortDirection.ascending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                      color: theme.primary,
                    ),
                ],
              ),
            );
          }).toList(),
        ),

        // Filter-Button
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.filter_list, color: theme.textPrimary),
              onPressed: () => _showFilterDialog(context),
            ),
            if (filterSettings.hasActiveFilters || _hasExtraFilters)
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

        // PDF Export
        IconButton(
          icon: _isExporting
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.textPrimary,
            ),
          )
              : Icon(Icons.picture_as_pdf, color: theme.textPrimary),
          onPressed: _isExporting ? null : () => _exportPdf(context),
          tooltip: 'Als PDF exportieren',
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER ANWENDEN
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> packages,
      FilterSettings filters,
      ) {
    var result = packages.where((pkg) {
      // Status-Filter
      if (filters.activeStatus.isNotEmpty) {
        final status = pkg['status'] ?? 'im_lager';
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

      // Dimensions-Filter (Standard - z.B. "27/120")
      if (filters.activeDimensions.isNotEmpty) {
        final hoehe = (pkg['hoehe'] ?? 0).toDouble();
        final breite = (pkg['breite'] ?? 0).toDouble();
        final pkgDimension = '${hoehe.toInt()}/${breite.toInt()}';

        final matchesStandard = filters.activeDimensions.contains(pkgDimension);
        final matchesAndere = filters.activeDimensions.contains('andere') &&
            filters.isOtherDimension(pkgDimension);

        if (!matchesStandard && !matchesAndere) return false;
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

      // Dimensions-Filter (Frei/Range)
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
    }).toList();

    // Nummern-Suche (intern/extern)
    if (_nummerSuche.isNotEmpty) {
      result = _filterService.filterByNummer(result, _nummerSuche);
    }

    // Dimensions-Schnellauswahl (exakte Werte)
    if (_selectedHeights.isNotEmpty || _selectedWidths.isNotEmpty || _selectedLengths.isNotEmpty) {
      result = _filterService.filterByExactDimensions(
        result,
        heights: _selectedHeights,
        widths: _selectedWidths,
        lengths: _selectedLengths,
      );
    }

    // Sortierung
    result = _filterService.sortPackages(result, _sortField, _sortDirection);

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUCHE DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  void _showSearchDialog(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    _nummerSucheController.text = _nummerSuche;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.search, color: theme.primary),
            const SizedBox(width: 12),
            Text('Paket suchen', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: TextField(
          controller: _nummerSucheController,
          autofocus: true,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Interne oder externe Nummer',
            labelStyle: TextStyle(color: theme.textSecondary),
            hintText: 'z.B. 12345 oder EXT-001',
            prefixIcon: Icon(Icons.tag, color: theme.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.background,
          ),
          onSubmitted: (value) {
            setState(() => _nummerSuche = value.trim());
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nummerSucheController.clear();
              setState(() => _nummerSuche = '');
              Navigator.pop(ctx);
            },
            child: Text('Zurücksetzen', style: TextStyle(color: theme.error)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _nummerSuche = _nummerSucheController.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suchen'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

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
                        _resetAllFilters();
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
              Expanded(
                child: FilterWidget(isDeliveryNoteScreen: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _exportPdf(BuildContext context) async {
    final theme = context.read<ThemeProvider>();
    final filterSettings = context.read<FilterSettings>();

    final snapshot = await _packageService.getPackagesStream().first;
    final packages = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {...data, 'id': doc.id};
    }).toList();

    final filteredPackages = _applyFilters(packages, filterSettings);

    if (filteredPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keine Pakete zum Exportieren'),
          backgroundColor: theme.error,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // ALLE aktiven Filter sammeln
      final activeFilters = <String>[];

      // Status
      if (filterSettings.activeStatus.isNotEmpty) {
        final labels = filterSettings.activeStatus.map((s) {
          switch (s) {
            case 'im_lager': return 'Im Lager';
            case 'verkauft': return 'Verkauft';
            case 'verarbeitet': return 'Verarbeitet';
            case 'ausgebucht': return 'Ausgebucht';
            default: return s;
          }
        }).join(', ');
        activeFilters.add('Status: $labels');
      }

      // Holzarten
      if (filterSettings.activeHolzarten.isNotEmpty) {
        activeFilters.add('Holzarten: ${filterSettings.activeHolzarten.join(", ")}');
      }

      // Zustände
      if (filterSettings.activeStates.isNotEmpty) {
        activeFilters.add('Zustand: ${filterSettings.activeStates.join(", ")}');
      }

      // Lagerorte
      if (filterSettings.activeLagerort.isNotEmpty) {
        activeFilters.add('Lagerort: ${filterSettings.activeLagerort.join(", ")}');
      }

      // Dimensionen (Standard)
      if (filterSettings.activeDimensions.isNotEmpty) {
        activeFilters.add('Dimensionen: ${filterSettings.activeDimensions.join(", ")}');
      }

      // Kunden
      if (filterSettings.activeKunden.isNotEmpty) {
        activeFilters.add('Kunden: ${filterSettings.activeKunden.join(", ")}');
      }

      // Volumen
      if (filterSettings.volumeFilterEnabled) {
        String label = 'Volumen: ';
        if (filterSettings.minVolumeEnabled && filterSettings.maxVolumeEnabled) {
          label += '${filterSettings.volumeRange.start.toStringAsFixed(1)} - ${filterSettings.volumeRange.end.toStringAsFixed(1)} m³';
        } else if (filterSettings.minVolumeEnabled) {
          label += '≥ ${filterSettings.volumeRange.start.toStringAsFixed(1)} m³';
        } else if (filterSettings.maxVolumeEnabled) {
          label += '≤ ${filterSettings.volumeRange.end.toStringAsFixed(1)} m³';
        }
        activeFilters.add(label);
      }

      // Länge
      if (filterSettings.laengeFilterEnabled) {
        String label = 'Länge: ';
        if (filterSettings.minLaengeEnabled && filterSettings.maxLaengeEnabled) {
          label += '${filterSettings.laengeRange.start.toStringAsFixed(1)} - ${filterSettings.laengeRange.end.toStringAsFixed(1)} m';
        } else if (filterSettings.minLaengeEnabled) {
          label += '≥ ${filterSettings.laengeRange.start.toStringAsFixed(1)} m';
        } else if (filterSettings.maxLaengeEnabled) {
          label += '≤ ${filterSettings.laengeRange.end.toStringAsFixed(1)} m';
        }
        activeFilters.add(label);
      }

      // Dimensions-Schnellauswahl
      if (_selectedHeights.isNotEmpty) {
        activeFilters.add('Stärke: ${_selectedHeights.map((h) => "${h.toInt()} mm").join(", ")}');
      }
      if (_selectedWidths.isNotEmpty) {
        activeFilters.add('Breite: ${_selectedWidths.map((w) => "${w.toInt()} mm").join(", ")}');
      }
      if (_selectedLengths.isNotEmpty) {
        activeFilters.add('Länge: ${_selectedLengths.map((l) => "$l m").join(", ")}');
      }

      // Nummern-Suche
      if (_nummerSuche.isNotEmpty) {
        activeFilters.add('Suche: "$_nummerSuche"');
      }

      // PDF generieren
      final pdfBytes = await PackageListPdfService.generatePdf(
        packages: filteredPackages,
        title: 'Lagerbestandsliste',
        activeFilters: activeFilters.isNotEmpty ? activeFilters : null,
        groupByHolzart: true,
      );

      // PDF teilen
      await _sharePdf(pdfBytes);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Export: $e'),
          backgroundColor: theme.error,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }
  Future<void> _sharePdf(Uint8List pdfBytes) async {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final filename = 'Lagerliste_$timestamp.pdf';

    // Temporär speichern
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pdfBytes);

    // Teilen
    await Share.shareXFiles([XFile(file.path)], text: 'Lagerbestandsliste');
  }
  void _showPdfSuccessDialog(BuildContext context, String pdfUrl, String filename) {
    final theme = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: theme.success),
            ),
            const SizedBox(width: 12),
            Text('PDF erstellt', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filename,
              style: TextStyle(color: theme.textSecondary, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Text(
              'Die Liste wurde erfolgreich erstellt.',
              style: TextStyle(color: theme.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Schließen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: URL öffnen mit url_launcher
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Öffnen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: theme.textSecondary.withOpacity(0.5),
          ),
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
          Icon(
            Icons.search_off,
            size: 80,
            color: theme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Pakete gefunden',
            style: TextStyle(fontSize: 18, color: theme.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _resetAllFilters,
            child: Text(
              'Filter zurücksetzen',
              style: TextStyle(color: theme.primary),
            ),
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
  final bool hasExtraFilters;
  final String nummerSuche;
  final VoidCallback onReset;

  const _ActiveFiltersBar({
    required this.filterSettings,
    required this.hasExtraFilters,
    required this.nummerSuche,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final chips = _buildChips(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, size: 16, color: theme.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Aktive Filter',
                style: TextStyle(fontSize: 13, color: theme.textSecondary),
              ),
              const Spacer(),
              TextButton(
                onPressed: onReset,
                child: Text(
                  'Alle zurücksetzen',
                  style: TextStyle(fontSize: 12, color: theme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChips(ThemeProvider theme) {
    final chips = <Widget>[];

    // Status
    for (var status in filterSettings.activeStatus) {
      chips.add(_buildChip(
        theme: theme,
        label: _statusLabel(status),
        icon: Icons.inventory,
        onDelete: () {
          filterSettings.activeStatus.remove(status);
          filterSettings.notifyListeners();
        },
      ));
    }

    // Holzarten
    for (var holzart in filterSettings.activeHolzarten) {
      chips.add(_buildChip(
        theme: theme,
        label: holzart,
        icon: Icons.forest,
        onDelete: () {
          filterSettings.activeHolzarten.remove(holzart);
          filterSettings.notifyListeners();
        },
      ));
    }

    // Zustände
    for (var zustand in filterSettings.activeStates) {
      chips.add(_buildChip(
        theme: theme,
        label: zustand,
        icon: Icons.water_drop,
        color: theme.stateColors[zustand],
        onDelete: () {
          filterSettings.activeStates.remove(zustand);
          filterSettings.notifyListeners();
        },
      ));
    }

    // Lagerort
    for (var lagerort in filterSettings.activeLagerort) {
      chips.add(_buildChip(
        theme: theme,
        label: lagerort,
        icon: Icons.location_on,
        onDelete: () {
          filterSettings.activeLagerort.remove(lagerort);
          filterSettings.notifyListeners();
        },
      ));
    }

    // Dimensionen
    for (var dimension in filterSettings.activeDimensions) {
      chips.add(_buildChip(
        theme: theme,
        label: '$dimension mm',
        icon: Icons.straighten,
        onDelete: () {
          filterSettings.activeDimensions.remove(dimension);
          filterSettings.notifyListeners();
        },
      ));
    }

    // Kunden
    for (var kunde in filterSettings.activeKunden) {
      chips.add(_buildChip(
        theme: theme,
        label: kunde,
        icon: Icons.person,
        onDelete: () {
          filterSettings.activeKunden.remove(kunde);
          filterSettings.notifyListeners();
        },
      ));
    }

    // Nummern-Suche
    if (nummerSuche.isNotEmpty) {
      chips.add(_buildChip(
        theme: theme,
        label: 'Suche: "$nummerSuche"',
        icon: Icons.search,
        onDelete: null, // Wird über Reset gelöscht
      ));
    }

    // Volumen
    if (filterSettings.volumeFilterEnabled) {
      String label = '';
      if (filterSettings.minVolumeEnabled && filterSettings.maxVolumeEnabled) {
        label = '${filterSettings.volumeRange.start.toStringAsFixed(1)} - ${filterSettings.volumeRange.end.toStringAsFixed(1)} m³';
      } else if (filterSettings.minVolumeEnabled) {
        label = '≥ ${filterSettings.volumeRange.start.toStringAsFixed(1)} m³';
      } else if (filterSettings.maxVolumeEnabled) {
        label = '≤ ${filterSettings.volumeRange.end.toStringAsFixed(1)} m³';
      }
      if (label.isNotEmpty) {
        chips.add(_buildChip(
          theme: theme,
          label: label,
          icon: Icons.view_in_ar,
          onDelete: () {
            filterSettings.volumeFilterEnabled = false;
            filterSettings.notifyListeners();
          },
        ));
      }
    }

    // Länge
    if (filterSettings.laengeFilterEnabled) {
      String label = '';
      if (filterSettings.minLaengeEnabled && filterSettings.maxLaengeEnabled) {
        label = 'L: ${filterSettings.laengeRange.start.toStringAsFixed(1)} - ${filterSettings.laengeRange.end.toStringAsFixed(1)} m';
      } else if (filterSettings.minLaengeEnabled) {
        label = 'L: ≥ ${filterSettings.laengeRange.start.toStringAsFixed(1)} m';
      } else if (filterSettings.maxLaengeEnabled) {
        label = 'L: ≤ ${filterSettings.laengeRange.end.toStringAsFixed(1)} m';
      }
      if (label.isNotEmpty) {
        chips.add(_buildChip(
          theme: theme,
          label: label,
          icon: Icons.straighten,
          onDelete: () {
            filterSettings.laengeFilterEnabled = false;
            filterSettings.notifyListeners();
          },
        ));
      }
    }

    return chips;
  }

  Widget _buildChip({
    required ThemeProvider theme,
    required String label,
    required IconData icon,
    Color? color,
    VoidCallback? onDelete,
  }) {
    final chipColor = color ?? theme.primary;

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
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close, size: 14, color: chipColor),
            ),
          ],
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
}
// ═══════════════════════════════════════════════════════════════════════════
// PACKAGE LIST
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
                  if (package['nrExt'] != null &&
                      package['nrExt'].toString().isNotEmpty)
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
                if (package['lagerort'] != null &&
                    package['lagerort'].toString().isNotEmpty)
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
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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

