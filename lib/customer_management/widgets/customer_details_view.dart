// lib/screens/CustomerManagement/widgets/customer_details_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/customer_management/models/customer.dart';
import 'package:saegewerk/customer_management/services/customer_service.dart';
import 'package:saegewerk/customer_management/widgets/customer_logo_section.dart';
import 'package:saegewerk/services/icon_helper.dart';

import 'customer_form_bottom_sheet.dart';
import 'customer_color_picker.dart';
import 'customer_contacts_section.dart';
import 'customer_detail_section.dart';
import '../dialogs/delete_customer_dialog.dart';

class CustomerDetailsView extends StatefulWidget {
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
  State<CustomerDetailsView> createState() => _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends State<CustomerDetailsView> {
  final CustomerService _customerService = CustomerService();
  Customer? _lastCustomer;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return StreamBuilder<Customer?>(
      stream: _customerService.getCustomerStream(widget.customerId),
      builder: (context, snapshot) {
        // Aktualisiere Cache nur wenn neue gültige Daten kommen
        if (snapshot.hasData && snapshot.data != null) {
          _lastCustomer = snapshot.data;
        }

        // Zeige Loading nur wenn noch NIE Daten da waren
        if (_lastCustomer == null) {
          return Center(
            child: CircularProgressIndicator(color: theme.primary),
          );
        }

        final customer = _lastCustomer!;

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
                        customerId: widget.customerId,
                        customer: customer,
                      ),
                      const SizedBox(height: 24),
                      CustomerLogoSection(
                        customerId: widget.customerId,
                        customer: customer,
                      ),
                      const SizedBox(height: 24),

                      // Adresse
                      _buildAddressSection(theme, customer),
                      // NEU: Lieferadresse (falls abweichend)
                      if (customer.hasDeliveryAddress) ...[
                        const SizedBox(height: 24),
                        _buildDeliveryAddressSection(theme, customer),
                      ],
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
                      const SizedBox(height: 24),
                      _buildEmailSettingsSection(theme, customer),

                      const SizedBox(height: 16),

                      // Ansprechpartner
                      CustomerContactsSection(customerId: widget.customerId),
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
          if (widget.isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: getAdaptiveIcon(
                  iconName: 'arrow_back',
                  defaultIcon: Icons.arrow_back,
                  color: theme.textSecondary,
                ),
                onPressed: widget.onBack,
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
                  customerId: widget.customerId,
                  customer: customer,
                ),
                tooltip: 'Bearbeiten',
              ),
              if (widget.userGroup >= 10)
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
                    onDeleted: widget.onBack,
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
  Widget _buildDeliveryAddressSection(dynamic theme, Customer customer) {
    return CustomerDetailSection(
      title: 'Lieferadresse',
      icon: 'local_shipping',
      children: [
        // Straße
        if (customer.fullDeliveryStreet != null)
          _buildDetailRow(theme, 'Straße', customer.fullDeliveryStreet!),

        // Zusatzzeilen (Hinterhaus, 3. OG, etc.)
        for (final line in customer.deliveryAdditionalLines)
          if (line.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Zusatz:',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

        // Ort
        if (customer.deliveryCityWithZip != null)
          _buildDetailRow(theme, 'Ort', customer.deliveryCityWithZip!),

        // Land
        if (customer.deliveryCountry != null)
          _buildDetailRow(theme, 'Land', customer.deliveryCountry!),

        // Info-Hinweis
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: theme.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Diese Adresse wird auf Lieferscheinen verwendet.',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildAddressSection(dynamic theme, Customer customer) {
    return CustomerDetailSection(
      title: 'Rechnungsadresse',
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

  Widget _buildEmailSettingsSection(dynamic theme, Customer customer) {
    if (customer.email == null || customer.email!.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomerDetailSection(
      title: 'Lieferschein per Email',
      icon: 'email',
      children: [
        // Hauptschalter
        _buildSettingRow(
          theme,
          'Erhält Lieferscheine',
          customer.emailReceivesDeliveryNote,
          customer.emailReceivesDeliveryNote ? theme.success : theme.textSecondary,
        ),

        if (customer.emailReceivesDeliveryNote) ...[
          const SizedBox(height: 8),
          Divider(color: theme.border, height: 1),
          const SizedBox(height: 8),

          // PDF Einstellung
          _buildSettingRow(
            theme,
            'PDF-Anhang',
            customer.emailSendPdf,
            customer.emailSendPdf ? theme.primary : theme.textSecondary,
          ),

          const SizedBox(height: 4),

          // JSON Einstellung
          _buildSettingRow(
            theme,
            'JSON-Export (Datenimport)',
            customer.emailSendJson,
            customer.emailSendJson ? theme.primary : theme.textSecondary,
          ),
        ],

        const SizedBox(height: 12),
        Text(
          'Diese Einstellungen werden beim Erstellen von Lieferscheinen verwendet.',
          style: TextStyle(
            fontSize: 11,
            color: theme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(dynamic theme, String label, bool isActive, Color activeColor) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.1) : theme.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? activeColor : theme.border,
            ),
          ),
          child: isActive
              ? Icon(Icons.check, size: 14, color: activeColor)
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive ? theme.textPrimary : theme.textSecondary,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
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