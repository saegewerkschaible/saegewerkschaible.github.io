// lib/screens/CustomerManagement/widgets/customer_color_picker.dart

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

import 'package:saegewerk/customer_management/models/customer.dart';
import 'package:saegewerk/services/icon_helper.dart';


class CustomerColorPicker extends StatelessWidget {
  final String customerId;
  final Customer customer;

  const CustomerColorPicker({
    Key? key,
    required this.customerId,
    required this.customer,
  }) : super(key: key);

  // Vordefinierte Farbpalette für Kunden
  static const List<Color> customerColors = [
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFFE53935), // Red
    Color(0xFF00897B), // Teal
    Color(0xFF3949AB), // Indigo
    Color(0xFFD81B60), // Pink
    Color(0xFFFFA000), // Amber
    Color(0xFF00ACC1), // Cyan
    Color(0xFFC0CA33), // Lime
    Color(0xFFF4511E), // Deep Orange
    Color(0xFF039BE5), // Light Blue
    Color(0xFF7CB342), // Light Green
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF6D4C41), // Brown
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              getAdaptiveIcon(
                iconName: 'palette',
                defaultIcon: Icons.palette,
                color: theme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Kundenfarbe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: customer.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.border, width: 2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ExpansionTile für eingeklappte Farbauswahl
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                'Farbe ändern',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
              leading: getAdaptiveIcon(
                iconName: 'color_lens',
                defaultIcon: Icons.color_lens,
                color: theme.primary,
                size: 20,
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 16),
              iconColor: theme.textSecondary,
              collapsedIconColor: theme.textSecondary,
              children: [
                // Schnellauswahl
                Text(
                  'Schnellauswahl:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: customerColors.map((color) {
                    final isSelected = customer.color?.value == color.value;
                    return InkWell(
                      onTap: () => _updateColor(color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? theme.primary : theme.border,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? getAdaptiveIcon(
                          iconName: 'check',
                          defaultIcon: Icons.check,
                          color: Colors.white,
                          size: 18,
                        )
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                Divider(color: theme.divider),
                const SizedBox(height: 12),

                // Freie Farbauswahl Button
                Center(
                  child: ElevatedButton.icon(
                    icon: getAdaptiveIcon(
                      iconName: 'colorize',
                      defaultIcon: Icons.colorize,
                      color: theme.primary,
                    ),
                    label: Text(
                      'Eigene Farbe wählen',
                      style: TextStyle(color: theme.primary),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.surface,
                      side: BorderSide(color: theme.primary),
                    ),
                    onPressed: () => _showColorPickerDialog(context, theme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateColor(Color color) async {
    await FirebaseFirestore.instance

        .collection('customers')
        .doc(customerId)
        .update({
      'colorValue': color.value,
    });
  }

  void _showColorPickerDialog(BuildContext context, dynamic theme) {
    Color selectedColor = customer.color ?? Colors.blue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Row(
          children: [
            getAdaptiveIcon(
              iconName: 'colorize',
              defaultIcon: Icons.colorize,
              color: theme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Farbe auswählen',
              style: TextStyle(color: theme.textPrimary),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                color: selectedColor,
                onColorChanged: (Color color) {
                  selectedColor = color;
                },
                width: 44,
                height: 44,
                borderRadius: 22,
                spacing: 5,
                runSpacing: 5,
                wheelDiameter: 250,
                heading: Text(
                  'Wähle eine Farbe',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textPrimary,
                  ),
                ),
                subheading: Text(
                  'Farbe und Sättigung',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
                wheelSubheading: Text(
                  'Farbe und Helligkeit',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
                showMaterialName: false,
                showColorName: false,
                showColorCode: true,
                pickersEnabled: const <ColorPickerType, bool>{
                  ColorPickerType.wheel: true,
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateColor(selectedColor);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Kundenfarbe wurde aktualisiert'),
                    backgroundColor: theme.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: theme.textOnPrimary,
            ),
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );
  }
}