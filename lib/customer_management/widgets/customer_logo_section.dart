// lib/customer_management/widgets/customer_logo_section.dart
// ═══════════════════════════════════════════════════════════════════════════
// CUSTOMER LOGO SECTION
// Zeigt und verwaltet das Kundenlogo in der Detailansicht
// WEB-KOMPATIBEL: Verbesserte Fehlerbehandlung und Caching
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/customer_management/models/customer.dart';
import 'package:saegewerk/customer_management/widgets/customer_logo_upload_dialog.dart';

class CustomerLogoSection extends StatelessWidget {
  final String customerId;
  final Customer customer;

  const CustomerLogoSection({
    Key? key,
    required this.customerId,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final hasLogo = customer.logoColorUrl != null;

    debugPrint('🔄 [CustomerLogoSection] build');
    debugPrint('   hasLogo: $hasLogo');
    debugPrint('   logoColorUrl: ${customer.logoColorUrl}');
    debugPrint('   logoBwUrl: ${customer.logoBwUrl}');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.image, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                'Firmenlogo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              // Bearbeiten Button
              TextButton.icon(
                onPressed: () => _showUploadDialog(context),
                icon: Icon(
                  hasLogo ? Icons.edit : Icons.add_photo_alternate,
                  size: 18,
                  color: theme.primary,
                ),
                label: Text(
                  hasLogo ? 'Ändern' : 'Hochladen',
                  style: TextStyle(color: theme.primary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Logo Vorschau oder Platzhalter
          if (hasLogo)
            _buildLogoPreview(theme)
          else
            _buildPlaceholder(theme, context),
        ],
      ),
    );
  }

  Widget _buildLogoPreview(ThemeProvider theme) {
    // Timestamp für Cache-Busting (& statt ? weil Firebase URL schon ?token=... hat)
    final cacheBuster = customer.logoUpdatedAt?.millisecondsSinceEpoch.toString() ?? '';
    final colorUrl = '${customer.logoColorUrl}${cacheBuster.isNotEmpty ? "&v=$cacheBuster" : ""}';
    final bwUrl = customer.logoBwUrl != null
        ? '${customer.logoBwUrl}${cacheBuster.isNotEmpty ? "&v=$cacheBuster" : ""}'
        : null;

    return Column(
      children: [
        // Farb-Logo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farbversion
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.border),
                    ),
                    child: _buildNetworkImage(
                      colorUrl,
                      theme,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description,
                          size: 12, color: theme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Lieferschein',
                        style: TextStyle(
                            fontSize: 11, color: theme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // S/W-Version
            if (bwUrl != null)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.border),
                      ),
                      child: _buildNetworkImage(
                        bwUrl,
                        theme,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping,
                            size: 12, color: theme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Paketzettel',
                          style: TextStyle(
                              fontSize: 11, color: theme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Info Text
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: theme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Das Logo erscheint automatisch auf allen Dokumenten dieses Kunden.',
                  style: TextStyle(fontSize: 11, color: theme.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Netzwerkbild mit verbesserter Fehlerbehandlung für Web
  Widget _buildNetworkImage(String url, ThemeProvider theme) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ [CustomerLogoSection] Bild laden fehlgeschlagen: $error');
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: theme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Fehler',
              style: TextStyle(
                fontSize: 10,
                color: theme.textSecondary,
              ),
            ),
          ],
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.primary,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      // Cache-Control für Web
      cacheWidth: 600, // Limitiere die gecachte Bildgröße
    );
  }

  Widget _buildPlaceholder(ThemeProvider theme, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showUploadDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate,
                  size: 32,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Logo hochladen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PNG oder JPG, max. 5 MB',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Web-Version',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.info,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    debugPrint('🔄 [CustomerLogoSection] _showUploadDialog()');
    CustomerLogoUploadDialog.show(
      context,
      customerId: customerId,
      currentLogoUrl: customer.logoColorUrl,
    );
  }
}