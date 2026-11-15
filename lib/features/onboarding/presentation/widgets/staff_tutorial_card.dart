import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/staff_tutorial_step_model.dart';
import 'staff_tutorial_step_visual.dart';

/// Operational tutorial step card with visual simulator, key workflows, and SOP rules
class StaffTutorialCard extends StatelessWidget {
  final StaffTutorialStepModel step;
  final bool isDark;

  const StaffTutorialCard({
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
            // 1. Highlight Target Area Eyebrow & Badge
            Row(
              children: [
                if (step.badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.matchaSage.withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(
                        color: AppColors.matchaSageLight,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      step.badgeText!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.matchaSageLight,
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
            StaffTutorialStepVisual(
              visualType: step.visualType,
              isDark: isDark,
            ),
            AppSpacing.vSpaceMd,

            // 5. Key Points / Operational Actions Breakdown Container
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        size: 16,
                        color: AppColors.matchaSageLight,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Staff Action & SOP:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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
                              decoration: const BoxDecoration(
                                color: AppColors.matchaSageLight,
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

            // 6. Operational Rule / Warning Banner (if available)
            if (step.operationalRule != null) ...[
              AppSpacing.vSpaceSm,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF221A15) : const Color(0xFFFFF7F0),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: AppColors.brandAmber.withValues(alpha: isDark ? 0.4 : 0.3),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: AppColors.brandAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.operationalRule!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
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

            // 7. Optional Quick Action Button (Navigates to screen safely)
            if (step.actionRoute != null && step.actionLabel != null) ...[
              AppSpacing.vSpaceMd,
              Center(
                child: TextButton.icon(
                  onPressed: () => context.push(step.actionRoute!),
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: AppColors.matchaSageLight,
                  ),
                  label: Text(
                    step.actionLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.matchaSageLight,
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
