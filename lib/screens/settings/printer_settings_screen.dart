// lib/screens/settings/printer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saegewerk/packages/services/printing/zebra_printer_service.dart';
import 'package:saegewerk/screens/settings/zebra_printer_settings_sheet.dart';

import '../../core/theme/theme_provider.dart';


class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _service = ZebraPrinterService();
  final _auth = FirebaseAuth.instance;

  String? _defaultPrinterIp;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultPrinter();
  }

  Future<void> _loadDefaultPrinter() async {
    final ip = await _service.getDefaultPrinterIp();
    if (mounted) {
      setState(() {
        _defaultPrinterIp = ip;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(child: _buildContent(theme)),
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
        boxShadow: [
          BoxShadow(color: theme.divider, spreadRadius: 1, blurRadius: 3),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.print, color: theme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Druckereinstellungen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: theme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeProvider theme) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: theme.primary));
    }

    return Column(
      children: [
        // Drucker hinzufügen Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddPrinterSheet(context, theme),
              icon: const Icon(Icons.add),
              label: const Text('Zebra-Drucker hinzufügen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        // Drucker-Liste
        Expanded(
          child: StreamBuilder<List<ZebraPrinter>>(
            stream: _service.watchPrinters(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.primary));
              }

              final printers = snapshot.data ?? [];

              if (printers.isEmpty) {
                return _buildEmptyState(theme);
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: printers.length,
                itemBuilder: (ctx, i) => _PrinterCard(
                  printer: printers[i],
                  isDefault: printers[i].ipAddress == _defaultPrinterIp,
                  onSetDefault: () => _setDefault(printers[i]),
                  onSettings: () => _showSettings(printers[i]),
                  onWake: () => _wakePrinter(printers[i]),
                  onDelete: () => _deletePrinter(printers[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.print_disabled, size: 64, color: theme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Noch keine Drucker',
            style: TextStyle(fontSize: 16, color: theme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge einen Zebra-Drucker hinzu',
            style: TextStyle(fontSize: 14, color: theme.textSecondary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  // ==================== AKTIONEN ====================

  void _showAddPrinterSheet(BuildContext context, ThemeProvider theme) {
    final nicknameCtrl = TextEditingController();
    final ipCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '9100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zebra-Drucker hinzufügen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: nicknameCtrl,
              label: 'Name',
              hint: 'z.B. Produktion',
              icon: Icons.label,
              theme: theme,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: ipCtrl,
              label: 'IP-Adresse',
              hint: '192.168.1.100',
              icon: Icons.wifi,
              theme: theme,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: portCtrl,
              label: 'Port',
              hint: '9100',
              icon: Icons.settings_ethernet,
              theme: theme,
              keyboardType: TextInputType.number,
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nicknameCtrl.text.isEmpty || ipCtrl.text.isEmpty) {
                        _showSnackbar('Bitte Name und IP eingeben', theme.error);
                        return;
                      }

                      await _service.addPrinter(
                        nickname: nicknameCtrl.text,
                        ipAddress: ipCtrl.text,
                        port: int.tryParse(portCtrl.text) ?? 9100,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                      _showSnackbar('Drucker hinzugefügt', theme.primary);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Hinzufügen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeProvider theme,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: theme.textSecondary),
            filled: true,
            fillColor: theme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _setDefault(ZebraPrinter printer) async {
    await _service.setDefaultPrinter(printer.ipAddress);
    setState(() => _defaultPrinterIp = printer.ipAddress);
    _showSnackbar('${printer.nickname} als Standard gesetzt', context.read<ThemeProvider>().primary);
  }

  void _showSettings(ZebraPrinter printer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ZebraPrinterSettingsSheet(printer: printer),
    );
  }

  Future<void> _wakePrinter(ZebraPrinter printer) async {
    final theme = context.read<ThemeProvider>();
    final isOnline = await printer.client.isOnline();

    _showSnackbar(
      isOnline ? '${printer.nickname} ist online' : '${printer.nickname} nicht erreichbar',
      isOnline ? theme.primary : theme.error,
    );
  }

  Future<void> _deletePrinter(ZebraPrinter printer) async {
    final theme = context.read<ThemeProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Drucker löschen?', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          '${printer.nickname} wirklich löschen?',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deletePrinter(printer.id);
      _showSnackbar('Drucker gelöscht', theme.primary);
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}

// ==================== DRUCKER CARD ====================

class _PrinterCard extends StatefulWidget {
  final ZebraPrinter printer;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onSettings;
  final VoidCallback onWake;
  final VoidCallback onDelete;

  const _PrinterCard({
    required this.printer,
    required this.isDefault,
    required this.onSetDefault,
    required this.onSettings,
    required this.onWake,
    required this.onDelete,
  });

  @override
  State<_PrinterCard> createState() => _PrinterCardState();
}

class _PrinterCardState extends State<_PrinterCard> {
  bool? _isOnline;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final online = await widget.printer.client.isOnline();
    if (mounted) setState(() => _isOnline = online);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDefault ? theme.primary : theme.border,
          width: widget.isDefault ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onSettings,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Status Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(theme).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.print, color: _getStatusColor(theme)),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.printer.nickname,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                          if (widget.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Standard',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.printer.model,
                        style: TextStyle(fontSize: 13, color: theme.textSecondary),
                      ),
                      Text(
                        widget.printer.displayAddress,
                        style: TextStyle(fontSize: 12, color: theme.textSecondary.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),

                // Menü
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.textSecondary),
                  color: theme.surface,
                  onSelected: (value) {
                    switch (value) {
                      case 'wake': widget.onWake(); break;
                      case 'settings': widget.onSettings(); break;
                      case 'default': widget.onSetDefault(); break;
                      case 'delete': widget.onDelete(); break;
                    }
                  },
                  itemBuilder: (_) => [
                    _buildMenuItem('wake', Icons.power_settings_new, 'Aufwecken', theme.primary, theme),
                    _buildMenuItem('settings', Icons.settings, 'Einstellungen', theme.textPrimary, theme),
                    if (!widget.isDefault)
                      _buildMenuItem('default', Icons.star, 'Als Standard', theme.primary, theme),
                    _buildMenuItem('delete', Icons.delete, 'Löschen', theme.error, theme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ThemeProvider theme) {
    if (_isOnline == null) return theme.textSecondary;
    return _isOnline! ? Colors.green : theme.error;
  }

  PopupMenuItem<String> _buildMenuItem(
      String value,
      IconData icon,
      String label,
      Color color,
      ThemeProvider theme,
      ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}