// lib/screens/CustomerManagement/dialogs/contact_person_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/services/icon_helper.dart';


class ContactPersonDialog extends StatefulWidget {
  final String customerId;
  final String? contactId;
  final Map<String, dynamic>? contactData;

  const ContactPersonDialog({
    Key? key,
    required this.customerId,
    this.contactId,
    this.contactData,
  }) : super(key: key);

  @override
  State<ContactPersonDialog> createState() => _ContactPersonDialogState();
}

class _ContactPersonDialogState extends State<ContactPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contactData != null) {
      _nameController.text = widget.contactData!['name'] ?? '';
      _phoneController.text = widget.contactData!['phone'] ?? '';
      _emailController.text = widget.contactData!['email'] ?? '';
      _positionController.text = widget.contactData!['position'] ?? '';
      _isPrimary = widget.contactData!['isPrimary'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isEditing = widget.contactId != null;

    return Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: getAdaptiveIcon(
                        iconName: isEditing ? 'edit' : 'person_add',
                        defaultIcon: isEditing ? Icons.edit : Icons.person_add,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'Ansprechpartner bearbeiten'
                            : 'Ansprechpartner hinzufügen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: theme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: theme.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: theme.background,
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Bitte Name eingeben' : null,
                ),
                const SizedBox(height: 16),

                // Position
                TextFormField(
                  controller: _positionController,
                  style: TextStyle(color: theme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Position/Rolle',
                    labelStyle: TextStyle(color: theme.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: theme.background,
                  ),
                ),
                const SizedBox(height: 16),

                // Telefon
                TextFormField(
                  controller: _phoneController,
                  style: TextStyle(color: theme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Telefon',
                    labelStyle: TextStyle(color: theme.textSecondary),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: getAdaptiveIcon(
                        iconName: 'phone',
                        defaultIcon: Icons.phone,
                        color: theme.textSecondary,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: theme.background,
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: theme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'E-Mail',
                    labelStyle: TextStyle(color: theme.textSecondary),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: getAdaptiveIcon(
                        iconName: 'email',
                        defaultIcon: Icons.email,
                        color: theme.textSecondary,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: theme.background,
                  ),
                ),
                const SizedBox(height: 16),

                // Haupt-Ansprechpartner Checkbox
                Container(
                  decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.border),
                  ),
                  child: CheckboxListTile(
                    value: _isPrimary,
                    onChanged: (value) {
                      setState(() => _isPrimary = value ?? false);
                    },
                    title: Text(
                      'Haupt-Ansprechpartner',
                      style: TextStyle(color: theme.textPrimary),
                    ),
                    subtitle: Text(
                      'Wird bei neuen Projekten vorausgewählt',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                    activeColor: theme.primary,
                    checkColor: theme.textOnPrimary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Abbrechen',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.textOnPrimary,
                        disabledBackgroundColor: theme.textSecondary.withOpacity(0.5),   ),
                      child: _isLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.textOnPrimary,
                        ),
                      )
                          : Text(isEditing ? 'Speichern' : 'Hinzufügen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'position': _positionController.text,
        'isPrimary': _isPrimary,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final contactsRef = FirebaseFirestore.instance

          .collection('customers')
          .doc(widget.customerId)
          .collection('contacts');

      if (widget.contactId == null) {
        await contactsRef.add(data);
      } else {
        await contactsRef.doc(widget.contactId).update(data);
      }

      if (mounted) {
     final theme = context.read<ThemeProvider>();   Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.contactId == null
                ? 'Ansprechpartner wurde hinzugefügt'
                : 'Ansprechpartner wurde aktualisiert'),
            backgroundColor: theme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
     final theme = context.read<ThemeProvider>();   ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}