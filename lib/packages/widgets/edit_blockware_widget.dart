// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/widgets/edit_blockware_widget.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants.dart';
import '../../core/theme/theme_provider.dart';

import '../dialogs/dimension_input_dialog.dart';
import '../services/printing/zebra_printer_service.dart';
import '../services/zebra_pdf_generator.dart';
import '../sections/blockware_board_section.dart';
import '../sections/comment_section.dart';
import '../sections/expandable_section.dart';
import '../sections/location_section.dart';
import '../sections/main_info_section.dart';
import '../services/package_service.dart';

class EditBlockwareWidget extends StatefulWidget {
  final Map<String, dynamic>? packageData;
  final int userGroup;
  final bool isNewPackage;
  final void Function(bool)? onSaved;

  const EditBlockwareWidget({
    super.key,
    required this.packageData,
    required this.userGroup,
    required this.isNewPackage,
    this.onSaved,
  });

  @override
  State<EditBlockwareWidget> createState() => _EditBlockwareWidgetState();
}

class _EditBlockwareWidgetState extends State<EditBlockwareWidget> {
  final PackageService _packageService = PackageService();
  final _printerService = ZebraPrinterService();

  // ═══════════════════════════════════════════════════════════════
  // CONTROLLER - Allgemeine Infos (gleich wie normales Paket)
  // ═══════════════════════════════════════════════════════════════
  late TextEditingController barcodeController;
  late TextEditingController nrExtController;
  late TextEditingController auftragsnrController;
  late TextEditingController datumController;
  late TextEditingController holzartController;
  late TextEditingController kundeController;
  late TextEditingController saegerController;

  // Blockware-spezifisch
  late TextEditingController staerkeController; // Fix für ganzes Paket
  late TextEditingController mengeController;

  // Abzug
  late TextEditingController abzugStkController;
  late TextEditingController abzugLaengeController;

  // Lagerort & Bemerkung
  late TextEditingController lagerortController;
  late TextEditingController bemerkungController;

  // Nicht benötigt aber für Kompatibilität mit MainInfoSection
  late TextEditingController statusController;
  late TextEditingController zustandController;

  String? _kundeId;

  // ═══════════════════════════════════════════════════════════════
  // BRETTLISTE
  // ═══════════════════════════════════════════════════════════════
  List<BrettEntry> _bretter = [];

  // ═══════════════════════════════════════════════════════════════
  // UI STATE
  // ═══════════════════════════════════════════════════════════════
  List<bool> _isExpanded = [true, true, true, true];
  Map<String, bool> invalidFields = {};

  // Pin State
  bool _pinHolzart = false;
  bool _pinKunde = false;
  bool _pinLagerort = false;
  bool _pinStaerke = false;

  DocumentReference get _pinSettingsRef => FirebaseFirestore.instance
      .collection('settings')
      .doc('blockware_pins');

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initBretter();

    if (widget.isNewPackage) {
      _loadPinSettings();
      _loadNextBarcode();
    }
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
    saegerController = TextEditingController(text: data?['saeger']?.toString() ?? '');
    staerkeController = TextEditingController(text: data?['staerke']?.toString() ?? '');
    mengeController = TextEditingController(text: data?['menge']?.toString() ?? '0.000');
    abzugStkController = TextEditingController(text: data?['abzugStk']?.toString() ?? '');
    abzugLaengeController = TextEditingController(text: data?['abzugLaenge']?.toString() ?? '');
    lagerortController = TextEditingController(text: data?['lagerort']?.toString() ?? '');
    bemerkungController = TextEditingController(text: data?['bemerkung']?.toString() ?? '');
    statusController = TextEditingController(text: data?['status']?.toString() ?? PackageStatus.imLager);
    zustandController = TextEditingController(text: data?['zustand']?.toString() ?? PackageZustand.frisch);
    _kundeId = data?['kundeId']?.toString();
  }

  void _initBretter() {
    final data = widget.packageData;
    if (data != null && data['bretter'] is List) {
      final bretterList = data['bretter'] as List;
      _bretter = bretterList
          .map((b) => BrettEntry.fromMap(b as Map<String, dynamic>))
          .toList();
    }
    // Immer eine leere Zeile am Ende
    _bretter.add(BrettEntry());
  }

  Future<void> _loadNextBarcode() async {
    final nextNumber = await _packageService.getNextPackageNumber();
    if (mounted) {
      setState(() => barcodeController.text = nextNumber.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PIN-LOGIK (analog zu EditPackageWidget)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadPinSettings() async {
    try {
      final doc = await _pinSettingsRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _pinHolzart = data['holzart'] ?? false;
          _pinKunde = data['kunde'] ?? false;
          _pinLagerort = data['lagerort'] ?? false;
          _pinStaerke = data['staerke'] ?? false;

          if (_pinHolzart && data['holzartValue'] != null) {
            holzartController.text = data['holzartValue'];
          }
          if (_pinKunde && data['kundeValue'] != null) {
            kundeController.text = data['kundeValue'];
          }
          if (_pinLagerort && data['lagerortValue'] != null) {
            lagerortController.text = data['lagerortValue'];
          }
          if (_pinStaerke && data['staerkeValue'] != null) {
            staerkeController.text = data['staerkeValue'];
          }
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Pin-Einstellungen: $e');
    }
  }

  Future<void> _togglePin(String field) async {
    setState(() {
      switch (field) {
        case 'holzart': _pinHolzart = !_pinHolzart; break;
        case 'kunde': _pinKunde = !_pinKunde; break;
        case 'lagerort': _pinLagerort = !_pinLagerort; break;
        case 'staerke': _pinStaerke = !_pinStaerke; break;
      }
    });

    try {
      await _pinSettingsRef.set({
        'holzart': _pinHolzart,
        'kunde': _pinKunde,
        'lagerort': _pinLagerort,
        'staerke': _pinStaerke,
        'holzartValue': _pinHolzart ? holzartController.text : null,
        'kundeValue': _pinKunde ? kundeController.text : null,
        'lagerortValue': _pinLagerort ? lagerortController.text : null,
        'staerkeValue': _pinStaerke ? staerkeController.text : null,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Fehler beim Speichern der Pin-Einstellungen: $e');
    }
  }

  Future<void> _updatePinnedValue(String field, String value) async {
    bool shouldUpdate = false;
    switch (field) {
      case 'holzart': shouldUpdate = _pinHolzart; break;
      case 'kunde': shouldUpdate = _pinKunde; break;
      case 'lagerort': shouldUpdate = _pinLagerort; break;
      case 'staerke': shouldUpdate = _pinStaerke; break;
    }

    if (shouldUpdate) {
      try {
        await _pinSettingsRef.set({
          '${field}Value': value,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Fehler beim Aktualisieren des gepinnten Werts: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // VOLUMEN-BERECHNUNG
  // ═══════════════════════════════════════════════════════════════

  void _recalculateVolume() {
    final staerke = double.tryParse(staerkeController.text) ?? 0;
    double total = 0;
    for (final brett in _bretter) {
      if (brett.isFilled) {
        total += brett.volumen(staerke);
      }
    }
    setState(() {
      mengeController.text = total.toStringAsFixed(3);
    });
  }

  int _getFilledCount() {
    return _bretter.where((b) => b.isFilled).length;
  }

  // ═══════════════════════════════════════════════════════════════
  // VALIDIERUNG
  // ═══════════════════════════════════════════════════════════════

  bool _validateRequiredFields() {
    setState(() {
      invalidFields = {
        'Holzart': holzartController.text.isEmpty,
        'Stärke': staerkeController.text.isEmpty,
        'Bretter': _getFilledCount() == 0,
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

  // ═══════════════════════════════════════════════════════════════
  // SPEICHERN
  // ═══════════════════════════════════════════════════════════════

  Future<bool> _saveChanges() async {
    if (!_validateRequiredFields()) return false;

    try {
      // Nur ausgefüllte Bretter speichern
      final filledBretter = _bretter
          .where((b) => b.isFilled)
          .map((b) => b.toMap())
          .toList();

      final data = {
        'isBlockware': true,
        'nrExt': nrExtController.text,
        'auftragsnr': auftragsnrController.text,
        'datum': datumController.text,
        'holzart': holzartController.text,
        'kunde': kundeController.text,
        'kundeId': _kundeId,
        'saeger': saegerController.text,
        'staerke': double.tryParse(staerkeController.text) ?? 0,
        'bretter': filledBretter,
        'stueckzahl': filledBretter.length,
        'menge': double.tryParse(mengeController.text) ?? 0,
        // Für Kompatibilität mit bestehendem System:
        'hoehe': double.tryParse(staerkeController.text) ?? 0,
        'breite': 0, // Nicht fix bei Blockware
        'laenge': 0, // Nicht fix bei Blockware
        'abzugStk': int.tryParse(abzugStkController.text) ?? 0,
        'abzugLaenge': double.tryParse(abzugLaengeController.text) ?? 0,
        'zustand': zustandController.text,
        'lagerort': lagerortController.text,
        'bemerkung': bemerkungController.text,
      };

      if (widget.isNewPackage) {
        final barcode = await _packageService.createPackage(data);
        if (mounted) showAppSnackbar(context, 'Blockware-Paket $barcode erstellt');
        _loadNextBarcode();
        _clearFieldsForNextPackage();
      } else {
        await _packageService.updatePackage(
          widget.packageData!['barcode'],
          data,
          widget.packageData!,
        );
        if (mounted) showAppSnackbar(context, 'Änderungen gespeichert');
      }

      widget.onSaved?.call(true);
      return true;
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Fehler: $e');
      return false;
    }
  }

  void _clearFieldsForNextPackage() {
    if (!mounted) return;
    setState(() {
      nrExtController.clear();
      auftragsnrController.clear();
      bemerkungController.clear();
      abzugStkController.clear();
      abzugLaengeController.clear();
      mengeController.text = '0.000';

      if (!_pinHolzart) holzartController.clear();
      if (!_pinKunde) {
        kundeController.clear();
        _kundeId = null;
      }
      if (!_pinLagerort) lagerortController.clear();
      if (!_pinStaerke) staerkeController.clear();

      // Bretter zurücksetzen
      for (final b in _bretter) {
        b.dispose();
      }
      _bretter = [BrettEntry()];
    });
  }

  Future<void> _handlePrint() async {
    // 1. Print-Daten JETZT sammeln, bevor _saveChanges die Controller leert
    final filledBretter = _bretter
        .where((b) => b.isFilled)
        .map((b) => b.toMap())
        .toList();

    final printData = {
      'Barcode': barcodeController.text,
      'Nr': barcodeController.text,
      'Kunde': kundeController.text,
      'kundeId': _kundeId,
      'Auftragsnr': auftragsnrController.text,
      'Holzart': holzartController.text,
      'Staerke': staerkeController.text,
      'Bretter': filledBretter,
      'Stueckzahl': filledBretter.length.toString(),
      'Menge': mengeController.text,
      'Bemerkung': bemerkungController.text,
      'Nr_ext': nrExtController.text,
      'AbzugStk': abzugStkController.text,
      'AbzugLaenge': abzugLaengeController.text,
    };

    // 2. Speichern
    final saved = await _saveChanges();
    if (!saved) return;

    // 3. Mounted check
    if (!mounted) return;

    try {
      // 4. PDF drucken über den bestehenden Printer-Service
      final result = await _printerService.printBlockwareLabel(context, printData);

      if (!mounted) return;
      showAppSnackbar(context, result.message);
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Fehler beim Drucken: $e');
      }
    }
  }

  @override
  void dispose() {
    barcodeController.dispose();
    nrExtController.dispose();
    auftragsnrController.dispose();
    datumController.dispose();
    holzartController.dispose();
    kundeController.dispose();
    saegerController.dispose();
    staerkeController.dispose();
    mengeController.dispose();
    abzugStkController.dispose();
    abzugLaengeController.dispose();
    lagerortController.dispose();
    bemerkungController.dispose();
    statusController.dispose();
    zustandController.dispose();

    for (final b in _bretter) {
      b.dispose();
    }

    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 800;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Füge diese Zeile hinzu!
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
        // Linke Spalte: Allgemein + Stärke + Brettliste
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildAllgemeineInfoSection(theme),
                const SizedBox(height: 8),
                _buildStaerkeSection(theme),
                const SizedBox(height: 8),
                _buildBrettListeSection(theme),
              ],
            ),
          ),
        ),

        // Vertikaler Divider
        Container(width: 1, color: theme.border),

        // Rechte Spalte: Abzug, Lagerort, Bemerkung, Buttons
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAbzugSection(theme),
                const SizedBox(height: 16),
                _buildLagerortSection(theme),
                const SizedBox(height: 16),
                _buildBemerkungSection(theme),
                const SizedBox(height: 32),
                _buildFooter(theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MOBILE LAYOUT - Einzelne Spalte
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildAllgemeineInfoSection(theme),
          const SizedBox(height: 8),
          _buildStaerkeSection(theme),
          const SizedBox(height: 8),
          _buildBrettListeSection(theme),
          const SizedBox(height: 8),
          _buildAbzugSection(theme),
          const SizedBox(height: 8),
          _buildLagerortSection(theme),
          const SizedBox(height: 8),
          _buildBemerkungSection(theme),
          const SizedBox(height: 24),
          _buildFooter(theme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTIONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAllgemeineInfoSection(ThemeProvider theme) {
    return ExpandableSection(
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
        pinHolzart: widget.isNewPackage ? _pinHolzart : false,
        pinKunde: widget.isNewPackage ? _pinKunde : false,
        onTogglePin: widget.isNewPackage ? _togglePin : null,
        onPinnedValueChanged: widget.isNewPackage ? _updatePinnedValue : null,
        onKundeIdChanged: (id) {
          setState(() => _kundeId = id);
        },
      ),
    );
  }

  Widget _buildStaerkeSection(ThemeProvider theme) {
    final staerke = double.tryParse(staerkeController.text) ?? 0;

    return ExpandableSection(
      title: 'Stärke (fix für alle Bretter)',
      icon: Icons.height,
      iconName: 'height',
      canEdit: true,
      isExpanded: _isExpanded[1],
      onExpansionChanged: (v) => setState(() => _isExpanded[1] = v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label mit Pin
          Row(
            children: [
              Icon(Icons.height, size: 16, color: theme.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Stärke [mm]',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
              Text(' *', style: TextStyle(color: theme.error, fontSize: 12)),
              const Spacer(),
              if (widget.isNewPackage)
                GestureDetector(
                  onTap: () => _togglePin('staerke'),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _pinStaerke ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                      color: _pinStaerke ? theme.primary : theme.textHint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Stärke-Feld
          GestureDetector(
            onTap: () {
              showDimensionInputDialog(
                context: context,
                controller: staerkeController,
                title: 'Stärke [mm]',
                quickOptions: const ['24', '27', '30', '34', '40', '45', '50', '55', '60', '65', '70', '80'],
                onValueChanged: () {
                  setState(() {});
                  _recalculateVolume();
                  _updatePinnedValue('staerke', staerkeController.text);
                },
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: _pinStaerke
                    ? theme.primary.withOpacity(0.05)
                    : theme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: invalidFields['Stärke'] == true
                      ? theme.error
                      : _pinStaerke
                      ? theme.primary
                      : theme.border,
                  width: _pinStaerke ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      staerkeController.text.isEmpty
                          ? 'Stärke auswählen...'
                          : '${staerkeController.text} mm',
                      style: TextStyle(
                        fontSize: 18,
                        color: staerkeController.text.isEmpty
                            ? theme.textHint
                            : theme.textPrimary,
                        fontWeight: staerke > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: theme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrettListeSection(ThemeProvider theme) {
    return ExpandableSection(
      title: 'Bretter (${_getFilledCount()} Stk.)',
      icon: Icons.view_column,
      iconName: 'view_column',
      canEdit: true,
      isExpanded: _isExpanded[2],
      onExpansionChanged: (v) => setState(() => _isExpanded[2] = v),
      child: BlockwareBoardSection(
        bretter: _bretter,
        staerke: double.tryParse(staerkeController.text) ?? 0,
        onChanged: () {
          setState(() {});
          _recalculateVolume();
        },
      ),
    );
  }

  Widget _buildAbzugSection(ThemeProvider theme) {
    final abzugStk = int.tryParse(abzugStkController.text) ?? 0;
    final abzugLaenge = double.tryParse(abzugLaengeController.text) ?? 0;
    final hasAbzug = abzugStk > 0 && abzugLaenge > 0;

    return ExpandableSection(
      title: 'Abzug & Volumen',
      icon: Icons.calculate_outlined,
      iconName: 'calculate',
      canEdit: true,
      isExpanded: _isExpanded[3],
      onExpansionChanged: (v) => setState(() => _isExpanded[3] = v),
      child: Column(
        children: [
          // Abzug Stk + Abzug Länge
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(
                  theme: theme,
                  label: 'Abzug Stk',
                  controller: abzugStkController,
                  icon: Icons.remove_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(
                  theme: theme,
                  label: 'Abzug Länge [m]',
                  controller: abzugLaengeController,
                  icon: Icons.straighten,
                  isDecimal: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Brutto-Volumen
          _buildVolumeRow(
            theme: theme,
            label: hasAbzug ? 'Brutto' : 'Volumen',
            value: mengeController.text,
            icon: Icons.view_in_ar,
            color: theme.textPrimary,
          ),

          // Abzug-Volumen (wenn vorhanden)
          if (hasAbzug) ...[
            const SizedBox(height: 8),
            _buildVolumeRow(
              theme: theme,
              label: 'Abzug',
              value: '-${_calculateAbzugVolumen().toStringAsFixed(3)}',
              icon: Icons.remove_circle,
              color: theme.error,
              bgColor: theme.error.withOpacity(0.1),
            ),
            const SizedBox(height: 8),
            _buildVolumeRow(
              theme: theme,
              label: 'Netto',
              value: _calculateNettoVolumen().toStringAsFixed(3),
              icon: Icons.check_circle,
              color: theme.primary,
              bgColor: theme.primary.withOpacity(0.1),
              borderColor: theme.primary,
              isBold: true,
            ),
          ],
        ],
      ),
    );
  }

  double _calculateAbzugVolumen() {
    final staerke = double.tryParse(staerkeController.text) ?? 0;
    // Bei Blockware: Abzug basiert auf Durchschnittsbreite oder wird pauschal berechnet
    // Einfachste Variante: Abzug-Stk × Abzug-Länge × Stärke × Durchschnittsbreite
    // Für den Moment: Abzug nur als Stk × Länge × Stärke × mittlere Breite der Bretter
    final abzugStk = int.tryParse(abzugStkController.text) ?? 0;
    final abzugLaenge = double.tryParse(abzugLaengeController.text) ?? 0;

    if (abzugStk == 0 || abzugLaenge == 0) return 0;

    // Durchschnittsbreite der Bretter berechnen
    final filledBretter = _bretter.where((b) => b.isFilled).toList();
    if (filledBretter.isEmpty) return 0;

    final avgBreite = filledBretter.map((b) => b.breite).reduce((a, b) => a + b) / filledBretter.length;
    return (staerke * avgBreite * abzugLaenge * abzugStk) / 1000000;
  }

  double _calculateNettoVolumen() {
    final brutto = double.tryParse(mengeController.text) ?? 0;
    return brutto - _calculateAbzugVolumen();
  }

  Widget _buildSimpleNumberField({
    required ThemeProvider theme,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: theme.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primary, width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeRow({
    required ThemeProvider theme,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    Color? bgColor,
    Color? borderColor,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor ?? theme.background,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '$value m³',
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLagerortSection(ThemeProvider theme) {
    return ExpandableSection(
      title: 'Lagerort',
      icon: Icons.location_on_outlined,
      iconName: 'location_on',
      canEdit: true,
      isExpanded: true,
      onExpansionChanged: (_) {},
      child: LocationSection(
        controller: lagerortController,
        packageService: _packageService,
        isPinned: widget.isNewPackage ? _pinLagerort : false,
        onTogglePin: widget.isNewPackage ? () => _togglePin('lagerort') : null,
        onChanged: widget.isNewPackage ? (v) => _updatePinnedValue('lagerort', v) : null,
      ),
    );
  }

  Widget _buildBemerkungSection(ThemeProvider theme) {
    return ExpandableSection(
      title: 'Bemerkung',
      icon: Icons.comment_outlined,
      iconName: 'comment',
      canEdit: true,
      isExpanded: true,
      onExpansionChanged: (_) {},
      child: CommentSection(controller: bemerkungController),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FOOTER BUTTONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFooter(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        children: [
          // Erstellen & Drucken
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

          // Nur Erstellen/Speichern
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: Text(widget.isNewPackage ? 'Nur Erstellen' : 'Nur Speichern'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Löschen (nur bei bestehend + Admin)
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
          'Blockware-Paket $barcode wirklich löschen?\nDiese Aktion kann nicht rückgängig gemacht werden.',
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
                showAppSnackbar(context, 'Paket $barcode gelöscht');
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