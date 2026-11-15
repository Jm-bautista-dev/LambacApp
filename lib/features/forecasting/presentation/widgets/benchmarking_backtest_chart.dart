import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/benchmark_backtest_point.dart';
import '../../data/models/model_benchmark_result.dart';

/// Backtest Actual vs Predicted Validation Curve Visualization
class BenchmarkingBacktestChart extends StatelessWidget {
  final List<BenchmarkBacktestPoint> points;
  final ModelBenchmarkResult winningModel;

  const BenchmarkingBacktestChart({
    super.key,
    required this.points,
    required this.winningModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxVal = 1.0;
    for (final pt in points) {
      maxVal = math.max(maxVal, math.max(pt.actualSales, pt.winnerPredictedSales));
    }

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
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
                      color: AppColors.brandAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.show_chart_rounded, color: AppColors.brandAmber, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Out-of-Sample Backtest: Actual vs ${winningModel.modelName}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Walk-forward validation test horizon showing real receipts vs model prediction fit',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF2ECE6),
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Text(
                  '${points.length} Test Steps',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Legend
          Row(
            children: [
              _buildLegend('Actual Sales', isDark ? AppColors.darkTextPrimary : Colors.black87, false, isDark),
              const SizedBox(width: 16),
              _buildLegend('${winningModel.candidateType.shortCode} Prediction (Winner)', AppColors.brandAmber, true, isDark),
            ],
          ),
          AppSpacing.vSpaceLg,

          // Visual Columns
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((pt) {
                final actualHeightRatio = (pt.actualSales / maxVal).clamp(0.06, 1.0);
                final predHeightRatio = (pt.winnerPredictedSales / maxVal).clamp(0.06, 1.0);
                final diff = (pt.actualSales - pt.winnerPredictedSales).abs();

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message:
                              '${pt.dateLabel}\nActual: ${CurrencyFormatter.format(pt.actualSales)}\nPredicted: ${CurrencyFormatter.format(pt.winnerPredictedSales)}\nDiff: ${CurrencyFormatter.format(diff)}',
                          child: SizedBox(
                            height: 130,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Actual Bar
                                Container(
                                  width: 8,
                                  height: 130 * actualHeightRatio,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF7E7268) : const Color(0xFF5A4D43),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                // Winner Prediction Bar
                                Container(
                                  width: 8,
                                  height: 130 * predHeightRatio,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandAmber,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.brandAmber.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, -1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pt.dateLabel,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, bool isWinner, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            color: isWinner
                ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ],
    );
  }
}
