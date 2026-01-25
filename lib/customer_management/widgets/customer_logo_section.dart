// lib/customer_management/widgets/customer_logo_section.dart
// ═══════════════════════════════════════════════════════════════════════════
// CUSTOMER LOGO SECTION
// Zeigt und verwaltet das Kundenlogo in der Detailansicht
// ═══════════════════════════════════════════════════════════════════════════

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
                    child: Image.network(
                      customer.logoColorUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image,
                        color: theme.textSecondary,
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 12, color: theme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Lieferschein',
                        style: TextStyle(fontSize: 11, color: theme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // S/W-Version
            if (customer.logoBwUrl != null)
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
                      child: Image.network(
                        customer.logoBwUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image,
                          color: theme.textSecondary,
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping, size: 12, color: theme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Paketzettel',
                          style: TextStyle(fontSize: 11, color: theme.textSecondary),
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

  Widget _buildPlaceholder(ThemeProvider theme, BuildContext context) {
    return InkWell(
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
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    CustomerLogoUploadDialog.show(
      context,
      customerId: customerId,
      currentLogoUrl: customer.logoColorUrl,
    );
  }
}