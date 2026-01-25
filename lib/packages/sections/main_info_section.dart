// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/sections/main_info_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/packages/dialogs/custom_keyboard_dialog.dart';
import 'package:saegewerk/packages/fields/date_field.dart';
import 'package:saegewerk/packages/fields/read_only_field.dart';
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
  final Function(String)? onTogglePin;
  final Function(String, String)? onPinnedValueChanged;

  // NEU: Callback für Kunden-ID
  final Function(String?)? onKundeIdChanged;

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
    this.onTogglePin,
    this.onPinnedValueChanged,
    this.onKundeIdChanged,
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
        // Externe Nr. GROSS + Barcode klein - GLEICHE HÖHE
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Externe Nr. - PROMINENT
              Expanded(
                flex: 2,
                child: _buildTapField(
                  context: context,
                  label: 'Externe Nr.',
                  controller: widget.nrExtController,
                  icon: Icons.tag,
                  iconName: 'tag',
                  isLarge: true,
                  onTap: () async {
                    await showCustomKeyboardDialog(
                      context: context,
                      controller: widget.nrExtController,
                    );
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Barcode - klein
              Expanded(
                flex: 1,
                child: ReadOnlyField(
                  label: 'Barcode',
                  value: widget.barcodeController.text,
                  icon: Icons.qr_code,
                  iconName: 'qr_code',
                  message: widget.isNewPackage ? 'Auto' : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Auftragsnr + Datum
        Row(
          children: [
            Expanded(
              child: _buildTapField(
                context: context,
                label: 'Auftragsnr.',
                controller: widget.auftragsnrController,
                icon: Icons.assignment,
                iconName: 'assignment',
                onTap: () async {
                  await showCustomKeyboardDialog(
                    context: context,
                    controller: widget.auftragsnrController,
                  );
                  setState(() {});
                },
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
        const SizedBox(height: 12),

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
        const SizedBox(height: 8),

        // Kunde MIT PIN - mit ID-Tracking
        _buildCustomerSelectField(context),
      ],
    );
  }

  /// Kunden-Auswahl mit ID-Tracking
  Widget _buildCustomerSelectField(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return StreamBuilder<QuerySnapshot>(
      stream: widget.packageService.getCustomersStream(),
      builder: (context, snapshot) {
        final docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label-Zeile
            Row(
              children: [
                Icon(Icons.person, size: 16, color: theme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Kunde',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Select Field mit Pin-Button
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCustomerSelectionSheet(context, docs),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.pinKunde
                            ? theme.primary.withOpacity(0.05)
                            : theme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.pinKunde ? theme.primary : theme.border,
                          width: widget.pinKunde ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.kundeController.text.isEmpty
                                  ? 'Auswählen...'
                                  : widget.kundeController.text,
                              style: TextStyle(
                                fontSize: 15,
                                color: widget.kundeController.text.isEmpty
                                    ? theme.textHint
                                    : theme.textPrimary,
                                fontWeight: widget.pinKunde
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: theme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.onTogglePin != null) ...[
                  const SizedBox(width: 8),
                  _PinButton(
                    isPinned: widget.pinKunde,
                    onToggle: () => widget.onTogglePin!('kunde'),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  /// Zeigt Kunden-Auswahl und tracked die ID
  void _showCustomerSelectionSheet(
      BuildContext context,
      List<QueryDocumentSnapshot> docs,
      ) {
    final theme = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.person, color: theme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Kunde auswählen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Kein Kunde Button
                  TextButton(
                    onPressed: () {
                      widget.kundeController.text = '';
                      widget.onKundeIdChanged?.call(null);
                      widget.onPinnedValueChanged?.call('kunde', '');
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Text('Keiner', style: TextStyle(color: theme.textSecondary)),
                  ),
                ],
              ),
            ),
            Divider(color: theme.border, height: 1),
            // Liste
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toString() ?? '';
                  final id = doc.id;
                  final logoUrl = data['logoColorUrl']?.toString();

                  return ListTile(
                    leading: logoUrl != null && logoUrl.isNotEmpty
                        ? Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _buildLetterAvatar(theme, name),
                        ),
                      ),
                    )
                        : _buildLetterAvatar(theme, name),
                    title: Text(name, style: TextStyle(color: theme.textPrimary)),
                    trailing: widget.kundeController.text == name
                        ? Icon(Icons.check, color: theme.primary)
                        : null,
                    onTap: () {
                      debugPrint('🟢 Kunde ausgewählt: $name (ID: $id)');

                      // WICHTIG: Zuerst ID setzen, dann Name
                      widget.onKundeIdChanged?.call(id);
                      widget.kundeController.text = name;
                      widget.onPinnedValueChanged?.call('kunde', name);

                      Navigator.pop(ctx);
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterAvatar(ThemeProvider theme, String name) {
    return CircleAvatar(
      backgroundColor: theme.primary.withOpacity(0.1),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: theme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
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
        // Label-Zeile
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
          ],
        ),
        const SizedBox(height: 4),

        // Select Field mit Pin-Button in der Zeile
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => showSelectionBottomSheet(
                  context: context,
                  title: label,
                  options: options,
                  controller: controller,
                  allowCustomInput: allowCustomInput,
                  onSelect: (v) {
                    controller.text = v;
                    widget.onPinnedValueChanged?.call(pinField, v);
                    setState(() {});
                  },
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
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
                      Icon(Icons.arrow_drop_down, color: theme.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.onTogglePin != null) ...[
              const SizedBox(width: 8),
              _PinButton(
                isPinned: isPinned,
                onToggle: () => widget.onTogglePin!(pinField),
              ),
            ],
          ],
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
    bool isLarge = false,
  }) {
    final theme = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 16 : 12),
        decoration: BoxDecoration(
          color: isLarge ? theme.primary.withOpacity(0.05) : theme.background,
          borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
          border: Border.all(
            color: isLarge ? theme.primary.withOpacity(0.3) : theme.border,
            width: isLarge ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: isLarge ? 20 : 16,
                    color: isLarge ? theme.primary : theme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isLarge ? 13 : 12,
                    color: isLarge ? theme.primary : theme.textSecondary,
                    fontWeight: isLarge ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLarge ? 8 : 4),
            Text(
              controller.text.isEmpty ? '-' : controller.text,
              style: TextStyle(
                fontSize: isLarge ? 22 : 14,
                color:
                controller.text.isEmpty ? theme.textSecondary : theme.textPrimary,
                fontWeight: isLarge ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dezenter Pin-Button - nur Icon
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          size: 20,
          color: isPinned ? theme.primary : theme.textHint,
        ),
      ),
    );
  }
}