// lib/screens/DeliveryNotes/dialogs/filter_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/services/filter/filter_widget.dart';
import 'package:saegewerk/services/icon_helper.dart';




class FilterDialog {
  static void show(BuildContext context, {VoidCallback? onApply}) {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle-Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        bottom: BorderSide(color: colors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: getAdaptiveIcon(
                            iconName: 'filter_list',
                            defaultIcon: Icons.filter_list,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: getAdaptiveIcon(
                            iconName: 'close',
                            defaultIcon: Icons.close,
                            color: colors.textSecondary,
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: FilterWidget(isDeliveryNoteScreen: true),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          offset: const Offset(0, -3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Abbrechen',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            onApply?.call();
                            Navigator.of(sheetContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Anwenden'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}