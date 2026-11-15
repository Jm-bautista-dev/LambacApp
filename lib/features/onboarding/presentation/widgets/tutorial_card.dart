import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/tutorial_step_model.dart';
import 'tutorial_step_visual.dart';

/// Luxury tutorial step card with visual preview, key takeaways, and practical tip
class TutorialCard extends StatelessWidget {
  final TutorialStepModel step;
  final bool isDark;

  const TutorialCard({
    super.key,
    required this.step,
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Highlight Target Area Eyebrow
            Row(
              children: [
                if (step.badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.brandAmber.withValues(alpha: 0.25)
                          : AppColors.brandAmber.withValues(alpha: 0.15),
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      step.badgeText!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    step.highlightArea.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            AppSpacing.vSpaceSm,

            // 2. Step Title
            Text(
              step.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                height: 1.25,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                decoration: TextDecoration.none,
              ),
            ),
            AppSpacing.vSpaceXs,

            // 3. Subtitle / High-level summary
            Text(
              step.subtitle,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.45,
                decoration: TextDecoration.none,
              ),
            ),
            AppSpacing.vSpaceMd,

            // 4. Interactive Step Visual Preview
            TutorialStepVisual(
              visualType: step.visualType,
              isDark: isDark,
            ),
            AppSpacing.vSpaceMd,

            // 5. Key Points / Feature Breakdown Container
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        size: 16,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'What you can do:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...step.keyPoints.map((point) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 8),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                height: 1.4,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // 6. Practical Roastery Tip (if available)
            if (step.practicalTip != null) ...[
              AppSpacing.vSpaceSm,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF221A15)
                      : const Color(0xFFF9F5EF),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: isDark
                        ? AppColors.brandAmber.withValues(alpha: 0.4)
                        : AppColors.brandAmber.withValues(alpha: 0.3),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      size: 16,
                      color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.practicalTip!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                          color: isDark ? const Color(0xFFE2D6CA) : const Color(0xFF5A4433),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 7. Optional Quick Action Button
            if (step.actionRoute != null && step.actionLabel != null) ...[
              AppSpacing.vSpaceMd,
              Center(
                child: TextButton.icon(
                  onPressed: () => context.push(step.actionRoute!),
                  icon: Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  ),
                  label: Text(
                    step.actionLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
