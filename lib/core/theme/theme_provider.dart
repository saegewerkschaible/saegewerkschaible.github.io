// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'dark_mode';

  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  // ═══════════════════════════════════════════════════════════════
  // COLORS WRAPPER (für Kompatibilität mit Filter-System)
  // ═══════════════════════════════════════════════════════════════

  /// Ermöglicht Zugriff via `theme.colors.primary` (Kompatibilität)
  /// oder direkt via `theme.primary`
  ThemeColors get colors => ThemeColors(this);

  // ═══════════════════════════════════════════════════════════════
  // AKTUELLE FARBEN (basierend auf Theme)
  // ═══════════════════════════════════════════════════════════════

  Color get primary => AppColors.primary;
  Color get primaryDark => AppColors.primaryDark;
  Color get primaryLight => AppColors.primaryLight;

  Color get background => _isDarkMode
      ? AppColors.darkBackground
      : AppColors.lightBackground;

  Color get surface => _isDarkMode
      ? AppColors.darkSurface
      : AppColors.lightSurface;

  Color get textPrimary => _isDarkMode
      ? AppColors.darkTextPrimary
      : AppColors.lightTextPrimary;

  Color get textSecondary => _isDarkMode
      ? AppColors.darkTextSecondary
      : AppColors.lightTextSecondary;

  Color get textOnPrimary => Colors.white;

  Color get textHint => _isDarkMode
      ? Colors.white.withOpacity(0.3)
      : Colors.black.withOpacity(0.3);

  Color get border => _isDarkMode
      ? Colors.white.withOpacity(0.1)
      : Colors.black.withOpacity(0.1);

  Color get divider => _isDarkMode
      ? Colors.white.withOpacity(0.05)
      : Colors.black.withOpacity(0.05);

  Color get shadow => _isDarkMode
      ? Colors.black.withOpacity(0.3)
      : Colors.black.withOpacity(0.08);

  // Semantische Farben
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get error => AppColors.error;
  Color get info => AppColors.info;

  // ═══════════════════════════════════════════════════════════════
  // ZUSTANDS-FARBEN (für Pakete: frisch, trocken, etc.)
  // ═══════════════════════════════════════════════════════════════

  Map<String, Color> get stateColors => {
    'frisch': AppColors.info,
    'trocken': AppColors.success,
    'verarbeitet': AppColors.warning,
  };

  // ═══════════════════════════════════════════════════════════════
  // INITIALISIERUNG
  // ═══════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefsKey) ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // THEME WECHSELN
  // ═══════════════════════════════════════════════════════════════

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isDarkMode);
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;

    _isDarkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isDarkMode);
  }

  // ═══════════════════════════════════════════════════════════════
  // FLUTTER THEME DATA
  // ═══════════════════════════════════════════════════════════════

  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: divider,
      colorScheme: ColorScheme(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: textOnPrimary,
        secondary: primaryLight,
        onSecondary: textOnPrimary,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME COLORS WRAPPER
// Ermöglicht `theme.colors.primary` Syntax für Kompatibilität
// ═══════════════════════════════════════════════════════════════════════════

class ThemeColors {
  final ThemeProvider _provider;

  ThemeColors(this._provider);

  Color get primary => _provider.primary;
  Color get primaryDark => _provider.primaryDark;
  Color get primaryLight => _provider.primaryLight;
  Color get background => _provider.background;
  Color get surface => _provider.surface;
  Color get textPrimary => _provider.textPrimary;
  Color get textSecondary => _provider.textSecondary;
  Color get textOnPrimary => _provider.textOnPrimary;
  Color get textHint => _provider.textHint;
  Color get border => _provider.border;
  Color get divider => _provider.divider;
  Color get shadow => _provider.shadow;
  Color get success => _provider.success;
  Color get warning => _provider.warning;
  Color get error => _provider.error;
  Color get info => _provider.info;
  Map<String, Color> get stateColors => _provider.stateColors;
}