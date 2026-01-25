// lib/screens/delivery_notes/services/pdf_helper.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfHelper {
  /// Öffnet eine PDF-URL im Browser oder teilt sie
  static Future<void> openPdfUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);

      // Versuche zuerst mit externem Browser
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) return;
      }

      // Fallback: In-App Browser
      final launchedInApp = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );

      if (launchedInApp) return;

      // Letzter Fallback: Teilen-Dialog
      if (context.mounted) {
        _showShareFallback(context, url);
      }
    } catch (e) {
      if (context.mounted) {
        _showShareFallback(context, url);
      }
    }
  }

  /// Teilt PDF-Bytes als Datei
  static Future<void> sharePdfBytes(
      BuildContext context,
      Uint8List pdfBytes,
      String fileName,
      ) async {
    try {
      // Temporäre Datei erstellen
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Teilen
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Lieferschein $fileName',
      );

      // Aufräumen nach 5 Minuten
      Future.delayed(const Duration(minutes: 5), () async {
        if (await file.exists()) {
          await file.delete();
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Teilen: $e')),
        );
      }
    }
  }

  /// Zeigt Fallback-Dialog mit Teilen-Option
  static void _showShareFallback(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PDF öffnen'),
        content: const Text(
          'Das PDF konnte nicht direkt geöffnet werden. '
              'Möchtest du den Link teilen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Share.share(url, subject: 'Lieferschein PDF');
            },
            child: const Text('Link teilen'),
          ),
        ],
      ),
    );
  }
}