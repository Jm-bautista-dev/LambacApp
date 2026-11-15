import 'package:flutter/material.dart';

/// Screen Size Breakpoints for Android, iOS, Tablet & Web form factors
enum ScreenType {
  compact, // Small phones (< 360 width, e.g. 320x568)
  standard, // Standard & large smartphones (360 - 599 width, e.g. 360x800, 390x844, 430x932)
  medium, // Tablets (600 - 1023 width, e.g. 600x960, 768x1024)
  expanded, // Desktop / Laptop / Full HD Web (>= 1024 width, e.g. 1024x768, 1366x768, 1920x1080)
}

/// Helper utilities and BuildContext extensions for responsive layouts
class ResponsiveLayout {
  ResponsiveLayout._();

  static const double compactBreakpoint = 360.0;
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;
  static const double maxContentWidth = 1200.0;
  static const double maxCatalogWidth = 1320.0;
  static const double maxReadingWidth = 760.0;
  static const double maxFormWidth = 600.0;
  static const double maxDialogWidth = 540.0;
  static const double maxSheetWidth = 640.0;

  static bool isCompactPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint &&
      MediaQuery.sizeOf(context).width < desktopBreakpoint;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Horizontal screen padding that adapts smoothly across phone, tablet, and desktop
  static EdgeInsets adaptiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 12);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (width < desktopBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  /// Calculates responsive product grid column count from available container width
  static int getProductGridColumnsForWidth(double availableWidth) {
    if (availableWidth >= 1100) return 4;
    if (availableWidth >= 820) return 3;
    if (availableWidth >= 540) return 3;
    return 2;
  }

  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactBreakpoint) {
      return ScreenType.compact;
    } else if (width < tabletBreakpoint) {
      return ScreenType.standard;
    } else if (width < desktopBreakpoint) {
      return ScreenType.medium;
    } else {
      return ScreenType.expanded;
    }
  }

  /// Calculates responsive cross-axis column count based on available width
  static int getGridColumnCount(
    BuildContext context, {
    double itemWidth = 200.0,
    int minColumns = 2,
    int maxColumns = 6,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final calculated = (width / itemWidth).floor();
    return calculated.clamp(minColumns, maxColumns);
  }

  /// Calculates safe dialog constraints preserving screen margin
  static BoxConstraints dialogConstraints(
    BuildContext context, {
    double maxWidth = maxDialogWidth,
    double maxHeightFactor = 0.85,
  }) {
    final size = MediaQuery.sizeOf(context);
    return BoxConstraints(
      maxWidth: maxWidth,
      maxHeight: size.height * maxHeightFactor,
    );
  }
}

/// Extension on BuildContext for quick access to responsive metrics and media query data
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get safeAreaPadding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  bool get isCompact => screenWidth < ResponsiveLayout.compactBreakpoint;
  bool get isStandard => screenWidth >= ResponsiveLayout.compactBreakpoint && screenWidth < ResponsiveLayout.tabletBreakpoint;
  bool get isTablet => screenWidth >= ResponsiveLayout.tabletBreakpoint && screenWidth < ResponsiveLayout.desktopBreakpoint;
  bool get isDesktop => screenWidth >= ResponsiveLayout.desktopBreakpoint;
  bool get isMediumOrLarger => screenWidth >= ResponsiveLayout.tabletBreakpoint;

  /// Returns responsive value based on current device screen size
  T responsiveValue<T>({
    required T standard,
    T? compact,
    T? tablet,
    T? desktop,
  }) {
    if (isCompact && compact != null) return compact;
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return standard;
  }
}

/// Responsive Builder Widget for rendering different layouts per screen type
class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder standard;
  final WidgetBuilder? compact;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.standard,
    this.compact,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isCompact && compact != null) {
      return compact!(context);
    }
    if (context.isDesktop && desktop != null) {
      return desktop!(context);
    }
    if (context.isTablet && tablet != null) {
      return tablet!(context);
    }
    return standard(context);
  }
}

/// Responsive Max Width Container for keeping content well-proportioned on larger devices
class ResponsiveContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.maxContentWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
