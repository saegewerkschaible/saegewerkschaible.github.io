// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/widgets/edit_package_widget.dart
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/packages/services/printing/zebra_printer_service.dart';

import '../../constants.dart';
import '../../core/theme/theme_provider.dart';

import '../dialogs/calculator_dialog.dart';
import '../dialogs/dimension_input_dialog.dart';
import '../sections/comment_section.dart';
import '../sections/dimensions_section.dart';
import '../sections/expandable_section.dart';
import '../sections/location_section.dart';
import '../sections/main_info_section.dart';
import '../sections/status_section.dart';
import '../services/package_service.dart';

class EditPackageWidget extends StatefulWidget {
  final Map<String, dynamic>? packageData;
  final int userGroup;
  final bool isNewPackage;
  final bool isEmbedded; // NEU: Für eingebetteten Modus (Säger-Ansicht)
  final void Function(bool)? onSaved;

  const EditPackageWidget({
    super.key,
    required this.packageData,
    required this.userGroup,
    required this.isNewPackage,
    this.isEmbedded = false,
    this.onSaved,
  });

  @override
  State<EditPackageWidget> createState() => _EditPackageWidgetState();
}

class _EditPackageWidgetState extends State<EditPackageWidget> {
  final PackageService _packageService = PackageService();
  final _printerService = ZebraPrinterService();

  // Controller
  late TextEditingController barcodeController;
  late TextEditingController nrExtController;
  late TextEditingController auftragsnrController;
  late TextEditingController datumController;
  late TextEditingController holzartController;
  late TextEditingController kundeController;
  late TextEditingController hController;
  late TextEditingController bController;
  late TextEditingController lController;
  late TextEditingController stkController;
  late TextEditingController mengeController;
  late TextEditingController zustandController;
  late TextEditingController lagerortController;
  late TextEditingController bemerkungController;
  late TextEditingController saegerController;
  late TextEditingController statusController;

  // Expansion State
  List<bool> _isExpanded = [true, true, true, true, true];

  // Validation
  Map<String, bool> invalidFields = {};

  // Labels
  static const String LABEL_HOLZART = 'Holzart';
  static const String LABEL_STAERKE = 'Stärke [mm]';
  static const String LABEL_BREITE = 'Breite [mm]';
  static const String LABEL_LAENGE = 'Länge [m]';
  static const String LABEL_STUECKZAHL = 'Stückzahl';

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.isNewPackage) {
      _loadNextBarcode();
    }
  }

  Future<void> _handlePrint() async {
    final saved = await _saveChanges();
    if (!saved) return;

    try {
      final barcode = widget.isNewPackage
          ? (int.tryParse(barcodeController.text)! - 1).toString()
          : barcodeController.text;

      final packageData = await _buildPrintData(barcode);
      final result = await _printerService.printPackageLabel(context, packageData);

      if (!mounted) return;
      showAppSnackbar(context, result.message);

      // Bei eingebettetem Modus: nicht schließen, nur Felder leeren
      if (result.success && !widget.isEmbedded && widget.userGroup != 2) {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      showAppSnackbar(context, 'Fehler beim Drucken: $e');
    }
  }

  Future<Map<String, dynamic>> _buildPrintData(String barcode) async {
    return {
      'Barcode': barcode,
      'Nr': barcode,
      'Kunde': kundeController.text,
      'Auftragsnr': auftragsnrController.text,
      'Holzart': holzartController.text,
      'H': hController.text,
      'B': bController.text,
      'L': lController.text,
      'Stk': stkController.text,
      'Menge': mengeController.text,
      'Bemerkung': bemerkungController.text,
      'Nr_ext': nrExtController.text,
    };
  }

  Future<String> _getInitials(String name) async {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  void _initControllers() {
    final data = widget.packageData;

    barcodeController = TextEditingController(text: data?['barcode']?.toString() ?? '');
    nrExtController = TextEditingController(text: data?['nrExt']?.toString() ?? '');
    auftragsnrController = TextEditingController(text: data?['auftragsnr']?.toString() ?? '');
    datumController = TextEditingController(
      text: data?['datum'] ?? DateFormat('dd.MM.yyyy').format(DateTime.now()),
    );
    holzartController = TextEditingController(text: data?['holzart']?.toString() ?? '');
    kundeController = TextEditingController(text: data?['kunde']?.toString() ?? '');
    hController = TextEditingController(text: data?['hoehe']?.toString() ?? '');
    bController = TextEditingController(text: data?['breite']?.toString() ?? '');
    lController = TextEditingController(text: data?['laenge']?.toString() ?? '');
    stkController = TextEditingController(text: data?['stueckzahl']?.toString() ?? '');
    mengeController = TextEditingController(text: data?['menge']?.toString() ?? '0.000');
    zustandController = TextEditingController(text: data?['zustand']?.toString() ?? PackageZustand.frisch);
    lagerortController = TextEditingController(text: data?['lagerort']?.toString() ?? '');
    bemerkungController = TextEditingController(text: data?['bemerkung']?.toString() ?? '');
    saegerController = TextEditingController(text: data?['saeger']?.toString() ?? '');
    statusController = TextEditingController(text: data?['status']?.toString() ?? PackageStatus.imLager);
  }

  Future<void> _loadNextBarcode() async {
    final nextNumber = await _packageService.getNextPackageNumber();
    setState(() {
      barcodeController.text = nextNumber.toString();
    });
  }

  @override
  void dispose() {
    barcodeController.dispose();
    nrExtController.dispose();
    auftragsnrController.dispose();
    datumController.dispose();
    holzartController.dispose();
    kundeController.dispose();
    hController.dispose();
    bController.dispose();
    lController.dispose();
    stkController.dispose();
    mengeController.dispose();
    zustandController.dispose();
    lagerortController.dispose();
    bemerkungController.dispose();
    saegerController.dispose();
    statusController.dispose();
    super.dispose();
  }

  void _recalculateVolume() {
    if (hController.text.isNotEmpty &&
        bController.text.isNotEmpty &&
        lController.text.isNotEmpty &&
        stkController.text.isNotEmpty) {
      final volume = PackageService.calculateVolume(
        hoehe: double.tryParse(hController.text) ?? 0,
        breite: double.tryParse(bController.text) ?? 0,
        laenge: double.tryParse(lController.text) ?? 0,
        stueckzahl: int.tryParse(stkController.text) ?? 0,
      );
      setState(() {
        mengeController.text = volume.toStringAsFixed(3);
      });
    }
  }

  bool _validateRequiredFields() {
    setState(() {
      invalidFields = {
        LABEL_HOLZART: holzartController.text.isEmpty,
        LABEL_STAERKE: hController.text.isEmpty,
        LABEL_BREITE: bController.text.isEmpty,
        LABEL_LAENGE: lController.text.isEmpty,
        LABEL_STUECKZAHL: stkController.text.isEmpty,
      };
    });

    if (invalidFields.values.contains(true)) {
      final missingFields = invalidFields.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .join(', ');
      showAppSnackbar(context, 'Bitte ausfüllen: $missingFields');
      return false;
    }
    return true;
  }

  Future<bool> _saveChanges() async {
    if (!_validateRequiredFields()) return false;

    try {
      final data = {
        'nrExt': nrExtController.text,
        'auftragsnr': auftragsnrController.text,
        'datum': datumController.text,
        'holzart': holzartController.text,
        'kunde': kundeController.text,
        'hoehe': double.tryParse(hController.text) ?? 0,
        'breite': double.tryParse(bController.text) ?? 0,
        'laenge': double.tryParse(lController.text) ?? 0,
        'stueckzahl': int.tryParse(stkController.text) ?? 0,
        'menge': double.tryParse(mengeController.text) ?? 0,
        'zustand': zustandController.text,
        'lagerort': lagerortController.text,
        'bemerkung': bemerkungController.text,
        'saeger': saegerController.text,
      };

      if (widget.isNewPackage) {
        final barcode = await _packageService.createPackage(data);
        showAppSnackbar(context, 'Paket $barcode erstellt');
        _loadNextBarcode();
        _clearFieldsForNextPackage();
      } else {
        await _packageService.updatePackage(
          widget.packageData!['barcode'],
          data,
          widget.packageData!,
        );
        showAppSnackbar(context, 'Änderungen gespeichert');
      }

      widget.onSaved?.call(true);
      return true;
    } catch (e) {
      showAppSnackbar(context, 'Fehler: $e');
      return false;
    }
  }

  void _clearFieldsForNextPackage() {
    setState(() {
      nrExtController.clear();
      auftragsnrController.clear();
      stkController.clear();
      mengeController.text = '0.000';
      bemerkungController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    // Tablet-Layout ab 800px Breite
    final isTablet = screenWidth >= 800;

    // Für eingebetteten Säger-Modus: kein Scaffold wrapper
    if (widget.isEmbedded) {
      return isTablet
          ? _buildTabletLayout(theme)
          : _buildMobileLayout(theme);
    }

    return Scaffold(
      backgroundColor: theme.background,
      body: isTablet
          ? _buildTabletLayout(theme)
          : _buildMobileLayout(theme),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TABLET LAYOUT - Zwei Spalten
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabletLayout(ThemeProvider theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linke Spalte: Hauptinformationen
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Paket-Nummer Header (nur bei eingebettetem Modus)
                if (widget.isEmbedded) _buildPackageHeader(theme),

                // Allgemeine Informationen
                ExpandableSection(
                  title: 'Allgemeine Informationen',
                  icon: Icons.info_outline,
                  iconName: 'info',
                  canEdit: true,
                  isExpanded: _isExpanded[0],
                  onExpansionChanged: (v) => setState(() => _isExpanded[0] = v),
                  child: MainInfoSection(
                    isNewPackage: widget.isNewPackage,
                    barcodeController: barcodeController,
                    nrExtController: nrExtController,
                    auftragsnrController: auftragsnrController,
                    datumController: datumController,
                    holzartController: holzartController,
                    kundeController: kundeController,
                    saegerController: saegerController,
                    invalidFields: invalidFields,
                    packageService: _packageService,
                  ),
                ),
                const SizedBox(height: 16),

                // Maße & Menge
                ExpandableSection(
                  title: 'Maße & Menge',
                  icon: Icons.straighten,
                  iconName: 'straighten',
                  canEdit: true,
                  isExpanded: _isExpanded[1],
                  onExpansionChanged: (v) => setState(() => _isExpanded[1] = v),
                  child: DimensionsSection(
                    hController: hController,
                    bController: bController,
                    lController: lController,
                    stkController: stkController,
                    mengeController: mengeController,
                    invalidFields: invalidFields,
                    onRecalculateVolume: _recalculateVolume,
                    onStkFieldTap: () => showCalculatorDialog(
                      context: context,
                      controller: stkController,
                      onValueChanged: _recalculateVolume,
                      allowDecimals: false,
                    ),
                    onSelectFieldTap: (label, controller, options) {
                      showDimensionInputDialog(
                        context: context,
                        controller: controller,
                        title: label,
                        quickOptions: options,
                        onValueChanged: () {
                          setState(() {});
                          _recalculateVolume();
                        },
                        maxValue: label == LABEL_LAENGE ? 10 : null,
                        maxValueMessage: 'Länge max. 10m',
                        onValidationError: (msg) => showAppSnackbar(context, msg),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Vertikaler Divider
        Container(
          width: 1,
          color: theme.border,
        ),

        // Rechte Spalte: Lagerort, Bemerkung, Buttons
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Lagerort
                ExpandableSection(
                  title: 'Lagerort',
                  icon: Icons.location_on_outlined,
                  iconName: 'location_on',
                  canEdit: true,
                  isExpanded: _isExpanded[2],
                  onExpansionChanged: (v) => setState(() => _isExpanded[2] = v),
                  child: LocationSection(
                    controller: lagerortController,
                    packageService: _packageService,
                  ),
                ),
                const SizedBox(height: 16),

                // Status (nur bei bestehenden Paketen)
                if (!widget.isNewPackage) ...[
                  ExpandableSection(
                    title: 'Status',
                    icon: Icons.check_circle_outline,
                    iconName: 'check_circle',
                    canEdit: widget.userGroup >= 2,
                    isExpanded: _isExpanded[3],
                    onExpansionChanged: (v) => setState(() => _isExpanded[3] = v),
                    child: StatusSection(
                      barcode: widget.packageData!['barcode'],
                      zustandController: zustandController,
                      statusController: statusController,
                      packageData: widget.packageData!,
                      packageService: _packageService,
                      userGroup: widget.userGroup,
                      onStatusChanged: () => widget.onSaved?.call(true),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Bemerkung
                ExpandableSection(
                  title: 'Bemerkung',
                  icon: Icons.comment_outlined,
                  iconName: 'comment',
                  canEdit: true,
                  isExpanded: _isExpanded[4],
                  onExpansionChanged: (v) => setState(() => _isExpanded[4] = v),
                  child: CommentSection(controller: bemerkungController),
                ),
                const SizedBox(height: 32),

                // Footer Buttons
                _buildFooter(theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MOBILE LAYOUT - Einzelne Spalte (bisheriges Layout)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Paket-Nummer Header (nur bei eingebettetem Modus)
          if (widget.isEmbedded) _buildPackageHeader(theme),

          // Allgemeine Informationen
          ExpandableSection(
            title: 'Allgemeine Informationen',
            icon: Icons.info_outline,
            iconName: 'info',
            canEdit: true,
            isExpanded: _isExpanded[0],
            onExpansionChanged: (v) => setState(() => _isExpanded[0] = v),
            child: MainInfoSection(
              isNewPackage: widget.isNewPackage,
              barcodeController: barcodeController,
              nrExtController: nrExtController,
              auftragsnrController: auftragsnrController,
              datumController: datumController,
              holzartController: holzartController,
              kundeController: kundeController,
              saegerController: saegerController,
              invalidFields: invalidFields,
              packageService: _packageService,
            ),
          ),
          const SizedBox(height: 8),

          // Maße & Menge
          ExpandableSection(
            title: 'Maße & Menge',
            icon: Icons.straighten,
            iconName: 'straighten',
            canEdit: true,
            isExpanded: _isExpanded[1],
            onExpansionChanged: (v) => setState(() => _isExpanded[1] = v),
            child: DimensionsSection(
              hController: hController,
              bController: bController,
              lController: lController,
              stkController: stkController,
              mengeController: mengeController,
              invalidFields: invalidFields,
              onRecalculateVolume: _recalculateVolume,
              onStkFieldTap: () => showCalculatorDialog(
                context: context,
                controller: stkController,
                onValueChanged: _recalculateVolume,
                allowDecimals: false,
              ),
              onSelectFieldTap: (label, controller, options) {
                showDimensionInputDialog(
                  context: context,
                  controller: controller,
                  title: label,
                  quickOptions: options,
                  onValueChanged: () {
                    setState(() {});
                    _recalculateVolume();
                  },
                  maxValue: label == LABEL_LAENGE ? 10 : null,
                  maxValueMessage: 'Länge max. 10m',
                  onValidationError: (msg) => showAppSnackbar(context, msg),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Lagerort
          ExpandableSection(
            title: 'Lagerort',
            icon: Icons.location_on_outlined,
            iconName: 'location_on',
            canEdit: true,
            isExpanded: _isExpanded[2],
            onExpansionChanged: (v) => setState(() => _isExpanded[2] = v),
            child: LocationSection(
              controller: lagerortController,
              packageService: _packageService,
            ),
          ),
          const SizedBox(height: 8),

          // Status (nur bei bestehenden Paketen)
          if (!widget.isNewPackage) ...[
            ExpandableSection(
              title: 'Status',
              icon: Icons.check_circle_outline,
              iconName: 'check_circle',
              canEdit: widget.userGroup >= 2,
              isExpanded: _isExpanded[3],
              onExpansionChanged: (v) => setState(() => _isExpanded[3] = v),
              child: StatusSection(
                barcode: widget.packageData!['barcode'],
                zustandController: zustandController,
                statusController: statusController,
                packageData: widget.packageData!,
                packageService: _packageService,
                userGroup: widget.userGroup,
                onStatusChanged: () => widget.onSaved?.call(true),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Bemerkung
          ExpandableSection(
            title: 'Bemerkung',
            icon: Icons.comment_outlined,
            iconName: 'comment',
            canEdit: true,
            isExpanded: _isExpanded[4],
            onExpansionChanged: (v) => setState(() => _isExpanded[4] = v),
            child: CommentSection(controller: bemerkungController),
          ),
          const SizedBox(height: 24),

          // Footer Buttons
          _buildFooter(theme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PACKAGE HEADER - Zeigt Paketnummer prominent an
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPackageHeader(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nächste Paketnummer',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${barcodeController.text}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Neu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        children: [
          // Speichern & Drucken Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _handlePrint,
              icon: const Icon(Icons.print),
              label: Text(widget.isNewPackage ? 'Erstellen & Drucken' : 'Speichern & Drucken'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nur Speichern Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Nur Speichern'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Löschen Button (nur bei bestehenden Paketen + Admin)
          if (!widget.isNewPackage && widget.userGroup >= 3) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showDeleteDialog,
                icon: Icon(Icons.delete_outline, color: theme.error),
                label: Text('Löschen', style: TextStyle(color: theme.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    final theme = context.read<ThemeProvider>();
    final barcode = widget.packageData!['barcode'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Paket löschen?', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          'Paket $barcode wirklich löschen?\nDiese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _packageService.deletePackage(barcode);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Paket $barcode gelöscht')),
                );
              }
              widget.onSaved?.call(true);
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