// ═══════════════════════════════════════════════════════════════════════════
// lib/screens/home/start_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../packages/widgets/app_drawer.dart';
import '../../packages/widgets/edit_package_widget.dart';
import '../scanner/scanner_screen.dart';
import '../statistic_screen.dart';
import '../packages/packages_screen.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../constants.dart';

import '../admin/user_management_screen.dart';
import '../admin/admin_screen.dart';
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

  // Key für EditPackageWidget Reset
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
      });
    }
  }

  void updateBottomNavPreference(bool value) {
    setState(() {
      _showBottomNav = value;
    });
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

        // Büro (2) und Admin (3) bekommen volle Navigation
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
          ),
          appBar: _buildAppBar(theme, userName),
          body: showFullNavigation
              ? _buildBodyForNavigation()
              : _buildSaegerBody(theme, userName),
          bottomNavigationBar: (showFullNavigation && _showBottomNav)
              ? _buildBottomNav(theme)
              : null,
        );
      },
    );
  }

  AppBar _buildAppBar(ThemeProvider theme, String userName) {
    final titles = ['Pakete', 'Lager', 'Statistik'];

    // Für Säger: "Neues Paket" als Titel
    final title = _userGroup >= 2 ? titles[_currentIndex] : 'Neues Paket';

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
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_userGroup >= 3)
          IconButton(
            icon: Icon(Icons.settings, color: theme.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            ),
          ),
        if (_userGroup >= 3)
          IconButton(
            icon: Icon(Icons.people_outline, color: theme.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserManagementScreen()),
            ),
          ),
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
      default:
        return ScannerScreen(userGroup: _userGroup);
    }
  }

  Widget _buildBottomNav(ThemeProvider theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(theme: theme, icon: Icons.qr_code_scanner, label: 'Pakete', index: 0),
              _buildNavItem(theme: theme, icon: Icons.inventory_2, label: 'Lager', index: 1),
              _buildNavItem(theme: theme, icon: Icons.bar_chart, label: 'Statistik', index: 2),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.primary : theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SÄGER BODY - Direkt EditPackageWidget
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSaegerBody(ThemeProvider theme, String userName) {
    return EditPackageWidget(
      key: _editPackageKey,
      packageData: null,
      userGroup: _userGroup,
      isNewPackage: true,
      isEmbedded: true, // Neuer Parameter für eingebetteten Modus
      onSaved: (success) {
        if (success) {
          // Widget neu laden für nächstes Paket
          setState(() {
            _editPackageKey = UniqueKey();
          });
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