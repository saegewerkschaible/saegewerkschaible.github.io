// ═══════════════════════════════════════════════════════════════════════════
// lib/screens/statistic_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../core/theme/theme_provider.dart';

class StatisticsScreen extends StatefulWidget {
  final int userGroup;

  const StatisticsScreen({super.key, required this.userGroup});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTab = 0; // 0=Heute, 1=Woche, 2=Monat, 3=Gesamt
  String? _selectedWoodType;
  String _selectedStatus = 'all';
  String _selectedZustand = 'all';

  final _packagesRef = FirebaseFirestore.instance.collection('packages');

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Column(
      children: [
        _buildTimeframeTabs(theme),
        _buildFilters(theme),
        Expanded(child: _buildContent(theme)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TIMEFRAME TABS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTimeframeTabs(ThemeProvider theme) {
    final tabs = ['Heute', 'Woche', 'Monat', 'Gesamt'];

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin: EdgeInsets.only(right: i < tabs.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : theme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? theme.primary : theme.border,
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : theme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilters(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Erste Reihe: Status + Zustand
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  theme: theme,
                  value: _selectedStatus,
                  items: const {
                    'all': 'Alle Status',
                    'im_lager': 'Im Lager',
                    'verarbeitet': 'Verarbeitet',
                    'verkauft': 'Verkauft',
                    'ausgebucht': 'Ausgebucht',
                  },
                  onChanged: (v) => setState(() => _selectedStatus = v ?? 'all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  theme: theme,
                  value: _selectedZustand,
                  items: const {
                    'all': 'Alle Zustände',
                    'frisch': 'Frisch',
                    'trocken': 'Trocken',
                  },
                  onChanged: (v) => setState(() => _selectedZustand = v ?? 'all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Zweite Reihe: Holzart
          _buildWoodTypeDropdown(theme),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required ThemeProvider theme,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          style: TextStyle(fontSize: 13, color: theme.textPrimary),
          dropdownColor: theme.surface,
          icon: Icon(Icons.arrow_drop_down, color: theme.textSecondary),
          onChanged: onChanged,
          items: items.entries.map((e) {
            return DropdownMenuItem(value: e.key, child: Text(e.value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWoodTypeDropdown(ThemeProvider theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('wood_types').snapshots(),
      builder: (context, snapshot) {
        List<String> woodTypes = ['Alle Holzarten'];
        if (snapshot.hasData) {
          woodTypes.addAll(
            snapshot.data!.docs.map((d) => d['name']?.toString() ?? '').where((n) => n.isNotEmpty),
          );
        }

        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _selectedWoodType,
              hint: Text('Alle Holzarten', style: TextStyle(fontSize: 13, color: theme.textSecondary)),
              style: TextStyle(fontSize: 13, color: theme.textPrimary),
              dropdownColor: theme.surface,
              icon: Icon(Icons.arrow_drop_down, color: theme.textSecondary),
              onChanged: (v) => setState(() => _selectedWoodType = v == 'Alle Holzarten' ? null : v),
              items: woodTypes.map((w) {
                return DropdownMenuItem(
                  value: w == 'Alle Holzarten' ? null : w,
                  child: Text(w),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CONTENT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildContent(ThemeProvider theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _packagesRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.primary));
        }

        final allPackages = snapshot.data!.docs
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();

        // Zeitfilter anwenden
        final packages = _filterByTimeframe(allPackages);

        // Statistiken berechnen
        final stats = _calculateStats(packages);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Übersicht Cards
              _buildOverviewCards(theme, stats),
              const SizedBox(height: 16),

              // Zustand (frisch/trocken) - NEU
              _buildSection(
                theme: theme,
                title: 'Nach Zustand',
                icon: Icons.water_drop,
                child: _buildZustandBreakdown(theme, stats),
              ),
              const SizedBox(height: 12),

              // Nach Status
              _buildSection(
                theme: theme,
                title: 'Nach Status',
                icon: Icons.inventory,
                child: _buildStatusBreakdown(theme, stats),
              ),
              const SizedBox(height: 12),

              // Nach Holzart
              _buildSection(
                theme: theme,
                title: 'Nach Holzart',
                icon: Icons.forest,
                child: _buildWoodTypeBreakdown(theme, stats),
              ),
              const SizedBox(height: 12),

              // Kombiniert: Holzart + Zustand
              _buildSection(
                theme: theme,
                title: 'Holzart × Zustand',
                icon: Icons.grid_view,
                child: _buildCombinedBreakdown(theme, stats),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterByTimeframe(List<Map<String, dynamic>> packages) {
    if (_selectedTab == 3) return packages; // Gesamt

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return packages.where((p) {
      final datumStr = p['datum']?.toString();
      if (datumStr == null || datumStr.isEmpty) return false;

      try {
        final datum = DateFormat('dd.MM.yyyy').parse(datumStr);
        switch (_selectedTab) {
          case 0: // Heute
            return datum.year == today.year && datum.month == today.month && datum.day == today.day;
          case 1: // Woche
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            return !datum.isBefore(weekStart);
          case 2: // Monat
            return datum.year == today.year && datum.month == today.month;
          default:
            return true;
        }
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> packages) {
    int totalPackages = 0;
    double totalVolume = 0;

    // Nach Status
    Map<String, double> byStatus = {};
    Map<String, int> countByStatus = {};

    // Nach Zustand (NEU)
    Map<String, double> byZustand = {'frisch': 0, 'trocken': 0};
    Map<String, int> countByZustand = {'frisch': 0, 'trocken': 0};

    // Nach Holzart
    Map<String, double> byWoodType = {};
    Map<String, int> countByWoodType = {};

    // Kombiniert: Holzart + Zustand (NEU)
    Map<String, Map<String, double>> combined = {};

    for (var p in packages) {
      final status = p['status']?.toString() ?? 'im_lager';
      final zustand = p['zustand']?.toString() ?? 'frisch';
      final holzart = p['holzart']?.toString() ?? 'Sonstige';
      final menge = _parseDouble(p['menge']);

      // Filter anwenden
      if (_selectedStatus != 'all' && status != _selectedStatus) continue;
      if (_selectedZustand != 'all' && zustand != _selectedZustand) continue;
      if (_selectedWoodType != null && holzart != _selectedWoodType) continue;

      totalPackages++;
      totalVolume += menge;

      // Status
      byStatus[status] = (byStatus[status] ?? 0) + menge;
      countByStatus[status] = (countByStatus[status] ?? 0) + 1;

      // Zustand
      byZustand[zustand] = (byZustand[zustand] ?? 0) + menge;
      countByZustand[zustand] = (countByZustand[zustand] ?? 0) + 1;

      // Holzart
      byWoodType[holzart] = (byWoodType[holzart] ?? 0) + menge;
      countByWoodType[holzart] = (countByWoodType[holzart] ?? 0) + 1;

      // Kombiniert
      combined.putIfAbsent(holzart, () => {'frisch': 0, 'trocken': 0});
      combined[holzart]![zustand] = (combined[holzart]![zustand] ?? 0) + menge;
    }

    return {
      'totalPackages': totalPackages,
      'totalVolume': totalVolume,
      'byStatus': byStatus,
      'countByStatus': countByStatus,
      'byZustand': byZustand,
      'countByZustand': countByZustand,
      'byWoodType': byWoodType,
      'countByWoodType': countByWoodType,
      'combined': combined,
    };
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════
  // UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOverviewCards(ThemeProvider theme, Map<String, dynamic> stats) {
    final byZustand = stats['byZustand'] as Map<String, double>;

    return Column(
      children: [
        // Haupt-Karten
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme: theme,
                icon: Icons.inventory_2,
                value: '${stats['totalPackages']}',
                label: 'Pakete',
                color: theme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                theme: theme,
                icon: Icons.view_in_ar,
                value: _formatVolume(stats['totalVolume']),
                label: 'Gesamt',
                color: theme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Zustand-Karten
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme: theme,
                icon: Icons.water_drop,
                value: _formatVolume(byZustand['frisch'] ?? 0),
                label: 'Frisch',
                color: theme.stateColors['frisch'] ?? theme.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                theme: theme,
                icon: Icons.wb_sunny,
                value: _formatVolume(byZustand['trocken'] ?? 0),
                label: 'Trocken',
                color: theme.stateColors['trocken'] ?? theme.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ThemeProvider theme,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required ThemeProvider theme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ZUSTAND BREAKDOWN (NEU)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildZustandBreakdown(ThemeProvider theme, Map<String, dynamic> stats) {
    final byZustand = stats['byZustand'] as Map<String, double>;
    final countByZustand = stats['countByZustand'] as Map<String, int>;
    final total = stats['totalVolume'] as double;

    final zustandLabels = {'frisch': 'Frisch', 'trocken': 'Trocken'};

    return Column(
      children: ['frisch', 'trocken'].map((zustand) {
        final volume = byZustand[zustand] ?? 0;
        final count = countByZustand[zustand] ?? 0;
        final percentage = total > 0 ? (volume / total * 100) : 0;
        final color = theme.stateColors[zustand] ?? theme.textSecondary;

        return _buildBreakdownRow(
          theme: theme,
          label: zustandLabels[zustand] ?? zustand,
          count: count,
          volume: volume,
          percentage: percentage.toDouble(),
          color: color,
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS BREAKDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatusBreakdown(ThemeProvider theme, Map<String, dynamic> stats) {
    final byStatus = stats['byStatus'] as Map<String, double>;
    final countByStatus = stats['countByStatus'] as Map<String, int>;
    final total = stats['totalVolume'] as double;

    final statusColors = {
      'im_lager': theme.info,
      'verarbeitet': theme.warning,
      'verkauft': theme.success,
      'ausgebucht': theme.error,
    };

    final statusLabels = {
      'im_lager': 'Im Lager',
      'verarbeitet': 'Verarbeitet',
      'verkauft': 'Verkauft',
      'ausgebucht': 'Ausgebucht',
    };

    final sortedEntries = byStatus.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: sortedEntries.map((e) {
        final percentage = total > 0 ? (e.value / total * 100) : 0;
        final color = statusColors[e.key] ?? theme.textSecondary;
        final count = countByStatus[e.key] ?? 0;

        return _buildBreakdownRow(
          theme: theme,
          label: statusLabels[e.key] ?? e.key,
          count: count,
          volume: e.value,
          percentage: percentage.toDouble(),
          color: color,
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WOOD TYPE BREAKDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWoodTypeBreakdown(ThemeProvider theme, Map<String, dynamic> stats) {
    final byWoodType = stats['byWoodType'] as Map<String, double>;
    final countByWoodType = stats['countByWoodType'] as Map<String, int>;
    final total = stats['totalVolume'] as double;

    if (byWoodType.isEmpty) {
      return _buildEmptyState(theme);
    }

    final sorted = byWoodType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((e) {
        final percentage = total > 0 ? (e.value / total * 100) : 0;
        final color = _getWoodColor(e.key);
        final count = countByWoodType[e.key] ?? 0;

        return _buildBreakdownRow(
          theme: theme,
          label: e.key,
          count: count,
          volume: e.value,
          percentage: percentage.toDouble(),
          color: color,
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COMBINED BREAKDOWN (Holzart × Zustand) - NEU
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCombinedBreakdown(ThemeProvider theme, Map<String, dynamic> stats) {
    final combined = stats['combined'] as Map<String, Map<String, double>>;

    if (combined.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Sortiert nach Gesamt-Volumen
    final sorted = combined.entries.toList()
      ..sort((a, b) {
        final totalA = (a.value['frisch'] ?? 0) + (a.value['trocken'] ?? 0);
        final totalB = (b.value['frisch'] ?? 0) + (b.value['trocken'] ?? 0);
        return totalB.compareTo(totalA);
      });

    return Column(
      children: sorted.map((e) {
        final holzart = e.key;
        final frisch = e.value['frisch'] ?? 0;
        final trocken = e.value['trocken'] ?? 0;
        final total = frisch + trocken;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getWoodColor(holzart),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      holzart,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _formatVolume(total),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Stacked Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      if (frisch > 0)
                        Expanded(
                          flex: (frisch * 100).round(),
                          child: Container(
                            color: theme.stateColors['frisch'],
                            alignment: Alignment.center,
                            child: frisch > total * 0.15
                                ? Text(
                              _formatVolumeShort(frisch),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                                : null,
                          ),
                        ),
                      if (trocken > 0)
                        Expanded(
                          flex: (trocken * 100).round(),
                          child: Container(
                            color: theme.stateColors['trocken'],
                            alignment: Alignment.center,
                            child: trocken > total * 0.15
                                ? Text(
                              _formatVolumeShort(trocken),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Legende
              Row(
                children: [
                  _buildLegendItem(theme, 'Frisch', frisch, theme.stateColors['frisch']!),
                  const SizedBox(width: 16),
                  _buildLegendItem(theme, 'Trocken', trocken, theme.stateColors['trocken']!),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(ThemeProvider theme, String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${_formatVolumeShort(value)}',
          style: TextStyle(fontSize: 11, color: theme.textSecondary),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBreakdownRow({
    required ThemeProvider theme,
    required String label,
    required int count,
    required double volume,
    required double percentage,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                Text(
                  '$count Pakete',
                  style: TextStyle(fontSize: 10, color: theme.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (percentage / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 4),
                    child: percentage > 10
                        ? Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 65,
            child: Text(
              _formatVolume(volume),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine Daten',
          style: TextStyle(color: theme.textSecondary),
        ),
      ),
    );
  }

  Color _getWoodColor(String woodType) {
    final hash = woodType.hashCode;
    final hue = (hash % 360).toDouble().abs();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.45).toColor();
  }

  String _formatVolume(double v) {
    return '${v.toStringAsFixed(2).replaceAll('.', ',')} m³';
  }

  String _formatVolumeShort(double v) {
    return '${v.toStringAsFixed(1)} m³';
  }
}