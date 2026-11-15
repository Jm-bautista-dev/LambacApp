import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';

/// Compact Visual Methodology Panel for Academic Defensibility & Transparency
class HowForecastingWorksCard extends StatelessWidget {
  const HowForecastingWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final steps = [
      (
        '1. Historical Sales',
        'Ledger aggregates past daily transactions & volume.',
        Icons.receipt_long_rounded,
      ),
      (
        '2. Candidate Models',
        '7 candidate algorithms (HW Seasonal, Holt, OLS, SES, MA, Poly, Naive) initialized.',
        Icons.hub_rounded,
      ),
      (
        '3. Backtesting',
        'Models predict historical unseen partitions with walk-forward origin.',
        Icons.science_rounded,
      ),
      (
        '4. Error Metrics',
        'Calculates out-of-sample MAE, RMSE, and zero-safe sMAPE/MAPE.',
        Icons.analytics_rounded,
      ),
      (
        '5. Automatic Selection',
        'The lowest composite-error model is promoted to production.',
        Icons.verified_rounded,
      ),
      (
        '6. Future Forecast',
        'Optimal model projects revenue and bag depletion forward.',
        Icons.trending_up_rounded,
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree_rounded,
                size: 18,
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              ),
              const SizedBox(width: 8),
              Text(
                'How Forecasting Works',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceSm,
          Text(
            'Objective, empirical model selection pipeline (Academic capstone methodology)',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          AppSpacing.vSpaceLg,

          // 6-Step Visual Flow Grid / Wrap
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 96,
                ),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: AppRadius.radiusSm,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              step.$3,
                              size: 14,
                              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                step.$1,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          step.$2,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.25,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
