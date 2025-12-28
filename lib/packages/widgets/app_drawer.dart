// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';


class AppDrawer extends StatefulWidget {
  final String userName;
  final int userGroup;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userGroup,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = info.version);
      }
    } catch (e) {
      // Fallback wenn PackageInfo nicht verfügbar
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Drawer(
      backgroundColor: theme.surface,
      child: Column(
        children: [
          // Header mit Logo
          _buildHeader(theme),

          Divider(height: 1, color: theme.border),

          // Menü-Items (aktuell leer)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Hier kommen später die Menü-Items
              ],
            ),
          ),

          // Footer mit Version
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Image.asset(
            theme.isDarkMode ? 'assets/images/logo_w.png' : 'assets/images/logo.png',
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildFallbackLogo(theme),
          ),
          const SizedBox(height: 16),

          // Begrüßung
          Text(
            'Hallo, ${widget.userName}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getUserGroupLabel(widget.userGroup),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo(ThemeProvider theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SCHAIBLE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: theme.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 24,
          color: theme.primary,
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeProvider theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            _version != null ? 'Version $_version' : 'Sägewerk',
            style: TextStyle(
              fontSize: 12,
              color: theme.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserGroupLabel(int userGroup) {
    switch (userGroup) {
      case 1:
        return 'Säger';
      case 2:
        return 'Büro';
      case 3:
        return 'Administrator';
      default:
        return 'Benutzer';
    }
  }
}