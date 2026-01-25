// lib/customer_management/services/customer_logo_service.dart
// ═══════════════════════════════════════════════════════════════════════════
// CUSTOMER LOGO SERVICE
// Upload, Komprimierung, S/W-Konvertierung für Kundenlogos
// WEB-KOMPATIBEL: Verwendet compute() für Bildverarbeitung
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

class CustomerLogoService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final ImagePicker _picker = ImagePicker();

  // Maximale Größen
  static const int maxWidthColor = 600;
  static const int maxHeightColor = 300;
  static const int maxWidthBw = 400;
  static const int maxHeightBw = 200;
  static const int pngCompressionLevel = 6;



  /// Generiert nur S/W Vorschau (für individuelles S/W Bild)
  static Future<Uint8List?> generateBwPreview({
    required Uint8List imageBytes,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final resized = _resizeImage(image, maxWidthBw, maxHeightBw);
      final grayscale = img.grayscale(resized);

      return Uint8List.fromList(img.encodePng(grayscale));
    } catch (e) {
      debugPrint('❌ [CustomerLogoService] Fehler bei S/W Vorschau: $e');
      return null;
    }
  }


  /// Bild auswählen (Galerie oder Kamera)
  /// Auf Web ist nur Galerie verfügbar
  static Future<Uint8List?> pickImage({bool fromCamera = false}) async {
    try {
      // Auf Web ist Kamera meist nicht verfügbar
      if (kIsWeb && fromCamera) {
        debugPrint('⚠️ [CustomerLogoService] Kamera nicht verfügbar auf Web');
        return null;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 95,
      );

      if (pickedFile == null) {
        debugPrint('ℹ️ [CustomerLogoService] Keine Datei ausgewählt');
        return null;
      }

      debugPrint('✅ [CustomerLogoService] Bild ausgewählt: ${pickedFile.name}');
      return await pickedFile.readAsBytes();
    } catch (e) {
      debugPrint('❌ [CustomerLogoService] Fehler beim Bildauswahl: $e');
      return null;
    }
  }

  /// Verarbeitet und lädt Logo hoch
  /// Erstellt automatisch Farb- und S/W-Version
  static Future<Map<String, dynamic>> uploadLogo({
    required String customerId,
    required Uint8List imageBytes,
    bool invertBw = false,
    Uint8List? customBwBytes,  // NEU: Optionales individuelles S/W Bild
  }) async {
    try {
      debugPrint('🔄 [CustomerLogoService] Starte Logo-Upload für $customerId');
      debugPrint('📦 [CustomerLogoService] Bildgröße: ${imageBytes.length} bytes');
      debugPrint('🎨 [CustomerLogoService] Custom S/W: ${customBwBytes != null}');

      // Bildverarbeitung - auf Web synchron, auf Mobile mit compute()
      final Map<String, Uint8List>? processed = await _processImageCrossPlatform(
        imageBytes,
        invertBw,
      );

      if (processed == null) {
        return {'success': false, 'error': 'Bild konnte nicht verarbeitet werden'};
      }

      final colorBytes = processed['color']!;
      // S/W: Custom Bild verwenden falls vorhanden, sonst generiertes
      final bwBytes = customBwBytes ?? processed['bw']!;

      debugPrint('✅ [CustomerLogoService] Bilder verarbeitet');
      debugPrint('   Color: ${colorBytes.length} bytes');
      debugPrint('   B/W: ${bwBytes.length} bytes (custom: ${customBwBytes != null})');

      // Upload zu Firebase Storage
      final colorUrl = await _uploadToStorage(
        customerId,
        'logo_color.png',
        colorBytes,
      );
      debugPrint('✅ [CustomerLogoService] Color-Logo hochgeladen');

      final bwUrl = await _uploadToStorage(
        customerId,
        'logo_bw.png',
        bwBytes,
      );
      debugPrint('✅ [CustomerLogoService] B/W-Logo hochgeladen');

      // URLs in Firestore speichern
      await _db.collection('customers').doc(customerId).update({
        'logoColorUrl': colorUrl,
        'logoBwUrl': bwUrl,
        'logoUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [CustomerLogoService] Firestore aktualisiert');

      return {
        'success': true,
        'colorUrl': colorUrl,
        'bwUrl': bwUrl,
        'colorBytes': colorBytes,
        'bwBytes': bwBytes,
      };
    } catch (e, stack) {
      debugPrint('❌ [CustomerLogoService] Fehler beim Logo-Upload: $e');
      debugPrint('   Stack: $stack');
      return {'success': false, 'error': e.toString()};
    }
  }
  /// Cross-Platform Bildverarbeitung
  /// Web: Synchron (muss sein, da compute() auf Web nicht richtig funktioniert)
  /// Mobile: Mit compute() für bessere Performance
  static Future<Map<String, Uint8List>?> _processImageCrossPlatform(
      Uint8List imageBytes,
      bool invertBw,
      ) async {
    try {
      if (kIsWeb) {
        // Auf Web synchron verarbeiten
        debugPrint('🌐 [CustomerLogoService] Web-Modus: Synchrone Verarbeitung');
        return _processImageSync(_ProcessParams(
          imageBytes: imageBytes,
          invertBw: invertBw,
        ));
      } else {
        // Auf Mobile mit compute()
        debugPrint('📱 [CustomerLogoService] Mobile-Modus: Compute-Verarbeitung');
        return await compute(
          _processImageSync,
          _ProcessParams(imageBytes: imageBytes, invertBw: invertBw),
        );
      }
    } catch (e) {
      debugPrint('❌ [CustomerLogoService] Fehler bei Bildverarbeitung: $e');
      return null;
    }
  }

  /// Löscht das Logo eines Kunden
  static Future<bool> deleteLogo(String customerId) async {
    try {
      debugPrint('🗑️ [CustomerLogoService] Lösche Logo für $customerId');

      // Storage löschen
      final colorRef = _storage.ref().child('customer_logos/$customerId/logo_color.png');
      final bwRef = _storage.ref().child('customer_logos/$customerId/logo_bw.png');

      try {
        await colorRef.delete();
        debugPrint('✅ [CustomerLogoService] Color-Logo gelöscht');
      } catch (e) {
        debugPrint('⚠️ [CustomerLogoService] Color-Logo nicht gefunden: $e');
      }

      try {
        await bwRef.delete();
        debugPrint('✅ [CustomerLogoService] B/W-Logo gelöscht');
      } catch (e) {
        debugPrint('⚠️ [CustomerLogoService] B/W-Logo nicht gefunden: $e');
      }

      // Firestore aktualisieren
      await _db.collection('customers').doc(customerId).update({
        'logoColorUrl': FieldValue.delete(),
        'logoBwUrl': FieldValue.delete(),
        'logoUpdatedAt': FieldValue.delete(),
      });
      debugPrint('✅ [CustomerLogoService] Firestore aktualisiert');

      return true;
    } catch (e) {
      debugPrint('❌ [CustomerLogoService] Fehler beim Logo-Löschen: $e');
      return false;
    }
  }

  /// Generiert Vorschau-Bilder ohne Upload
  static Future<Map<String, Uint8List>?> generatePreview({
    required Uint8List imageBytes,
    bool invertBw = false,
  }) async {
    debugPrint('🔄 [CustomerLogoService] Generiere Vorschau');
    return await _processImageCrossPlatform(imageBytes, invertBw);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload zu Firebase Storage
  static Future<String> _uploadToStorage(
      String customerId,
      String filename,
      Uint8List bytes,
      ) async {
    final ref = _storage.ref().child('customer_logos/$customerId/$filename');

    // Für Web: Metadata explizit setzen
    final metadata = SettableMetadata(
      contentType: 'image/png',
      cacheControl: 'public, max-age=31536000',
    );

    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  /// Lädt Logo-Bytes von URL
  static Future<Uint8List?> downloadLogo(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      return await ref.getData();
    } catch (e) {
      debugPrint('❌ [CustomerLogoService] Fehler beim Logo-Download: $e');
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ISOLATE-SICHERE KLASSEN UND FUNKTIONEN
// Diese müssen top-level sein für compute()
// ═══════════════════════════════════════════════════════════════════════════

/// Parameter für die Bildverarbeitung (muss serialisierbar sein)
class _ProcessParams {
  final Uint8List imageBytes;
  final bool invertBw;

  _ProcessParams({
    required this.imageBytes,
    required this.invertBw,
  });
}

/// Synchrone Bildverarbeitung (wird in compute() oder direkt aufgerufen)
Map<String, Uint8List>? _processImageSync(_ProcessParams params) {
  try {
    final originalImage = img.decodeImage(params.imageBytes);
    if (originalImage == null) {
      return null;
    }

    // Farbversion erstellen
    final colorImage = _resizeImage(
      originalImage,
      CustomerLogoService.maxWidthColor,
      CustomerLogoService.maxHeightColor,
    );

    // S/W-Version erstellen
    final bwImage = _createBlackWhiteImage(
      originalImage,
      CustomerLogoService.maxWidthBw,
      CustomerLogoService.maxHeightBw,
      invert: params.invertBw,
    );

    return {
      'color': Uint8List.fromList(img.encodePng(colorImage)),
      'bw': Uint8List.fromList(img.encodePng(bwImage)),
    };
  } catch (e) {
    return null;
  }
}

/// Bild proportional skalieren
img.Image _resizeImage(img.Image image, int maxWidth, int maxHeight) {
  double ratio = image.width / image.height;
  int newWidth, newHeight;

  if (image.width > image.height) {
    newWidth = maxWidth;
    newHeight = (maxWidth / ratio).round();
    if (newHeight > maxHeight) {
      newHeight = maxHeight;
      newWidth = (maxHeight * ratio).round();
    }
  } else {
    newHeight = maxHeight;
    newWidth = (maxHeight * ratio).round();
    if (newWidth > maxWidth) {
      newWidth = maxWidth;
      newHeight = (maxWidth / ratio).round();
    }
  }

  return img.copyResize(
    image,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.cubic,
  );
}

/// Erstellt S/W-Version mit hohem Kontrast
/// Helle Farben (wie Gold) werden auch dunkel
img.Image _createBlackWhiteImage(
    img.Image image,
    int maxWidth,
    int maxHeight, {
      bool invert = false,
    }) {
  // Zuerst skalieren
  final resized = _resizeImage(image, maxWidth, maxHeight);

  // Zu Graustufen konvertieren
  final grayscale = img.grayscale(resized);

  // Stark erhöhter Kontrast + reduzierte Helligkeit
  // Damit helle Farben (Gold) auch richtig dunkel werden
  final contrasted = img.adjustColor(
    grayscale,
    contrast: 1.8,      // Stark erhöht
    brightness: 0.85,   // Etwas dunkler
  );

  if (invert) {
    return img.invert(contrasted);
  }

  return contrasted;
}