import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/forecasting_benchmark_report_model.dart';

/// KPI Header Showcase for Forecasting Benchmarking Dashboard
class BenchmarkingKpiHeader extends StatelessWidget {
  final ForecastingBenchmarkReportModel report;
  final bool isRebenchmarking;

  const BenchmarkingKpiHeader({
    super.key,
    required this.report,
    this.isRebenchmarking = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final winner = report.winningModel;
    final lastBenchFormatted = DateFormat('MMM d, yyyy • h:mm a').format(report.benchmarkTimestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Winner Spotlight Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2E1F14), const Color(0xFF1E140C)]
                  : [const Color(0xFFFDF7F2), const Color(0xFFF4ECE4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: isDark ? AppColors.cremaGold.withOpacity(0.6) : AppColors.brandAmber.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandAmber,
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'CURRENT BEST MODEL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          report.granularity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Benchmark Status Badge
                  _buildStatusPill(isDark),
                ],
              ),
              AppSpacing.vSpaceMd,

              // Winning Model Title
              Text(
                winner.modelName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                ),
              ),
              const SizedBox(height: 6),

              // Winner Dynamic Reason
              Text(
                report.winnerExplanation,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
              AppSpacing.vSpaceMd,
              Divider(
                height: 1,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
              AppSpacing.vSpaceSm,

              // Metadata Row (Evaluation Period & Last Benchmark Date)
              Wrap(
                spacing: 20,
                runSpacing: 6,
                children: [
                  _buildMetaItem(
                    Icons.calendar_today_rounded,
                    'Evaluation Period',
                    report.evaluationPeriodLabel,
                    isDark,
                  ),
                  _buildMetaItem(
                    Icons.history_rounded,
                    'Last Benchmark Date',
                    lastBenchFormatted,
                    isDark,
                  ),
                  _buildMetaItem(
                    Icons.dataset_rounded,
                    'Split Ratio',
                    '${report.trainingPoints} Train / ${report.validationPoints} Validation points',
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.vSpaceLg,

        // Metric Stat Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 650;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isWide ? 1.6 : 1.45,
              children: [
                _buildStatCard(
                  'Benchmark Score',
                  winner.compositeScore.toStringAsFixed(1),
                  'Weighted blend (Lower is better)',
                  Icons.military_tech_rounded,
                  isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                  isDark,
                ),
                _buildStatCard(
                  'Validation MAE',
                  '₱${winner.mae.toStringAsFixed(2)}',
                  'Mean Absolute Error (₱)',
                  Icons.trending_down_rounded,
                  AppColors.brandAmber,
                  isDark,
                ),
                _buildStatCard(
                  'Validation RMSE',
                  '₱${winner.rmse.toStringAsFixed(2)}',
                  'Root Mean Squared Error (₱)',
                  Icons.analytics_rounded,
                  isDark ? const Color(0xFFE29578) : const Color(0xFFB04A26),
                  isDark,
                ),
                _buildStatCard(
                  'Validation sMAPE',
                  '${winner.smape.toStringAsFixed(1)}%',
                  'Symmetric MAPE (MAPE: ${winner.mape.toStringAsFixed(1)}%)',
                  Icons.query_stats_rounded,
                  isDark ? const Color(0xFF83C5BE) : const Color(0xFF006D77),
                  isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusPill(bool isDark) {
    if (isRebenchmarking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.brandAmber.withOpacity(0.2),
          borderRadius: AppRadius.radiusPill,
          border: Border.all(color: AppColors.brandAmber),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandAmber),
            ),
            SizedBox(width: 6),
            Text(
              'Benchmarking...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.brandAmber,
              ),
            ),
          ],
        ),
      );
    }

    final isOk = report.status == 'Up to date';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOk
            ? (isDark ? const Color(0xFF1B3828) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF3E2818) : const Color(0xFFFFF3E0)),
        borderRadius: AppRadius.radiusPill,
        border: Border.all(
          color: isOk ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOk ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            report.status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOk
                  ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                  : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
    bool isDark,
  ) {
    return AppCard.elevated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
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
}
