import 'package:flutter/material.dart';

/// Zentrale Farbdefinitionen für die Schaible App
abstract class AppColors {
  // ═══════════════════════════════════════════════════════════════
  // BRAND FARBEN (Schaible Türkis)
  // ═══════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF00998B);
  static const Color primaryDark = Color(0xFF007A6F);
  static const Color primaryLight = Color(0xFF4DB8AD);

  // ═══════════════════════════════════════════════════════════════
  // LIGHT MODE
  // ═══════════════════════════════════════════════════════════════
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // ═══════════════════════════════════════════════════════════════
  // DARK MODE
  // ═══════════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // ═══════════════════════════════════════════════════════════════
  // SEMANTISCHE FARBEN
  // ═══════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}