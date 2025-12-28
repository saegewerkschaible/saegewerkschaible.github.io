// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/sections/location_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/packages/fields/select_field.dart';
import '../../core/theme/theme_provider.dart';

import '../services/package_service.dart';

class LocationSection extends StatefulWidget {
  final TextEditingController controller;
  final PackageService packageService;
  final bool isInvalid;
  final ValueChanged<String>? onChanged;

  const LocationSection({
    super.key,
    required this.controller,
    required this.packageService,
    this.isInvalid = false,
    this.onChanged,
  });

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('locations')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: theme.primary),
            ),
          );
        }

        List<String> locations = snapshot.data!.docs
            .map((doc) => doc['name'] as String)
            .toList();

        return
          SelectField(
          label: 'Lagerort',
          controller: widget.controller,
          options: locations,
          icon: Icons.warehouse,
          iconName: 'warehouse',
          isInvalid: widget.isInvalid,
          onTap: () => _showLocationBottomSheet(
            context: context,
            locations: locations,
            theme: theme,
          ),
        );
      },
    );
  }

  void _showLocationBottomSheet({
    required BuildContext context,
    required List<String> locations,
    required ThemeProvider theme,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.warehouse, color: theme.primary),
                const SizedBox(width: 8),
                Text(
                  'Lagerort wählen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Liste
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  final isSelected = widget.controller.text == location;

                  return ListTile(
                    title: Text(
                      location,
                      style: TextStyle(
                        color: isSelected ? theme.primary : theme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: theme.primary)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: isSelected ? theme.primaryLight.withOpacity(0.1) : null,
                    onTap: () {
                      setState(() {
                        widget.controller.text = location;
                      });
                      widget.onChanged?.call(location);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}