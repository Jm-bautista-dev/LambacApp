import 'package:flutter/material.dart';

/// Japanese Minimalist + Apple-Inspired Coffee Roastery Color Palette
class AppColors {
  AppColors._();

  // --------------------------------------------------------------------------
  // Light Palette (Warm Japanese Wabi-Sabi / Parchment)
  // --------------------------------------------------------------------------

  /// Canvas background: Warm parchment off-white
  static const Color lightCanvas = Color(0xFFFAF7F2);

  /// Primary surface: Soft cream
  static const Color lightSurface = Color(0xFFF3EFE8);

  /// Secondary surface: Pure warm linen
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  /// Hairline border: Delicate warm sand
  static const Color lightBorder = Color(0xFFE7E1D6);

  /// Subtle divider
  static const Color lightDivider = Color(0xFFEFE9DF);

  /// Text Primary: Deep Sumi / Espresso
  static const Color lightTextPrimary = Color(0xFF161311);

  /// Text Secondary: Muted Coffee Ash / Taupe
  static const Color lightTextSecondary = Color(0xFF756A61);

  /// Text Tertiary / Placeholder: Soft stone
  static const Color lightTextTertiary = Color(0xFFA59B90);

  // --------------------------------------------------------------------------
  // Dark Palette (Tokyo Night Cafe / Roasted Sumi Obsidian)
  // --------------------------------------------------------------------------

  /// Canvas background: Deep roast sumi charcoal
  static const Color darkCanvas = Color(0xFF12100E);

  /// Primary surface: Roasted beans obsidian
  static const Color darkSurface = Color(0xFF1B1714);

  /// Secondary surface: Warm night charcoal
  static const Color darkSurfaceElevated = Color(0xFF231E1A);

  /// Hairline border: Muted charcoal border
  static const Color darkBorder = Color(0xFF2E2721);

  /// Subtle divider
  static const Color darkDivider = Color(0xFF25201A);

  /// Text Primary: Warm milk cream
  static const Color darkTextPrimary = Color(0xFFF8F5EE);

  /// Text Secondary: Muted warm ash
  static const Color darkTextSecondary = Color(0xFFA59B90);

  /// Text Tertiary / Placeholder: Dark muted stone
  static const Color darkTextTertiary = Color(0xFF6B6258);

  // --------------------------------------------------------------------------
  // Brand & Roastery Accents
  // --------------------------------------------------------------------------

  /// Roastery Amber — Signature brand accent
  static const Color brandAmber = Color(0xFFC17A48);
  static const Color brandAmberLight = Color(0xFFD89566);
  static const Color brandAmberDark = Color(0xFFA35F30);

  /// Crema Gold — Warm secondary highlight
  static const Color cremaGold = Color(0xFFD8A47F);
  static const Color cremaGoldLight = Color(0xFFE8C2A7);

  /// Matcha Sage — Natural herbal accent
  static const Color matchaSage = Color(0xFF4E6E5D);
  static const Color matchaSageLight = Color(0xFFE8EFEA);

  /// Deep Espresso — Grounding rich roast tone
  static const Color deepEspresso = Color(0xFF2A1D15);

  /// Cold Brew Obsidian
  static const Color coldBrew = Color(0xFF1A1410);

  // --------------------------------------------------------------------------
  // Semantic Feedback Colors
  // --------------------------------------------------------------------------

  /// Success: Fresh botanical green
  static const Color success = Color(0xFF388E3C);
  static const Color successBackground = Color(0xFFEBF5EC);

  /// Warning: Warm honey amber
  static const Color warning = Color(0xFFE67E22);
  static const Color warningBackground = Color(0xFFFDF3E7);

  /// Error: Red clay / Crimson
  static const Color error = Color(0xFFC84B31);
  static const Color errorBackground = Color(0xFFFBEBE8);

  /// Info: Slate blue
  static const Color info = Color(0xFF3498DB);
  static const Color infoBackground = Color(0xFFEBF5FB);

  // Shimmer colors
  static const Color shimmerBase = Color(0xFFEAE4D9);
  static const Color shimmerHighlight = Color(0xFFF7F4EC);
  static const Color shimmerBaseDark = Color(0xFF231E1A);
  static const Color shimmerHighlightDark = Color(0xFF2E2721);
}
