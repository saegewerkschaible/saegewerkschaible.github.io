// ═══════════════════════════════════════════════════════════════════════════
// lib/shared/sections/expandable_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/services/icon_helper.dart';
import '../../core/theme/theme_provider.dart';

class ExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String iconName;
  final Widget child;
  final bool canEdit;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconName,
    required this.child,
    required this.canEdit,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: getAdaptiveIcon(
                iconName: iconName,
                defaultIcon: icon,
                color: theme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: canEdit ? theme.textPrimary : theme.textSecondary,
                ),
              ),
            ),
            if (!canEdit)
              getAdaptiveIcon(
                iconName: 'lock',
                defaultIcon: Icons.lock,
                size: 16,
                color: theme.textSecondary.withOpacity(0.5),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: AbsorbPointer(
              absorbing: !canEdit,
              child: Opacity(
                opacity: canEdit ? 1.0 : 0.7,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}