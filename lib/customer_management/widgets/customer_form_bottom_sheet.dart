// lib/components/customer_form_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // Wichtig für Provider.of
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/customer_management/models/customer.dart';
import 'package:saegewerk/customer_management/services/customer_service.dart';


import '../../services/icon_helper.dart';
import '../../constants.dart';



class CustomerFormBottomSheet extends StatefulWidget {
  final String? customerId;
  final Customer? customer;
  final bool isEdit;

  const CustomerFormBottomSheet({
    Key? key,
    this.customerId,
    this.customer,
  }) : isEdit = customerId != null,
        super(key: key);

  static Future<void> show(
      BuildContext context, {
        String? customerId,
        Customer? customer,
      }) {
    // Für Web auf mobilen Geräten: Dialog statt BottomSheet
    final isWebMobile = kIsWeb && MediaQuery.of(context).size.width < 600;

    if (isWebMobile) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 500,
            ),
            child: CustomerFormBottomSheet(
              customerId: customerId,
              customer: customer,
            ),
          ),
        ),
      );
    }

    // Standard BottomSheet für Desktop und Native
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerFormBottomSheet(
        customerId: customerId,
        customer: customer,
      ),
    );
  }

  @override
  State<CustomerFormBottomSheet> createState() => _CustomerFormBottomSheetState();
}

class _CustomerFormBottomSheetState extends State<CustomerFormBottomSheet> {
  final CustomerService _customerService = CustomerService();

  late final TextEditingController nameController;
  late final TextEditingController streetController;
  late final TextEditingController houseNumberController;
  late final TextEditingController zipCodeController;
  late final TextEditingController cityController;
  late final TextEditingController countryController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController websiteController;
  late final TextEditingController notesController;
  late final TextEditingController aliasController;
  late final TextEditingController latitudeController;
  late final TextEditingController longitudeController;
  bool _isLoading = false;
  bool _useAliasOnLabels = false;

  // Google Places Daten
  String? _selectedPlaceId;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedFormattedAddress;
  String? _googlePhone;
  String? _googleWebsite;

  @override
  void initState() {
    super.initState();

    if (widget.customer != null) {
      final customer = widget.customer!;
      nameController = TextEditingController(text: customer.name);
      streetController = TextEditingController(text: customer.street ?? '');
      houseNumberController = TextEditingController(text: customer.houseNumber ?? '');
      zipCodeController = TextEditingController(text: customer.zipCode ?? '');
      cityController = TextEditingController(text: customer.city ?? '');
      countryController = TextEditingController(text: customer.country ?? 'Deutschland');
      phoneController = TextEditingController(text: customer.phone ?? '');
      emailController = TextEditingController(text: customer.email ?? '');
      websiteController = TextEditingController(text: customer.website ?? '');
      notesController = TextEditingController(text: customer.notes ?? '');
      aliasController = TextEditingController(text: customer.alias ?? '');
      latitudeController = TextEditingController(
          text: customer.latitude?.toString() ?? ''
      );
      longitudeController = TextEditingController(
          text: customer.longitude?.toString() ?? ''
      );

      _useAliasOnLabels = customer.useAliasOnLabels;

      // Google Places Daten
      _selectedPlaceId = customer.placeId;
      _selectedLatitude = customer.latitude;
      _selectedLongitude = customer.longitude;
      _selectedFormattedAddress = customer.formattedAddress;
      _googlePhone = customer.googlePhone;
      _googleWebsite = customer.googleWebsite;
    } else {
      nameController = TextEditingController();
      streetController = TextEditingController();
      houseNumberController = TextEditingController();
      zipCodeController = TextEditingController();
      cityController = TextEditingController();
      countryController = TextEditingController(text: 'Deutschland');
      phoneController = TextEditingController();
      emailController = TextEditingController();
      websiteController = TextEditingController();
      notesController = TextEditingController();
      aliasController = TextEditingController();
      latitudeController = TextEditingController();
      longitudeController = TextEditingController();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    streetController.dispose();
    houseNumberController.dispose();
    zipCodeController.dispose();
    cityController.dispose();
    countryController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    notesController.dispose();
    aliasController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    // Theme Colors abrufen (listen: false, da wir hier nicht neu bauen)
    final theme = context.read<ThemeProvider>();

    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: getAdaptiveIcon(
                  iconName: 'warning',
                  defaultIcon: Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Bitte geben Sie einen Namen ein'),
            ],
          ),
          backgroundColor: theme.warning, // Theme Warning
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final manualLat = latitudeController.text.isNotEmpty
        ? double.tryParse(latitudeController.text)
        : null;
    final manualLng = longitudeController.text.isNotEmpty
        ? double.tryParse(longitudeController.text)
        : null;

    // Verwende manuelle Koordinaten, falls vorhanden, sonst Google Places
    final finalLat = manualLat ?? _selectedLatitude;
    final finalLng = manualLng ?? _selectedLongitude;

    try {
      if (widget.customerId == null) {
        // ===== NEUEN KUNDEN ERSTELLEN =====
        final newCustomer = Customer(
          id: '',
          name: nameController.text.trim(),
          street: streetController.text.trim().isEmpty ? null : streetController.text.trim(),
          houseNumber: houseNumberController.text.trim().isEmpty ? null : houseNumberController.text.trim(),
          zipCode: zipCodeController.text.trim().isEmpty ? null : zipCodeController.text.trim(),
          city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
          country: countryController.text.trim().isEmpty ? null : countryController.text.trim(),
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          website: websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
          alias: aliasController.text.trim().isEmpty ? null : aliasController.text.trim(),
          useAliasOnLabels: _useAliasOnLabels,
          placeId: _selectedPlaceId,
          latitude: finalLat,
          longitude: finalLng,
          formattedAddress: _selectedFormattedAddress,
          googlePhone: _googlePhone,
          googleWebsite: _googleWebsite,
          isGeocoded: _selectedLatitude != null && _selectedLongitude != null,
          lastGeocoded: _selectedLatitude != null ? DateTime.now() : null,
          color: theme.info, // Theme Info Farbe statt Hardcoded Blue
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _customerService.createCustomer(newCustomer);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: getAdaptiveIcon(
                      iconName: 'check_circle',
                      defaultIcon: Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Kunde "${nameController.text}" wurde angelegt'),
                ],
              ),
              backgroundColor: theme.success, // Theme Success
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // ===== BESTEHENDEN KUNDEN AKTUALISIEREN =====

        final updatedCustomer = widget.customer!.copyWith(
          name: nameController.text.trim(),
          street: streetController.text.trim().isEmpty ? null : streetController.text.trim(),
          houseNumber: houseNumberController.text.trim().isEmpty ? null : houseNumberController.text.trim(),
          zipCode: zipCodeController.text.trim().isEmpty ? null : zipCodeController.text.trim(),
          city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
          country: countryController.text.trim().isEmpty ? null : countryController.text.trim(),
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          website: websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
          alias: aliasController.text.trim().isEmpty ? null : aliasController.text.trim(),
          useAliasOnLabels: _useAliasOnLabels,
          placeId: _selectedPlaceId,
          latitude: finalLat,
          longitude: finalLng,
          formattedAddress: _selectedFormattedAddress,
          googlePhone: _googlePhone,
          googleWebsite: _googleWebsite,
          isGeocoded: finalLat != null && finalLng != null,
          lastGeocoded: finalLat != null ? DateTime.now() : null,
          updatedAt: DateTime.now(),
        );

        await _customerService.updateCustomer(updatedCustomer);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: getAdaptiveIcon(
                      iconName: 'check_circle',
                      defaultIcon: Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Kunde wurde aktualisiert'),
                ],
              ),
              backgroundColor: theme.success, // Theme Success
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: theme.error, // Theme Error
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ===== THEME INTEGRATION =====
    final theme = context.watch<ThemeProvider>();

    final isWebMobile = kIsWeb && MediaQuery.of(context).size.width < 600;
    final isDialog = context.findAncestorWidgetOfExactType<Dialog>() != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isWebMobile ? 0 : MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: isDialog ? null : MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.surface, // Theme Surface
            borderRadius: isDialog
                ? BorderRadius.circular(12)
                : const BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: Column(
            mainAxisSize: isDialog ? MainAxisSize.min : MainAxisSize.max,
            children: [
              // Griff-Indikator nur bei BottomSheet
              if (!isDialog)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.border, // Theme Border
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.divider, // Theme Divider
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.1), // Theme Primary Opacity
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: getAdaptiveIcon(
                              iconName: widget.isEdit ? 'edit' : 'person_add',
                              defaultIcon: widget.isEdit ? Icons.edit : Icons.person_add,
                              color: theme.primary, // Theme Primary
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isEdit ? 'Kunde bearbeiten' : 'Neuer Kunde',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textPrimary, // Theme Text
                                  ),
                                ),
                                if (widget.isEdit && widget.customer != null)
                                  Text(
                                    widget.customer!.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textSecondary, // Theme Text Secondary
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: getAdaptiveIcon(
                        iconName: 'close',
                        defaultIcon: Icons.close,
                        color: theme.textPrimary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.background, // Theme Background
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        isWebMobile ? 140 : 120,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Grunddaten
                          _buildSectionTitle('Grunddaten', Icons.business, 'business', theme),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: nameController,
                            label: 'Firma/Name*',
                            autofocus: !widget.isEdit && !isWebMobile,
                            textInputAction: TextInputAction.next,
                            theme: theme,
                          ),



                          // const SizedBox(height: 20),
                          //
                          // // Alias
                          // _buildTextField(
                          //   controller: aliasController,
                          //   label: 'Alias (Deckname)',
                          //   textInputAction: TextInputAction.next,
                          //   theme: theme,
                          //   prefixIcon: Container(
                          //     margin: const EdgeInsets.all(12),
                          //     padding: const EdgeInsets.all(8),
                          //     decoration: BoxDecoration(
                          //       color: theme.primary.withOpacity(0.1), // Theme
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //     child: getAdaptiveIcon(
                          //       iconName: 'badge',
                          //       defaultIcon: Icons.badge,
                          //       size: 18,
                          //       color: theme.primary, // Theme
                          //     ),
                          //   ),
                          // ),
                          //
                          // const SizedBox(height: 12),
                          //
                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: theme.background, // Theme
                          //     borderRadius: BorderRadius.circular(12),
                          //     border: Border.all(color: theme.border), // Theme
                          //   ),
                          //   child: CheckboxListTile(
                          //     value: _useAliasOnLabels,
                          //     onChanged: (value) {
                          //       setState(() => _useAliasOnLabels = value ?? false);
                          //     },
                          //     title: Text(
                          //       'Alias auf Paketzetteln verwenden',
                          //       style: TextStyle(
                          //           fontSize: 14,
                          //           fontWeight: FontWeight.w500,
                          //           color: theme.textPrimary // Theme
                          //       ),
                          //     ),
                          //     subtitle: Text(
                          //       'Wenn aktiviert, wird der Alias anstelle des Firmennamens gedruckt',
                          //       style: TextStyle(fontSize: 12, color: theme.textSecondary),
                          //     ),
                          //     activeColor: theme.primary, // Theme
                          //     checkColor: theme.textOnPrimary,
                          //     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          //   ),
                          // ),

                          const SizedBox(height: 24),

                          // Adresse
                          _buildSectionTitle('Adresse', Icons.location_on, 'location_on', theme),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  controller: streetController,
                                  label: 'Straße',
                                  textInputAction: TextInputAction.next,
                                  theme: theme,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: houseNumberController,
                                  label: 'Nr.',
                                  textInputAction: TextInputAction.next,
                                  theme: theme,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: zipCodeController,
                                  label: 'PLZ',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  theme: theme,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  controller: cityController,
                                  label: 'Ort',
                                  textInputAction: TextInputAction.next,
                                  theme: theme,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: countryController,
                            label: 'Land',
                            textInputAction: TextInputAction.next,
                            theme: theme,
                          ),
                          const SizedBox(height: 16),

                          // Geo-Koordinaten
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: latitudeController,
                                  label: 'Breitengrad (Latitude)',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  textInputAction: TextInputAction.next,
                                  theme: theme,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: longitudeController,
                                  label: 'Längengrad (Longitude)',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  textInputAction: TextInputAction.next,
                                  theme: theme,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Kontakt
                          _buildSectionTitle('Kontakt', Icons.contact_phone, 'contact_phone', theme),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: phoneController,
                            label: 'Telefon',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            theme: theme,
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.info.withOpacity(0.1), // Theme Info
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: getAdaptiveIcon(
                                iconName: 'phone',
                                defaultIcon: Icons.phone,
                                size: 18,
                                color: theme.info, // Theme Info
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: emailController,
                            label: 'E-Mail',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            theme: theme,
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primary.withOpacity(0.1), // Theme Variant
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: getAdaptiveIcon(
                                iconName: 'email',
                                defaultIcon: Icons.email,
                                size: 18,
                                color: theme.primary, // Theme Variant
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: websiteController,
                            label: 'Website',
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            theme: theme,
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.success.withOpacity(0.1), // Theme Success
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: getAdaptiveIcon(
                                iconName: 'language',
                                defaultIcon: Icons.language,
                                size: 18,
                                color: theme.success, // Theme Success
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Notizen
                          _buildSectionTitle('Notizen', Icons.note, 'note', theme),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: notesController,
                            label: 'Notizen',
                            maxLines: 4,
                            alignLabelWithHint: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _saveCustomer(),
                            theme: theme,
                          ),
                        ],
                      ),
                    ),

                    // Fixed Action Buttons
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 24,
                          bottom: isWebMobile ? 24 : MediaQuery.of(context).padding.bottom + 24,
                        ),
                        decoration: BoxDecoration(
                          color: theme.surface, // Theme
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.surface.withOpacity(0.0),
                              theme.surface.withOpacity(0.8),
                              theme.surface,
                            ],
                            stops: const [0.0, 0.2, 0.3],
                          ),
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: theme.border), // Theme Border
                                    backgroundColor: theme.surface, // Theme Surface
                                  ),
                                  child: Text(
                                    'Abbrechen',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.textSecondary, // Theme Text Secondary
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveCustomer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primary, // Theme Primary
                                    foregroundColor: theme.textOnPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: theme.textOnPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      getAdaptiveIcon(
                                        iconName: 'save',
                                        defaultIcon: Icons.save,
                                        size: 20,
                                        color: theme.textOnPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.isEdit ? 'Speichern' : 'Anlegen',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeProvider theme, // Colors übergeben
    int maxLines = 1,
    bool alignLabelWithHint = false,
    bool autofocus = false,
    Widget? prefixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onFieldSubmitted,
      style: TextStyle(color: theme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textSecondary),
        alignLabelWithHint: alignLabelWithHint,
        filled: true,
        fillColor: theme.background, // Theme Background
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border), // Theme Border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border), // Theme Border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primary, width: 2), // Theme Primary
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, String iconName, ThemeProvider theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.1), // Theme
            borderRadius: BorderRadius.circular(8),
          ),
          child: getAdaptiveIcon(
            iconName: iconName,
            defaultIcon: icon,
            size: 16,
            color: theme.primary, // Theme
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textSecondary, // Theme
          ),
        ),
      ],
    );
  }
}
