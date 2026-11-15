import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/model_benchmark_result.dart';

/// Visual Error Metrics Comparison Bar Charts (MAE/RMSE & MAPE/sMAPE)
class BenchmarkingErrorChart extends StatelessWidget {
  final List<ModelBenchmarkResult> results;

  const BenchmarkingErrorChart({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxCurrencyError = 1.0;
    double maxPctError = 1.0;

    for (final r in results) {
      maxCurrencyError = math.max(maxCurrencyError, math.max(r.mae, r.rmse));
      maxPctError = math.max(maxPctError, math.max(r.mape, r.smape));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        final maeRmseChart = _buildErrorBarCard(
          title: 'Model Absolute Error Comparison (₱)',
          subtitle: 'Validation MAE vs RMSE by Algorithm (Lower is better)',
          icon: Icons.bar_chart_rounded,
          isDark: isDark,
          maxVal: maxCurrencyError,
          val1Label: 'MAE (₱)',
          val2Label: 'RMSE (₱)',
          val1Color: AppColors.brandAmber,
          val2Color: isDark ? const Color(0xFFE29578) : const Color(0xFFB04A26),
          itemBuilder: (r) => (val1: r.mae, val2: r.rmse, format: (v) => '₱${v.toStringAsFixed(0)}'),
        );

        final percentageChart = _buildErrorBarCard(
          title: 'Percentage Error Comparison (%)',
          subtitle: 'Validation MAPE vs sMAPE by Algorithm (Lower is better)',
          icon: Icons.percent_rounded,
          isDark: isDark,
          maxVal: maxPctError,
          val1Label: 'MAPE (%)',
          val2Label: 'sMAPE (%)',
          val1Color: isDark ? const Color(0xFF83C5BE) : const Color(0xFF006D77),
          val2Color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
          itemBuilder: (r) => (val1: r.mape, val2: r.smape, format: (v) => '${v.toStringAsFixed(1)}%'),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: maeRmseChart),
              const SizedBox(width: 14),
              Expanded(child: percentageChart),
            ],
          );
        }

        return Column(
          children: [
            maeRmseChart,
            AppSpacing.vSpaceLg,
            percentageChart,
          ],
        );
      },
    );
  }

  Widget _buildErrorBarCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required double maxVal,
    required String val1Label,
    required String val2Label,
    required Color val1Color,
    required Color val2Color,
    required ({double val1, double val2, String Function(double) format}) Function(ModelBenchmarkResult) itemBuilder,
  }) {
    return AppCard.elevated(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.brandAmber, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
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
          AppSpacing.vSpaceMd,

          // Legend
          Row(
            children: [
              _buildLegendBadge(val1Label, val1Color, isDark),
              const SizedBox(width: 12),
              _buildLegendBadge(val2Label, val2Color, isDark),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Bars List
          ...results.map((result) {
            final data = itemBuilder(result);
            final ratio1 = (data.val1 / maxVal).clamp(0.04, 1.0);
            final ratio2 = (data.val2 / maxVal).clamp(0.04, 1.0);
            final isWinner = result.isWinner;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isWinner) ...[
                            const Icon(Icons.star_rounded, size: 12, color: AppColors.brandAmber),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            result.candidateType.shortCode,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                              color: isWinner
                                  ? (isDark ? AppColors.cremaGold : AppColors.brandAmberDark)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '#${result.rank}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${data.format(data.val1)} / ${data.format(data.val2)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Dual Horizontal Bars
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 12,
                      width: double.infinity,
                      color: isDark ? const Color(0xFF261E18) : const Color(0xFFEBE3DC),
                      child: Stack(
                        children: [
                          // Bar 2 (Background / larger)
                          FractionallySizedBox(
                            widthFactor: ratio2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: val2Color.withOpacity(isWinner ? 0.9 : 0.65),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // Bar 1 (Foreground / smaller)
                          FractionallySizedBox(
                            widthFactor: ratio1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: val1Color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegendBadge(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
