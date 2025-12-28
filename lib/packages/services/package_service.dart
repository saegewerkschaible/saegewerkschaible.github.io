// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/services/package_service.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Status-Werte für Pakete
class PackageStatus {
  static const String imLager = 'im_lager';
  static const String verkauft = 'verkauft';
  static const String verarbeitet = 'verarbeitet';
  static const String ausgebucht = 'ausgebucht';
}

/// Zustand-Werte für Pakete
class PackageZustand {
  static const String frisch = 'frisch';
  static const String trocken = 'trocken';
}

/// Service für alle Paket-Operationen
class PackageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // COLLECTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  CollectionReference get _packages => _firestore.collection('packages');
  CollectionReference get _locations => _firestore.collection('locations');
  CollectionReference get _woodTypes => _firestore.collection('wood_types');
  CollectionReference get _customers => _firestore.collection('customers');
  DocumentReference get _settings => _firestore.collection('settings').doc('app');

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream aller Pakete (sortiert nach Erstelldatum)
  Stream<QuerySnapshot> getPackagesStream() {
    return _packages.orderBy('createdAt', descending: true).snapshots();
  }

  /// Stream für ein einzelnes Paket
  Stream<DocumentSnapshot> getPackageStream(String barcode) {
    return _packages.doc(barcode).snapshots();
  }

  /// Stream der Lagerorte
  Stream<QuerySnapshot> getLocationsStream() {
    return _locations.orderBy('name').snapshots();
  }

  /// Stream der Holzarten
  Stream<QuerySnapshot> getWoodTypesStream() {
    return _woodTypes.orderBy('name').snapshots();
  }

  /// Stream der Kunden
  Stream<QuerySnapshot> getCustomersStream() {
    return _customers.orderBy('name').snapshots();
  }

  /// Stream der Paket-Historie
  Stream<QuerySnapshot> getPackageHistoryStream(String barcode) {
    return _packages
        .doc(barcode)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONEN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nächste freie Paketnummer holen
  Future<int> getNextPackageNumber() async {
    final settingsDoc = await _settings.get();
    final data = settingsDoc.data() as Map<String, dynamic>?;
    return (data?['lastPackage'] ?? 0) + 1;
  }

  /// Neues Paket erstellen
  Future<String> createPackage(Map<String, dynamic> data) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

    // Nächste Paketnummer in Transaktion holen
    int newPackageNumber = 0;

    await _firestore.runTransaction((transaction) async {
      final settingsDoc = await transaction.get(_settings);
      final settingsData = settingsDoc.data() as Map<String, dynamic>? ?? {};
      final lastPackage = settingsData['lastPackage'] ?? 0;
      newPackageNumber = lastPackage + 1;

      // Settings aktualisieren
      transaction.set(_settings, {'lastPackage': newPackageNumber}, SetOptions(merge: true));
    });

    final barcode = newPackageNumber.toString();

    // Paketdaten vorbereiten
    final packageData = {
      'barcode': barcode,
      'nr': newPackageNumber,
      'nrExt': data['nrExt'] ?? '',
      'auftragsnr': data['auftragsnr'] ?? '',
      'datum': data['datum'] ?? currentDate,
      'holzart': data['holzart'] ?? '',
      'kunde': data['kunde'] ?? '',
      'hoehe': data['hoehe'] ?? 0,
      'breite': data['breite'] ?? 0,
      'laenge': data['laenge'] ?? 0,
      'stueckzahl': data['stueckzahl'] ?? 0,
      'menge': data['menge'] ?? 0.0,
      'zustand': data['zustand'] ?? PackageZustand.frisch,
      'lagerort': data['lagerort'] ?? '',
      'bemerkung': data['bemerkung'] ?? '',
      'saeger': data['saeger'] ?? '',
      'status': PackageStatus.imLager,
      'verkauftAm': null,
      'verarbeitetAm': null,
      'ausgebuchtAm': null,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser?.email ?? 'unbekannt',
      'lastModified': FieldValue.serverTimestamp(),
      'lastModifiedBy': currentUser?.email ?? 'unbekannt',
    };

    // Paket erstellen
    await _packages.doc(barcode).set(packageData);

    // Historie-Eintrag
    await _packages.doc(barcode).collection('history').add({
      'timestamp': FieldValue.serverTimestamp(),
      'changedBy': currentUser?.email ?? 'unbekannt',
      'action': 'Paket erstellt',
      'initialData': packageData,
    });

    return barcode;
  }

  /// Paket aktualisieren
  Future<void> updatePackage(String barcode, Map<String, dynamic> newData, Map<String, dynamic> oldData) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Geänderte Felder ermitteln
    final changedFields = <String, Map<String, dynamic>>{};
    newData.forEach((key, value) {
      if (oldData[key] != value) {
        changedFields[key] = {
          'old': oldData[key],
          'new': value,
        };
      }
    });

    if (changedFields.isEmpty) return;

    // Update-Daten vorbereiten
    final updateData = Map<String, dynamic>.from(newData);
    updateData['lastModified'] = FieldValue.serverTimestamp();
    updateData['lastModifiedBy'] = currentUser?.email ?? 'unbekannt';

    // Transaktion für Update + Historie
    await _firestore.runTransaction((transaction) async {
      transaction.update(_packages.doc(barcode), updateData);

      // Historie-Eintrag
      final historyData = {
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser?.email ?? 'unbekannt',
        'action': 'Paket aktualisiert',
        'changes': changedFields,
      };

      transaction.set(
        _packages.doc(barcode).collection('history').doc(),
        historyData,
      );
    });
  }

  /// Paket löschen (mit Backup)
  Future<void> deletePackage(String barcode) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Paketdaten holen
    final packageDoc = await _packages.doc(barcode).get();
    if (!packageDoc.exists) return;

    final packageData = packageDoc.data() as Map<String, dynamic>;

    // Historie holen
    final historyDocs = await _packages.doc(barcode).collection('history').get();

    // Backup erstellen
    await _firestore.collection('deleted_packages').doc(barcode).set({
      ...packageData,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': currentUser?.email ?? 'unbekannt',
    });

    // Historie ins Backup
    for (var doc in historyDocs.docs) {
      await _firestore
          .collection('deleted_packages')
          .doc(barcode)
          .collection('history')
          .add(doc.data());
    }

    // Original löschen
    for (var doc in historyDocs.docs) {
      await doc.reference.delete();
    }
    await _packages.doc(barcode).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS-ÄNDERUNGEN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Paket als verkauft markieren
  Future<void> markAsVerkauft(String barcode) async {
    final currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
    await _updateStatus(barcode, PackageStatus.verkauft, 'verkauftAm', currentDate);
  }

  /// Paket als verarbeitet markieren
  Future<void> markAsVerarbeitet(String barcode) async {
    final currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
    await _updateStatus(barcode, PackageStatus.verarbeitet, 'verarbeitetAm', currentDate);
  }

  /// Paket ausbuchen
  Future<void> markAsAusgebucht(String barcode) async {
    final currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
    await _updateStatus(barcode, PackageStatus.ausgebucht, 'ausgebuchtAm', currentDate);
  }

  /// Status zurücksetzen
  Future<void> resetStatus(String barcode) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    await _firestore.runTransaction((transaction) async {
      transaction.update(_packages.doc(barcode), {
        'status': PackageStatus.imLager,
        'verkauftAm': null,
        'verarbeitetAm': null,
        'ausgebuchtAm': null,
        'lastModified': FieldValue.serverTimestamp(),
        'lastModifiedBy': currentUser?.email ?? 'unbekannt',
      });

      transaction.set(
        _packages.doc(barcode).collection('history').doc(),
        {
          'timestamp': FieldValue.serverTimestamp(),
          'changedBy': currentUser?.email ?? 'unbekannt',
          'action': 'Status zurückgesetzt',
        },
      );
    });
  }

  /// Interne Hilfsmethode für Status-Updates
  Future<void> _updateStatus(String barcode, String newStatus, String dateField, String date) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(_packages.doc(barcode));
      final oldStatus = (doc.data() as Map<String, dynamic>?)?['status'] ?? '';

      transaction.update(_packages.doc(barcode), {
        'status': newStatus,
        dateField: date,
        'lastModified': FieldValue.serverTimestamp(),
        'lastModifiedBy': currentUser?.email ?? 'unbekannt',
      });

      transaction.set(
        _packages.doc(barcode).collection('history').doc(),
        {
          'timestamp': FieldValue.serverTimestamp(),
          'changedBy': currentUser?.email ?? 'unbekannt',
          'action': 'Status geändert',
          'changes': {
            'status': {'old': oldStatus, 'new': newStatus},
          },
        },
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAMMDATEN VERWALTUNG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Neuen Lagerort hinzufügen
  Future<void> addLocation(String name) async {
    await _locations.add({'name': name});
  }

  /// Neue Holzart hinzufügen
  Future<void> addWoodType(String name) async {
    await _woodTypes.add({'name': name});
  }

  /// Neuen Kunden hinzufügen
  Future<void> addCustomer(String name) async {
    await _customers.add({'name': name});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOLUMEN-BERECHNUNG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Berechnet das Volumen in m³
  static double calculateVolume({
    required double hoehe,
    required double breite,
    required double laenge,
    required int stueckzahl,
  }) {
    // hoehe und breite in mm, laenge in m
    // Formel: (H * B * L * Stk) / 1.000.000
    return (hoehe * breite * laenge * stueckzahl) / 1000000;
  }
}