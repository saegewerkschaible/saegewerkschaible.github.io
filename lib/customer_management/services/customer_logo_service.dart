// lib/customer_management/services/customer_logo_service.dart
// ═══════════════════════════════════════════════════════════════════════════
// CUSTOMER LOGO SERVICE
// Upload, Komprimierung, S/W-Konvertierung für Kundenlogos
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'dart:ui' as ui;
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
  static const int maxWidthColor = 600;    // erhöht
  static const int maxHeightColor = 300;   // erhöht
  static const int maxWidthBw = 400;       // erhöht von 200
  static const int maxHeightBw = 200;      // erhöht von 100
  static const int pngCompressionLevel = 6;

  /// Bild auswählen (Galerie oder Kamera)
  static Future<Uint8List?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 95,
      );

      if (pickedFile == null) return null;

      return await pickedFile.readAsBytes();
    } catch (e) {
      debugPrint('Fehler beim Bildauswahl: $e');
      return null;
    }
  }

  /// Verarbeitet und lädt Logo hoch
  /// Erstellt automatisch Farb- und S/W-Version
  static Future<Map<String, dynamic>> uploadLogo({
    required String customerId,
    required Uint8List imageBytes,
    bool invertBw = false,
  }) async {
    try {
      // 1. Bild dekodieren
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        return {'success': false, 'error': 'Bild konnte nicht gelesen werden'};
      }

      // 2. Farbversion erstellen (für Lieferschein)
      final colorImage = _resizeImage(
        originalImage,
        maxWidthColor,
        maxHeightColor,
      );
      final colorBytes = img.encodePng(colorImage);

      // 3. S/W-Version erstellen (für Paketzettel)
      final bwImage = _createBlackWhiteImage(
        originalImage,
        maxWidthBw,
        maxHeightBw,
        invert: invertBw,
      );
      final bwBytes = img.encodePng(bwImage);

      // 4. Upload zu Firebase Storage
      final colorUrl = await _uploadToStorage(
        customerId,
        'logo_color.png',
        Uint8List.fromList(colorBytes),
      );

      final bwUrl = await _uploadToStorage(
        customerId,
        'logo_bw.png',
        Uint8List.fromList(bwBytes),
      );

      // 5. URLs in Firestore speichern
      await _db.collection('customers').doc(customerId).update({
        'logoColorUrl': colorUrl,
        'logoBwUrl': bwUrl,
        'logoUpdatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'colorUrl': colorUrl,
        'bwUrl': bwUrl,
        'colorBytes': Uint8List.fromList(colorBytes),
        'bwBytes': Uint8List.fromList(bwBytes),
      };
    } catch (e) {
      debugPrint('Fehler beim Logo-Upload: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Löscht das Logo eines Kunden
  static Future<bool> deleteLogo(String customerId) async {
    try {
      // Storage löschen
      final colorRef = _storage.ref().child('customer_logos/$customerId/logo_color.png');
      final bwRef = _storage.ref().child('customer_logos/$customerId/logo_bw.png');

      try {
        await colorRef.delete();
      } catch (_) {}

      try {
        await bwRef.delete();
      } catch (_) {}

      // Firestore aktualisieren
      await _db.collection('customers').doc(customerId).update({
        'logoColorUrl': FieldValue.delete(),
        'logoBwUrl': FieldValue.delete(),
        'logoUpdatedAt': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      debugPrint('Fehler beim Logo-Löschen: $e');
      return false;
    }
  }

  /// Generiert Vorschau-Bilder ohne Upload
  static Future<Map<String, Uint8List>?> generatePreview({
    required Uint8List imageBytes,
    bool invertBw = false,
  }) async {
    try {
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      // Farbversion
      final colorImage = _resizeImage(
        originalImage,
        maxWidthColor,
        maxHeightColor,
      );

      // S/W-Version
      final bwImage = _createBlackWhiteImage(
        originalImage,
        maxWidthBw,
        maxHeightBw,
        invert: invertBw,
      );

      return {
        'color': Uint8List.fromList(img.encodePng(colorImage)),
        'bw': Uint8List.fromList(img.encodePng(bwImage)),
      };
    } catch (e) {
      debugPrint('Fehler bei Vorschau-Generierung: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bild proportional skalieren
  static img.Image _resizeImage(img.Image image, int maxWidth, int maxHeight) {
    // Seitenverhältnis beibehalten
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

  /// Erstellt S/W-Version mit optionaler Invertierung
  static img.Image _createBlackWhiteImage(
      img.Image image,
      int maxWidth,
      int maxHeight, {
        bool invert = false,
      }) {
    // Zuerst skalieren
    final resized = _resizeImage(image, maxWidth, maxHeight);

    // Zu Graustufen konvertieren
    final grayscale = img.grayscale(resized);

    // Kontrast erhöhen für besseren Druck
    final contrasted = img.adjustColor(
      grayscale,
      contrast: 1.2,
      brightness: 1.05,
    );

// Schärfen für klarere Kanten
    final sharpened = img.convolution(
      contrasted,
      filter: [
        0, -0.5, 0,
        -0.5, 3, -0.5,
        0, -0.5, 0,
      ],
      div: 1,
    );

    if (invert) {
      return img.invert(sharpened);
    }

    return sharpened;
  }

  /// Upload zu Firebase Storage
  static Future<String> _uploadToStorage(
      String customerId,
      String filename,
      Uint8List bytes,
      ) async {
    final ref = _storage.ref().child('customer_logos/$customerId/$filename');

    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/png'),
    );

    return await ref.getDownloadURL();
  }

  /// Lädt Logo-Bytes von URL
  static Future<Uint8List?> downloadLogo(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      return await ref.getData();
    } catch (e) {
      debugPrint('Fehler beim Logo-Download: $e');
      return null;
    }
  }
}