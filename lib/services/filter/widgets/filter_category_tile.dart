// lib/services/filter/widgets/filter_category_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';


import '../../../services/icon_helper.dart';

class FilterCategoryTile extends StatelessWidget {
  final IconData icon;
  final String iconName;
  final String title;
  final Widget child;
  final bool hasActiveFilters;
  final bool showQuickFilterStar;
  final bool isQuickFilterActive;
  final VoidCallback? onQuickFilterToggle;

  const FilterCategoryTile({
    Key? key,
    required this.icon,
    required this.iconName,
    required this.title,
    required this.child,
    this.hasActiveFilters = false,
    this.showQuickFilterStar = false,
    this.isQuickFilterActive = false,
    this.onQuickFilterToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasActiveFilters
              ? colors.primaryLight
              : colors.textSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: getAdaptiveIcon(
          iconName: iconName,
          defaultIcon: icon,
          size: 20,
          color: hasActiveFilters ? colors.primary : colors.textSecondary,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight:
                hasActiveFilters ? FontWeight.bold : FontWeight.normal,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (showQuickFilterStar && onQuickFilterToggle != null)
            _QuickFilterStar(
              isActive: isQuickFilterActive,
              onToggle: onQuickFilterToggle!,
            ),
        ],
      ),
      iconColor: colors.textSecondary,
      collapsedIconColor: colors.textSecondary,
      backgroundColor: colors.surface,
      collapsedBackgroundColor: colors.surface,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      ],
    );
  }
}

class _QuickFilterStar extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const _QuickFilterStar({
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return IconButton(
      icon: Icon(
        isActive ? Icons.star : Icons.star_border,
        color: isActive ? colors.warning : colors.textHint,
        size: 20,
      ),
      onPressed: onToggle,
      tooltip: isActive
          ? 'Von Schnellfilter entfernen'
          : 'Zu Schnellfilter hinzufügen',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}