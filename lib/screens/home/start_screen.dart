// ═══════════════════════════════════════════════════════════════════════════
// lib/screens/home/start_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/packages/widgets/app_drawer.dart';
import 'package:saegewerk/screens/scanner/scanner_screen.dart';
import 'package:saegewerk/screens/statistic_screen.dart';

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

        // Büro (2) und Admin (3) bekommen Scanner + Statistik
        final bool showFullNavigation = _userGroup >= 2;

        return Scaffold(
          backgroundColor: theme.background,
          drawer: AppDrawer(
            userName: userName,
            userGroup: _userGroup,
          ),
          appBar: _buildAppBar(theme, userName),
          body: showFullNavigation
              ? _buildBodyForNavigation()
              : _buildSimpleBody(theme, userName),
          bottomNavigationBar: showFullNavigation
              ? _buildBottomNav(theme)
              : null,
        );
      },
    );
  }

  AppBar _buildAppBar(ThemeProvider theme, String userName) {
    String title;
    switch (_currentIndex) {
      case 0:
        title = _userGroup >= 2 ? 'Pakete' : 'Hallo, $userName!';
        break;
      case 1:
        title = 'Statistik';
        break;
      case 2:
        title = 'Einstellungen';
        break;
      default:
        title = 'Sägewerk';
    }

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
              _buildNavItem(
                theme: theme,
                icon: Icons.qr_code_scanner,
                label: 'Pakete',
                index: 0,
              ),
              _buildNavItem(
                theme: theme,
                icon: Icons.bar_chart,
                label: 'Statistik',
                index: 1,
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.primary : theme.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.primary : theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Für Säger (userGroup 1) - einfache Ansicht ohne BottomNav
  Widget _buildSimpleBody(ThemeProvider theme, String userName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hallo, $userName!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            getUserGroupName(_userGroup),
            style: TextStyle(
              fontSize: 16,
              color: theme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // Einfaches Grid für Säger
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildSimpleMenuCard(
                theme: theme,
                icon: Icons.qr_code_scanner,
                title: 'Scannen',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScannerScreen(
                      userGroup: _userGroup,
                      showBackButton: true,
                    ),
                  ),
                ),
              ),
              _buildSimpleMenuCard(
                theme: theme,
                icon: Icons.add_box,
                title: 'Neues Paket',
                isHighlighted: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScannerScreen(
                      userGroup: _userGroup,
                      showBackButton: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMenuCard({
    required ThemeProvider theme,
    required IconData icon,
    required String title,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isHighlighted ? theme.primaryLight : theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted ? theme.primary : theme.border,
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: theme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsScreen(),
    );
  }
}