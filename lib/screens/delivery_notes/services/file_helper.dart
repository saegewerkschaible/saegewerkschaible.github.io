// lib/screens/delivery_notes/services/file_helper.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

// Conditional imports
import 'file_helper_mobile.dart' if (dart.library.html) 'file_helper_web.dart'
as platform;

class FileHelper {
  /// Teilt eine Datei (Web: Link kopieren, Mobile: Share Sheet)
  static Future<void> shareFile({
    required BuildContext context,
    required String url,
    required String fileName,
    required String fileType,
  }) async {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;

    if (kIsWeb) {
      // Web: Link in Zwischenablage kopieren
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('$fileType-Link kopiert!'),
              ],
            ),
            backgroundColor: colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Mobile: Share Sheet verwenden
      await platform.shareFileMobile(
        context: context,
        url: url,
        fileName: fileName,
        fileType: fileType,
      );
    }
  }
}