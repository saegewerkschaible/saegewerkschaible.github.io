// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/sections/main_info_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/packages/dialogs/custom_keyboard_dialog.dart';
import 'package:saegewerk/packages/fields/date_field.dart';
import 'package:saegewerk/packages/fields/input_field.dart';
import 'package:saegewerk/packages/fields/read_only_field.dart';
import 'package:saegewerk/packages/fields/select_field.dart';
import 'package:saegewerk/packages/sections/section_container.dart';
import 'package:saegewerk/packages/dialogs/show_selection_bottom_sheet.dart';
import '../../core/theme/theme_provider.dart';

import '../services/package_service.dart';

class MainInfoSection extends StatefulWidget {
  final bool isNewPackage;
  final TextEditingController barcodeController;
  final TextEditingController nrExtController;
  final TextEditingController auftragsnrController;
  final TextEditingController datumController;
  final TextEditingController holzartController;
  final TextEditingController kundeController;
  final TextEditingController saegerController;
  final Map<String, bool> invalidFields;
  final PackageService packageService;

  const MainInfoSection({
    super.key,
    required this.isNewPackage,
    required this.barcodeController,
    required this.nrExtController,
    required this.auftragsnrController,
    required this.datumController,
    required this.holzartController,
    required this.kundeController,
    required this.saegerController,
    required this.invalidFields,
    required this.packageService,
  });

  @override
  State<MainInfoSection> createState() => _MainInfoSectionState();
}

class _MainInfoSectionState extends State<MainInfoSection> {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return SectionContainer(
      children: [
        // Barcode + Auftragsnr
        Row(
          children: [
            Expanded(
              child: ReadOnlyField(
                label: 'Barcode',
                value: widget.barcodeController.text,
                icon: Icons.qr_code,
                iconName: 'qr_code',
                message: widget.isNewPackage ? 'Nächste freie Nummer' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTapField(
                context: context,
                label: 'Auftragsnr.',
                controller: widget.auftragsnrController,
                icon: Icons.assignment,
                iconName: 'assignment',
                onTap: () => showCustomKeyboardDialog(
                  context: context,
                  controller: widget.auftragsnrController,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Externe Nr + Datum
        Row(
          children: [
            Expanded(
              child: InputField(
                label: 'Externe Nr.',
                controller: widget.nrExtController,
                icon: Icons.numbers,
                iconName: 'numbers',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DateField(
                label: 'Datum',
                controller: widget.datumController,
                icon: Icons.calendar_today,
                iconName: 'calendar_today',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Holzart
        StreamBuilder<QuerySnapshot>(
          stream: widget.packageService.getWoodTypesStream(),
          builder: (context, snapshot) {
            final options = snapshot.hasData
                ? snapshot.data!.docs.map((d) => d['name'] as String).toList()
                : <String>[];

            return SelectField(
              label: 'Holzart',
              controller: widget.holzartController,
              options: options,
              icon: Icons.forest,
              iconName: 'forest',
              isRequired: true,
              isInvalid: widget.invalidFields['Holzart'] == true,
              onTap: () => showSelectionBottomSheet(
                context: context,
                title: 'Holzart',
                options: options,
                controller: widget.holzartController,
                allowCustomInput: false,
                onSelect: (v) {
                  widget.holzartController.text = v;
                  setState(() {}); // <-- HIER: Widget neu bauen
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Kunde
        StreamBuilder<QuerySnapshot>(
          stream: widget.packageService.getCustomersStream(),
          builder: (context, snapshot) {
            final options = snapshot.hasData
                ? snapshot.data!.docs.map((d) => d['name'] as String).toList()
                : <String>[];

            return SelectField(
              label: 'Kunde',
              controller: widget.kundeController,
              options: options,
              icon: Icons.person,
              iconName: 'person',
              onTap: () => showSelectionBottomSheet(
                context: context,
                title: 'Kunde',
                options: options,
                controller: widget.kundeController,
                allowCustomInput: true,
                onSelect: (v) {
                  widget.kundeController.text = v;
                  setState(() {}); // <-- HIER: Widget neu bauen
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTapField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String iconName,
    required VoidCallback onTap,
  }) {
    final theme = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.textSecondary),
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
            Text(
              controller.text.isEmpty ? '-' : controller.text,
              style: TextStyle(
                fontSize: 14,
                color: controller.text.isEmpty ? theme.textSecondary : theme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}