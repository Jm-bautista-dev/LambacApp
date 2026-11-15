import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/forecast_summary_model.dart';

/// Measurable Model Reliability & Error Metrics Card
/// Replaces arbitrary AI confidence percentages with empirical validation evidence.
class ModelReliabilityCard extends StatelessWidget {
  final ForecastSummaryModel summary;

  const ModelReliabilityCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.brandAmberLight : AppColors.brandAmber).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model Reliability & Validation Metrics',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Empirical out-of-sample error measurements (Zero arbitrary confidence scores)',
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
          AppSpacing.vSpaceLg,

          // Grid of 4 Measurable Reliability Metrics
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isWide ? 1.5 : 1.4,
                children: [
                  _buildMetricTile(
                    'Validation MAE',
                    '₱${summary.mae.toStringAsFixed(2)}',
                    'Mean Absolute Error in revenue',
                    Icons.trending_down_rounded,
                    AppColors.brandAmber,
                    isDark,
                  ),
                  _buildMetricTile(
                    'Validation RMSE',
                    '₱${summary.rmse.toStringAsFixed(2)}',
                    'Penalizes large forecast variance',
                    Icons.insights_rounded,
                    isDark ? const Color(0xFFE29578) : const Color(0xFFB04A26),
                    isDark,
                  ),
                  _buildMetricTile(
                    'Validation sMAPE',
                    '${summary.smape.toStringAsFixed(1)}%',
                    'Symmetric Percentage Error',
                    Icons.percent_rounded,
                    isDark ? const Color(0xFF83C5BE) : const Color(0xFF006D77),
                    isDark,
                  ),
                  _buildMetricTile(
                    'History Samples',
                    '${summary.points.length} Points',
                    'Historical ledger observations',
                    Icons.dataset_rounded,
                    isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                    isDark,
                  ),
                ],
              );
            },
          ),
          AppSpacing.vSpaceMd,

          // Summary Specification Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF9F6F0),
              borderRadius: AppRadius.radiusSm,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpecRow('Selected Algorithm', summary.modelName, isDark),
                const Divider(height: 10),
                _buildSpecRow('Validation Horizon', summary.evaluationPeriodLabel, isDark),
                const Divider(height: 10),
                _buildSpecRow('Composite Error Score', summary.benchmarkScore.toStringAsFixed(2), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
