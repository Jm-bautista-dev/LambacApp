import 'package:flutter/material.dart';

/// Standardized Spacing & Padding Metrics (4pt & 8pt Rhythm Grid)
class AppSpacing {
  AppSpacing._();

  /// 2.0 pt
  static const double xxs = 2.0;

  /// 4.0 pt
  static const double xs = 4.0;

  /// 8.0 pt
  static const double sm = 8.0;

  /// 12.0 pt
  static const double md = 12.0;

  /// 16.0 pt (Standard baseline spacing)
  static const double lg = 16.0;

  /// 20.0 pt
  static const double xl = 20.0;

  /// 24.0 pt (Section rhythm)
  static const double xxl = 24.0;

  /// 32.0 pt (Major module division)
  static const double xxxl = 32.0;

  /// 48.0 pt (Hero / Banner spacing)
  static const double huge = 48.0;

  /// Standard Screen Horizontal Padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: lg);

  /// Standard Screen Edge Insets with Top & Bottom
  static const EdgeInsets screenFullPadding = EdgeInsets.all(lg);

  /// Card Inner Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);

  /// Button Inner Padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xxl, vertical: md);
  static const EdgeInsets buttonSmallPadding = EdgeInsets.symmetric(horizontal: lg, vertical: sm);

  /// Standard SizedBox Vertical Spacing Helpers
  static const Widget vSpaceXxs = SizedBox(height: xxs);
  static const Widget vSpaceXs = SizedBox(height: xs);
  static const Widget vSpaceSm = SizedBox(height: sm);
  static const Widget vSpaceMd = SizedBox(height: md);
  static const Widget vSpaceLg = SizedBox(height: lg);
  static const Widget vSpaceXl = SizedBox(height: xl);
  static const Widget vSpaceXxl = SizedBox(height: xxl);
  static const Widget vSpaceXxxl = SizedBox(height: xxxl);
  static const Widget vSpaceHuge = SizedBox(height: huge);

  /// Standard SizedBox Horizontal Spacing Helpers
  static const Widget hSpaceXxs = SizedBox(width: xxs);
  static const Widget hSpaceXs = SizedBox(width: xs);
  static const Widget hSpaceSm = SizedBox(width: sm);
  static const Widget hSpaceMd = SizedBox(width: md);
  static const Widget hSpaceLg = SizedBox(width: lg);
  static const Widget hSpaceXl = SizedBox(width: xl);
  static const Widget hSpaceXxl = SizedBox(width: xxl);
  static const Widget hSpaceXxxl = SizedBox(width: xxxl);
}
