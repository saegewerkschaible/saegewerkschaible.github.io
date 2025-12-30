// lib/screens/delivery_notes/services/file_helper_mobile.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

/// Mobile-spezifische Share-Implementierung
Future<void> shareFileMobile({
  required BuildContext context,
  required String url,
  required String fileName,
  required String fileType,
}) async {
  final colors = Provider.of<ThemeProvider>(context, listen: false).colors;

  try {
    // Loading Dialog anzeigen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colors.primary),
                const SizedBox(height: 16),
                Text('$fileType wird vorbereitet...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Datei herunterladen
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Download fehlgeschlagen (${response.statusCode})');
    }

    // Temporäre Datei erstellen
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);

    // Loading schließen
    if (context.mounted) Navigator.pop(context);

    // Share Sheet öffnen
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
    // Loading schließen falls noch offen
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Teilen: $e'),
          backgroundColor: colors.error,
        ),
      );
    }
  }
}