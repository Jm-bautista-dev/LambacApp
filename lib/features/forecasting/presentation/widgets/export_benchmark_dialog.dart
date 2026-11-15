import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../data/models/forecasting_benchmark_report_model.dart';
import '../../data/models/model_benchmark_result.dart';

/// Export Benchmark Dialog with CSV & Text Audit Output respecting selected date filter
class ExportBenchmarkDialog extends StatelessWidget {
  final ForecastingBenchmarkReportModel report;

  const ExportBenchmarkDialog({
    super.key,
    required this.report,
  });

  static Future<void> show(BuildContext context, ForecastingBenchmarkReportModel report) {
    return showDialog<void>(
      context: context,
      builder: (context) => ExportBenchmarkDialog(report: report),
    );
  }

  String _generateCsvContent() {
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    final buffer = StringBuffer();

    // Metadata header
    buffer.writeln('# LAMBAC COFFEE ROASTERY - FORECASTING BENCHMARK AUDIT REPORT');
    buffer.writeln('# Benchmark Timestamp,${df.format(report.benchmarkTimestamp)}');
    buffer.writeln('# Evaluation Period,${report.evaluationPeriodLabel}');
    buffer.writeln('# Start Date,${DateFormat('yyyy-MM-dd').format(report.startDate)}');
    buffer.writeln('# End Date,${DateFormat('yyyy-MM-dd').format(report.endDate)}');
    buffer.writeln('# Time Granularity,${report.granularity}');
    buffer.writeln('# Total Dataset Points,${report.totalObservedPoints}');
    buffer.writeln('# Training Window,${report.trainingPoints} points');
    buffer.writeln('# Validation Window,${report.validationPoints} points');
    buffer.writeln('# Winning Model,${report.winningModel.modelName}');
    buffer.writeln('# Winner Rationale,"${report.winnerExplanation.replaceAll('"', '""')}"');
    buffer.writeln('');

    // Table Header
    buffer.writeln('Rank,Model Name,Short Code,MAE (PHP),RMSE (PHP),MAPE (%),sMAPE (%),Composite Score,Selected Best');

    // Rows
    for (final r in report.benchmarkResults) {
      buffer.writeln(
        '${r.rank},"${r.modelName}",${r.candidateType.shortCode},${r.mae.toStringAsFixed(2)},${r.rmse.toStringAsFixed(2)},${r.mape.toStringAsFixed(2)},${r.smape.toStringAsFixed(2)},${r.compositeScore.toStringAsFixed(2)},${r.isWinner ? "YES (WINNER)" : "NO"}',
      );
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final csvContent = _generateCsvContent();

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandAmber.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.file_download_outlined, color: AppColors.brandAmber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Forecasting Benchmark Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Period: ${report.evaluationPeriodLabel} (${report.granularity})',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            AppSpacing.vSpaceMd,

            // Description info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF9F5F0),
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 16, color: AppColors.brandAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Includes full audit trails, ${report.benchmarkResults.length} candidate model rankings, MAE, RMSE, sMAPE, and dataset split metadata.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vSpaceMd,

            // CSV Preview Box
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF140E0A) : const Color(0xFFF4ECE5),
                  borderRadius: AppRadius.radiusSm,
                  border: Border.all(
                    color: isDark ? const Color(0xFF332418) : const Color(0xFFE2D6CB),
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csvContent,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFFE8DCCF) : const Color(0xFF332418),
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
            AppSpacing.vSpaceLg,

            // Bottom Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                AppButton.primary(
                  text: 'Copy CSV to Clipboard',
                  leadingIcon: const Icon(Icons.copy_rounded, size: 16),
                  size: AppButtonSize.small,
                  isFullWidth: false,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: csvContent));
                    Navigator.pop(context);
                    AppToast.success(
                      context,
                      'Benchmark audit data for ${report.evaluationPeriodLabel} copied to clipboard!',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
