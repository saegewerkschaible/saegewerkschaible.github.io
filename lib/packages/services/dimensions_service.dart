// lib/packages/services/dimensions_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DimensionsService {
  static final DimensionsService _instance = DimensionsService._internal();
  factory DimensionsService() => _instance;
  DimensionsService._internal();

  final _db = FirebaseFirestore.instance;

  Future<List<double>> getHeightOptions() async {
    return await _loadOptions('height');
  }

  Future<List<double>> getWidthOptions() async {
    return await _loadOptions('width');
  }

  Future<List<double>> getLengthOptions() async {
    return await _loadOptions('length');
  }

  Future<List<double>> _loadOptions(String key) async {
    try {
      final doc = await _db.collection('settings').doc('dimensions').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final values = List<double>.from(data?[key] ?? []);
        values.sort();
        return values;
      }
    } catch (e) {
      // Bei Fehler leere Liste
    }
    return [];
  }

  /// Stream für Live-Updates
  Stream<Map<String, List<double>>> watchDimensions() {
    return _db.collection('settings').doc('dimensions').snapshots().map((doc) {
      final data = doc.data() ?? {};
      return {
        'height': List<double>.from(data['height'] ?? [])..sort(),
        'width': List<double>.from(data['width'] ?? [])..sort(),
        'length': List<double>.from(data['length'] ?? [])..sort(),
      };
    });
  }
}