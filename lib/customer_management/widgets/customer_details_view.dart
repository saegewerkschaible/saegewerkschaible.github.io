// lib/screens/CustomerManagement/widgets/customer_details_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/customer_management/models/customer.dart';
import 'package:saegewerk/customer_management/services/customer_service.dart';
import 'package:saegewerk/services/icon_helper.dart';


import 'customer_form_bottom_sheet.dart';

import 'customer_color_picker.dart';
import 'customer_contacts_section.dart';
import 'customer_detail_section.dart';
import '../dialogs/delete_customer_dialog.dart';

class CustomerDetailsView extends StatelessWidget {
  final String customerId;
  final int userGroup;
  final VoidCallback onBack;
  final bool isMobile;

  const CustomerDetailsView({
    Key? key,
    required this.customerId,
    required this.userGroup,
    required this.onBack,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final customerService = CustomerService();

    return StreamBuilder<Customer?>(
      stream: customerService.getCustomerStream(customerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: CircularProgressIndicator(color: theme.primary),
          );
        }

        final customer = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            color: theme.background,
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(context, theme, customer),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farbauswahl
                      CustomerColorPicker(
                        customerId: customerId,
                        customer: customer,
                      ),

                      const SizedBox(height: 24),

                      // // Alias-Sektion
                      // _buildAliasSection(theme, customer),
                      //
                      // const SizedBox(height: 24),

                      // Adresse
                      _buildAddressSection(theme, customer),

                      // Kontakt
                      if (customer.phone != null ||
                          customer.email != null ||
                          customer.website != null) ...[
                        const SizedBox(height: 24),
                        _buildContactSection(theme, customer),
                      ],

                      // Notizen
                      if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        CustomerDetailSection(
                          title: 'Notizen',
                          icon: 'notes',
                          children: [
                            Text(
                              customer.notes!,
                              style: TextStyle(color: theme.textSecondary),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Ansprechpartner
                      CustomerContactsSection(customerId: customerId),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, dynamic theme, Customer customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: getAdaptiveIcon(
                  iconName: 'arrow_back',
                  defaultIcon: Icons.arrow_back,
                  color: theme.textSecondary,
                ),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          getAdaptiveIcon(
            iconName: 'person',
            defaultIcon: Icons.person,
            color: theme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              customer.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                icon: getAdaptiveIcon(
                  iconName: 'edit',
                  defaultIcon: Icons.edit,
                  color: theme.primary,
                  size: 20,
                ),
                onPressed: () => CustomerFormBottomSheet.show(
                  context,
                  customerId: customerId,
                  customer: customer,
                ),
                tooltip: 'Bearbeiten',
              ),
              if (userGroup >= 10)
                IconButton(
                  icon: getAdaptiveIcon(
                    iconName: 'delete',
                    defaultIcon: Icons.delete,
                    color: theme.error,
                    size: 20,
                  ),
                  onPressed: () => DeleteCustomerDialog.show(
                    context,
                    customer: customer,
                    onDeleted: onBack,
                  ),
                  tooltip: 'Löschen',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAliasSection(dynamic theme, Customer customer) {
    return CustomerDetailSection(
      title: 'Alias (Deckname)',
      icon: 'badge',
      children: [
        if (customer.alias != null && customer.alias!.isNotEmpty) ...[
          _buildDetailRow(theme, 'Alias', customer.alias!),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: customer.useAliasOnLabels
                      ? theme.success.withOpacity(0.1)
                      : theme.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: customer.useAliasOnLabels
                        ? theme.success
                        : theme.textSecondary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    getAdaptiveIcon(
                      iconName: customer.useAliasOnLabels
                          ? 'check_circle'
                          : 'cancel',
                      defaultIcon: customer.useAliasOnLabels
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 14,
                      color: customer.useAliasOnLabels
                          ? theme.success
                          : theme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      customer.useAliasOnLabels
                          ? 'Wird auf Paketzetteln verwendet'
                          : 'Alias auf Paketzetteln nicht aktiviert',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: customer.useAliasOnLabels
                            ? theme.success
                            : theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ] else ...[
          Text(
            'Kein Alias festgelegt',
            style: TextStyle(
              color: theme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Der Alias kann auf Paketzetteln anstelle des echten Kundennamens verwendet werden.',
          style: TextStyle(
            fontSize: 12,
            color: theme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(dynamic theme, Customer customer) {
    return CustomerDetailSection(
      title: 'Adresse',
      icon: 'location_on',
      children: [
        if (customer.fullStreet != null)
          _buildDetailRow(theme, 'Straße', customer.fullStreet!),
        if (customer.cityWithZip != null)
          _buildDetailRow(theme, 'Ort', customer.cityWithZip!),
        if (customer.country != null)
          _buildDetailRow(theme, 'Land', customer.country!),

        // Geocoding Status
        if (customer.isGeocoded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                getAdaptiveIcon(
                  iconName: 'check_circle',
                  defaultIcon: Icons.check_circle,
                  color: theme.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Standort geocodiert',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactSection(dynamic theme, Customer customer) {
    return CustomerDetailSection(
      title: 'Kontakt',
      icon: 'contact_phone',
      children: [
        if (customer.phone != null)
          _buildDetailRow(theme, 'Telefon', customer.phone!),
        if (customer.email != null)
          _buildDetailRow(theme, 'E-Mail', customer.email!),
        if (customer.website != null)
          _buildDetailRow(theme, 'Website', customer.website!),
      ],
    );
  }

  Widget _buildDetailRow(dynamic theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: theme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}