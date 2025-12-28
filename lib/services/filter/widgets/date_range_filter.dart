// lib/services/filter/widgets/date_range_filter.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

import '../../../services/icon_helper.dart';
import '../filter_settings.dart';

class DateRangeFilter extends StatelessWidget {
  final FilterSettings settings;
  final VoidCallback onChanged;

  const DateRangeFilter({
    Key? key,
    required this.settings,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final DateFormat formatter = DateFormat('dd.MM.yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Schnellfilter-Buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: _QuickDateButton(
                  label: 'Heute',
                  iconName: 'today',
                  icon: Icons.today,
                  onTap: () => _setToday(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickDateButton(
                  label: 'Woche',
                  iconName: 'calendar_view_week',
                  icon: Icons.calendar_view_week,
                  onTap: () => _setThisWeek(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickDateButton(
                  label: 'Monat',
                  iconName: 'calendar_month',
                  icon: Icons.calendar_month,
                  onTap: () => _setThisMonth(context),
                ),
              ),
            ],
          ),
        ),

        // Datum-Picker
        Row(
          children: [
            Expanded(
              child: _DatePickerField(
                label: 'Von',
                value: settings.startDate,
                formatter: formatter,
                onTap: () => _pickStartDate(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DatePickerField(
                label: 'Bis',
                value: settings.endDate,
                formatter: formatter,
                onTap: () => _pickEndDate(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _setToday(BuildContext context) {
    final now = DateTime.now();
    settings.startDate = DateTime(now.year, now.month, now.day);
    settings.endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    settings.dateRangeEnabled = true;
    settings.notifyListeners();
    onChanged();
  }

  void _setThisWeek(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    settings.startDate = DateTime(monday.year, monday.month, monday.day);
    settings.endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    settings.dateRangeEnabled = true;
    settings.notifyListeners();
    onChanged();
  }

  void _setThisMonth(BuildContext context) {
    final now = DateTime.now();
    settings.startDate = DateTime(now.year, now.month, 1);
    settings.endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    settings.dateRangeEnabled = true;
    settings.notifyListeners();
    onChanged();
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _DatePickerDialog(
          title: 'Start',
          initialDate: settings.startDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: settings.endDate ?? DateTime(2100),
          colors: colors,
        );
      },
    );

    if (picked != null) {
      settings.startDate = picked;
      settings.dateRangeEnabled = true;
      settings.notifyListeners();
      onChanged();
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _DatePickerDialog(
          title: 'Ende',
          initialDate: settings.endDate ?? DateTime.now(),
          firstDate: settings.startDate ?? DateTime(2000),
          lastDate: DateTime(2100),
          colors: colors,
        );
      },
    );

    if (picked != null) {
      settings.endDate = picked;
      settings.dateRangeEnabled = true;
      settings.notifyListeners();
      onChanged();
    }
  }
}

class _QuickDateButton extends StatelessWidget {
  final String label;
  final String iconName;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickDateButton({
    required this.label,
    required this.iconName,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getAdaptiveIcon(
              iconName: iconName,
              defaultIcon: icon,
              size: 16,
              color: colors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                getAdaptiveIcon(
                  iconName: 'calendar_today',
                  defaultIcon: Icons.calendar_today,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  value != null ? formatter.format(value!) : label,
                  style: TextStyle(
                    fontSize: 14,
                    color: value != null ? colors.textPrimary : colors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerDialog extends StatelessWidget {
  final String title;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final dynamic colors;

  const _DatePickerDialog({
    required this.title,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: colors.surface,
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
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: getAdaptiveIcon(
                      iconName: 'calendar_today',
                      defaultIcon: Icons.calendar_today,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: getAdaptiveIcon(
                      iconName: 'close',
                      defaultIcon: Icons.close,
                      color: colors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            CalendarDatePicker(
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              onDateChanged: (DateTime date) {
                Navigator.pop(context, date);
              },
            ),
          ],
        ),
      ),
    );
  }
}