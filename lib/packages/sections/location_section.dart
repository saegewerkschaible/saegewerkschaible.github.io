// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/sections/location_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

import '../services/package_service.dart';

class LocationSection extends StatefulWidget {
  final TextEditingController controller;
  final PackageService packageService;
  final bool isInvalid;
  final ValueChanged<String>? onChanged;

  // Pin-Properties
  final bool isPinned;
  final VoidCallback onTogglePin;

  const LocationSection({
    super.key,
    required this.controller,
    required this.packageService,
    this.isInvalid = false,
    this.onChanged,
    this.isPinned = false,
    required this.onTogglePin,
  });

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('locations').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: theme.primary),
            ),
          );
        }

        List<String> locations =
        snapshot.data!.docs.map((doc) => doc['name'] as String).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label-Zeile mit Pin-Button
            Row(
              children: [
                Icon(Icons.warehouse, size: 16, color: theme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Lagerort',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                ),
                const Spacer(),
                _PinButton(
                  isPinned: widget.isPinned,
                  onToggle: widget.onTogglePin,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lagerort-Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: locations.map((location) {
                final isSelected = widget.controller.text == location;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.controller.text = location;
                    });
                    widget.onChanged?.call(location);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.primary
                          : widget.isPinned
                          ? theme.primary.withOpacity(0.05)
                          : theme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.primary
                            : widget.isPinned
                            ? theme.primary
                            : theme.border,
                        width: isSelected || widget.isPinned ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected && widget.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        Text(
                          location,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color:
                            isSelected ? Colors.white : theme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// Pin-Button Widget
class _PinButton extends StatelessWidget {
  final bool isPinned;
  final VoidCallback onToggle;

  const _PinButton({
    required this.isPinned,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPinned ? theme.primary : theme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPinned ? theme.primary : theme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 14,
              color: isPinned ? Colors.white : theme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              isPinned ? 'Gepinnt' : 'Pinnen',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPinned ? Colors.white : theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}