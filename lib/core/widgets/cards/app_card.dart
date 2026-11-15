import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Card Visual Variations
enum AppCardVariant {
  flat,
  outlined,
  elevated,
}

/// Minimalist Roastery Card with Micro-Borders
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.variant = AppCardVariant.flat,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius,
    this.backgroundColor,
    this.width,
    this.height,
  });

  const AppCard.outlined({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius,
    this.backgroundColor,
    this.width,
    this.height,
  }) : variant = AppCardVariant.outlined;

  const AppCard.elevated({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius,
    this.backgroundColor,
    this.width,
    this.height,
  }) : variant = AppCardVariant.elevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedRadius = borderRadius ?? AppRadius.radiusMd;

    final defaultBg = backgroundColor ??
        switch (variant) {
          AppCardVariant.flat => isDark ? AppColors.darkSurface : AppColors.lightSurface,
          AppCardVariant.outlined => isDark ? AppColors.darkCanvas : AppColors.lightSurfaceElevated,
          AppCardVariant.elevated => isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        };

    final borderSide = switch (variant) {
      AppCardVariant.flat => BorderSide(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.lightBorder.withValues(alpha: 0.6),
          width: 0.8,
        ),
      AppCardVariant.outlined => BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
      AppCardVariant.elevated => BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder.withValues(alpha: 0.5),
          width: 0.8,
        ),
    };

    final shadows = switch (variant) {
      AppCardVariant.elevated => isDark ? AppShadows.elevatedDark : AppShadows.elevatedLight,
      AppCardVariant.flat => isDark ? AppShadows.cardDark : AppShadows.cardLight,
      AppCardVariant.outlined => null,
    };

    final cardShape = RoundedRectangleBorder(
      borderRadius: resolvedRadius,
      side: borderSide,
    );

    Widget innerContent = Padding(
      padding: padding,
      child: child,
    );

    if (width != null || height != null) {
      innerContent = SizedBox(
        width: width,
        height: height,
        child: innerContent,
      );
    }

    Widget cardMaterial;
    if (onTap != null) {
      cardMaterial = Material(
        color: defaultBg,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          highlightColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
          child: innerContent,
        ),
      );
    } else {
      cardMaterial = Material(
        color: defaultBg,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        child: innerContent,
      );
    }

    if (shadows != null && shadows.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: resolvedRadius,
          boxShadow: shadows,
        ),
        child: cardMaterial,
      );
    }

    return cardMaterial;
  }
}
