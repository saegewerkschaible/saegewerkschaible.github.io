// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/widgets/app_drawer.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saegewerk/customer_management/customer_management_screen.dart';
import 'package:saegewerk/screens/admin/paketzettel_design_screen.dart';
import 'package:saegewerk/services/auth_service.dart';

import '../../core/theme/theme_provider.dart';
import '../../constants.dart';
import '../../screens/admin/admin_screen.dart';
import '../../screens/admin/user_management_screen.dart';

class AppDrawer extends StatefulWidget {
  final String userName;
  final int userGroup;
  final int currentIndex;
  final Function(int) onNavigate;
  final bool showQuickAccess;
  final Function(bool)? onQuickAccessChanged;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userGroup,
    required this.currentIndex,
    required this.onNavigate,
    this.showQuickAccess = false,
    this.onQuickAccessChanged,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Drawer(
      backgroundColor: theme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Divider(height: 1, color: theme.divider),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Quick-Access Toggle (nur auf Web)
                  if (kIsWeb && widget.userGroup >= 2)
                    _buildQuickAccessToggle(context, theme),

                  // Haupt-Navigation
                  if (widget.userGroup >= 2) ...[
                    _buildNavItem(theme: theme, icon: Icons.qr_code_scanner, label: 'Pakete', index: 0),
                    _buildNavItem(theme: theme, icon: Icons.inventory_2, label: 'Lager', index: 1),
                    _buildNavItem(theme: theme, icon: Icons.bar_chart, label: 'Statistik', index: 2),
                    _buildNavItem(theme: theme, icon: Icons.receipt_long, label: 'Lieferscheine', index: 3),
                    _buildNavItem(theme: theme, icon: Icons.shopping_cart, label: 'Warenkorb', index: 4),
                  ],

                  // Admin-Bereich
                  if (widget.userGroup >= 3) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(color: theme.divider),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'VERWALTUNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildActionItem(
                      context: context,
                      theme: theme,
                      icon: Icons.people,
                      label: 'Kundenverwaltung',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _CustomerManagementWrapper(userGroup: widget.userGroup),
                          ),
                        );
                      },
                    ),
                    _buildActionItem(
                      context: context,
                      theme: theme,
                      icon: Icons.manage_accounts,
                      label: 'Benutzerverwaltung',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                        );
                      },
                    ),
                    _buildActionItemWithSubtitle(
                      context: context,
                      theme: theme,
                      icon: Icons.tune,
                      label: 'Paketeigenschaften',
                      subtitle: 'Holzarten, Lagerorte, Maße',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminScreen()),
                        );
                      },
                    ),
                    _buildActionItemWithSubtitle(
                      context: context,
                      theme: theme,
                      icon: Icons.receipt_long,
                      label: 'Design Paketzettel',
                      subtitle: 'Schriftgrößen, Logos anpassen',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaketzettelDesignScreen()),
                        );
                      },
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
                                style: TextStyle(fontWeight: FontWeight.w600, color: theme.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(theme, 'Version', _appVersion),
                          _buildInfoRow(theme, 'Benutzer', widget.userName),
                          _buildInfoRow(theme, 'Rolle', getUserGroupName(widget.userGroup)),
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
                    style: TextStyle(fontSize: 14, color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessToggle(BuildContext context, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.dock, color: theme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick-Access-Leiste',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textPrimary,
                    ),
                  ),
                  Text(
                    'Seitenleiste mit Icons',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: widget.showQuickAccess,
              onChanged: (value) {
                widget.onQuickAccessChanged?.call(value);
                Navigator.pop(context);
              },
              activeColor: theme.primary,
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
                  widget.userName,
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
                    getUserGroupName(widget.userGroup),
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
    final isSelected = widget.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onNavigate(index),
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
                Icon(icon, color: isSelected ? theme.primary : theme.textSecondary, size: 22),
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
                    decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: theme.textSecondary, size: 22),
                const SizedBox(width: 16),
                Text(label, style: TextStyle(fontSize: 15, color: theme.textPrimary)),
                const Spacer(),
                Icon(Icons.chevron_right, color: theme.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItemWithSubtitle({
    required BuildContext context,
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: theme.textSecondary, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 15, color: theme.textPrimary)),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.textSecondary, size: 20),
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
          Text(label, style: TextStyle(fontSize: 13, color: theme.textSecondary)),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _CustomerManagementWrapper extends StatelessWidget {
  final int userGroup;

  const _CustomerManagementWrapper({required this.userGroup});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kundenverwaltung',
          style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomerManagementScreen(userGroup: userGroup),
    );
  }
}