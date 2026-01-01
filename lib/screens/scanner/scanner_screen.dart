// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/screens/scanner_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/packages/widgets/edit_package_widget.dart';

import '../../core/theme/theme_provider.dart';
import '../../constants.dart';

import 'barcode_scanner_page.dart';

class ScannerScreen extends StatefulWidget {
  final int userGroup;
  final bool showBackButton;

  const ScannerScreen({
    super.key,
    required this.userGroup,
    this.showBackButton = false,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? lastScannedBarcode;
  Map<String, dynamic>? packageData;
  final TextEditingController barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLastPackage();
  }

  @override
  void dispose() {
    barcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadLastPackage() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('app')
        .get();
    if (doc.exists && mounted) {
      setState(() {
        lastScannedBarcode = (doc.data() as Map<String, dynamic>?)?['lastPackage']?.toString();
      });
    }
  }

  Future<void> _scanBarcode() async {
    // Auf Web keinen Scanner öffnen
    if (kIsWeb) {
      _showBarcodeInputDialog();
      return;
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (result != null && result.isNotEmpty) {
      await _fetchPackageData(result);
    }
  }

  Future<void> _fetchPackageData(String barcode) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('packages')
        .doc(barcode)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      _showPackageSheet(data);
    } else {
      if (mounted) {
        showAppSnackbar(context, 'Paket $barcode nicht gefunden');
      }
    }
  }

  void _showPackageSheet(Map<String, dynamic> data) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    if (isWideScreen) {
      // Auf großen Screens: Dialog statt BottomSheet
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85, // 85% der Bildschirmbreite
            constraints: const BoxConstraints(maxWidth: 1200), // Max 1200px
            height: MediaQuery.of(context).size.height * 0.85,

            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Paket ${data['barcode']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.border),
                Expanded(
                  child: EditPackageWidget(
                    packageData: data,
                    userGroup: widget.userGroup,
                    isNewPackage: false,
                    onSaved: (success) {
                      _loadLastPackage();
                      if (success) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Auf kleinen Screens: BottomSheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: theme.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Paket ${data['barcode']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.border),
                Expanded(
                  child: EditPackageWidget(
                    packageData: data,
                    userGroup: widget.userGroup,
                    isNewPackage: false,
                    onSaved: (success) {
                      _loadLastPackage();
                      if (success) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showNewPackageSheet() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    if (isWideScreen) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85, // 85% der Bildschirmbreite
            constraints: const BoxConstraints(maxWidth: 1200), // Max 1200px
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Neues Paket',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.border),
                Expanded(
                  child: EditPackageWidget(
                    packageData: null,
                    userGroup: widget.userGroup,
                    isNewPackage: true,
                    onSaved: (success) {
                      _loadLastPackage();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: theme.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Neues Paket',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.border),
                Expanded(
                  child: EditPackageWidget(
                    packageData: null,
                    userGroup: widget.userGroup,
                    isNewPackage: true,
                    onSaved: (success) {
                      _loadLastPackage();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showBarcodeInputDialog() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    String currentNumber = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: theme.surface,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double dialogWidth = math.min(400.0, constraints.maxWidth * 0.9);
                double buttonSize = math.min((dialogWidth - 48) / 4, 80.0);
                double fontSize = buttonSize * 0.4;

                return Container(
                  width: dialogWidth,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.keyboard, color: theme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Barcode eingeben',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: theme.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.border),
                        ),
                        child: Text(
                          currentNumber.isEmpty ? '0' : currentNumber,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildNumpad(
                        theme: theme,
                        buttonSize: buttonSize,
                        fontSize: fontSize,
                        currentNumber: currentNumber,
                        onNumberChanged: (n) => setState(() => currentNumber = n),
                        onConfirm: () {
                          if (currentNumber.isNotEmpty) {
                            Navigator.pop(ctx);
                            _fetchPackageData(currentNumber);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildNumpad({
    required ThemeProvider theme,
    required double buttonSize,
    required double fontSize,
    required String currentNumber,
    required Function(String) onNumberChanged,
    required VoidCallback onConfirm,
  }) {
    Widget btn(String label, {Color? bg, Color? fg, VoidCallback? onTap}) {
      return SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg ?? theme.background,
            foregroundColor: fg ?? theme.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
          ),
          child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          btn('7', onTap: () => onNumberChanged(currentNumber + '7')),
          btn('8', onTap: () => onNumberChanged(currentNumber + '8')),
          btn('9', onTap: () => onNumberChanged(currentNumber + '9')),
          btn('⌫', bg: theme.textSecondary.withOpacity(0.3), onTap: () {
            if (currentNumber.isNotEmpty) {
              onNumberChanged(currentNumber.substring(0, currentNumber.length - 1));
            }
          }),
        ],
      ),
      SizedBox(height: buttonSize * 0.15),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          btn('4', onTap: () => onNumberChanged(currentNumber + '4')),
          btn('5', onTap: () => onNumberChanged(currentNumber + '5')),
          btn('6', onTap: () => onNumberChanged(currentNumber + '6')),
          btn('C', bg: theme.error.withOpacity(0.7), fg: Colors.white, onTap: () => onNumberChanged('')),
        ],
      ),
      SizedBox(height: buttonSize * 0.15),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          btn('1', onTap: () => onNumberChanged(currentNumber + '1')),
          btn('2', onTap: () => onNumberChanged(currentNumber + '2')),
          btn('3', onTap: () => onNumberChanged(currentNumber + '3')),
          btn('✓', bg: theme.success, fg: Colors.white, onTap: onConfirm),
        ],
      ),
      SizedBox(height: buttonSize * 0.15),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          btn('0', onTap: () => onNumberChanged(currentNumber + '0')),
        ],
      ),
    ];
  }

  // Füge diese Helper-Methode zur Klasse hinzu:
  double _getButtonSize(double screenWidth) {
    if (screenWidth < 400) return 130;      // Kleine Phones
    if (screenWidth < 600) return 150;      // Normale Phones
    if (screenWidth < 900) return 140;      // Tablets
    return 150;                              // Desktop
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: widget.showBackButton
          ? AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        title: Text('Pakete', style: TextStyle(color: theme.textPrimary)),
        iconTheme: IconThemeData(color: theme.textPrimary),
      )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: EdgeInsets.all(isWideScreen ? 32 : 24),
            child: Column(
              children: [
                // Info-Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: theme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paketverwaltung',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kIsWeb
                                  ? 'Gib einen Barcode ein oder erstelle ein neues Paket'
                                  : 'Scanne einen Barcode oder erstelle ein neues Paket',
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
                ),
                const SizedBox(height: 24),

                // Grid Buttons - RESPONSIVE
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          // Scanner nur auf Mobile
                          if (!kIsWeb)
                            _buildMenuButton(
                              theme: theme,
                              icon: Icons.qr_code_scanner,
                              label: 'Scannen',
                              onTap: _scanBarcode,
                              fixedSize: _getButtonSize(screenWidth),
                            ),
                          _buildMenuButton(
                            theme: theme,
                            icon: Icons.keyboard,
                            label: 'Manuell',
                            onTap: _showBarcodeInputDialog,
                            fixedSize: _getButtonSize(screenWidth),
                          ),
                          _buildMenuButton(
                            theme: theme,
                            icon: Icons.history,
                            label: 'Zuletzt',
                            subtitle: lastScannedBarcode ?? '–',
                            enabled: lastScannedBarcode != null,
                            onTap: lastScannedBarcode != null
                                ? () => _fetchPackageData(lastScannedBarcode!)
                                : null,
                            fixedSize: _getButtonSize(screenWidth),
                          ),
                          _buildMenuButton(
                            theme: theme,
                            icon: Icons.add_box,
                            label: 'Neu',
                            onTap: _showNewPackageSheet,
                            fixedSize: _getButtonSize(screenWidth),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildMenuButton({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    String? subtitle,
    bool enabled = true,
    VoidCallback? onTap,
    double? fixedSize, // NEU: Optional
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            width: fixedSize,   // null = flexible (GridView bestimmt)
            height: fixedSize,  // null = flexible
            decoration: BoxDecoration(  color: theme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.border),
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: theme.primary),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}