import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/forecast_summary_model.dart';

/// Interactive Candidate Model Benchmark Leaderboard & Selection Card
class ModelBenchmarkLeaderboardCard extends StatelessWidget {
  final ForecastSummaryModel summary;
  final VoidCallback onRebenchmark;

  const ModelBenchmarkLeaderboardCard({
    super.key,
    required this.summary,
    required this.onRebenchmark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final winner = summary.benchmarkResults.isNotEmpty ? summary.benchmarkResults.first : null;

    return AppCard.elevated(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandAmber.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: AppColors.brandAmber, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automatic Model Selection',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        summary.evaluationPeriodLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Re-evaluate & Benchmark Models',
                onPressed: onRebenchmark,
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Winning Model Showcase Banner
          if (winner != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF281C13), const Color(0xFF1E140D)]
                      : [const Color(0xFFFDF7F2), const Color(0xFFF7EFE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: AppColors.brandAmber.withOpacity(0.5),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandAmber,
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'RANK 1 WINNER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          summary.modelName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.selectionReason,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          AppSpacing.vSpaceMd,

          // Candidate Models Benchmark Leaderboard
          Text(
            'BENCHMARK CANDIDATE LEADERBOARD (${summary.benchmarkResults.length} EVALUATED)',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          AppSpacing.vSpaceSm,

          // Leaderboard List
          ...summary.benchmarkResults.map((result) {
            final isWinner = result.isWinner;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isWinner
                    ? (isDark ? AppColors.brandAmber.withOpacity(0.12) : AppColors.brandAmber.withOpacity(0.08))
                    : (isDark ? AppColors.darkSurface : Colors.white),
                borderRadius: AppRadius.radiusSm,
                border: Border.all(
                  color: isWinner
                      ? AppColors.brandAmber.withOpacity(0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isWinner ? 1.0 : 0.8,
                ),
              ),
              child: Row(
                children: [
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
                      '${result.rank}',
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
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.modelName,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'MAE: ₱${result.mae.toStringAsFixed(1)} • RMSE: ₱${result.rmse.toStringAsFixed(1)} • sMAPE: ${result.smape.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                      Text(
                        result.compositeScore.toStringAsFixed(1),
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
        ],
      ),
    );
  }
}
