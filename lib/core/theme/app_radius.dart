import 'package:flutter/material.dart';

/// Standardized Border Radius Tokens
class AppRadius {
  AppRadius._();

  /// 4.0 pt (Tags, micro badges)
  static const double xs = 4.0;

  /// 8.0 pt (Small buttons, compact cards)
  static const double sm = 8.0;

  /// 12.0 pt (Standard inputs, medium cards)
  static const double md = 12.0;

  /// 16.0 pt (Standard modal cards, containers)
  static const double lg = 16.0;

  /// 24.0 pt (Bottom sheets, prominent banners)
  static const double xl = 24.0;

  /// 32.0 pt (Large hero containers)
  static const double xxl = 32.0;

  /// 999.0 pt (Pill buttons, floating chips)
  static const double pill = 999.0;

  // BorderRadius Helpers
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));

  // Top Rounded for Bottom Sheets
  static const BorderRadius topSheetRadius = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
