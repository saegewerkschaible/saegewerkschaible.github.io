// lib/screens/delivery_notes/cart_screen.dart

import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/screens/delivery_notes/dialogs/email_settings_dialog.dart';
import 'package:saegewerk/screens/delivery_notes/widgets/summary_card.dart';

import '../../core/theme/theme_provider.dart';
import '../../constants.dart';
import '../scanner/barcode_scanner_page.dart';

import 'services/cart_provider.dart';
import 'services/delivery_note_service.dart';
import 'services/pdf_helper.dart';
import 'widgets/info_chips.dart';
import 'widgets/cart_item_card.dart';
import 'dialogs/customer_selection_dialog.dart';

class CartScreen extends StatefulWidget {
  final int userGroup;
  final bool showBackButton;

  const CartScreen({
    super.key,
    required this.userGroup,
    this.showBackButton = false,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Warenkorb aus Firebase laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadFromTemporaryCart();
    });
  }

  Future<void> _scanBarcode() async {
    if (kIsWeb) {
      _showBarcodeInputDialog();
      return;
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (result != null && result.isNotEmpty) {
      await _fetchAndAddPackage(result);
    }
  }

  Future<void> _fetchAndAddPackage(String barcode) async {
    final cart = context.read<CartProvider>();

    // Prüfen ob bereits im Warenkorb
    if (cart.containsPackage(barcode)) {
      showAppSnackbar(context, 'Paket ist bereits im Warenkorb');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('packages')
          .doc(barcode)
          .get();

      if (!doc.exists) {
        if (mounted) showAppSnackbar(context, 'Paket $barcode nicht gefunden');
        return;
      }

      final data = doc.data()!;
      data['barcode'] = barcode;

      if (mounted) {
        await cart.addPackage(context, data);
      }
    } catch (e) {
      if (mounted) showAppSnackbar(context, 'Fehler: $e');
    }
  }

  void _showBarcodeInputDialog() {
    final theme = context.read<ThemeProvider>();
    String currentNumber = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            backgroundColor: theme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
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

                  // Anzeige
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

                  // Numpad
                  _buildNumpad(
                    theme: theme,
                    currentNumber: currentNumber,
                    onNumberChanged: (n) => setState(() => currentNumber = n),
                    onConfirm: () {
                      if (currentNumber.isNotEmpty) {
                        Navigator.pop(ctx);
                        _fetchAndAddPackage(currentNumber);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumpad({
    required ThemeProvider theme,
    required String currentNumber,
    required Function(String) onNumberChanged,
    required VoidCallback onConfirm,
  }) {
    Widget btn(String label, {Color? bg, Color? fg, VoidCallback? onTap}) {
      return SizedBox(
        width: 70,
        height: 56,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg ?? theme.background,
            foregroundColor: fg ?? theme.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
            elevation: 0,
          ),
          child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            btn('7', onTap: () => onNumberChanged(currentNumber + '7')),
            btn('8', onTap: () => onNumberChanged(currentNumber + '8')),
            btn('9', onTap: () => onNumberChanged(currentNumber + '9')),
            btn('⌫', bg: theme.textSecondary.withOpacity(0.2), onTap: () {
              if (currentNumber.isNotEmpty) {
                onNumberChanged(currentNumber.substring(0, currentNumber.length - 1));
              }
            }),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            btn('4', onTap: () => onNumberChanged(currentNumber + '4')),
            btn('5', onTap: () => onNumberChanged(currentNumber + '5')),
            btn('6', onTap: () => onNumberChanged(currentNumber + '6')),
            btn('C', bg: theme.error.withOpacity(0.2), fg: theme.error, onTap: () => onNumberChanged('')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            btn('1', onTap: () => onNumberChanged(currentNumber + '1')),
            btn('2', onTap: () => onNumberChanged(currentNumber + '2')),
            btn('3', onTap: () => onNumberChanged(currentNumber + '3')),
            btn('✓', bg: theme.success, fg: Colors.white, onTap: onConfirm),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            btn('0', onTap: () => onNumberChanged(currentNumber + '0')),
          ],
        ),
      ],
    );
  }

  void _showCustomerSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomerSelectionDialog(),
    );
  }

  Future<void> _createDeliveryNote() async {
    final cart = context.read<CartProvider>();
    final theme = context.read<ThemeProvider>();

    if (cart.isEmpty) {
      showAppSnackbar(context, 'Warenkorb ist leer');
      return;
    }

    // NEU: Kunde als Pflichtfeld prüfen
    if (cart.selectedCustomer == null) {
      showAppSnackbar(context, 'Bitte zuerst einen Kunden auswählen', isError: true);
      return;
    }

    // Loading anzeigen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: theme.primary),
                const SizedBox(height: 16),
                const Text('Lieferschein wird erstellt...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await DeliveryNoteService.createDeliveryNote(
        items: cart.items,
        customer: cart.selectedCustomer,
      );

      if (!mounted) return;
      Navigator.pop(context); // Loading schließen

      if (result['success'] == true) {
        showAppSnackbar(context, 'Lieferschein ${result['number']} erstellt');

        // Erfolgs-Dialog
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showAppSnackbar(context, 'Fehler: $e', isError: true);
      }
    }
  }
  void _showSuccessDialog(Map<String, dynamic> result) {
    final theme = context.read<ThemeProvider>();
    final cart = context.read<CartProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: theme.success),
            const SizedBox(width: 12),
            Text('Lieferschein erstellt', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lieferschein Nr. ${result['number']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Der Lieferschein wurde erfolgreich gespeichert.',
              style: TextStyle(color: theme.textSecondary),
            ),
            if (result['pdfUrl'] != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => PdfHelper.openPdfUrl(context, result['pdfUrl']),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('PDF öffnen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => PdfHelper.sharePdfBytes(
                        context,
                        result['pdfBytes'],
                        'LS_${result['number']}.pdf',
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text('Teilen'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primary,
                        side: BorderSide(color: theme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cart.clearCart();
              cart.clearCustomer();
            },
            child: Text('Schließen', style: TextStyle(color: theme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    final theme = context.read<ThemeProvider>();
    final cart = context.read<CartProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Warenkorb leeren', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          'Möchtest du wirklich alle Pakete aus dem Warenkorb entfernen?',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leeren'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final cart = context.watch<CartProvider>();
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: _buildAppBar(theme, cart),
      body: isWideScreen
          ? _buildDesktopLayout(theme, cart)
          : _buildMobileLayout(theme, cart),
    );
  }

  Widget _buildEmailInfoBar(ThemeProvider theme, CartProvider cart) {
    final hasEmail = cart.customerHasEmail;
    final receivesEmail = cart.customerReceivesEmail;
    final email = cart.selectedCustomer?['email'] ?? '';
    final settings = cart.customerEmailSettings;

    if (!hasEmail) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: receivesEmail
            ? theme.success.withOpacity(0.1)
            : theme.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: receivesEmail
              ? theme.success.withOpacity(0.3)
              : theme.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            receivesEmail ? Icons.email : Icons.email_outlined,
            size: 20,
            color: receivesEmail ? theme.success : theme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receivesEmail
                      ? 'Kunde erhält Lieferschein'
                      : 'Email-Versand deaktiviert',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: receivesEmail ? theme.success : theme.textSecondary,
                  ),
                ),
                if (receivesEmail) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Anhänge-Badges
          if (receivesEmail) ...[
            if (settings['sendPdf'] == true)
              _buildAttachmentBadge(theme, 'PDF', theme.primary),
            const SizedBox(width: 6),
            if (settings['sendJson'] == true)
              _buildAttachmentBadge(theme, 'JSON', theme.info),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentBadge(ThemeProvider theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider theme, CartProvider cart) {
    return AppBar(
      backgroundColor: theme.surface,
      elevation: 0,
      automaticallyImplyLeading: widget.showBackButton,
      title: Row(
        children: [
          // Kunden-Anzeige
          GestureDetector(
            onTap: _showCustomerSelection,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cart.selectedCustomer != null
                    ? theme.success.withOpacity(0.15)
                    : theme.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: cart.selectedCustomer != null ? theme.success : theme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cart.selectedCustomer != null
                        ? (cart.selectedCustomer!['name'] as String).substring(
                      0,
                      min(20, (cart.selectedCustomer!['name'] as String).length),
                    )
                        : 'Kunde wählen',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cart.selectedCustomer != null ? theme.success : theme.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: cart.selectedCustomer != null ? theme.success : theme.error,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Scanner Button
        if (!kIsWeb)
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: theme.primary),
            onPressed: _scanBarcode,
          ),
        // Manuelle Eingabe
        IconButton(
          icon: Icon(Icons.keyboard, color: theme.primary),
          onPressed: _showBarcodeInputDialog,
        ),
        IconButton(
          icon: Icon(Icons.email, color: theme.primary),
          onPressed: () => EmailSettingsSheet.show(context),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(ThemeProvider theme, CartProvider cart) {
    return Row(
      children: [
        // Linke Sidebar: Summary + Actions
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border(right: BorderSide(color: theme.border)),
          ),
          child: Column(
            children: [
              _buildSummarySection(theme, cart, isDesktop: true),
              Divider(color: theme.divider),
              // NEU: Email-Info-Leiste
              if (cart.showEmailInfo)
                _buildEmailInfoBar(theme, cart),

              const Spacer(),
              _buildActionButtons(theme, cart),
            ],
          ),
        ),

        // Rechts: Paketliste
        Expanded(
          child: _buildPackageList(theme, cart),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeProvider theme, CartProvider cart) {
    return Column(
      children: [
        _buildSummarySection(theme, cart),
        Divider(color: theme.divider, height: 1),
        Expanded(child: _buildPackageList(theme, cart)),
        // NEU: Email-Info-Leiste
        if (cart.showEmailInfo)
          _buildEmailInfoBar(theme, cart),

        _buildActionButtons(theme, cart),


      ],
    );
  }

  Widget _buildSummarySection(ThemeProvider theme, CartProvider cart, {bool isDesktop = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.surface,
      child: isDesktop
          ? Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SummaryCard(
                icon: Icons.inventory_2,
                label: 'Pakete',
                value: '${cart.itemCount}',
                isCompact: true,
              ),
              SummaryCard(
                icon: Icons.view_in_ar,
                label: 'Volumen',
                value: '${cart.totalVolume.toStringAsFixed(2)} m³',
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SummaryCard(
            icon: Icons.format_list_numbered,
            label: 'Stückzahl',
            value: '${cart.totalQuantity}',
            isCompact: true,
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: CompactSummaryItem(
              icon: Icons.inventory_2,
              iconName: 'inventory_2',
              value: '${cart.itemCount}',
              label: 'Pakete',
            ),
          ),
          Container(width: 1, height: 40, color: theme.border),
          Expanded(
            child: CompactSummaryItem(
              icon: Icons.view_in_ar,
              iconName: 'view_in_ar',
              value: '${cart.totalVolume.toStringAsFixed(1)} m³',
              label: 'Volumen',
            ),
          ),
          Container(width: 1, height: 40, color: theme.border),
          Expanded(
            child: CompactSummaryItem(
              icon: Icons.format_list_numbered,
              iconName: 'format_list_numbered',
              value: '${cart.totalQuantity}',
              label: 'Stk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageList(ThemeProvider theme, CartProvider cart) {
    if (cart.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primary),
      );
    }

    if (cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: theme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Warenkorb ist leer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Gib einen Barcode ein um Pakete hinzuzufügen'
                  : 'Scanne Pakete oder gib den Barcode manuell ein',
              style: TextStyle(color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return CartItemCard(
          item: item,
          onRemove: () => cart.removePackage(item.barcode),
        );
      },
    );
  }

  Widget _buildActionButtons(ThemeProvider theme, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Lieferschein erstellen
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: cart.isEmpty ? null : _createDeliveryNote,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Lieferschein'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: theme.textSecondary.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Warenkorb leeren
            Expanded(
              child: OutlinedButton.icon(
                onPressed: cart.isEmpty ? null : _showClearCartDialog,
                icon: Icon(Icons.delete_outline, color: cart.isEmpty ? theme.textSecondary : theme.error),
                label: Text(
                  'Leeren',
                  style: TextStyle(color: cart.isEmpty ? theme.textSecondary : theme.error),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: cart.isEmpty ? theme.textSecondary.withOpacity(0.3) : theme.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}