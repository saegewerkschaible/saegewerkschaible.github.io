// lib/services/printing/zebra_settings_cache.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Cached Zebra-Einstellungen aus Firebase
/// Speichert nur die Rohdaten - Konvertierung passiert im Service
class ZebraSettingsCache {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference get _printersCollection =>
      _db.collection('zebra_printers');

  /// Rohdaten aus Firebase laden
  static Future<Map<String, dynamic>?> getSettingsRaw(String printerId) async {
    try {
      final doc = await _printersCollection.doc(printerId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      // Prüfe ob Einstellungen vorhanden sind
      if (data['darkness'] == null && data['printWidth'] == null) {
        return null;
      }

      return {
        'darkness': (data['darkness'] ?? 15.0).toDouble(),
        'printSpeed': (data['printSpeed'] ?? 4.0).toDouble(),
        'printWidth': data['printWidth'] ?? 1200,
        'tearOff': data['tearOff'] ?? 0,
        'mediaType': data['mediaType'] ?? 'MARK',
      };
    } catch (e) {
      print('ZebraSettingsCache: Fehler beim Laden: $e');
      return null;
    }
  }

  /// Einstellungen in Firebase speichern (als Map)
  static Future<void> saveSettingsRaw(String printerId, Map<String, dynamic> settings) async {
    try {
      await _printersCollection.doc(printerId).set({
        'darkness': settings['darkness'],
        'printSpeed': settings['printSpeed'],
        'printWidth': settings['printWidth'],
        'tearOff': settings['tearOff'],
        'mediaType': settings['mediaType'],
        'settingsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('ZebraSettingsCache: Fehler beim Speichern: $e');
      rethrow;
    }
  }

  /// Label-Breite in mm (für PDF-Generierung)
  static Future<double> getLabelWidthMm(String printerId, {double defaultWidth = 100.0}) async {
    final data = await getSettingsRaw(printerId);
    if (data == null) return defaultWidth;
    final dots = data['printWidth'] as int? ?? 1200;
    return dots / 12.0; // 300 DPI: 12 dots = 1mm
  }

  /// Darkness-Wert laden
  static Future<double> getDarkness(String printerId, {double defaultValue = 15.0}) async {
    final data = await getSettingsRaw(printerId);
    return (data?['darkness'] as double?) ?? defaultValue;
  }
}