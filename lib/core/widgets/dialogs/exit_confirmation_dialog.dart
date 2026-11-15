import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../buttons/app_button.dart';

/// Wraps a root shell screen with platform-aware exit confirmation.
///
/// - On Android (non-web), intercepts system back at the root shell level and
///   presents [ExitConfirmationDialog] without affecting secondary routes.
/// - On iOS, Flutter Web, and Desktop, preserves native platform navigation and
///   browser history behavior (`canPop: true`).
class ExitConfirmationScope extends StatefulWidget {
  final Widget child;

  /// Optional override for testing platform exit behavior in widget tests.
  @visibleForTesting
  final bool? forceEnableForTesting;

  /// Optional callback invoked when the user confirms exit (defaults to [SystemNavigator.pop]).
  @visibleForTesting
  final VoidCallback? onExitConfirmed;

  const ExitConfirmationScope({
    super.key,
    required this.child,
    this.forceEnableForTesting,
    this.onExitConfirmed,
  });

  @override
  State<ExitConfirmationScope> createState() => _ExitConfirmationScopeState();
}

class _ExitConfirmationScopeState extends State<ExitConfirmationScope> {
  bool _isDialogOpen = false;

  bool get _shouldInterceptRootBack {
    if (widget.forceEnableForTesting != null) {
      return widget.forceEnableForTesting!;
    }
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  Future<void> _handleRootBackPressed() async {
    if (_isDialogOpen || !mounted) return;

    // Never intercept if there is still a route on the root navigator above the shell.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.maybePop();
      return;
    }

    _isDialogOpen = true;
    try {
      final shouldExit = await showExitConfirmationDialog(context);
      if (!mounted || shouldExit != true) return;

      if (widget.onExitConfirmed != null) {
        widget.onExitConfirmed!();
      } else {
        await SystemNavigator.pop();
      }
    } finally {
      _isDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldInterceptRootBack) {
      return widget.child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleRootBackPressed();
      },
      child: widget.child,
    );
  }
}

/// Shows the Lambac Coffee Roastery exit confirmation dialog with subtle animation.
Future<bool?> showExitConfirmationDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss exit confirmation',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, __) {
      return const ExitConfirmationDialog();
    },
    transitionBuilder: (dialogContext, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Branded Exit Confirmation Modal matching Lambac Coffee Roastery's design system.
class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final stackActionsVertically = screenWidth < 340;

    final cancelButton = AppButton.outlined(
      text: 'Cancel',
      size: AppButtonSize.medium,
      onPressed: () => Navigator.of(context).pop(false),
    );

    final exitButton = AppButton.primary(
      text: 'Exit',
      size: AppButtonSize.medium,
      onPressed: () => Navigator.of(context).pop(true),
    );

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.brandAmber.withValues(alpha: 0.18)
                        : AppColors.brandAmber.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.coffee_rounded,
                    size: 26,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  ),
                ),
              ),
              AppSpacing.vSpaceLg,
              Text(
                'Exit Application?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              AppSpacing.vSpaceSm,
              Text(
                'Are you sure you want to leave Lambac Coffee Roastery?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              AppSpacing.vSpaceXxl,
              if (stackActionsVertically)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    exitButton,
                    AppSpacing.vSpaceSm,
                    cancelButton,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: 12),
                    Expanded(child: exitButton),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
