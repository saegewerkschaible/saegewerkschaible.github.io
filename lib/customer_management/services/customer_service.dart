// lib/services/customer_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/customer_management/models/customer.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _customersCollection =>
      _firestore.collection('customers');

  // ===== LESEN =====

  /// Hole alle Kunden (sortiert nach Name)
  Future<List<Customer>> getAllCustomers() async {
    try {
      final snapshot = await _customersCollection
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading customers: $e');
      return [];
    }
  }

  /// Stream aller Kunden (Echtzeit)
  Stream<List<Customer>> getCustomersStream() {
    return _customersCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Customer.fromFirestore(doc))
        .toList());
  }

  /// Hole einen einzelnen Kunden
  Future<Customer?> getCustomer(String customerId) async {
    try {
      final doc = await _customersCollection.doc(customerId).get();

      if (!doc.exists) return null;

      return Customer.fromFirestore(doc);
    } catch (e) {
      print('Error loading customer: $e');
      return null;
    }
  }

  /// Stream eines einzelnen Kunden (Echtzeit)
  Stream<Customer?> getCustomerStream(String customerId) {
    return _customersCollection
        .doc(customerId)
        .snapshots()
        .map((doc) => doc.exists ? Customer.fromFirestore(doc) : null);
  }

  /// Suche Kunden nach Namen oder Stadt
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final queryLower = query.toLowerCase();

      // Hole alle Kunden und filtere clientseitig
      // (Firestore unterstützt keine contains-Queries)
      final snapshot = await _customersCollection.get();

      return snapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .where((customer) =>
      customer.name.toLowerCase().contains(queryLower) ||
          (customer.city?.toLowerCase().contains(queryLower) ?? false) ||
          (customer.alias?.toLowerCase().contains(queryLower) ?? false))
          .toList();
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  /// Hole nur geocodierte Kunden (für Karte)
  Future<List<Customer>> getGeocodedCustomers() async {
    try {
      final snapshot = await _customersCollection
          .where('isGeocoded', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .where((customer) => customer.hasCoordinates)
          .toList();
    } catch (e) {
      print('Error loading geocoded customers: $e');
      return [];
    }
  }

  // ===== SCHREIBEN =====

  /// Erstelle neuen Kunden
  Future<String> createCustomer(Customer customer) async {
    try {
      final data = customer.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _customersCollection.add(data);

      print('✅ Customer created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating customer: $e');
      rethrow;
    }
  }

  /// Aktualisiere bestehenden Kunden
  Future<void> updateCustomer(Customer customer) async {
    try {
      final data = customer.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      // Überschreibe createdAt nicht!
      data.remove('createdAt');

      await _customersCollection.doc(customer.id).update(data);

      print('✅ Customer updated: ${customer.id}');
    } catch (e) {
      print('❌ Error updating customer: $e');
      rethrow;
    }
  }

  /// Aktualisiere nur bestimmte Felder eines Kunden
  Future<void> updateCustomerFields(
      String customerId,
      Map<String, dynamic> fields,
      ) async {
    try {
      fields['updatedAt'] = FieldValue.serverTimestamp();

      await _customersCollection.doc(customerId).update(fields);

      print('✅ Customer fields updated: $customerId');
    } catch (e) {
      print('❌ Error updating customer fields: $e');
      rethrow;
    }
  }

  /// Lösche Kunden
  Future<void> deleteCustomer(String customerId) async {
    try {
      // Optional: Prüfe ob Kunde Projekte hat
      final projectsSnapshot = await _firestore

          .collection('customer_projects')
          .where('customerId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (projectsSnapshot.docs.isNotEmpty) {
        throw Exception(
          'Kunde kann nicht gelöscht werden: Es existieren noch Projekte.',
        );
      }

      // Lösche alle Ansprechpartner
      final contactsSnapshot = await _customersCollection
          .doc(customerId)
          .collection('contacts')
          .get();

      for (var doc in contactsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Lösche Kunde
      await _customersCollection.doc(customerId).delete();

      print('✅ Customer deleted: $customerId');
    } catch (e) {
      print('❌ Error deleting customer: $e');
      rethrow;
    }
  }

  // ===== GEOCODING =====

  /// Aktualisiere Geocoding-Daten eines Kunden
  Future<void> updateCustomerGeocoding({
    required String customerId,
    required double latitude,
    required double longitude,
    String? placeId,
    String? formattedAddress,
    String? googlePhone,
    String? googleWebsite,
    String? googleBusinessStatus,
  }) async {
    try {
      await updateCustomerFields(customerId, {
        'latitude': latitude,
        'longitude': longitude,
        'placeId': placeId,
        'formattedAddress': formattedAddress,
        'googlePhone': googlePhone,
        'googleWebsite': googleWebsite,
        'googleBusinessStatus': googleBusinessStatus,
        'isGeocoded': true,
        'lastGeocoded': FieldValue.serverTimestamp(),
      });

      print('✅ Customer geocoding updated: $customerId');
    } catch (e) {
      print('❌ Error updating customer geocoding: $e');
      rethrow;
    }
  }

  /// Setze Geocoding zurück
  Future<void> resetCustomerGeocoding(String customerId) async {
    try {
      await updateCustomerFields(customerId, {
        'latitude': null,
        'longitude': null,
        'placeId': null,
        'formattedAddress': null,
        'googlePhone': null,
        'googleWebsite': null,
        'googleBusinessStatus': null,
        'isGeocoded': false,
        'lastGeocoded': null,
      });

      print('✅ Customer geocoding reset: $customerId');
    } catch (e) {
      print('❌ Error resetting customer geocoding: $e');
      rethrow;
    }
  }

  // ===== ANSPRECHPARTNER =====

  /// Hole Ansprechpartner eines Kunden
  Stream<QuerySnapshot> getContactsStream(String customerId) {
    return _customersCollection
        .doc(customerId)
        .collection('contacts')
        .orderBy('isPrimary', descending: true)
        .snapshots();
  }

  /// Erstelle Ansprechpartner
  Future<String> createContact(
      String customerId,
      Map<String, dynamic> contactData,
      ) async {
    try {
      contactData['createdAt'] = FieldValue.serverTimestamp();

      final docRef = await _customersCollection
          .doc(customerId)
          .collection('contacts')
          .add(contactData);

      print('✅ Contact created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating contact: $e');
      rethrow;
    }
  }

  /// Aktualisiere Ansprechpartner
  Future<void> updateContact(
      String customerId,
      String contactId,
      Map<String, dynamic> contactData,
      ) async {
    try {
      await _customersCollection
          .doc(customerId)
          .collection('contacts')
          .doc(contactId)
          .update(contactData);

      print('✅ Contact updated: $contactId');
    } catch (e) {
      print('❌ Error updating contact: $e');
      rethrow;
    }
  }

  /// Lösche Ansprechpartner
  Future<void> deleteContact(String customerId, String contactId) async {
    try {
      await _customersCollection
          .doc(customerId)
          .collection('contacts')
          .doc(contactId)
          .delete();

      print('✅ Contact deleted: $contactId');
    } catch (e) {
      print('❌ Error deleting contact: $e');
      rethrow;
    }
  }

  // ===== STATISTIKEN =====

  /// Zähle alle Kunden
  Future<int> getCustomerCount() async {
    try {
      final snapshot = await _customersCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error counting customers: $e');
      return 0;
    }
  }

  /// Zähle geocodierte Kunden
  Future<int> getGeocodedCustomerCount() async {
    try {
      final snapshot = await _customersCollection
          .where('isGeocoded', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error counting geocoded customers: $e');
      return 0;
    }
  }

  /// Hole Kunden nach Stadt gruppiert
  Future<Map<String, int>> getCustomersByCity() async {
    try {
      final snapshot = await _customersCollection.get();
      final customersByCity = <String, int>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final city = data['city'] ?? 'Unbekannt';
        customersByCity[city] = (customersByCity[city] ?? 0) + 1;
      }

      return Map.fromEntries(
        customersByCity.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );
    } catch (e) {
      print('Error getting customers by city: $e');
      return {};
    }
  }
}