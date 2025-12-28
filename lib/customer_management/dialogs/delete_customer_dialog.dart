// lib/screens/CustomerManagement/dialogs/delete_customer_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/customer_management/models/customer.dart';
import 'package:saegewerk/customer_management/services/customer_service.dart';
import 'package:saegewerk/services/icon_helper.dart';

class DeleteCustomerDialog {
  static void show(
      BuildContext context, {
        required Customer customer,
        required VoidCallback onDeleted,
      }) {
    final theme = context.read<ThemeProvider>();
    final customerService = CustomerService();

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
              'Kunde löschen?',
              style: TextStyle(color: theme.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Möchten Sie den Kunden "${customer.name}" wirklich löschen? '
              'Diese Aktion kann nicht rückgängig gemacht werden.',
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
                await customerService.deleteCustomer(customer.id);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  onDeleted();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Kunde wurde gelöscht'),
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