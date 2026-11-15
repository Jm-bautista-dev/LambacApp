import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/buttons/app_icon_button.dart';
import '../../data/models/staff_tutorial_step_model.dart';

/// Top bar with progress indicator, category badge, and navigation actions for staff tutorial
class StaffTutorialProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final StaffTutorialCategory category;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final bool isDark;

  const StaffTutorialProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.category,
    required this.onBack,
    required this.onSkip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps > 0 ? (currentStep + 1) / totalSteps : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Actions & Step Info Row
        Row(
          children: [
            if (onBack != null)
              AppIconButton(
                icon: Icons.arrow_back_rounded,
                size: 36,
                iconSize: 18,
                hasBorder: true,
                tooltip: 'Previous Step',
                onPressed: onBack,
              )
            else
              const SizedBox(width: 36),
            const Spacer(),

            // Category Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: AppRadius.radiusPill,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 13,
                    color: AppColors.matchaSageLight,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    category.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Skip Button
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(44, 36),
                foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress Bar & Step Text Row
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.radiusPill,
                child: SizedBox(
                  height: 5,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.matchaSage,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
