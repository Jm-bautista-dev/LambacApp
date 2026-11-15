import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/historical_vs_forecast_data_point.dart';

/// Forecast Chart Component Visually Distinguishing Historical Data from Forecasted Data with Confidence Range
class HistoricalVsForecastChart extends ConsumerWidget {
  final List<HistoricalVsForecastDataPoint> points;

  const HistoricalVsForecastChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (points.isEmpty) {
      return AppCard.elevated(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 36,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              AppSpacing.vSpaceSm,
              Text(
                'No forecast projection points available for this period',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    double maxVal = 1.0;
    for (final pt in points) {
      final val = pt.upperBound ?? pt.predictedSales ?? pt.actualSales ?? 0.0;
      if (val > maxVal) maxVal = val;
    }
    maxVal = maxVal * 1.1; // Add 10% headroom

    final historicalCount = points.where((p) => !p.isForecasted).length;
    final forecastCount = points.where((p) => p.isForecasted).length;

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historical Sales vs. Forecast Projection',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Actual historical records ($historicalCount days) ➔ Projected forward ($forecastCount days)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Chart Legends
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildLegendItem(
                'Actual Historical Sales',
                isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                false,
                isDark,
              ),
              _buildLegendItem(
                'ML Projected Forecast',
                isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                true,
                isDark,
              ),
              _buildLegendItem(
                '95% Uncertainty Range (±Bound)',
                (isDark ? AppColors.cremaGold : AppColors.brandAmber).withOpacity(0.35),
                false,
                isDark,
                isDashed: true,
              ),
            ],
          ),
          AppSpacing.vSpaceLg,

          // Visualization Bars
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((pt) {
                final value = pt.actualSales ?? pt.predictedSales ?? 0.0;
                final heightRatio = (value / maxVal).clamp(0.06, 1.0);
                final isForecast = pt.isForecasted;

                final primaryColor = isForecast
                    ? (isDark ? AppColors.cremaGold : AppColors.brandAmberDark)
                    : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber);

                final tooltipMsg = isForecast
                    ? '${pt.dateLabel} (Forecast)\nExpected: ${CurrencyFormatter.format(value)}\n95% Bound: ₱${(pt.lowerBound ?? value * 0.9).toStringAsFixed(0)} – ₱${(pt.upperBound ?? value * 1.1).toStringAsFixed(0)}'
                    : '${pt.dateLabel} (Actual)\nRevenue: ${CurrencyFormatter.format(value)}';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: tooltipMsg,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Optional Uncertainty Shading for Forecasted Points
                              if (isForecast && pt.upperBound != null && pt.lowerBound != null) ...[
                                Container(
                                  height: (pt.upperBound! / maxVal).clamp(0.1, 1.0) * 150,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(AppRadius.radiusSm.topLeft.x + 2),
                                    ),
                                    border: Border(
                                      top: BorderSide(color: primaryColor.withOpacity(0.6), width: 1.2),
                                    ),
                                  ),
                                ),
                              ],

                              // Main Bar
                              Container(
                                height: 150 * heightRatio,
                                decoration: BoxDecoration(
                                  color: isForecast ? primaryColor.withOpacity(0.7) : primaryColor,
                                  borderRadius: BorderRadius.vertical(top: AppRadius.radiusSm.topLeft),
                                  border: isForecast
                                      ? Border.all(color: primaryColor, width: 1.5)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pt.dateLabel,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: isForecast ? FontWeight.w700 : FontWeight.w500,
                            color: isForecast
                                ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                                : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
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

  Widget _buildLegendItem(
    String label,
    Color color,
    bool isBordered,
    bool isDark, {
    bool isDashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isBordered ? color.withOpacity(0.5) : color,
            borderRadius: BorderRadius.circular(3),
            border: isBordered || isDashed
                ? Border.all(
                    color: isDashed ? color.withOpacity(0.9) : color,
                    width: 1.5,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
