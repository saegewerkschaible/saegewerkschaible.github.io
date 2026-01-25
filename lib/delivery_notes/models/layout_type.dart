// lib/screens/delivery_notes/models/layout_type.dart

import 'package:flutter/material.dart';

/// Responsive breakpoints
class ScreenSize {
  static const double mobile = 600;
  static const double tablet = 1000;
}

/// Layout-Typen für responsive Design
enum LayoutType {
  mobile,
  tablet,
  desktop,
}

/// Extension für einfache Layout-Erkennung
extension LayoutTypeExtension on BuildContext {
  LayoutType get layoutType {
    final width = MediaQuery.of(this).size.width;
    if (width < ScreenSize.mobile) {
      return LayoutType.mobile;
    } else if (width < ScreenSize.tablet) {
      return LayoutType.tablet;
    } else {
      return LayoutType.desktop;
    }
  }

  bool get isMobile => layoutType == LayoutType.mobile;
  bool get isTablet => layoutType == LayoutType.tablet;
  bool get isDesktop => layoutType == LayoutType.desktop;
}