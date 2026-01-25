// ═══════════════════════════════════════════════════════════════════════════
// lib/screens/home/start_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/customer_management/customer_management_screen.dart';
import 'package:saegewerk/delivery_notes/cart_screen.dart' show CartScreen;
import 'package:saegewerk/delivery_notes/delivery_note_screen.dart';
import 'package:saegewerk/screens/admin/admin_screen.dart';
import 'package:saegewerk/screens/admin/user_management_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../packages/widgets/app_drawer.dart';
import '../../packages/widgets/edit_package_widget.dart';
import '../scanner/scanner_screen.dart';
import '../statistic_screen.dart';
import '../../packages/packages_screen.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../constants.dart';

import '../settings/settings_screen.dart';

class StartScreen extends StatefulWidget {
  static const String id = 'start_screen';
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _authService = AuthService();
  int _currentIndex = 0;
  int _userGroup = 1;
  bool _showBottomNav = true;
  bool _showQuickAccess = false;

  Key _editPackageKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showBottomNav = prefs.getBool('show_bottom_nav') ?? true;
        _showQuickAccess = prefs.getBool('show_quick_access') ?? false;
      });
    }
  }

  void updateBottomNavPreference(bool value) {
    setState(() => _showBottomNav = value);
  }

  void updateQuickAccessPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_quick_access', value);
    setState(() => _showQuickAccess = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _authService.getUserStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Center(
              child: CircularProgressIndicator(color: theme.primary),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Benutzer';
        _userGroup = userData?['userGroup'] ?? 1;

        final bool showFullNavigation = _userGroup >= 2;

        return Scaffold(
          backgroundColor: theme.background,
          drawer: AppDrawer(
            userName: userName,
            userGroup: _userGroup,
            currentIndex: _currentIndex,
            onNavigate: (index) {
              setState(() => _currentIndex = index);
              Navigator.pop(context);
            },
            showQuickAccess: _showQuickAccess,
            onQuickAccessChanged: updateQuickAccessPreference,
          ),
          appBar: _buildAppBar(theme, userName),
          body: showFullNavigation
              ? _buildBodyWithQuickAccess(theme)
              : _buildSaegerBody(theme, userName),
          bottomNavigationBar: (showFullNavigation && _showBottomNav && !_showQuickAccess)
              ? _buildBottomNav(theme)
              : null,
        );
      },
    );
  }

  Widget _buildBodyWithQuickAccess(ThemeProvider theme) {
    final content = _buildBodyForNavigation();

    if (!kIsWeb || !_showQuickAccess) {
      return content;
    }

    return Row(
      children: [
        _buildQuickAccessBar(theme),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildQuickAccessBar(ThemeProvider theme) {
    // Haupt-Navigation Items
    final navItems = [
      _QuickAccessNavItem(icon: Icons.qr_code_scanner, label: 'Pakete', index: 0),
      _QuickAccessNavItem(icon: Icons.inventory_2, label: 'Lager', index: 1),
      _QuickAccessNavItem(icon: Icons.bar_chart, label: 'Statistik', index: 2),
      _QuickAccessNavItem(icon: Icons.receipt_long, label: 'Lieferung', index: 3),
      _QuickAccessNavItem(icon: Icons.shopping_cart, label: 'Warenkorb', index: 4),
    ];

    // Admin Items (nur für userGroup >= 3)
    final adminItems = <_QuickAccessActionItem>[
      if (_userGroup >= 3) ...[
        _QuickAccessActionItem(
          icon: Icons.people,
          label: 'Kundenverwaltung',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _CustomerManagementWrapper(userGroup: _userGroup),
            ),
          ),
        ),
        _QuickAccessActionItem(
          icon: Icons.manage_accounts,
          label: 'Benutzerverwaltung',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserManagementScreen()),
          ),
        ),
        _QuickAccessActionItem(
          icon: Icons.tune,
          label: 'Paketeigenschaften',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminScreen()),
          ),
        ),
      ],
    ];

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          right: BorderSide(color: theme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Haupt-Navigation
          ...navItems.map((item) => _buildQuickAccessNavButton(theme, item)),

          // Divider wenn Admin-Items vorhanden
          if (adminItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Divider(color: theme.border, thickness: 1),
            ),
            // Admin Items
            ...adminItems.map((item) => _buildQuickAccessActionButton(theme, item)),
          ],

          const Spacer(),

          // Logo unten
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 24,
              child: Image.asset(
                theme.isDarkMode ? 'assets/images/logo_w.png' : 'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildQuickAccessNavButton(ThemeProvider theme, _QuickAccessNavItem item) {
    final isSelected = _currentIndex == item.index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _currentIndex = item.index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? theme.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: theme.primary.withOpacity(0.3))
                    : null,
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  color: isSelected ? theme.primary : theme.textSecondary,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessActionButton(ThemeProvider theme, _QuickAccessActionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  color: theme.textSecondary,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeProvider theme, String userName) {
    return AppBar(
      backgroundColor: theme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Builder(
        builder: (context) => GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Row(
            children: [
              SizedBox(
                height: 32,
                child: Image.asset(
                  theme.isDarkMode ? 'assets/images/logo_w.png' : 'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined, color: theme.textPrimary),
          onPressed: () => _showSettings(context),
        ),
      ],
    );
  }

  Widget _buildBodyForNavigation() {
    switch (_currentIndex) {
      case 0:
        return ScannerScreen(userGroup: _userGroup);
      case 1:
        return PackagesScreen(userGroup: _userGroup);
      case 2:
        return StatisticsScreen(userGroup: _userGroup);
      case 3:
        return DeliveryNoteScreen();
      case 4:
        return CartScreen(userGroup: _userGroup);
      default:
        return ScannerScreen(userGroup: _userGroup);
    }
  }

  Widget _buildBottomNav(ThemeProvider theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    const int itemCount = 5;
    const double itemWidth = 72.0;
    const double totalItemsWidth = itemCount * itemWidth;

    final bool needsScroll = screenWidth < totalItemsWidth + 32;

    final navItems = Row(
      mainAxisAlignment: needsScroll ? MainAxisAlignment.start : MainAxisAlignment.center,
      mainAxisSize: needsScroll ? MainAxisSize.min : MainAxisSize.max,
      children: [
        _buildNavItem(theme: theme, icon: Icons.qr_code_scanner, label: 'Pakete', index: 0),
        _buildNavItem(theme: theme, icon: Icons.inventory_2, label: 'Lager', index: 1),
        _buildNavItem(theme: theme, icon: Icons.bar_chart, label: 'Statistik', index: 2),
        _buildNavItem(theme: theme, icon: Icons.receipt_long, label: 'Lieferung', index: 3),
        _buildNavItem(theme: theme, icon: Icons.shopping_cart, label: 'Warenkorb', index: 4),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: needsScroll
              ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: navItems,
          )
              : navItems,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? theme.primary : theme.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.primary : theme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaegerBody(ThemeProvider theme, String userName) {
    return EditPackageWidget(
      key: _editPackageKey,
      packageData: null,
      userGroup: _userGroup,
      isNewPackage: true,
      isEmbedded: true,
      onSaved: (success) {
        if (success) {
          setState(() => _editPackageKey = UniqueKey());
        }
      },
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsScreen(
        onBottomNavChanged: updateBottomNavPreference,
      ),
    );
  }
}

// Hilfsklasse für Navigation Items (mit Index)
class _QuickAccessNavItem {
  final IconData icon;
  final String label;
  final int index;

  const _QuickAccessNavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

// Hilfsklasse für Action Items (mit onTap Callback)
class _QuickAccessActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

// Wrapper für Kundenverwaltung
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