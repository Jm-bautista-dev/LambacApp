import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';

/// Toast / Floating Banner Notification Type
enum AppToastType {
  success,
  error,
  info,
  warning,
}

/// Premium Apple- & Dribbble-inspired Toast Notification System for Lambac Coffee Roastery
class AppToast {
  AppToast._();

  /// Displays a floating contextual toast notification
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(milliseconds: 3200),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // Prevent notification spam by clearing any lingering snackbar immediately
    messenger.clearSnackBars();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (icon, iconColor, iconBgColor) = switch (type) {
      AppToastType.success => (
          Icons.check_rounded,
          AppColors.success,
          AppColors.success.withOpacity(isDark ? 0.2 : 0.12),
        ),
      AppToastType.error => (
          Icons.error_outline_rounded,
          AppColors.error,
          AppColors.error.withOpacity(isDark ? 0.2 : 0.12),
        ),
      AppToastType.warning => (
          Icons.warning_amber_rounded,
          AppColors.warning,
          AppColors.warning.withOpacity(isDark ? 0.2 : 0.12),
        ),
      AppToastType.info => (
          Icons.local_cafe_rounded,
          isDark ? AppColors.cremaGold : AppColors.brandAmber,
          isDark ? AppColors.brandAmber.withOpacity(0.2) : AppColors.brandAmber.withOpacity(0.12),
        ),
    };

    final bgColor = isDark ? const Color(0xFF221A15) : Colors.white;
    final borderColor = isDark ? const Color(0xFF382C24) : const Color(0xFFE8DFD3);
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Badge with soft tinted background
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),

              // Notification Title & Message Content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      message,
                      style: TextStyle(
                        color: title != null ? secondaryTextColor : primaryTextColor,
                        fontSize: title != null ? 12 : 13,
                        fontWeight: title != null ? FontWeight.w500 : FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Optional Contextual Action Button (e.g. "View Cart →")
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.brandAmber.withOpacity(0.2)
                          : AppColors.brandAmber.withOpacity(0.12),
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Specialized Add-To-Cart feedback toast with item details & "View Cart →" action
  static void cartItemAdded(
    BuildContext context, {
    required String productName,
    required int quantity,
    String? variantDescription,
    VoidCallback? onViewCart,
  }) {
    final qtyPrefix = quantity > 1 ? '$quantity × ' : '';
    final variantSuffix = variantDescription != null && variantDescription.isNotEmpty
        ? ' ($variantDescription)'
        : '';

    show(
      context,
      title: 'Added to Cart',
      message: '$qtyPrefix$productName$variantSuffix',
      type: AppToastType.success,
      actionLabel: onViewCart != null ? 'View Cart →' : null,
      onAction: onViewCart,
      duration: const Duration(milliseconds: 3500),
    );
  }

  /// Standard success toast notification
  static void success(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppToastType.success,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Standard error toast notification with safe user-friendly messaging
  static void error(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // Sanitize message to never expose raw technical errors or stack traces
    final cleanMessage = _sanitizeErrorMessage(message);

    show(
      context,
      message: cleanMessage,
      title: title,
      type: AppToastType.error,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Standard informational toast notification
  static void info(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppToastType.info,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Standard warning toast notification
  static void warning(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppToastType.warning,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Sanitizes raw exceptions to prevent technical leakages
  static String _sanitizeErrorMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('socketexception') || lower.contains('connection refused') || lower.contains('network error')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    if (lower.contains('unauthorized') || lower.contains('401') || lower.contains('jwt')) {
      return 'Your session has expired. Please sign in again to continue.';
    }
    if (lower.contains('500') || lower.contains('internal server error') || lower.contains('sqlexception')) {
      return 'Something went wrong on our end. Please try again.';
    }
    return rawMessage;
  }
}
