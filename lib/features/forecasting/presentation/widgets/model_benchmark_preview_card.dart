import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/forecast_summary_model.dart';

/// Compact Model Benchmark Preview Card
/// Shows top evaluated candidate models and provides a direct entry point to the dedicated Benchmarking module.
class ModelBenchmarkPreviewCard extends StatelessWidget {
  final ForecastSummaryModel summary;
  final VoidCallback onViewFullBenchmark;
  final VoidCallback onRebenchmark;

  const ModelBenchmarkPreviewCard({
    super.key,
    required this.summary,
    required this.onViewFullBenchmark,
    required this.onRebenchmark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final candidates = summary.benchmarkResults.take(4).toList();

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.brandAmber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.leaderboard_rounded,
                        color: AppColors.brandAmber,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Model Benchmark',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Top candidate algorithms evaluated by lowest backtest error',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 19),
                tooltip: 'Re-evaluate Candidate Models',
                onPressed: onRebenchmark,
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Candidate List (Top 4)
          ...candidates.map((candidate) {
            final isWinner = candidate.isWinner;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isWinner
                    ? (isDark ? AppColors.brandAmber.withOpacity(0.12) : const Color(0xFFFDF7F2))
                    : (isDark ? AppColors.darkSurface : Colors.white),
                borderRadius: AppRadius.radiusSm,
                border: Border.all(
                  color: isWinner
                      ? AppColors.brandAmber.withOpacity(0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isWinner ? 1.2 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  // Rank Badge
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isWinner
                          ? AppColors.brandAmber
                          : (isDark ? const Color(0xFF2C221C) : const Color(0xFFEDE5DF)),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${candidate.rank}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isWinner
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Model Name & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                candidate.modelName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isWinner) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.brandAmber,
                                  borderRadius: AppRadius.radiusPill,
                                ),
                                child: const Text(
                                  'BEST',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MAE: ₱${candidate.mae.toStringAsFixed(1)} • RMSE: ₱${candidate.rmse.toStringAsFixed(1)} • sMAPE: ${candidate.smape.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score Column
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                      Text(
                        candidate.compositeScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isWinner
                              ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          AppSpacing.vSpaceSm,

          // View Full Benchmark Navigation Button
          InkWell(
            onTap: onViewFullBenchmark,
            borderRadius: AppRadius.radiusSm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF281C13) : const Color(0xFFF7EFE8),
                borderRadius: AppRadius.radiusSm,
                border: Border.all(
                  color: isDark ? AppColors.brandAmberLight.withOpacity(0.4) : AppColors.brandAmber.withOpacity(0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics_rounded, size: 16, color: AppColors.brandAmber),
                  const SizedBox(width: 8),
                  Text(
                    'View Full Benchmark & Backtest Audit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brandAmber),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
