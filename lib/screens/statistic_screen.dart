// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/screens/statistics_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

class StatisticsScreen extends StatefulWidget {
  final int userGroup;

  const StatisticsScreen({super.key, required this.userGroup});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTab = 0; // 0=Heute, 1=Woche, 2=Monat
  String? _selectedWoodType;
  String _selectedStatus = 'all'; // all, im_lager, verarbeitet, verkauft

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
    final tabs = ['Heute', 'Woche', 'Monat'];

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : theme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? theme.primary : theme.border,
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 14,
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
      child: Row(
        children: [
          // Status Filter
          Expanded(
            child: _buildDropdown(
              theme: theme,
              value: _selectedStatus,
              items: const {
                'all': 'Alle Status',
                'im_lager': 'Im Lager',
                'verarbeitet': 'Verarbeitet',
                'verkauft': 'Verkauft',
              },
              onChanged: (v) => setState(() => _selectedStatus = v ?? 'all'),
            ),
          ),
          const SizedBox(width: 8),
          // Holzart Filter
          Expanded(
            child: _buildWoodTypeDropdown(theme),
          ),
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
      stream: FirebaseFirestore.instance
          .collection('wood_types')
          .snapshots(),
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
      stream: _getFilteredStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.primary));
        }

        final packages = snapshot.data!.docs
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();

        // Statistiken berechnen
        final stats = _calculateStats(packages);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Übersicht Cards
              _buildOverviewCards(theme, stats),
              const SizedBox(height: 20),

              // Nach Status
              _buildSection(
                theme: theme,
                title: 'Nach Status',
                child: _buildStatusBreakdown(theme, stats),
              ),
              const SizedBox(height: 16),

              // Nach Holzart
              _buildSection(
                theme: theme,
                title: 'Nach Holzart',
                child: _buildWoodTypeBreakdown(theme, stats),
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    final now = DateTime.now();
    String startDate;

    switch (_selectedTab) {
      case 0: // Heute
        startDate = DateFormat('dd.MM.yyyy').format(now);
        return _packagesRef.where('datum', isEqualTo: startDate).snapshots();
      case 1: // Woche
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateFormat('dd.MM.yyyy').format(weekStart);
        return _packagesRef.where('datum', isGreaterThanOrEqualTo: startDate).snapshots();
      case 2: // Monat
        final monthStart = DateTime(now.year, now.month, 1);
        startDate = DateFormat('dd.MM.yyyy').format(monthStart);
        return _packagesRef.where('datum', isGreaterThanOrEqualTo: startDate).snapshots();
      default:
        return _packagesRef.snapshots();
    }
  }

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> packages) {
    int totalPackages = 0;
    double totalVolume = 0;

    // Nach Status
    Map<String, double> byStatus = {'im_lager': 0, 'verarbeitet': 0, 'verkauft': 0};
    Map<String, int> countByStatus = {'im_lager': 0, 'verarbeitet': 0, 'verkauft': 0};

    // Nach Holzart
    Map<String, double> byWoodType = {};
    Map<String, int> countByWoodType = {};

    for (var p in packages) {
      final status = p['status']?.toString() ?? 'im_lager';
      final holzart = p['holzart']?.toString() ?? 'Sonstige';
      final menge = _parseDouble(p['menge']);

      // Filter anwenden
      if (_selectedStatus != 'all' && status != _selectedStatus) continue;
      if (_selectedWoodType != null && holzart != _selectedWoodType) continue;

      totalPackages++;
      totalVolume += menge;

      // Status
      byStatus[status] = (byStatus[status] ?? 0) + menge;
      countByStatus[status] = (countByStatus[status] ?? 0) + 1;

      // Holzart
      byWoodType[holzart] = (byWoodType[holzart] ?? 0) + menge;
      countByWoodType[holzart] = (countByWoodType[holzart] ?? 0) + 1;
    }

    return {
      'totalPackages': totalPackages,
      'totalVolume': totalVolume,
      'byStatus': byStatus,
      'countByStatus': countByStatus,
      'byWoodType': byWoodType,
      'countByWoodType': countByWoodType,
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
    return Row(
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
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme: theme,
            icon: Icons.view_in_ar,
            value: _formatVolume(stats['totalVolume']),
            label: 'Volumen',
            color: theme.success,
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required ThemeProvider theme,
    required String title,
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(ThemeProvider theme, Map<String, dynamic> stats) {
    final byStatus = stats['byStatus'] as Map<String, double>;
    final countByStatus = stats['countByStatus'] as Map<String, int>;
    final total = stats['totalVolume'] as double;

    final statusColors = {
      'im_lager': theme.info,
      'verarbeitet': theme.warning,
      'verkauft': theme.success,
    };

    final statusLabels = {
      'im_lager': 'Im Lager',
      'verarbeitet': 'Verarbeitet',
      'verkauft': 'Verkauft',
    };

    return Column(
      children: byStatus.entries.map((e) {
        final percentage = total > 0 ? (e.value / total * 100) : 0;
        final color = statusColors[e.key] ?? theme.textSecondary;
        final count = countByStatus[e.key] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabels[e.key] ?? e.key,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      '$count Pakete',
                      style: TextStyle(fontSize: 11, color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 70,
                child: Text(
                  _formatVolume(e.value),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWoodTypeBreakdown(ThemeProvider theme, Map<String, dynamic> stats) {
    final byWoodType = stats['byWoodType'] as Map<String, double>;
    final countByWoodType = stats['countByWoodType'] as Map<String, int>;
    final total = stats['totalVolume'] as double;

    if (byWoodType.isEmpty) {
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

    // Sortiert nach Volumen
    final sorted = byWoodType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((e) {
        final percentage = total > 0 ? (e.value / total * 100) : 0;
        final color = _getWoodColor(e.key);
        final count = countByWoodType[e.key] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      '$count Pakete',
                      style: TextStyle(fontSize: 11, color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 70,
                child: Text(
                  _formatVolume(e.value),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getWoodColor(String woodType) {
    // Deterministische Farbe basierend auf Holzart-Name
    final hash = woodType.hashCode;
    final hue = (hash % 360).toDouble().abs();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  String _formatVolume(double v) {
    return '${v.toStringAsFixed(2).replaceAll('.', ',')} m³';
  }
}