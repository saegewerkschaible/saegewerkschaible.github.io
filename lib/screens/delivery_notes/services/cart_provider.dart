// lib/screens/delivery_notes/services/cart_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../constants.dart';

/// Ein Artikel im Warenkorb
class CartItem {
  final String packageId;
  final String barcode;
  final String? nrExt;
  final String holzart;
  final double hoehe;
  final double breite;
  final double laenge;
  final int stueckzahl;
  final double menge;
  final String zustand;
  final String? kunde;
  final String? bemerkung;

  CartItem({
    required this.packageId,
    required this.barcode,
    this.nrExt,
    required this.holzart,
    required this.hoehe,
    required this.breite,
    required this.laenge,
    required this.stueckzahl,
    required this.menge,
    required this.zustand,
    this.kunde,
    this.bemerkung,
  });

  /// Erstellt CartItem aus Firestore-Paketdaten
  factory CartItem.fromPackageData(Map<String, dynamic> data) {
    final barcode = data['barcode']?.toString() ?? '';
    return CartItem(
      packageId: barcode,
      barcode: barcode,
      nrExt: data['nrExt']?.toString(),
      holzart: data['holzart']?.toString() ?? '',
      hoehe: (data['hoehe'] as num?)?.toDouble() ?? 0,
      breite: (data['breite'] as num?)?.toDouble() ?? 0,
      laenge: (data['laenge'] as num?)?.toDouble() ?? 0,
      stueckzahl: (data['stueckzahl'] as num?)?.toInt() ?? 0,
      menge: (data['menge'] as num?)?.toDouble() ?? 0,
      zustand: data['zustand']?.toString() ?? '',
      kunde: data['kunde']?.toString(),
      bemerkung: data['bemerkung']?.toString(),
    );
  }

  /// Konvertiert zu Map für Firestore
  Map<String, dynamic> toMap() {
    return {
      'packageId': packageId,
      'barcode': barcode,
      'nrExt': nrExt,
      'holzart': holzart,
      'hoehe': hoehe,
      'breite': breite,
      'laenge': laenge,
      'stueckzahl': stueckzahl,
      'menge': menge,
      'zustand': zustand,
      'kunde': kunde,
      'bemerkung': bemerkung,
    };
  }

  /// Formatierte Maße als String
  String get dimensionsString => '${hoehe.toInt()} × ${breite.toInt()} mm × ${laenge.toStringAsFixed(1)} m';
}

/// Provider für den Warenkorb (Lieferschein-Erstellung)
class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<CartItem> _items = [];
  Map<String, dynamic>? _selectedCustomer;
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  List<CartItem> get items => List.unmodifiable(_items);
  Map<String, dynamic>? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get itemCount => _items.length;

  /// Gesamtvolumen aller Pakete
  double get totalVolume => _items.fold(0.0, (sum, item) => sum + item.menge);

  /// Gesamtstückzahl aller Pakete
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.stueckzahl);

  /// Prüft ob ein Paket bereits im Warenkorb ist
  bool containsPackage(String barcode) {
    return _items.any((item) => item.barcode == barcode);
  }

  // ═══════════════════════════════════════════════════════════════
  // WARENKORB AKTIONEN
  // ═══════════════════════════════════════════════════════════════

  /// Fügt ein Paket zum Warenkorb hinzu
  Future<bool> addPackage(BuildContext context, Map<String, dynamic> packageData) async {
    final barcode = packageData['barcode']?.toString() ?? '';

    // Prüfen ob bereits im Warenkorb
    if (containsPackage(barcode)) {
      showAppSnackbar(context, 'Paket ist bereits im Warenkorb');
      return false;
    }

    // Prüfen ob bereits verkauft/ausgebucht
    final status = packageData['status']?.toString() ?? '';
    if (status == PackageStatus.verkauft || status == PackageStatus.ausgebucht) {
      showAppSnackbar(context, 'Paket ist bereits verkauft oder ausgebucht');
      return false;
    }

    try {
      final item = CartItem.fromPackageData(packageData);
      _items.add(item);

      // Optional: In temporäre Collection speichern für Sync
      await _saveToTemporaryCart(item);

      notifyListeners();
      showAppSnackbar(context, 'Paket $barcode hinzugefügt');
      return true;
    } catch (e) {
      showAppSnackbar(context, 'Fehler: $e');
      return false;
    }
  }

  /// Entfernt ein Paket aus dem Warenkorb
  Future<void> removePackage(String barcode) async {
    _items.removeWhere((item) => item.barcode == barcode);
    await _removeFromTemporaryCart(barcode);
    notifyListeners();
  }

  /// Leert den gesamten Warenkorb
  Future<void> clearCart() async {
    _items.clear();
    await _clearTemporaryCart();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // KUNDEN AUSWAHL
  // ═══════════════════════════════════════════════════════════════

  /// Setzt den ausgewählten Kunden
  void setCustomer(Map<String, dynamic>? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  /// Entfernt den ausgewählten Kunden
  void clearCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // TEMPORÄRER WARENKORB (Firebase Sync)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _saveToTemporaryCart(CartItem item) async {
    try {
      await _db
          .collection('temporary_cart')
          .doc(item.barcode)
          .set({
        ...item.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Fehler beim Speichern in temp cart: $e');
    }
  }

  Future<void> _removeFromTemporaryCart(String barcode) async {
    try {
      await _db.collection('temporary_cart').doc(barcode).delete();
    } catch (e) {
      debugPrint('Fehler beim Löschen aus temp cart: $e');
    }
  }

  Future<void> _clearTemporaryCart() async {
    try {
      final batch = _db.batch();
      final docs = await _db.collection('temporary_cart').get();
      for (var doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Fehler beim Leeren des temp cart: $e');
    }
  }

  /// Lädt den Warenkorb aus der temporären Collection
  Future<void> loadFromTemporaryCart() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _db
          .collection('temporary_cart')
          .orderBy('timestamp')
          .get();

      _items.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _items.add(CartItem(
          packageId: data['packageId'] ?? doc.id,
          barcode: data['barcode'] ?? doc.id,
          nrExt: data['nrExt'],
          holzart: data['holzart'] ?? '',
          hoehe: (data['hoehe'] as num?)?.toDouble() ?? 0,
          breite: (data['breite'] as num?)?.toDouble() ?? 0,
          laenge: (data['laenge'] as num?)?.toDouble() ?? 0,
          stueckzahl: (data['stueckzahl'] as num?)?.toInt() ?? 0,
          menge: (data['menge'] as num?)?.toDouble() ?? 0,
          zustand: data['zustand'] ?? '',
          kunde: data['kunde'],
          bemerkung: data['bemerkung'],
        ));
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des temp cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Startet Live-Sync mit temporärem Warenkorb
  void startSync() {
    _cartSubscription?.cancel();
    _cartSubscription = _db
        .collection('temporary_cart')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      _items.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _items.add(CartItem(
          packageId: data['packageId'] ?? doc.id,
          barcode: data['barcode'] ?? doc.id,
          nrExt: data['nrExt'],
          holzart: data['holzart'] ?? '',
          hoehe: (data['hoehe'] as num?)?.toDouble() ?? 0,
          breite: (data['breite'] as num?)?.toDouble() ?? 0,
          laenge: (data['laenge'] as num?)?.toDouble() ?? 0,
          stueckzahl: (data['stueckzahl'] as num?)?.toInt() ?? 0,
          menge: (data['menge'] as num?)?.toDouble() ?? 0,
          zustand: data['zustand'] ?? '',
          kunde: data['kunde'],
          bemerkung: data['bemerkung'],
        ));
      }
      notifyListeners();
    });
  }

  /// Stoppt Live-Sync
  void stopSync() {
    _cartSubscription?.cancel();
    _cartSubscription = null;
  }

  @override
  void dispose() {
    stopSync();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KONSTANTEN (in constants.dart ergänzen falls nicht vorhanden)
// ═══════════════════════════════════════════════════════════════════════════

class PackageStatus {
  static const String imLager = 'im Lager';
  static const String reserviert = 'reserviert';
  static const String verkauft = 'verkauft';
  static const String ausgebucht = 'ausgebucht';
}

class PackageZustand {
  static const String frisch = 'frisch';
  static const String trocken = 'trocken';
  static const String verarbeitet = 'verarbeitet';
}