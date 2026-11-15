import 'package:flutter/material.dart';
import '../errors/app_failure.dart';
import '../widgets/dialogs/app_dialog.dart';
import '../widgets/feedback/app_toast.dart';

/// Centralized Global User Feedback Service for Lambac Coffee Roastery
class AppFeedback {
  AppFeedback._();

  /// Displays a contextual success toast
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    AppToast.success(
      context,
      message,
      title: title,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Displays a contextual error toast with technical message sanitization
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    AppToast.error(
      context,
      message,
      title: title,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Displays an informational toast
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    AppToast.info(
      context,
      message,
      title: title,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Displays a warning toast
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    AppToast.warning(
      context,
      message,
      title: title,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Displays an Apple/Dribbble-inspired Add-to-Cart toast with item details & "View Cart →" action
  static void showAddToCart(
    BuildContext context, {
    required String productName,
    required int quantity,
    String? variantDescription,
    VoidCallback? onViewCart,
  }) {
    AppToast.cartItemAdded(
      context,
      productName: productName,
      quantity: quantity,
      variantDescription: variantDescription,
      onViewCart: onViewCart,
    );
  }

  /// Handles AppFailure by mapping backend errors to polite, professional user-facing copy
  static void handleFailure(BuildContext context, AppFailure failure) {
    final userMessage = switch (failure) {
      NetworkFailure() => 'Unable to connect. Please check your internet connection and try again.',
      UnauthorizedFailure(message: final msg) =>
        msg.isNotEmpty ? msg : 'Your session has expired. Please sign in again.',
      NotFoundFailure(message: final msg) =>
        msg.isNotEmpty ? msg : 'The requested item could not be found.',
      ForbiddenFailure(message: final msg) =>
        msg.isNotEmpty ? msg : 'You do not have permission to perform this action.',
      ValidationFailure(message: final msg) =>
        msg.isNotEmpty ? msg : 'Please review the entered details and try again.',
      ServerFailure() => 'Something went wrong on our end. Please try again.',
      CacheFailure() => 'Unable to access offline local cache.',
      TimeoutFailure() => 'The request took too long. Please check your connection and try again.',
      BadRequestFailure() => 'Bad request. Please verify details and try again.',
      ConflictFailure() => 'A conflict occurred. Record already exists.',
      UnprocessableFailure() => 'Unable to complete request due to business rules.',
      RateLimitFailure() => 'Too many requests. Please wait a moment.',
      FormatFailure() => 'Received unexpected data from server. Please try again.',
      ServiceFailure(message: final msg) =>
        msg.isNotEmpty ? msg : 'A service error occurred. Please try again.',
      UnknownFailure() => 'Something unexpected occurred. Please try again.',
      _ => failure.message.isNotEmpty ? failure.message : 'An error occurred. Please try again.',
    };

    showError(context, userMessage);
  }

  /// Prompts user with a decision modal dialog
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
  }) {
    return AppDialog.confirm(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
    );
  }

  /// Prompts user with a destructive action decision dialog (e.g. Logout, Delete Account, Void Record)
  static Future<bool?> showDestructive(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData icon = Icons.warning_amber_rounded,
  }) {
    return AppDialog.destructive(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
    );
  }
}
