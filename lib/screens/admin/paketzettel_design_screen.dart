// ═══════════════════════════════════════════════════════════════════════════
// lib/screens/admin/paketzettel_design_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/packages/services/zebra_pdf_generator.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/theme_provider.dart';
import '../../constants.dart';
import '../../packages/services/printing/zebra_printer_service.dart';

/// Einstellungen für das Paketzettel-Design
class PaketzettelDesignSettings {
  // Logo-Einstellungen
  final double companyLogoHeight;
  final double customerLogoHeight;
  final double customerLogoWidth;
  final String logoPosition; // 'left', 'right', 'center'

  // Schriftgrößen
  final double barcodeNumberSize;
  final double labelFontSize;
  final double valueFontSize;
  final double headerFontSize;

  // Abstände
  final double rowPadding;
  final double sectionSpacing;

  const PaketzettelDesignSettings({
    this.companyLogoHeight = 40,
    this.customerLogoHeight = 36,
    this.customerLogoWidth = 70,
    this.logoPosition = 'split', // 'split' = Firma links, Kunde rechts
    this.barcodeNumberSize = 32,
    this.labelFontSize = 14,
    this.valueFontSize = 16,
    this.headerFontSize = 20,
    this.rowPadding = 3,
    this.sectionSpacing = 4,
  });

  factory PaketzettelDesignSettings.fromMap(Map<String, dynamic> map) {
    return PaketzettelDesignSettings(
      companyLogoHeight: (map['companyLogoHeight'] ?? 40).toDouble(),
      customerLogoHeight: (map['customerLogoHeight'] ?? 36).toDouble(),
      customerLogoWidth: (map['customerLogoWidth'] ?? 70).toDouble(),
      logoPosition: map['logoPosition'] ?? 'split',
      barcodeNumberSize: (map['barcodeNumberSize'] ?? 32).toDouble(),
      labelFontSize: (map['labelFontSize'] ?? 14).toDouble(),
      valueFontSize: (map['valueFontSize'] ?? 16).toDouble(),
      headerFontSize: (map['headerFontSize'] ?? 20).toDouble(),
      rowPadding: (map['rowPadding'] ?? 3).toDouble(),
      sectionSpacing: (map['sectionSpacing'] ?? 4).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyLogoHeight': companyLogoHeight,
      'customerLogoHeight': customerLogoHeight,
      'customerLogoWidth': customerLogoWidth,
      'logoPosition': logoPosition,
      'barcodeNumberSize': barcodeNumberSize,
      'labelFontSize': labelFontSize,
      'valueFontSize': valueFontSize,
      'headerFontSize': headerFontSize,
      'rowPadding': rowPadding,
      'sectionSpacing': sectionSpacing,
    };
  }

  PaketzettelDesignSettings copyWith({
    double? companyLogoHeight,
    double? customerLogoHeight,
    double? customerLogoWidth,
    String? logoPosition,
    double? barcodeNumberSize,
    double? labelFontSize,
    double? valueFontSize,
    double? headerFontSize,
    double? rowPadding,
    double? sectionSpacing,
  }) {
    return PaketzettelDesignSettings(
      companyLogoHeight: companyLogoHeight ?? this.companyLogoHeight,
      customerLogoHeight: customerLogoHeight ?? this.customerLogoHeight,
      customerLogoWidth: customerLogoWidth ?? this.customerLogoWidth,
      logoPosition: logoPosition ?? this.logoPosition,
      barcodeNumberSize: barcodeNumberSize ?? this.barcodeNumberSize,
      labelFontSize: labelFontSize ?? this.labelFontSize,
      valueFontSize: valueFontSize ?? this.valueFontSize,
      headerFontSize: headerFontSize ?? this.headerFontSize,
      rowPadding: rowPadding ?? this.rowPadding,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
    );
  }
}

class PaketzettelDesignScreen extends StatefulWidget {
  const PaketzettelDesignScreen({super.key});

  @override
  State<PaketzettelDesignScreen> createState() => _PaketzettelDesignScreenState();
}

class _PaketzettelDesignScreenState extends State<PaketzettelDesignScreen> {
  final _settingsRef = FirebaseFirestore.instance.collection('settings').doc('paketzettel_design');
  final _printerService = ZebraPrinterService();

  PaketzettelDesignSettings _settings = const PaketzettelDesignSettings();
  Map<String, dynamic>? _examplePackage;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Einstellungen laden
      final settingsDoc = await _settingsRef.get();
      if (settingsDoc.exists) {
        _settings = PaketzettelDesignSettings.fromMap(settingsDoc.data()!);
      }

      // Beispiel-Paket laden (das neueste)
      final packagesSnapshot = await FirebaseFirestore.instance
          .collection('packages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (packagesSnapshot.docs.isNotEmpty) {
        _examplePackage = packagesSnapshot.docs.first.data();
        _examplePackage!['barcode'] = packagesSnapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint('Fehler beim Laden: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    try {
      await _settingsRef.set(_settings.toMap());
      setState(() => _hasChanges = false);
      if (mounted) {
        showAppSnackbar(context, 'Einstellungen gespeichert');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Fehler beim Speichern: $e');
      }
    }
  }
  Future<void> _saveTestPdf() async {
    if (_examplePackage == null) {
      showAppSnackbar(context, 'Kein Beispiel-Paket vorhanden');
      return;
    }

    await _saveSettings();

    final printData = {
      'Barcode': _examplePackage!['barcode']?.toString() ?? '12345',
      'Nr': _examplePackage!['barcode']?.toString() ?? '12345',
      'Kunde': _examplePackage!['kunde']?.toString() ?? 'Testkunde',
      'kundeId': _examplePackage!['kundeId']?.toString(),
      'Auftragsnr': _examplePackage!['auftragsnr']?.toString() ?? '',
      'Holzart': _examplePackage!['holzart']?.toString() ?? 'Fichte',
      'H': _examplePackage!['hoehe']?.toString() ?? '24',
      'B': _examplePackage!['breite']?.toString() ?? '120',
      'L': _examplePackage!['laenge']?.toString() ?? '4.0',
      'Stk': _examplePackage!['stueckzahl']?.toString() ?? '50',
      'Menge': _examplePackage!['menge']?.toString() ?? '0.576',
      'Bemerkung': _examplePackage!['bemerkung']?.toString() ?? '',
      'Nr_ext': _examplePackage!['nrExt']?.toString() ?? '',
      'AbzugStk': _examplePackage!['abzugStk']?.toString() ?? '0',
      'AbzugLaenge': _examplePackage!['abzugLaenge']?.toString() ?? '0',
    };

    try {
      final file = await ZebraPdfGenerator.generatePackageLabel(printData, 100);
      await Share.shareXFiles([XFile(file.path)], text: 'Test-Paketzettel');
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Fehler: $e');
      }
    }
  }
  Future<void> _printTestLabel() async {
    if (_examplePackage == null) {
      showAppSnackbar(context, 'Kein Beispiel-Paket vorhanden');
      return;
    }

    // Zuerst speichern
    await _saveSettings();

    // Test-Daten vorbereiten
    final printData = {
      'Barcode': _examplePackage!['barcode']?.toString() ?? '12345',
      'Nr': _examplePackage!['barcode']?.toString() ?? '12345',
      'Kunde': _examplePackage!['kunde']?.toString() ?? 'Testkunde',
      'kundeId': _examplePackage!['kundeId']?.toString(),
      'Auftragsnr': _examplePackage!['auftragsnr']?.toString() ?? '',
      'Holzart': _examplePackage!['holzart']?.toString() ?? 'Fichte',
      'H': _examplePackage!['hoehe']?.toString() ?? '24',
      'B': _examplePackage!['breite']?.toString() ?? '120',
      'L': _examplePackage!['laenge']?.toString() ?? '4.0',
      'Stk': _examplePackage!['stueckzahl']?.toString() ?? '50',
      'Menge': _examplePackage!['menge']?.toString() ?? '0.576',
      'Bemerkung': _examplePackage!['bemerkung']?.toString() ?? '',
      'Nr_ext': _examplePackage!['nrExt']?.toString() ?? '',
      'AbzugStk': _examplePackage!['abzugStk']?.toString() ?? '0',
      'AbzugLaenge': _examplePackage!['abzugLaenge']?.toString() ?? '0',
    };

    try {
      final result = await _printerService.printPackageLabel(context, printData);
      if (mounted) {
        showAppSnackbar(context, result.message);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, 'Fehler beim Drucken: $e');
      }
    }
  }

  void _updateSetting(PaketzettelDesignSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Design Paketzettel',
          style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _saveSettings,
              icon: Icon(Icons.save, color: theme.primary),
              label: Text('Speichern', style: TextStyle(color: theme.primary)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info-Banner
            _buildInfoBanner(theme),
            const SizedBox(height: 24),

            // Logo-Einstellungen
            _buildSectionHeader(theme, Icons.image, 'Logo-Einstellungen'),
            const SizedBox(height: 12),
            _buildLogoSettings(theme),
            const SizedBox(height: 24),

            // Schriftgrößen
            _buildSectionHeader(theme, Icons.text_fields, 'Schriftgrößen'),
            const SizedBox(height: 12),
            _buildFontSettings(theme),
            const SizedBox(height: 24),

            // Abstände
            _buildSectionHeader(theme, Icons.space_bar, 'Abstände'),
            const SizedBox(height: 12),
            _buildSpacingSettings(theme),
            const SizedBox(height: 32),

            // Test-Druck Button
            // Test-Druck Button
            _buildTestPrintButton(theme),
            const SizedBox(height: 12),

// NEU: PDF Speichern & Öffnen Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _saveTestPdf,
                icon: Icon(Icons.picture_as_pdf, color: theme.primary),
                label: Text('PDF Vorschau', style: TextStyle(color: theme.primary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),

// Reset Button
            _buildResetButton(theme),
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paketzettel-Design anpassen',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hier kannst du Schriftgrößen, Logo-Größen und Positionen für den Paketzettel einstellen.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeProvider theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSettings(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          // Logo-Position
          _buildDropdownSetting(
            theme: theme,
            label: 'Logo-Anordnung',
            value: _settings.logoPosition,
            options: const {
              'split': 'Firma links, Kunde rechts',
              'company_only': 'Nur Firmenlogo (zentriert)',
              'customer_only': 'Nur Kundenlogo (zentriert)',
              'stacked': 'Untereinander',
            },
            onChanged: (value) {
              _updateSetting(_settings.copyWith(logoPosition: value));
            },
          ),
          const SizedBox(height: 16),

          // Firmenlogo Höhe
          _buildSliderSetting(
            theme: theme,
            label: 'Firmenlogo Höhe',
            value: _settings.companyLogoHeight,
            min: 20,
            max: 60,
            unit: 'pt',
            onChanged: (value) {
              _updateSetting(_settings.copyWith(companyLogoHeight: value));
            },
          ),
          const SizedBox(height: 16),

          // Kundenlogo Höhe
          _buildSliderSetting(
            theme: theme,
            label: 'Kundenlogo Höhe',
            value: _settings.customerLogoHeight,
            min: 20,
            max: 60,
            unit: 'pt',
            onChanged: (value) {
              _updateSetting(_settings.copyWith(customerLogoHeight: value));
            },
          ),
          const SizedBox(height: 16),

          // Kundenlogo Breite
          _buildSliderSetting(
            theme: theme,
            label: 'Kundenlogo Breite',
            value: _settings.customerLogoWidth,
            min: 40,
            max: 100,
            unit: 'pt',
            onChanged: (value) {
              _updateSetting(_settings.copyWith(customerLogoWidth: value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontSettings(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          // Barcode-Nummer
          _buildSliderSetting(
            theme: theme,
            label: 'Barcode-Nummer',
            value: _settings.barcodeNumberSize,
            min: 20,
            max: 48,
            unit: 'pt',
            onChanged: (value) {
              _updateSetting(_settings.copyWith(barcodeNumberSize: value));
            },
          ),
          const SizedBox(height: 16),

          // Label (links)
          _buildSliderSetting(
            theme: theme,
            label: 'Beschriftung (z.B. "Kunde")',
            value: _settings.labelFontSize,
            min: 10,
            max: 20,
            unit: 'pt',
            onChanged: (value) {
              _updateSetting(_settings.copyWith(labelFontSize: value));
            },
          ),
          const SizedBox(height: 16),

          // Wert (rechts)
          _buildSliderSetting(
            theme: theme,
            label: 'Werte (z.B. Kundenname)',
            value: _settings.valueFontSize,
            min: 12,
            max: 24,
            unit: 'pt',
            onChanged: (value) {
              _updateSetting(_settings.copyWith(valueFontSize: value));
            },
          ),
          // const SizedBox(height: 16),
          //
          // // Header (Lamelle-Banner)
          // _buildSliderSetting(
          //   theme: theme,
          //   label: 'Header (z.B. "LAMELLE")',
          //   value: _settings.headerFontSize,
          //   min: 14,
          //   max: 28,
          //   unit: 'pt',
          //   onChanged: (value) {
          //     _updateSetting(_settings.copyWith(headerFontSize: value));
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildSpacingSettings(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          // Zeilen-Padding
          _buildSliderSetting(
            theme: theme,
            label: 'Zeilen-Abstand (vertikal)',
            value: _settings.rowPadding,
            min: 1,
            max: 8,
            unit: 'pt',
            onChanged: (value) {
              _updateSetting(_settings.copyWith(rowPadding: value));
            },
          ),
          const SizedBox(height: 16),

          // Abschnitt-Abstand
          _buildSliderSetting(
            theme: theme,
            label: 'Abschnitt-Abstand',
            value: _settings.sectionSpacing,
            min: 2,
            max: 12,
            unit: 'pt',
            onChanged: (value) {
              _updateSetting(_settings.copyWith(sectionSpacing: value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required ThemeProvider theme,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: theme.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()} $unit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.primary,
            inactiveTrackColor: theme.primary.withOpacity(0.2),
            thumbColor: theme.primary,
            overlayColor: theme.primary.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSetting({
    required ThemeProvider theme,
    required String label,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: theme.surface,
              style: TextStyle(color: theme.textPrimary),
              items: options.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestPrintButton(ThemeProvider theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _printTestLabel,
        icon: const Icon(Icons.print),
        label: const Text('Test-Paketzettel drucken'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildResetButton(ThemeProvider theme) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _settings = const PaketzettelDesignSettings();
            _hasChanges = true;
          });
          showAppSnackbar(context, 'Auf Standardwerte zurückgesetzt');
        },
        icon: const Icon(Icons.restore),
        label: const Text('Auf Standard zurücksetzen'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.textSecondary,
          side: BorderSide(color: theme.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}