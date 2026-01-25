// lib/packages/services/package_filter_service.dart
// ═══════════════════════════════════════════════════════════════════════════
// PACKAGE FILTER SERVICE
// Filterlogik für Pakete - unabhängig vom FilterSettings Provider
// ═══════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'dimensions_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum PackageSortField {
  createdAt,
  barcode,
  nrExt,
  holzart,
  menge,
  hoehe,
  breite,
  laenge,
  datum,
}

enum SortDirection { ascending, descending }

// ═══════════════════════════════════════════════════════════════════════════
// PACKAGE FILTER SERVICE
// ═══════════════════════════════════════════════════════════════════════════

class PackageFilterService {
  static final PackageFilterService _instance = PackageFilterService._internal();
  factory PackageFilterService() => _instance;
  PackageFilterService._internal();

  final DimensionsService _dimensionsService = DimensionsService();

  // ═══════════════════════════════════════════════════════════════════════════
  // DIMENSIONS OPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, List<double>>> loadDimensionOptions() async {
    return {
      'height': await _dimensionsService.getHeightOptions(),
      'width': await _dimensionsService.getWidthOptions(),
      'length': await _dimensionsService.getLengthOptions(),
    };
  }

  Stream<Map<String, List<double>>> watchDimensionOptions() {
    return _dimensionsService.watchDimensions();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER BY NUMMER (Intern/Extern)
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> filterByNummer(
      List<Map<String, dynamic>> packages,
      String suche,
      ) {
    if (suche.isEmpty) return packages;

    final sucheLower = suche.toLowerCase().trim();
    return packages.where((pkg) {
      final barcode = (pkg['barcode'] ?? '').toString().toLowerCase();
      final nrExt = (pkg['nrExt'] ?? '').toString().toLowerCase();
      return barcode.contains(sucheLower) || nrExt.contains(sucheLower);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER BY EXACT DIMENSIONS (aus Settings)
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> filterByExactDimensions(
      List<Map<String, dynamic>> packages, {
        Set<double> heights = const {},
        Set<double> widths = const {},
        Set<double> lengths = const {},
      }) {
    return packages.where((pkg) {
      // Stärke/Höhe
      if (heights.isNotEmpty) {
        final hoehe = (pkg['hoehe'] ?? 0).toDouble();
        if (!heights.contains(hoehe)) return false;
      }

      // Breite
      if (widths.isNotEmpty) {
        final breite = (pkg['breite'] ?? 0).toDouble();
        if (!widths.contains(breite)) return false;
      }

      // Länge
      if (lengths.isNotEmpty) {
        final laenge = (pkg['laenge'] ?? 0).toDouble();
        if (!lengths.contains(laenge)) return false;
      }

      return true;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SORTIERUNG
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> sortPackages(
      List<Map<String, dynamic>> packages,
      PackageSortField field,
      SortDirection direction,
      ) {
    final sorted = List<Map<String, dynamic>>.from(packages);

    sorted.sort((a, b) {
      int result = 0;

      switch (field) {
        case PackageSortField.createdAt:
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          result = (aTime?.millisecondsSinceEpoch ?? 0)
              .compareTo(bTime?.millisecondsSinceEpoch ?? 0);
          break;

        case PackageSortField.barcode:
          result = (a['barcode'] ?? '').toString()
              .compareTo((b['barcode'] ?? '').toString());
          break;

        case PackageSortField.nrExt:
          final aExt = (a['nrExt'] ?? '').toString();
          final bExt = (b['nrExt'] ?? '').toString();
          final aNum = int.tryParse(aExt);
          final bNum = int.tryParse(bExt);
          if (aNum != null && bNum != null) {
            result = aNum.compareTo(bNum);
          } else {
            result = aExt.compareTo(bExt);
          }
          break;

        case PackageSortField.holzart:
          result = (a['holzart'] ?? '').toString()
              .compareTo((b['holzart'] ?? '').toString());
          break;

        case PackageSortField.menge:
          result = ((a['menge'] ?? 0) as num)
              .compareTo((b['menge'] ?? 0) as num);
          break;

        case PackageSortField.hoehe:
          result = ((a['hoehe'] ?? 0) as num)
              .compareTo((b['hoehe'] ?? 0) as num);
          break;

        case PackageSortField.breite:
          result = ((a['breite'] ?? 0) as num)
              .compareTo((b['breite'] ?? 0) as num);
          break;

        case PackageSortField.laenge:
          result = ((a['laenge'] ?? 0) as num)
              .compareTo((b['laenge'] ?? 0) as num);
          break;

        case PackageSortField.datum:
          final aDate = a['datum']?.toString() ?? '';
          final bDate = b['datum']?.toString() ?? '';
          try {
            final aParsed = DateFormat('dd.MM.yyyy').parse(aDate);
            final bParsed = DateFormat('dd.MM.yyyy').parse(bDate);
            result = aParsed.compareTo(bParsed);
          } catch (_) {
            result = aDate.compareTo(bDate);
          }
          break;
      }

      return direction == SortDirection.ascending ? result : -result;
    });

    return sorted;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════

  PackageSummary generateSummary(List<Map<String, dynamic>> packages) {
    final totalMenge = packages.fold<double>(
      0, (sum, pkg) => sum + ((pkg['menge'] ?? 0) as num).toDouble(),
    );

    final totalStueck = packages.fold<int>(
      0, (sum, pkg) => sum + ((pkg['stueckzahl'] ?? 0) as num).toInt(),
    );

    final Map<String, int> byHolzart = {};
    final Map<String, double> mengeByHolzart = {};

    for (var pkg in packages) {
      final holzart = pkg['holzart']?.toString() ?? 'Unbekannt';
      byHolzart[holzart] = (byHolzart[holzart] ?? 0) + 1;
      mengeByHolzart[holzart] = (mengeByHolzart[holzart] ?? 0) +
          ((pkg['menge'] ?? 0) as num).toDouble();
    }

    return PackageSummary(
      totalPackages: packages.length,
      totalMenge: totalMenge,
      totalStueck: totalStueck,
      packagesByHolzart: byHolzart,
      mengeByHolzart: mengeByHolzart,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER: Sortfield Label
  // ═══════════════════════════════════════════════════════════════════════════

  static String getSortFieldLabel(PackageSortField field) {
    switch (field) {
      case PackageSortField.createdAt: return 'Erstelldatum';
      case PackageSortField.barcode: return 'Interne Nr.';
      case PackageSortField.nrExt: return 'Externe Nr.';
      case PackageSortField.holzart: return 'Holzart';
      case PackageSortField.menge: return 'Menge';
      case PackageSortField.hoehe: return 'Stärke';
      case PackageSortField.breite: return 'Breite';
      case PackageSortField.laenge: return 'Länge';
      case PackageSortField.datum: return 'Datum';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUMMARY CLASS
// ═══════════════════════════════════════════════════════════════════════════

class PackageSummary {
  final int totalPackages;
  final double totalMenge;
  final int totalStueck;
  final Map<String, int> packagesByHolzart;
  final Map<String, double> mengeByHolzart;

  const PackageSummary({
    required this.totalPackages,
    required this.totalMenge,
    required this.totalStueck,
    required this.packagesByHolzart,
    required this.mengeByHolzart,
  });
}