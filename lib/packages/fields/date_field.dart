// ═══════════════════════════════════════════════════════════════════════════
// lib/shared/widgets/date_field.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/services/icon_helper.dart';
import '../../core/theme/theme_provider.dart';

/// Datumsauswahl-Feld mit integriertem DatePicker-Dialog
class DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String iconName;
  final ValueChanged<DateTime>? onDateSelected;
  final String placeholder;

  const DateField({
    super.key,
    required this.label,
    required this.controller,
    this.icon = Icons.calendar_today,
    this.iconName = 'calendar_today',
    this.onDateSelected,
    this.placeholder = 'Datum wählen',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _selectDate(context, theme),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label Row
                Row(
                  children: [
                    getAdaptiveIcon(
                      iconName: iconName,
                      defaultIcon: icon,
                      size: 16,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Value Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.text.isEmpty ? placeholder : controller.text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: controller.text.isEmpty
                              ? theme.textSecondary.withOpacity(0.5)
                              : theme.textPrimary,
                        ),
                      ),
                    ),
                    getAdaptiveIcon(
                      iconName: 'calendar_today',
                      defaultIcon: Icons.calendar_today,
                      size: 16,
                      color: theme.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ThemeProvider theme) async {
    final DateFormat formatter = DateFormat('dd.MM.yyyy');

    // Parse aktuelles Datum aus Controller
    DateTime initialDate;
    try {
      initialDate = formatter.parse(controller.text);
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: getAdaptiveIcon(
                          iconName: 'calendar_today',
                          defaultIcon: Icons.calendar_today,
                          color: theme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Datum wählen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: getAdaptiveIcon(
                          iconName: 'close',
                          defaultIcon: Icons.close,
                          color: theme.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Calendar
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: theme.primary,
                      onPrimary: Colors.white,
                      surface: theme.surface,
                      onSurface: theme.textPrimary,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: initialDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (DateTime date) {
                      Navigator.pop(context, date);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      controller.text = formatter.format(picked);
      onDateSelected?.call(picked);
    }
  }
}