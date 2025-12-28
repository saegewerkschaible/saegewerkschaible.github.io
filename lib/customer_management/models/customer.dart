// lib/models/customer.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Customer {
  final String id;
  final String name;

  // Adresse
  final String? street;
  final String? houseNumber;
  final String? zipCode;
  final String? city;
  final String? country;

  // Kontaktdaten
  final String? phone;
  final String? email;
  final String? website;

  // Notizen & Extras
  final String? notes;
  final String? alias;
  final bool useAliasOnLabels;

  // Google Places & Geocoding Daten
  final String? placeId;              // Google Place ID
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;     // Von Google verifizierte Adresse
  final String? googlePhone;          // Von Places API (falls abweichend)
  final String? googleWebsite;        // Von Places API
  final DateTime? lastGeocoded;       // Wann zuletzt geocodiert
  final bool isGeocoded;              // Wurde bereits geocodiert
  final String? googleBusinessStatus; // OPERATIONAL, CLOSED_TEMPORARILY, etc.

  // Farbe für Visualisierung
  final Color color;

  // Metadaten
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.street,
    this.houseNumber,
    this.zipCode,
    this.city,
    this.country,
    this.phone,
    this.email,
    this.website,
    this.notes,
    this.alias,
    this.useAliasOnLabels = false,
    this.placeId,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.googlePhone,
    this.googleWebsite,
    this.lastGeocoded,
    this.isGeocoded = false,
    this.googleBusinessStatus,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory: Aus Firestore Document erstellen
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer.fromMap(data, doc.id);
  }

  /// Factory: Aus Map erstellen
  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    // Farbe bestimmen
    Color customerColor;
    if (map['colorValue'] != null) {
      customerColor = Color(map['colorValue']);
    } else {
      // Fallback: Generiere Farbe basierend auf ID/Name
      final colors = [
        Colors.blue.shade600,
        Colors.green.shade600,
        Colors.orange.shade600,
        Colors.purple.shade600,
        Colors.red.shade600,
        Colors.teal.shade600,
        Colors.indigo.shade600,
        Colors.pink.shade600,
        Colors.amber.shade700,
        Colors.cyan.shade600,
        Colors.lime.shade700,
        Colors.deepOrange.shade600,
      ];
      customerColor = colors[id.hashCode.abs() % colors.length];
    }

    return Customer(
      id: id,
      name: map['name'] ?? '',
      street: map['street'],
      houseNumber: map['houseNumber'],
      zipCode: map['zipCode'],
      city: map['city'],
      country: map['country'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      notes: map['notes'],
      alias: map['alias'],
      useAliasOnLabels: map['useAliasOnLabels'] ?? false,
      placeId: map['placeId'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      formattedAddress: map['formattedAddress'],
      googlePhone: map['googlePhone'],
      googleWebsite: map['googleWebsite'],
      lastGeocoded: map['lastGeocoded'] != null
          ? (map['lastGeocoded'] is Timestamp
          ? (map['lastGeocoded'] as Timestamp).toDate()
          : DateTime.tryParse(map['lastGeocoded']))
          : null,
      isGeocoded: map['isGeocoded'] ?? false,
      googleBusinessStatus: map['googleBusinessStatus'],
      color: customerColor,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']))
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['updatedAt']))
          : null,
    );
  }

  /// Zu Firestore Map konvertieren
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'street': street,
      'houseNumber': houseNumber,
      'zipCode': zipCode,
      'city': city,
      'country': country,
      'phone': phone,
      'email': email,
      'website': website,
      'notes': notes,
      'alias': alias,
      'useAliasOnLabels': useAliasOnLabels,
      'placeId': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': formattedAddress,
      'googlePhone': googlePhone,
      'googleWebsite': googleWebsite,
      'lastGeocoded': lastGeocoded?.toIso8601String(),
      'isGeocoded': isGeocoded,
      'googleBusinessStatus': googleBusinessStatus,
      'colorValue': color?.value,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Erstellt eine Kopie mit geänderten Werten
  Customer copyWith({
    String? name,
    String? street,
    String? houseNumber,
    String? zipCode,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? website,
    String? notes,
    String? alias,
    bool? useAliasOnLabels,
    String? placeId,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    String? googlePhone,
    String? googleWebsite,
    DateTime? lastGeocoded,
    bool? isGeocoded,
    String? googleBusinessStatus,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      street: street ?? this.street,
      houseNumber: houseNumber ?? this.houseNumber,
      zipCode: zipCode ?? this.zipCode,
      city: city ?? this.city,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      alias: alias ?? this.alias,
      useAliasOnLabels: useAliasOnLabels ?? this.useAliasOnLabels,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      googlePhone: googlePhone ?? this.googlePhone,
      googleWebsite: googleWebsite ?? this.googleWebsite,
      lastGeocoded: lastGeocoded ?? this.lastGeocoded,
      isGeocoded: isGeocoded ?? this.isGeocoded,
      googleBusinessStatus: googleBusinessStatus ?? this.googleBusinessStatus,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===== Hilfsmethoden =====

  /// Gibt die vollständige Straße mit Hausnummer zurück
  String? get fullStreet {
    if (street == null) return null;
    if (houseNumber == null) return street;
    return '$street $houseNumber';
  }

  /// Gibt "PLZ Stadt" zurück
  String? get cityWithZip {
    if (city == null) return null;
    if (zipCode == null) return city;
    return '$zipCode $city';
  }

  /// Gibt die vollständige Adresse als String zurück
  String? get fullAddress {
    final parts = <String>[];

    if (fullStreet != null) parts.add(fullStreet!);
    if (cityWithZip != null) parts.add(cityWithZip!);
    if (country != null) parts.add(country!);

    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Hat der Kunde Geokoordinaten?
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Soll Alias auf Labels verwendet werden?
  String get displayNameForLabels =>
      (useAliasOnLabels && alias != null && alias!.isNotEmpty)
          ? alias!
          : name;

  /// Ist Geocodierung veraltet (älter als 90 Tage)?
  bool get isGeocodingStale {
    if (!isGeocoded || lastGeocoded == null) return false;
    return DateTime.now().difference(lastGeocoded!) > const Duration(days: 90);
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, city: $city, isGeocoded: $isGeocoded)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}