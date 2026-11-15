import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Tactile Icon Button for AppBars, Search, and Action Items
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool hasBorder;
  final int? badgeCount;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 44.0,
    this.iconSize = 20.0,
    this.backgroundColor,
    this.iconColor,
    this.hasBorder = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = backgroundColor ??
        (hasBorder
            ? (isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated)
            : Colors.transparent);

    final defaultIconColor = iconColor ??
        (onPressed == null
            ? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary));

    Widget button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: defaultBg,
        borderRadius: AppRadius.radiusPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed != null
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          splashColor: defaultIconColor.withOpacity(0.1),
          highlightColor: defaultIconColor.withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusPill,
              border: hasBorder
                  ? Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: iconSize,
              color: defaultIconColor,
            ),
          ),
        ),
      ),
    );

    if (badgeCount != null && badgeCount! > 0) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.brandAmber,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount! > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
