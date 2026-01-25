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
        final rawValues = data?[key] as List<dynamic>? ?? [];
        // Konvertiere zu double (funktioniert für int UND double)
        final values = rawValues.map((e) => (e as num).toDouble()).toList();
        values.sort();
        return values;
      }
    } catch (e) {
      print('Fehler beim Laden von $key: $e');
    }
    return [];
  }

  Stream<Map<String, List<double>>> watchDimensions() {
    return _db.collection('settings').doc('dimensions').snapshots().map((doc) {
      final data = doc.data() ?? {};

      List<double> parseList(dynamic raw) {
        if (raw == null) return [];
        return (raw as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList()
          ..sort();
      }

      return {
        'height': parseList(data['height']),
        'width': parseList(data['width']),
        'length': parseList(data['length']),
      };
    });
  }
}