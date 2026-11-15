import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../data/models/forecasting_benchmark_report_model.dart';
import '../../data/models/model_benchmark_result.dart';

/// In-Depth Candidate Model Inspector Modal Sheet
class ModelInspectionDialog extends StatelessWidget {
  final ModelBenchmarkResult model;
  final ForecastingBenchmarkReportModel report;

  const ModelInspectionDialog({
    super.key,
    required this.model,
    required this.report,
  });

  static Future<void> show(
    BuildContext context, {
    required ModelBenchmarkResult model,
    required ForecastingBenchmarkReportModel report,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModelInspectionDialog(model: model, report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWinner = model.isWinner;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isWinner
                  ? AppColors.brandAmber.withOpacity(0.6)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF4A3E36) : const Color(0xFFD4C8BE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Content
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isWinner
                                ? AppColors.brandAmber.withOpacity(0.18)
                                : (isDark ? AppColors.darkSurface : const Color(0xFFEDE5DF)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isWinner ? Icons.emoji_events_rounded : Icons.analytics_outlined,
                            color: isWinner ? AppColors.brandAmber : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isWinner ? AppColors.brandAmber : (isDark ? const Color(0xFF33271E) : const Color(0xFFE5DDD6)),
                                      borderRadius: AppRadius.radiusPill,
                                    ),
                                    child: Text(
                                      isWinner ? '✓ SELECTED BEST MODEL' : 'RANK #${model.rank}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isWinner ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    model.candidateType.shortCode,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                model.modelName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    AppSpacing.vSpaceLg,

                    // Algorithm Description
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFFAF6F2),
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MATHEMATICAL FORMULATION & BEHAVIOR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model.candidateType.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vSpaceLg,

                    // Metrics Breakdown Grid
                    Text(
                      'OUT-OF-SAMPLE BACKTEST METRICS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                    AppSpacing.vSpaceSm,

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.55,
                      children: [
                        _buildMetricBox('Mean Absolute Error (MAE)', '₱${model.mae.toStringAsFixed(2)}', isDark),
                        _buildMetricBox('Root Mean Squared Error (RMSE)', '₱${model.rmse.toStringAsFixed(2)}', isDark),
                        _buildMetricBox('Mean Abs Percentage Error (MAPE)', '${model.mape.toStringAsFixed(1)}%', isDark),
                        _buildMetricBox('Symmetric MAPE (sMAPE)', '${model.smape.toStringAsFixed(1)}%', isDark),
                        _buildMetricBox('Composite Score', model.compositeScore.toStringAsFixed(1), isDark),
                        _buildMetricBox('Backtest Rank', '#${model.rank} of ${report.benchmarkResults.length}', isDark),
                      ],
                    ),
                    AppSpacing.vSpaceLg,

                    // Evaluation Window & Split Information
                    Text(
                      'BACKTEST DATASET SCOPE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                    AppSpacing.vSpaceSm,

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Evaluation Period', report.evaluationPeriodLabel, isDark),
                          _buildDetailRow('Time Granularity', report.granularity, isDark),
                          _buildDetailRow('Total Observations', '${report.totalObservedPoints} points', isDark),
                          _buildDetailRow('Training Window Size', '${report.trainingPoints} points (${((report.trainingPoints / math.max(1, report.totalObservedPoints)) * 100).toStringAsFixed(0)}%)', isDark),
                          _buildDetailRow('Validation Test Window', '${report.validationPoints} points (${((report.validationPoints / math.max(1, report.totalObservedPoints)) * 100).toStringAsFixed(0)}%)', isDark),
                          _buildDetailRow('Validation Protocol', 'Rolling-Origin Walk-Forward (1-Step Ahead)', isDark),
                        ],
                      ),
                    ),
                    AppSpacing.vSpaceLg,

                    // Rationale
                    Text(
                      'EMPIRICAL DIAGNOSTIC RATIONALE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                    AppSpacing.vSpaceSm,
                    Text(
                      model.rationale,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    AppSpacing.vSpaceXl,

                    // Close Button
                    AppButton.secondary(
                      text: 'Close Inspection',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF9F6F3),
        borderRadius: AppRadius.radiusSm,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
