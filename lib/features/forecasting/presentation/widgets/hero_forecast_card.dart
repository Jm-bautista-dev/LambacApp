import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/forecast_summary_model.dart';

/// Hero Forecast Showcase Card
/// Displays expected sales, uncertainty interval, winning model status, and expandable selection rationale.
class HeroForecastCard extends StatefulWidget {
  final ForecastSummaryModel summary;
  final VoidCallback onOpenBenchmark;

  const HeroForecastCard({
    super.key,
    required this.summary,
    required this.onOpenBenchmark,
  });

  @override
  State<HeroForecastCard> createState() => _HeroForecastCardState();
}

class _HeroForecastCardState extends State<HeroForecastCard> {
  bool _isWhyExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = widget.summary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C1E14), const Color(0xFF1B120B)]
              : [const Color(0xFFFDF7F2), const Color(0xFFF3ECE3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.cremaGold.withValues(alpha: 0.55) : AppColors.brandAmber.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------
          // Top Primary Forecast Block
          // -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Horizon Badge
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.brandAmber,
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_graph_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'SALES FORECAST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: AppRadius.radiusPill,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        summary.forecastPeriod,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpaceMd,

                // Big Forecast Value
                Text(
                  CurrencyFormatter.format(summary.expectedSales),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                  ),
                ),
                const SizedBox(height: 2),

                // Subtitle & Confidence Range
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Expected revenue (${summary.forecastPeriod})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                    Text(
                      'Range: ₱${summary.expectedLowerRange.toStringAsFixed(0)} – ₱${summary.expectedUpperRange.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpaceLg,

                // Metadata KPI Strip
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetaColumn(
                          'Recommended Model',
                          summary.modelName,
                          Icons.military_tech_rounded,
                          isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                          isDark,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                      ),
                      Expanded(
                        child: _buildMetaColumn(
                          'Validated Score',
                          summary.benchmarkScore.toStringAsFixed(1),
                          Icons.analytics_rounded,
                          isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                          isDark,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                      ),
                      Expanded(
                        child: _buildMetaColumn(
                          'Validation Error',
                          '${summary.smape.toStringAsFixed(1)}% sMAPE',
                          Icons.trending_down_rounded,
                          isDark ? const Color(0xFF83C5BE) : const Color(0xFF006D77),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),

          // -------------------------------------------------------------
          // "Why was this model selected?" Expandable Section
          // -------------------------------------------------------------
          InkWell(
            onTap: () => setState(() => _isWhyExpanded = !_isWhyExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 18,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Why was this model selected?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isWhyExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ],
              ),
            ),
          ),

          if (_isWhyExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.selectionReason,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  AppSpacing.vSpaceMd,

                  // Empirical Metrics Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: AppRadius.radiusSm,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        _buildMetricPill('Validation MAE', '₱${summary.mae.toStringAsFixed(2)}', isDark),
                        _buildMetricPill('Validation RMSE', '₱${summary.rmse.toStringAsFixed(2)}', isDark),
                        _buildMetricPill('Relative Error', '${summary.smape.toStringAsFixed(1)}% sMAPE (${summary.mape.toStringAsFixed(1)}% MAPE)', isDark),
                        _buildMetricPill('Evaluation Window', summary.evaluationPeriodLabel, isDark),
                        _buildMetricPill('Observations', '${summary.points.length} Historical Ledger Points', isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaColumn(
    String title,
    String value,
    IconData icon,
    Color accentColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: accentColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricPill(String label, String value, bool isDark) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
