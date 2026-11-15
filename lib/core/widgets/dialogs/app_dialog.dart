import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../buttons/app_button.dart';

/// Apple- & Dribbble-inspired Modal Decision Dialog for Lambac Coffee Roastery
class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
  });

  /// Displays a modal decision dialog and returns true if confirmed, false or null otherwise
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    String? cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (modalContext) => AppDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon ?? (isDestructive ? Icons.warning_amber_rounded : Icons.info_outline_rounded),
        onConfirm: () => Navigator.of(modalContext).pop(true),
        onCancel: () => Navigator.of(modalContext).pop(false),
      ),
    );
  }

  /// Convenience helper for destructive action confirmations (e.g., Logout, Cancel Order, Delete Account)
  static Future<bool?> destructive(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData icon = Icons.logout_rounded,
  }) {
    return show(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: true,
      icon: icon,
    );
  }

  /// Convenience helper for standard confirmation decisions
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
  }) {
    return show(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: false,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final iconBgColor = isDestructive
        ? AppColors.error.withOpacity(isDark ? 0.2 : 0.12)
        : (isDark ? AppColors.brandAmber.withOpacity(0.2) : AppColors.brandAmber.withOpacity(0.12));

    final iconColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF221A15) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.radiusXl,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Badge
              if (icon != null) ...[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 26,
                    color: iconColor,
                  ),
                ),
                AppSpacing.vSpaceLg,
              ],

              // Dialog Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vSpaceSm,

              // Explanation Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vSpaceXxl,

              // Dual Decision Action Buttons
              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: AppButton.outlined(
                        text: cancelText!,
                        onPressed: onCancel ?? () => Navigator.of(context).pop(),
                        size: AppButtonSize.medium,
                      ),
                    ),
                    AppSpacing.hSpaceMd,
                  ],
                  Expanded(
                    child: isDestructive
                        ? AppButton.destructive(
                            text: confirmText,
                            onPressed: onConfirm,
                            size: AppButtonSize.medium,
                          )
                        : AppButton.primary(
                            text: confirmText,
                            onPressed: onConfirm,
                            size: AppButtonSize.medium,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
