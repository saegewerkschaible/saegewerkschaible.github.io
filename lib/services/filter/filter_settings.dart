// lib/packages/services/filter/filter_settings.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FilterSettings extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════
  // FILTER-OPTIONEN (aus Firebase geladen)
  // ═══════════════════════════════════════════════════════════════

  List<String> holzarten = [];
  List<String> dimensions = [];
  List<String> states = [];
  List<String> lagerort = [];
  List<String> kunden = [];
  List<String> statusOptions = ['im_lager', 'verkauft', 'verarbeitet', 'ausgebucht'];

  // ═══════════════════════════════════════════════════════════════
  // AKTIVE FILTER
  // ═══════════════════════════════════════════════════════════════

  Set<String> activeHolzarten = {};
  Set<String> activeDimensions = {};
  Set<String> activeStates = {};
  Set<String> activeLagerort = {};
  Set<String> activeKunden = {};
  Set<String> activeStatus = {'im_lager'}; // Default: nur Lager-Pakete

  // Text-Filter
  String auftragsnrFilter = '';
  String kundenFreitextFilter = '';

  // Datumsfilter
  bool dateRangeEnabled = false;
  DateTime? startDate;
  DateTime? endDate;

  // Schnellfilter
  bool showQuickFilterDate = false;
  bool showQuickFilterCustomer = false;

  // Volumenfilter
  RangeValues volumeRange = const RangeValues(0, 10);
  bool volumeFilterEnabled = false;
  bool minVolumeEnabled = true;
  bool maxVolumeEnabled = true;

  // Dimensionsfilter (frei)
  bool dimensionFilterEnabled = false;
  RangeValues staerkeRange = const RangeValues(0, 100);
  RangeValues breiteRange = const RangeValues(0, 300);
  bool minStaerkeEnabled = true;
  bool maxStaerkeEnabled = true;
  bool minBreiteEnabled = true;
  bool maxBreiteEnabled = true;

  // Längenfilter
  RangeValues laengeRange = const RangeValues(0, 10);
  bool laengeFilterEnabled = false;
  bool minLaengeEnabled = true;
  bool maxLaengeEnabled = true;

  // User
  int userGroup = 0;

  // ═══════════════════════════════════════════════════════════════
  // ALIASE (Kompatibilität mit alter App)
  // ═══════════════════════════════════════════════════════════════

  Set<String> get activePremiumkunden => activeKunden;
  set activePremiumkunden(Set<String> v) => activeKunden = v;
  List<String> get premiumkunden => kunden;
  set premiumkunden(List<String> v) => kunden = v;

  Set<String> get activeId23 => activeStatus;
  set activeId23(Set<String> v) => activeStatus = v;
  List<String> get id23Options => statusOptions;

  // Nicht verwendet in Sägewerk, aber für Kompatibilität
  Set<String> get activeId27 => {};
  List<String> get id27Options => [];
  Set<String> get activeInventoryFilter => {};
  List<String> get inventoryFilterOptions => [];
  bool get hasActiveInventory => false;
  String? get activeInventoryId => null;

  // ═══════════════════════════════════════════════════════════════
  // GETTER
  // ═══════════════════════════════════════════════════════════════

  bool get hasQuickFilters => showQuickFilterDate || showQuickFilterCustomer;
  bool get hasActiveDateFilter => dateRangeEnabled && (startDate != null || endDate != null);

  bool get hasActiveFilters {
    return activeHolzarten.isNotEmpty ||
        activeStates.isNotEmpty ||
        activeDimensions.isNotEmpty ||
        activeLagerort.isNotEmpty ||
        activeStatus.isNotEmpty ||
        activeKunden.isNotEmpty ||
        kundenFreitextFilter.isNotEmpty ||
        volumeFilterEnabled ||
        dimensionFilterEnabled ||
        laengeFilterEnabled ||
        auftragsnrFilter.isNotEmpty ||
        hasActiveDateFilter;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  bool isOtherDimension(String dimension) => !dimensions.contains(dimension);
  bool isOtherZustand(String state) => !states.contains(state);
  bool isOtherLagerort(String loc) => !lagerort.contains(loc);

  // ═══════════════════════════════════════════════════════════════
  // RESET
  // ═══════════════════════════════════════════════════════════════

  void resetFilters() {
    activeKunden.clear();
    kundenFreitextFilter = '';
    activeHolzarten.clear();
    activeStates.clear();
    activeDimensions.clear();
    activeLagerort.clear();
    activeStatus = {'im_lager'};
    volumeFilterEnabled = false;
    dimensionFilterEnabled = false;
    laengeFilterEnabled = false;
    auftragsnrFilter = '';
    dateRangeEnabled = false;
    startDate = null;
    endDate = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // FIREBASE LOADING
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadAllFilters() async {
    await Future.wait([
      _loadWoodTypes(),
      _loadDimensions(),
      _loadStates(),
      _loadLagerorte(),
      _loadKunden(),
      _loadUserGroup(),
      loadQuickFilterSettings(),
    ]);
    notifyListeners();
  }

  Future<void> _loadWoodTypes() async {
    try {
      final snapshot = await _firestore.collection('wood_types').orderBy('name').get();
      holzarten = snapshot.docs
          .map((doc) => (doc.data()['name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Fehler beim Laden der Holzarten: $e');
    }
  }

  Future<void> _loadDimensions() async {
    try {
      // Dimensionen aus Paketen aggregieren oder aus eigener Collection
      // Für jetzt: Standard-Dimensionen
      dimensions = ['27/120', '27/160', '32/120', '32/160', '52/120', '52/160', 'andere'];
    } catch (e) {
      debugPrint('Fehler beim Laden der Dimensionen: $e');
    }
  }

  Future<void> _loadStates() async {
    try {
      // Zustände sind in Sägewerk fix definiert
      states = ['frisch', 'trocken'];
    } catch (e) {
      debugPrint('Fehler beim Laden der Zustände: $e');
    }
  }

  Future<void> _loadLagerorte() async {
    try {
      final snapshot = await _firestore.collection('locations').orderBy('name').get();
      lagerort = snapshot.docs
          .map((doc) => (doc.data()['name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
      if (!lagerort.contains('andere')) {
        lagerort.add('andere');
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Lagerorte: $e');
    }
  }

  Future<void> _loadKunden() async {
    try {
      final snapshot = await _firestore.collection('customers').orderBy('name').get();
      kunden = snapshot.docs
          .map((doc) => (doc.data()['name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Fehler beim Laden der Kunden: $e');
    }
  }

  Future<void> _loadUserGroup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userGroup = userDoc.data()?['userGroup'] ?? 1;
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der UserGroup: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK FILTER SETTINGS (User-spezifisch)
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveQuickFilterSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'quickFilters': {
            'showDate': showQuickFilterDate,
            'showCustomer': showQuickFilterCustomer,
          }
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Speichern der Schnellfilter: $e');
    }
  }

  Future<void> loadQuickFilterSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final quickFilters = userDoc.data()?['quickFilters'] as Map<String, dynamic>?;
          if (quickFilters != null) {
            showQuickFilterDate = quickFilters['showDate'] ?? false;
            showQuickFilterCustomer = quickFilters['showCustomer'] ?? false;
          }
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Schnellfilter: $e');
    }
  }
}