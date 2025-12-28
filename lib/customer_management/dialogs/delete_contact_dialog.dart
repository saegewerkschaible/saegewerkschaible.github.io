// lib/screens/CustomerManagement/dialogs/delete_contact_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/services/icon_helper.dart';


class DeleteContactDialog {
  static void show(
      BuildContext context, {
        required String customerId,
        required String contactId,
        required String contactName,
      }) {
    final theme = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            getAdaptiveIcon(
              iconName: 'warning',
              defaultIcon: Icons.warning_amber_rounded,
              color: theme.warning,
            ),
            const SizedBox(width: 8),
            Text(
              'Ansprechpartner löschen?',
              style: TextStyle(color: theme.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Möchten Sie "$contactName" wirklich löschen?',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance

                    .collection('customers')
                    .doc(customerId)
                    .collection('contacts')
                    .doc(contactId)
                    .delete();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Ansprechpartner wurde gelöscht'),
                      backgroundColor: theme.success,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler: $e'),
                      backgroundColor: theme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}