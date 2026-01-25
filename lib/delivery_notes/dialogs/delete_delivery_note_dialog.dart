// lib/screens/delivery_notes/dialogs/delete_delivery_note_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_provider.dart';

class DeleteDeliveryNoteDialog {
  static Future<bool> show(
      BuildContext context, {
        required Map<String, dynamic> deliveryNote,
      }) async {
    final theme = context.read<ThemeProvider>();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Lieferschein löschen',
          style: TextStyle(color: theme.textPrimary),
        ),
        content: Text(
          'Willst du den gesamten Lieferschein wirklich löschen? '
              'Alle Pakete werden wieder als verfügbar markiert.',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return false;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final items = deliveryNote['items'] as List<dynamic>;

      // Pakete zurücksetzen
      for (var item in items) {
        final packageRef = FirebaseFirestore.instance
            .collection('packages')
            .doc(item['packageId'].toString());

        batch.update(packageRef, {
          'status': 'im Lager',
          'verkauftAm': null,
          'lieferscheinNr': null,
        });
      }

      // Lieferschein löschen
      final deliveryNoteRef = FirebaseFirestore.instance
          .collection('delivery_notes')
          .doc(deliveryNote['id']);

      batch.delete(deliveryNoteRef);

      // Alle Änderungen ausführen
      await batch.commit();

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lieferschein wurde erfolgreich gelöscht'),
            backgroundColor: theme.success,
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
      return false;
    }
  }
}