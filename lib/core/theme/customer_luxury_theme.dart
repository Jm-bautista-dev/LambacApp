import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';

/// Customer Luxury Editorial Design System
/// Combines Apple-grade minimalism, luxury editorial coffee typography,
/// and warm tactile coffee roastery tones.
class CustomerLuxuryTheme {
  CustomerLuxuryTheme._();

  // ---------------------------------------------------------------------------
  // 60/30/10 Curated Coffee Roastery Color Harmony
  // ---------------------------------------------------------------------------

  /// 60% Warm Neutral Canvas (Light: Warm Oat Cream, Dark: Roasted Sumi Obsidian)
  static const Color lightOatCanvas = Color(0xFFFAF7F2);
  static const Color warmCream = lightOatCanvas;
  static const Color darkRoastCanvas = Color(0xFF12100E);

  /// 30% Supporting Rich Surfaces
  static const Color lightCreamSurface = Color(0xFFF3EFE8);
  static const Color lightElevatedSurface = Color(0xFFFFFFFF);
  static const Color darkEspressoSurface = Color(0xFF1B1714);
  static const Color darkElevatedSurface = Color(0xFF241E1A);

  /// 10% Accents
  static const Color amberGold = Color(0xFFC17A48);
  static const Color amberGoldLight = Color(0xFFD89566);
  static const Color amberGoldDark = Color(0xFFA66033);
  static const Color cremaBronze = Color(0xFFD8A47F);
  static const Color matchaSage = Color(0xFF4E6E5D);

  /// Hairline borders with warm tint
  static const Color borderLight = Color(0xFFE7E0D4);
  static const Color borderDark = Color(0xFF2C241E);

  // ---------------------------------------------------------------------------
  // Editorial Typography Helpers
  // ---------------------------------------------------------------------------

  /// Artisanal Editorial Serif for Signature Moments, Headlines, and Roastery Stories
  static TextStyle editorialDisplay({
    required BuildContext context,
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double height = 1.15,
    double letterSpacing = -0.5,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? defaultColor,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Artisanal Editorial Serif accepting explicit isDark flag
  static TextStyle editorialStyle({
    bool isDark = false,
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double height = 1.2,
    double letterSpacing = -0.3,
  }) {
    final defaultColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? defaultColor,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Refined Modern Sans-Serif for Product Specs, Prices, and Controls
  static TextStyle productHeadline({
    required BuildContext context,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = -0.2,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? defaultColor,
      letterSpacing: letterSpacing,
    );
  }

  /// Elegant Micro Eyebrow / Category Tag
  static TextStyle eyebrow({
    required BuildContext context,
    double fontSize = 10.5,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double letterSpacing = 0.8,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? amberGoldLight : amberGold;

    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? defaultColor,
      letterSpacing: letterSpacing,
    );
  }

  // ---------------------------------------------------------------------------
  // Luxury Card & Surface Decorations
  // ---------------------------------------------------------------------------

  static BoxDecoration cardDecoration({
    required bool isDark,
    BorderRadius? borderRadius,
    bool isElevated = false,
    bool hasBorder = true,
    Color? customBg,
  }) {
    final radius = borderRadius ?? AppRadius.radiusLg;
    final bgColor = customBg ??
        (isDark
            ? (isElevated ? darkElevatedSurface : darkEspressoSurface)
            : (isElevated ? lightElevatedSurface : lightCreamSurface));

    return BoxDecoration(
      color: bgColor,
      borderRadius: radius,
      border: hasBorder
          ? Border.all(
              color: isDark ? borderDark : borderLight,
              width: 0.8,
            )
          : null,
      boxShadow: isDark ? luxuryShadowDark : luxuryShadowLight,
    );
  }

  /// Ultra-subtle Apple-style ambient layered shadows
  static List<BoxShadow> get luxuryShadowLight => [
        BoxShadow(
          color: const Color(0xFF1E140C).withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF1E140C).withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get luxuryShadowDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Floating Action Pill decoration (e.g. for cart count, quick actions)
  static BoxDecoration pillBadgeDecoration({
    required bool isDark,
    Color? accent,
  }) {
    final col = accent ?? amberGold;
    return BoxDecoration(
      color: col.withOpacity(isDark ? 0.2 : 0.12),
      borderRadius: AppRadius.radiusPill,
      border: Border.all(
        color: col.withOpacity(isDark ? 0.4 : 0.25),
        width: 0.8,
      ),
    );
  }
}
