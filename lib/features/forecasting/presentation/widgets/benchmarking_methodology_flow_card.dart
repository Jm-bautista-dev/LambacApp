import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';

/// Academic Defensibility Pipeline Flow Card
/// Explains the 7-stage empirical model selection methodology
class BenchmarkingMethodologyFlowCard extends StatelessWidget {
  const BenchmarkingMethodologyFlowCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final steps = [
      (
        step: '1',
        title: 'Historical Data',
        desc: 'Actual daily sales ledger (non-voided store receipts)',
        icon: Icons.receipt_long_rounded,
      ),
      (
        step: '2',
        title: 'Candidate Models',
        desc: '7 algorithms: HW Seasonal, Holt, OLS Linear, SES, MA, Poly, Naive',
        icon: Icons.hub_rounded,
      ),
      (
        step: '3',
        title: 'Walk-Forward Backtesting',
        desc: 'Rolling-origin temporal validation without lookahead leakage',
        icon: Icons.alt_route_rounded,
      ),
      (
        step: '4',
        title: 'Error Metrics',
        desc: 'Out-of-sample MAE, RMSE, MAPE, and sMAPE calculation',
        icon: Icons.calculate_rounded,
      ),
      (
        step: '5',
        title: 'Benchmark Ranking',
        desc: 'Weighted error score evaluation across all 7 candidates',
        icon: Icons.leaderboard_rounded,
      ),
      (
        step: '6',
        title: 'Best Model Winner',
        desc: 'Lowest-error model crowned automatically as Rank 1',
        icon: Icons.emoji_events_rounded,
      ),
      (
        step: '7',
        title: 'Empirical Forecast',
        desc: 'Production sales & stockout depletion projection',
        icon: Icons.trending_up_rounded,
      ),
    ];

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.brandAmber, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated Model Selection Methodology',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Empirical, auditable, and academically defensible 7-stage evaluation pipeline',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Horizontal scrollable step flow
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  // Arrow separator
                  return Container(
                    padding: const EdgeInsets.only(top: 24, left: 4, right: 4),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: isDark ? AppColors.brandAmberLight.withOpacity(0.6) : AppColors.brandAmber.withOpacity(0.6),
                    ),
                  );
                }

                final stepIdx = i ~/ 2;
                final item = steps[stepIdx];
                final isLast = stepIdx == steps.length - 1;
                final isWinner = stepIdx == 5;

                return Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isWinner
                        ? (isDark ? AppColors.brandAmber.withOpacity(0.18) : AppColors.brandAmber.withOpacity(0.12))
                        : (isDark ? AppColors.darkSurface : const Color(0xFFF9F6F3)),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: isWinner
                          ? AppColors.brandAmber
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isWinner ? 1.4 : 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isWinner ? AppColors.brandAmber : (isDark ? const Color(0xFF33271E) : const Color(0xFFE5DDD6)),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.step,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isWinner ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                          Icon(
                            item.icon,
                            size: 16,
                            color: isWinner ? AppColors.brandAmber : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isWinner
                              ? (isDark ? AppColors.cremaGold : AppColors.brandAmberDark)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.desc,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          AppSpacing.vSpaceMd,

          // Academic note footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2822) : const Color(0xFFEBF7F0),
              borderRadius: AppRadius.radiusSm,
              border: Border.all(
                color: isDark ? const Color(0xFF2E5D42) : const Color(0xFFB5E4CA),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No hardcoded algorithm preference. Model selection is 100% computed via out-of-sample backtesting against actual transactional demand.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
