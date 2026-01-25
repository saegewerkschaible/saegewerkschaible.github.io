// lib/screens/delivery_notes/services/file_helper_web.dart

import 'package:flutter/material.dart';

/// Web-Stub - wird nicht aufgerufen da FileHelper selbst Web-Logik hat
Future<void> shareFileMobile({
  required BuildContext context,
  required String url,
  required String fileName,
  required String fileType,
}) async {
  // Diese Funktion wird auf Web nicht aufgerufen
  // Die Web-Logik ist direkt in FileHelper.shareFile()
  throw UnsupportedError('shareFileMobile sollte nicht auf Web aufgerufen werden');
}