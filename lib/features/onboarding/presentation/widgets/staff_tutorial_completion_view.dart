import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';

/// Celebratory completion view shown at the conclusion of the Barista/Staff Operations tutorial
class StaffTutorialCompletionView extends StatelessWidget {
  final VoidCallback onStartWorking;
  final VoidCallback onReplayTutorial;
  final bool isDark;

  const StaffTutorialCompletionView({
    super.key,
    required this.onStartWorking,
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

          // Staff Operations Badge
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF19251D) : const Color(0xFFEAF5EE),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.matchaSage,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.matchaSage.withValues(alpha: isDark ? 0.3 : 0.2),
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
                  Icons.coffee_maker_rounded,
                  size: 46,
                  color: AppColors.matchaSageLight,
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
            "You're ready for service.",
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
            'You now know the Lambac staff workflow. From incoming tickets and pour-over brewing to counter settlement and pickup notifications.',
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

          // Help & Operations Guide Reminder Card
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
                  color: AppColors.matchaSageLight,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Need a refresher later? Open My Shift → Help & Guide to replay this Staff tutorial anytime.',
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
            text: 'Start Working',
            leadingIcon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
            onPressed: onStartWorking,
          ),
          AppSpacing.vSpaceMd,
          AppButton.outlined(
            text: 'Replay Tutorial',
            leadingIcon: const Icon(
              Icons.replay_rounded,
              size: 18,
              color: AppColors.matchaSageLight,
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
