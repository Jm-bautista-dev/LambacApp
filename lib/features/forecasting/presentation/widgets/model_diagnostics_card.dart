import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/forecast_summary_model.dart';

/// Technical Model Diagnostics Card for Academic / Research Evaluation
class ModelDiagnosticsCard extends StatelessWidget {
  final ForecastSummaryModel summary;

  const ModelDiagnosticsCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ExpansionTile(
      title: Text(
        'Technical Model Diagnostics & Metrics',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        'MAE, RMSE, MAPE statistical model evaluation',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
      leading: Icon(
        Icons.analytics_outlined,
        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDiagRow('Algorithmic Model', summary.modelName, isDark),
              const SizedBox(height: 6),
              _buildDiagRow('Validation Horizon', summary.evaluationPeriodLabel, isDark),
              const SizedBox(height: 6),
              _buildDiagRow('Expected 95% Range', '₱${summary.expectedLowerRange.toStringAsFixed(0)} – ₱${summary.expectedUpperRange.toStringAsFixed(0)}', isDark),
              const Divider(height: 16),
              _buildDiagRow('MAE (Mean Absolute Error)', '₱${summary.mae.toStringAsFixed(2)}', isDark),
              const SizedBox(height: 6),
              _buildDiagRow('RMSE (Root Mean Sq. Error)', '₱${summary.rmse.toStringAsFixed(2)}', isDark),
              const SizedBox(height: 6),
              _buildDiagRow('sMAPE (Symmetric MAPE)', '${summary.smape.toStringAsFixed(1)}% (Zero-safe relative error)', isDark, isAccent: true),
              const SizedBox(height: 6),
              _buildDiagRow('Benchmark Error Score', summary.benchmarkScore.toStringAsFixed(1), isDark),
              AppSpacing.vSpaceMd,
              Text(
                'Statistical Notes: MAE & RMSE measure absolute revenue error in Philippine Pesos (₱). sMAPE measures symmetric relative error. Automatic Model Selection continuously tests 7 algorithm families (Linear, Quadratic, Single ES, Holt Trend, Holt-Winters Seasonal, Moving Average, Naive) via rolling-origin backtesting and deploys the lowest-error model.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagRow(String label, String value, bool isDark, {bool isAccent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isAccent
                  ? AppColors.success
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
