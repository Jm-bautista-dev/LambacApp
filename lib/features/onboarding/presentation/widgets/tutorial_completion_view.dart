import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';

/// Celebratory completion view shown at the conclusion of the customer tutorial
class TutorialCompletionView extends StatelessWidget {
  final VoidCallback onStartExploring;
  final VoidCallback onViewAgain;
  final VoidCallback onBrowseMenu;
  final bool isDark;

  const TutorialCompletionView({
    super.key,
    required this.onStartExploring,
    required this.onViewAgain,
    required this.onBrowseMenu,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 24).clamp(0.0, double.infinity),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Roastery Seal & Checkmark Badge
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF261D17) : const Color(0xFFF6EFE6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : AppColors.brandAmber).withValues(alpha: 0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.coffee_rounded,
                          size: 42,
                          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
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
                  AppSpacing.vSpaceXl,

                  // Main Header
                  Text(
                    "You're all set.",
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
                    'You now know your way around Lambac Coffee Roastery. Freshly roasted single-origin micro-lots await your morning ritual.',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.45,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.vSpaceXl,

                  // Help & Replay Reminder Card
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 20,
                          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Need help later? You can replay this guide anytime from Profile → Help & Guide.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.35,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vSpaceXl,

                  // Buttons
                  AppButton.primary(
                    text: 'Start Exploring Lambac',
                    leadingIcon: const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
                    onPressed: onStartExploring,
                  ),
                  AppSpacing.vSpaceMd,
                  AppButton.outlined(
                    text: 'Browse Roastery Menu',
                    leadingIcon: Icon(
                      Icons.coffee_rounded,
                      size: 18,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    ),
                    onPressed: onBrowseMenu,
                  ),
                  AppSpacing.vSpaceSm,
                  TextButton.icon(
                    onPressed: onViewAgain,
                    icon: Icon(
                      Icons.replay_rounded,
                      size: 16,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    label: Text(
                      'View Tutorial Again',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
