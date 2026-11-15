import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/spotlight_step_model.dart';

/// Luxury instructional coach-mark card rendered near the spotlight target
class SpotlightInstructionalCard extends StatelessWidget {
  final SpotlightStepModel step;
  final int totalSteps;
  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final bool isDark;
  final String finishButtonText;

  const SpotlightInstructionalCard({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.isFirstStep,
    required this.isLastStep,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    this.isDark = true,
    this.finishButtonText = 'Finish Tour',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: const TextStyle(
          decoration: TextDecoration.none,
          fontFamily: 'Inter',
          color: Colors.white,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xF41E1712), // Deep roasted espresso luxury glass
            borderRadius: AppRadius.radiusXl,
            border: Border.all(
              color: AppColors.brandAmber.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.brandAmber.withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // 1. Header: Step Category Badge & Skip Button
                // -------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandAmber.withValues(alpha: 0.20),
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(
                            color: AppColors.brandAmber.withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              step.icon,
                              size: 12.5,
                              color: AppColors.cremaGold,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'STEP ${step.stepNumber} OF $totalSteps • ${step.categoryTitle.toUpperCase()}',
                                style: const TextStyle(
                                  color: AppColors.cremaGold,
                                  fontSize: 9.8,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  decoration: TextDecoration.none,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onSkip,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          'Skip Tour',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // -------------------------------------------------------------
                // 2. Feature Title - Semibold weight, high contrast, no underline
                // -------------------------------------------------------------
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.white,
                    height: 1.24,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),

                // -------------------------------------------------------------
                // 3. Short Explanation - Comfortable line height, no underline
                // -------------------------------------------------------------
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Color(0xFFDCD2C9),
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                    decoration: TextDecoration.none,
                  ),
                ),

                // -------------------------------------------------------------
                // 4. Bullet Takeaways / Checklist items (if any)
                // -------------------------------------------------------------
                if (step.keyPoints.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...step.keyPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 3.5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0, right: 6),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 12.5,
                              color: AppColors.brandAmberLight,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFC8BDB2),
                                height: 1.30,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // -------------------------------------------------------------
                // 5. Progress Dots & Action Buttons
                // -------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Step Progress Dots
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(totalSteps, (index) {
                            final isCurrent = index == step.stepNumber - 1;
                            final isPassed = index < step.stepNumber - 1;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(right: 3),
                              width: isCurrent ? 12 : 3.5,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.brandAmberLight
                                    : isPassed
                                        ? AppColors.brandAmber.withValues(alpha: 0.55)
                                        : Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Controls (Back / Next / Finish)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isFirstStep) ...[
                              GestureDetector(
                                onTap: onPrevious,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: AppRadius.radiusPill,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back_rounded, size: 12, color: Colors.white),
                                      SizedBox(width: 3),
                                      Text(
                                        'Back',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.1,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],

                            // Next / Finish Button
                            GestureDetector(
                              onTap: onNext,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.brandAmber,
                                      Color(0xFFE5A862),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: AppRadius.radiusPill,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandAmber.withValues(alpha: 0.40),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isLastStep ? finishButtonText : 'Next',
                                      style: const TextStyle(
                                        color: Color(0xFF140F0B),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isLastStep
                                          ? Icons.check_circle_rounded
                                          : Icons.arrow_forward_rounded,
                                      size: 13,
                                      color: const Color(0xFF140F0B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
