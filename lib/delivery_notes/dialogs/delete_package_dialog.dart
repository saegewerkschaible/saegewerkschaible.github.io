// lib/screens/delivery_notes/dialogs/delete_package_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_provider.dart';

class DeletePackageDialog {
  static Future<bool> show(
      BuildContext context, {
        required String packageId,
        required Map<String, dynamic> deliveryNote,
      }) async {
    final theme = context.read<ThemeProvider>();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Paket entfernen',
          style: TextStyle(color: theme.textPrimary),
        ),
        content: Text(
          'Willst du das Paket wirklich aus dem Lieferschein entfernen? '
              'Das Paket wird wieder als verfügbar markiert.',
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
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return false;

    try {
      // Paket zurücksetzen
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(packageId)
          .update({
        'status': 'im Lager',
        'verkauftAm': null,
        'lieferscheinNr': null,
      });

      // Paket aus der items Liste des Lieferscheins entfernen
      final updatedItems = (deliveryNote['items'] as List<dynamic>)
          .where((item) => item['packageId'].toString() != packageId)
          .toList();

      // Neue Gesamtmengen berechnen
      final newTotalQuantity = updatedItems.fold<int>(
        0,
            (sum, item) => sum + ((item['stueckzahl'] as num?)?.toInt() ?? 0),
      );
      final newTotalVolume = updatedItems.fold<double>(
        0.0,
            (sum, item) => sum + ((item['menge'] as num?)?.toDouble() ?? 0.0),
      );

      // Lieferschein aktualisieren
      await FirebaseFirestore.instance
          .collection('delivery_notes')
          .doc(deliveryNote['id'])
          .update({
        'items': updatedItems,
        'totalQuantity': newTotalQuantity,
        'totalVolume': newTotalVolume,
        'itemCount': updatedItems.length,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Paket wurde erfolgreich entfernt'),
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