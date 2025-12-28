// ═══════════════════════════════════════════════════════════════════════════
// lib/shared/sections/section_container.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

/// Ein Container-Widget für Sektionen mit optionalem Header
///
/// [title] - Titel der Sektion (optional, für Header)
/// [icon] - Icon für den Header (optional)
/// [iconName] - Icon-Name für adaptive Icons (optional)
/// [showHeader] - Zeigt den Header an (default: false)
/// [children] - Inhalt der Sektion
class SectionContainer extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final String? iconName;
  final bool showHeader;
  final List<Widget> children;

  const SectionContainer({
    super.key,
    this.title,
    this.icon,
    this.iconName,
    this.showHeader = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader && title != null)
            _buildHeader(theme),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.primary,
              ),
            ),
          if (icon != null) const SizedBox(width: 12),
          Text(
            title ?? '',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}