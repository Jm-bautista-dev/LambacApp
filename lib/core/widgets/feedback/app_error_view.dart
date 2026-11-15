import 'package:flutter/material.dart';
import '../../errors/app_failure.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../buttons/app_button.dart';

/// Standardized Retryable Full-Screen or In-Card Error View for Lambac Coffee Roastery
class AppErrorView extends StatelessWidget {
  final AppFailure? failure;
  final String? message;
  final String? title;
  final VoidCallback? onRetry;
  final String retryText;
  final Widget? customAction;

  const AppErrorView({
    super.key,
    this.failure,
    this.message,
    this.title,
    this.onRetry,
    this.retryText = 'Try Again',
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedTitle = title ??
        switch (failure) {
          NetworkFailure() => 'Network Unavailable',
          ServerFailure() || ServiceFailure() => 'Roastery Offline',
          UnauthorizedFailure() => 'Authentication Required',
          ForbiddenFailure() => 'Access Denied',
          NotFoundFailure() => 'Item Not Found',
          ConflictFailure() => 'Record Conflict',
          PreconditionFailure() => 'Action Unavailable',
          RateLimitFailure() => 'Please Wait a Moment',
          TimeoutFailure() => 'Request Timed Out',
          DataIntegrityFailure() => 'Data Inconsistency',
          _ => 'Something Went Wrong',
        };

    final resolvedMessage = message ?? failure?.userFriendlyMessage ?? 'An unexpected error occurred. Please try again.';

    final icon = switch (failure) {
      NetworkFailure() => Icons.wifi_off_rounded,
      ServerFailure() || ServiceFailure() => Icons.cloud_off_rounded,
      UnauthorizedFailure() => Icons.lock_outline_rounded,
      ForbiddenFailure() => Icons.block_rounded,
      NotFoundFailure() => Icons.search_off_rounded,
      ConflictFailure() => Icons.sync_problem_rounded,
      PreconditionFailure() => Icons.rule_rounded,
      RateLimitFailure() => Icons.timer_outlined,
      TimeoutFailure() => Icons.hourglass_empty_rounded,
      _ => Icons.error_outline_rounded,
    };

    final canShowRetry = onRetry != null || (failure?.canRetry ?? false);

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppColors.error.withOpacity(0.15) : AppColors.errorBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 32,
                color: AppColors.error,
              ),
            ),
            AppSpacing.vSpaceLg,
            Text(
              resolvedTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vSpaceSm,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                resolvedMessage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (customAction != null) ...[
              AppSpacing.vSpaceXxl,
              customAction!,
            ] else if (canShowRetry && onRetry != null) ...[
              AppSpacing.vSpaceXxl,
              AppButton.primary(
                text: retryText,
                onPressed: onRetry,
                isFullWidth: false,
                leadingIcon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
