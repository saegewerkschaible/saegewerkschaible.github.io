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

  // Pin-Properties
  final bool pinHolzart;
  final bool pinKunde;
  final Function(String) onTogglePin;
  final Function(String, String) onPinnedValueChanged;

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
    this.pinHolzart = false,
    this.pinKunde = false,
    required this.onTogglePin,
    required this.onPinnedValueChanged,
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

        // Holzart MIT PIN
        StreamBuilder<QuerySnapshot>(
          stream: widget.packageService.getWoodTypesStream(),
          builder: (context, snapshot) {
            final options = snapshot.hasData
                ? snapshot.data!.docs.map((d) => d['name'] as String).toList()
                : <String>[];

            return _buildPinnableSelectField(
              context: context,
              label: 'Holzart',
              controller: widget.holzartController,
              options: options,
              icon: Icons.forest,
              iconName: 'forest',
              isRequired: true,
              isInvalid: widget.invalidFields['Holzart'] == true,
              isPinned: widget.pinHolzart,
              pinField: 'holzart',
              allowCustomInput: false,
            );
          },
        ),
        const SizedBox(height: 12),

        // Kunde MIT PIN
        StreamBuilder<QuerySnapshot>(
          stream: widget.packageService.getCustomersStream(),
          builder: (context, snapshot) {
            final options = snapshot.hasData
                ? snapshot.data!.docs.map((d) => d['name'] as String).toList()
                : <String>[];

            return _buildPinnableSelectField(
              context: context,
              label: 'Kunde',
              controller: widget.kundeController,
              options: options,
              icon: Icons.person,
              iconName: 'person',
              isRequired: false,
              isInvalid: false,
              isPinned: widget.pinKunde,
              pinField: 'kunde',
              allowCustomInput: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPinnableSelectField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required List<String> options,
    required IconData icon,
    required String iconName,
    required bool isRequired,
    required bool isInvalid,
    required bool isPinned,
    required String pinField,
    required bool allowCustomInput,
  }) {
    final theme = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label-Zeile mit Pin-Button
        Row(
          children: [
            Icon(icon, size: 16, color: theme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
            ),
            if (isRequired)
              Text(' *', style: TextStyle(color: theme.error, fontSize: 12)),
            const Spacer(),
            _PinButton(
              isPinned: isPinned,
              onToggle: () => widget.onTogglePin(pinField),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Select Field
        GestureDetector(
          onTap: () => showSelectionBottomSheet(
            context: context,
            title: label,
            options: options,
            controller: controller,
            allowCustomInput: allowCustomInput,
            onSelect: (v) {
              controller.text = v;
              widget.onPinnedValueChanged(pinField, v);
              setState(() {});
            },
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPinned
                  ? theme.primary.withOpacity(0.05)
                  : theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isInvalid
                    ? theme.error
                    : isPinned
                    ? theme.primary
                    : theme.border,
                width: isPinned ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Auswählen...' : controller.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: controller.text.isEmpty
                          ? theme.textHint
                          : theme.textPrimary,
                      fontWeight: isPinned ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.push_pin,
                      size: 16,
                      color: theme.primary,
                    ),
                  ),
                Icon(Icons.arrow_drop_down, color: theme.textSecondary),
              ],
            ),
          ),
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

// Pin-Button Widget
class _PinButton extends StatelessWidget {
  final bool isPinned;
  final VoidCallback onToggle;

  const _PinButton({
    required this.isPinned,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPinned ? theme.primary : theme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPinned ? theme.primary : theme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 14,
              color: isPinned ? Colors.white : theme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              isPinned ? 'Gepinnt' : 'Pinnen',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPinned ? Colors.white : theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}