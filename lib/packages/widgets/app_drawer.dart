// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/widgets/app_drawer.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/services/auth_service.dart';

import '../../core/theme/theme_provider.dart';
import '../../constants.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final int userGroup;
  final int currentIndex;
  final Function(int) onNavigate;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userGroup,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Drawer(
      backgroundColor: theme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme),

            Divider(height: 1, color: theme.divider),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Nur für Büro (2) und Admin (3)
                  if (userGroup >= 2) ...[
                    _buildNavItem(
                      theme: theme,
                      icon: Icons.qr_code_scanner,
                      label: 'Pakete',
                      index: 0,
                    ),
                    _buildNavItem(
                      theme: theme,
                      icon: Icons.inventory_2,
                      label: 'Lager',
                      index: 1,
                    ),
                    _buildNavItem(
                      theme: theme,
                      icon: Icons.bar_chart,
                      label: 'Statistik',
                      index: 2,
                    ),
                    _buildNavItem(
                      theme: theme,
                      icon: Icons.receipt_long,
                      label: 'Lieferscheine',
                      index: 3,
                    ),
                    _buildNavItem(
                      theme: theme,
                      icon: Icons.shopping_cart,
                      label: 'Warenkorb',
                      index: 4,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(color: theme.divider),
                    ),
                  ],

                  // Info-Bereich
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: theme.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'App Info',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(theme, 'Version', '1.0.0'),
                          _buildInfoRow(theme, 'Benutzer', userName),
                          _buildInfoRow(theme, 'Rolle', getUserGroupName(userGroup)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Divider(height: 1, color: theme.divider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    child: Image.asset(
                      theme.isDarkMode ? 'assets/images/logo_w.png' : 'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Schaible Sägewerk',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person, color: theme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    getUserGroupName(userGroup),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigate(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? theme.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: theme.primary.withOpacity(0.3)) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? theme.primary : theme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? theme.primary : theme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeProvider theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: theme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}