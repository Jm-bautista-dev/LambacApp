import 'package:flutter/material.dart';
import '../widgets/dialogs/app_dialog.dart';
import '../widgets/feedback/app_toast.dart';
import 'app_failure.dart';

/// Centralized UI Error Presenter for Lambac Coffee Roastery
/// Standardizes how errors are presented across all Customer, Barista, and Admin screens
class ErrorPresenter {
  ErrorPresenter._();

  static bool _isDialogShowing = false;

  /// Displays a floating contextual toast error notification
  static void showErrorToast(
    BuildContext context,
    AppFailure failure, {
    VoidCallback? onRetry,
    String? retryLabel,
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    if (!context.mounted) return;

    final resolvedTitle = _resolveErrorTitle(failure);
    final canShowRetry = onRetry != null || failure.canRetry;

    AppToast.show(
      context,
      title: resolvedTitle,
      message: failure.userFriendlyMessage,
      type: AppToastType.error,
      duration: duration,
      onAction: canShowRetry ? onRetry : null,
      actionLabel: canShowRetry ? (retryLabel ?? 'Retry') : null,
    );
  }

  /// Displays an authoritative success toast notification (only called after backend confirms)
  static void showSuccessToast(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    if (!context.mounted) return;

    AppToast.show(
      context,
      title: title,
      message: message,
      type: AppToastType.success,
      duration: duration,
    );
  }

  /// Displays a modal decision dialog for critical or non-recoverable failures
  static Future<void> showErrorDialog(
    BuildContext context,
    AppFailure failure, {
    String? title,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    if (!context.mounted || _isDialogShowing) return;

    _isDialogShowing = true;
    final resolvedTitle = title ?? _resolveErrorTitle(failure);
    final canRetry = onRetry != null || failure.canRetry;

    try {
      final confirmed = await AppDialog.show(
        context,
        title: resolvedTitle,
        message: failure.userFriendlyMessage,
        confirmText: canRetry ? 'Try Again' : 'Understood',
        cancelText: canRetry ? 'Cancel' : null,
        isDestructive: failure is ForbiddenFailure || failure is ConflictFailure,
        icon: _resolveDialogIcon(failure),
      );

      if (confirmed == true && canRetry) {
        onRetry?.call();
      } else {
        onDismiss?.call();
      }
    } finally {
      _isDialogShowing = false;
    }
  }

  static String _resolveErrorTitle(AppFailure failure) {
    return switch (failure) {
      NetworkFailure() => 'Network Unavailable',
      ServerFailure() || ServiceFailure() => 'Service Unavailable',
      UnauthorizedFailure() => 'Session Expired',
      ForbiddenFailure() => 'Access Denied',
      ValidationFailure() => 'Check Your Input',
      PreconditionFailure() => 'Cannot Proceed',
      ConflictFailure() => 'Order Conflict',
      RateLimitFailure() => 'Too Many Attempts',
      NotFoundFailure() => 'Not Found',
      TimeoutFailure() => 'Connection Timeout',
      CancelledFailure() => 'Cancelled',
      DataIntegrityFailure() => 'Data Inconsistency',
      _ => 'Something Went Wrong',
    };
  }

  static IconData _resolveDialogIcon(AppFailure failure) {
    return switch (failure) {
      NetworkFailure() => Icons.wifi_off_rounded,
      ServerFailure() || ServiceFailure() => Icons.cloud_off_rounded,
      UnauthorizedFailure() => Icons.lock_outline_rounded,
      ForbiddenFailure() => Icons.block_rounded,
      ValidationFailure() => Icons.error_outline_rounded,
      ConflictFailure() => Icons.sync_problem_rounded,
      RateLimitFailure() => Icons.timer_outlined,
      _ => Icons.warning_amber_rounded,
    };
  }
}
