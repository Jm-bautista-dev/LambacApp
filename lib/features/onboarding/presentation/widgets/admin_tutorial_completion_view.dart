import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';

/// Celebratory completion view shown at the conclusion of the Administrator & BI System tutorial
class AdminTutorialCompletionView extends StatelessWidget {
  final VoidCallback onOpenDashboard;
  final VoidCallback onReplayTutorial;
  final bool isDark;

  const AdminTutorialCompletionView({
    super.key,
    required this.onOpenDashboard,
    required this.onReplayTutorial,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        decoration: TextDecoration.none,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontFamily: 'Inter',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Executive BI Hub Seal
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF261E16) : const Color(0xFFFAF3EC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brandAmber,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandAmber.withValues(alpha: isDark ? 0.35 : 0.2),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.auto_graph_rounded,
                    size: 46,
                    color: AppColors.brandAmberLight,
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vSpaceXxl,

            // Main Header
            Text(
              "You're ready to manage Lambac.",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vSpaceSm,

            // Subtitle
            Text(
              'You now know how to operate the system, understand business performance, interpret forecasts, and turn recommendations into actions.',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.45,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vSpaceXxl,

            // Help & BI System Guide Reminder Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.9,
                ),
                boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 20,
                    color: AppColors.brandAmberLight,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Need a refresher later? Open Admin Profile → Help & Guide to replay this complete guide or select specific BI chapters.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

          // Buttons
          AppButton.primary(
            text: 'Open Dashboard',
            leadingIcon: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 18),
            onPressed: onOpenDashboard,
          ),
          AppSpacing.vSpaceMd,
          AppButton.outlined(
            text: 'Replay Tutorial',
            leadingIcon: const Icon(
              Icons.replay_rounded,
              size: 18,
              color: AppColors.brandAmberLight,
            ),
            onPressed: onReplayTutorial,
          ),
          AppSpacing.vSpaceLg,
        ],
      ),
    ),
  );
}
}
