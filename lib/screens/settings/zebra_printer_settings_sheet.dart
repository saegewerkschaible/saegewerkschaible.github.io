// lib/widgets/printer/zebra_printer_settings_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/packages/services/printing/zebra_printer_service.dart';
import 'package:saegewerk/packages/services/printing/zebra_tcp_client.dart';

import '../../core/theme/theme_provider.dart';

class ZebraPrinterSettingsSheet extends StatefulWidget {
  final ZebraPrinter printer;

  const ZebraPrinterSettingsSheet({super.key, required this.printer});

  @override
  State<ZebraPrinterSettingsSheet> createState() => _ZebraPrinterSettingsSheetState();
}

class _ZebraPrinterSettingsSheetState extends State<ZebraPrinterSettingsSheet> {
  final _service = ZebraPrinterService();

  bool _loading = true;
  bool _saving = false;
  bool _isOnline = false;
  ZebraPrinterSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);

    final isOnline = await widget.printer.client.isOnline();
    ZebraPrinterSettings? settings;

    if (isOnline) {
      settings = await _service.readSettings(widget.printer);
    }

    // Fallback auf Defaults
    settings ??= const ZebraPrinterSettings();

    if (mounted) {
      setState(() {
        _isOnline = isOnline;
        _settings = settings;
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    setState(() => _saving = true);

    final success = await _service.saveSettings(widget.printer, _settings!);

    if (mounted) {
      setState(() => _saving = false);

      final theme = context.read<ThemeProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Einstellungen gespeichert' : 'Fehler beim Speichern'),
          backgroundColor: success ? theme.primary : theme.error,
        ),
      );

      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: _loading
                ? _buildLoading(theme)
                : _settings == null
                ? _buildError(theme)
                : _buildForm(theme),
          ),
          if (_settings != null) _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: theme.divider, spreadRadius: 1, blurRadius: 3)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.settings, color: theme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Einstellungen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      widget.printer.nickname,
                      style: TextStyle(fontSize: 14, color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusBadge(theme),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeProvider theme) {
    final color = _isOnline ? Colors.green : theme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.check_circle : Icons.error_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            _isOnline ? 'Online - Einstellungen geladen' : 'Offline - Standard-Einstellungen',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primary),
          const SizedBox(height: 16),
          Text('Lade Einstellungen...', style: TextStyle(color: theme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.error.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Drucker nicht erreichbar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Druckbreite
          _buildSection(
            theme: theme,
            title: 'Label-Breite',
            icon: Icons.straighten,
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildWidthChip(theme, '108mm', 1280),
                    _buildWidthChip(theme, '100mm', 1200),
                    _buildWidthChip(theme, '90mm', 1080),
                    _buildWidthChip(theme, '80mm', 960),
                    _buildWidthChip(theme, '70mm', 840),
                    _buildWidthChip(theme, '60mm', 720),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _settings!.printWidth.toDouble(),
                        min: 240,
                        max: 1280,
                        divisions: 104,
                        activeColor: theme.primary,
                        onChanged: (v) => setState(() {
                          _settings = _settings!.copyWith(printWidth: v.round());
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${_settings!.printWidthMm.toStringAsFixed(0)}mm',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Geschwindigkeit
          _buildSection(
            theme: theme,
            title: 'Druckgeschwindigkeit',
            icon: Icons.speed,
            child: Column(
              children: [
                _buildSpeedOption(theme, 2.0, '51 mm/s - Beste Qualität'),
                _buildSpeedOption(theme, 3.0, '76 mm/s - Mittel'),
                _buildSpeedOption(theme, 4.0, '102 mm/s - Schnell'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Darkness
          _buildSection(
            theme: theme,
            title: 'Farbintensität (Darkness)',
            icon: Icons.brightness_6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bereich: 0-30 (höher = dunkler)',
                  style: TextStyle(fontSize: 12, color: theme.textSecondary, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _settings!.darkness,
                        min: 0,
                        max: 30,
                        divisions: 30,
                        activeColor: theme.primary,
                        onChanged: (v) => setState(() {
                          _settings = _settings!.copyWith(darkness: v);
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${_settings!.darkness.round()}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.textPrimary),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Zebra ${widget.printer.model} - 300 DPI\nÄnderungen werden permanent gespeichert.',
                    style: TextStyle(fontSize: 12, color: theme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required ThemeProvider theme,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.primary),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.border),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildWidthChip(ThemeProvider theme, String label, int dots) {
    final isSelected = _settings!.printWidth == dots;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? theme.primary : theme.textPrimary)),
      selected: isSelected,
      onSelected: (_) => setState(() => _settings = _settings!.copyWith(printWidth: dots)),
      selectedColor: theme.primary.withOpacity(0.15),
      checkmarkColor: theme.primary,
      backgroundColor: theme.surface,
      side: BorderSide(color: isSelected ? theme.primary : theme.border),
    );
  }

  Widget _buildSpeedOption(ThemeProvider theme, double speed, String label) {
    final isSelected = _settings!.printSpeed == speed;
    return InkWell(
      onTap: () => setState(() => _settings = _settings!.copyWith(printSpeed: speed)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? theme.primary : theme.border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? theme.primary : theme.textSecondary, width: 2),
              ),
              child: isSelected
                  ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.primary)))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.primary : theme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        boxShadow: [BoxShadow(color: theme.divider, spreadRadius: 1, blurRadius: 3, offset: const Offset(0, -1))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  theme: theme,
                  icon: Icons.print,
                  label: 'Test',
                  onTap: () async {
                    final result = await _service.printTestLabel(widget.printer);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.message), backgroundColor: result.success ? theme.primary : theme.error),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAction(
                  theme: theme,
                  icon: Icons.tune,
                  label: 'Kalibrieren',
                  onTap: () async {
                    final success = await _service.calibrate(widget.printer);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Kalibrierung gestartet' : 'Fehler'), backgroundColor: success ? theme.primary : theme.error),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAction(
                  theme: theme,
                  icon: Icons.info_outline,
                  label: 'Config',
                  onTap: () async {
                    final success = await _service.printConfigLabel(widget.printer);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Config-Label gedruckt' : 'Fehler'), backgroundColor: success ? theme.primary : theme.error),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveSettings,
              icon: _saving
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Speichere...' : 'Speichern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: _saving ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.primary,
        side: BorderSide(color: theme.primary),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }}