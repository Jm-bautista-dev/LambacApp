import 'package:flutter/material.dart';

/// Ultra-Subtle Ambient Shadows (Soft Apple / Dribbble styling)
class AppShadows {
  AppShadows._();

  /// Subtle ambient elevation for flat cards
  static List<BoxShadow> get cardLight => [
        BoxShadow(
          color: const Color(0xFF1A1412).withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF1A1412).withOpacity(0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Elevated card shadow (dropdowns, popovers, active cards)
  static List<BoxShadow> get elevatedLight => [
        BoxShadow(
          color: const Color(0xFF1A1412).withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF1A1412).withOpacity(0.03),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Floating button / Modal sheet shadow
  static List<BoxShadow> get floatingLight => [
        BoxShadow(
          color: const Color(0xFF1A1412).withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  /// Subtle card shadow for Dark mode
  static List<BoxShadow> get cardDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  /// Elevated shadow for Dark mode
  static List<BoxShadow> get elevatedDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.6),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
