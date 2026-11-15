import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../feedback/app_loading_indicator.dart';

/// Button Variant Styles
enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  destructive,
}

/// Button Size Presets
enum AppButtonSize {
  small,
  medium,
  large,
}

/// Unified Production App Button
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.destructive({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
  }) : variant = AppButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;

    final height = switch (size) {
      AppButtonSize.small => 38.0,
      AppButtonSize.medium => 48.0,
      AppButtonSize.large => 56.0,
    };

    final fontSize = switch (size) {
      AppButtonSize.small => 13.0,
      AppButtonSize.medium => 15.0,
      AppButtonSize.large => 16.0,
    };

    final (backgroundColor, foregroundColor, borderSide) = _resolveColors(isDark, isEnabled);

    final buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          AppLoadingIndicator(
            size: fontSize + 4,
            color: foregroundColor,
          ),
          AppSpacing.hSpaceSm,
        ] else if (leadingIcon != null) ...[
          leadingIcon!,
          AppSpacing.hSpaceSm,
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          AppSpacing.hSpaceSm,
          trailingIcon!,
        ],
      ],
    );

    return SizedBox(
      width: isFullWidth ? (width ?? double.infinity) : width,
      height: height,
      child: Material(
        color: backgroundColor,
        borderRadius: AppRadius.radiusPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          splashColor: foregroundColor.withOpacity(0.08),
          highlightColor: foregroundColor.withOpacity(0.04),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: size == AppButtonSize.small ? 10.0 : AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusPill,
              border: borderSide,
            ),
            alignment: Alignment.center,
            child: buttonContent,
          ),
        ),
      ),
    );
  }

  (Color, Color, Border?) _resolveColors(bool isDark, bool isEnabled) {
    if (!isEnabled && !isLoading) {
      final disabledBg = isDark ? const Color(0xFF241F1B) : const Color(0xFFEBE6DF);
      final disabledFg = isDark ? const Color(0xFF5E554C) : const Color(0xFFAAA197);
      return (disabledBg, disabledFg, null);
    }

    return switch (variant) {
      AppButtonVariant.primary => (
          isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
          isDark ? AppColors.darkCanvas : Colors.white,
          null,
        ),
      AppButtonVariant.secondary => (
          isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          null,
        ),
      AppButtonVariant.outlined => (
          Colors.transparent,
          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.2,
          ),
        ),
      AppButtonVariant.ghost => (
          Colors.transparent,
          isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
          null,
        ),
      AppButtonVariant.destructive => (
          AppColors.error,
          Colors.white,
          null,
        ),
    };
  }
}
