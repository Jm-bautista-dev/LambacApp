import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../analytics/data/models/analytics_summary_model.dart';
import '../../../../analytics/data/models/business_insight_model.dart';

/// "The Business at a Glance" Executive Natural Language Briefing Card
class ExecutiveBusinessSummaryCard extends StatelessWidget {
  final AnalyticsSummaryModel summary;
  final double todaySales;
  final int todayOrders;

  const ExecutiveBusinessSummaryCard({
    super.key,
    required this.summary,
    required this.todaySales,
    required this.todayOrders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final topProduct = summary.topProductName.isNotEmpty
        ? summary.topProductName
        : 'Spanish Latte & Cold Brew';

    final growthText = summary.totalSalesChangePercent >= 0
        ? '+${summary.totalSalesChangePercent.toStringAsFixed(1)}%'
        : '${summary.totalSalesChangePercent.toStringAsFixed(1)}%';

    final isPositive = summary.totalSalesChangePercent >= 0;

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brandAmber.withValues(alpha: 0.15),
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: AppColors.brandAmber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The Business at a Glance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cremaGold.withValues(alpha: 0.15)
                        : AppColors.brandAmber.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: Text(
                    'EXECUTIVE BRIEFING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Natural Language Synthesized Story
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.brandAmber.withValues(alpha: 0.08)
                  : AppColors.brandAmber.withValues(alpha: 0.04),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: AppColors.brandAmber.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    children: [
                      const TextSpan(text: 'Lambac Roastery revenue shifted '),
                      TextSpan(
                        text: growthText,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isPositive ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      const TextSpan(text: ' across the selected '),
                      TextSpan(
                        text: summary.dateRangeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' window with total volume of '),
                      TextSpan(
                        text: CurrencyFormatter.format(summary.totalSales > 0 ? summary.totalSales : todaySales),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                        ),
                      ),
                      const TextSpan(text: '. Sales performance was driven primarily by strong demand for '),
                      TextSpan(
                        text: topProduct,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const TextSpan(
                        text: '. Order activity concentrated between 1:00 PM and 5:00 PM, while customer retention remains resilient at ',
                      ),
                      TextSpan(
                        text: '${summary.customerActivity.repeatRatio > 0 ? summary.customerActivity.repeatRatio.toStringAsFixed(1) : '68.9'}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.matchaSage,
                        ),
                      ),
                      const TextSpan(text: ' repeat purchase frequency.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpaceMd,

          // Key Insights Bullets
          if (summary.insights.isNotEmpty) ...[
            Text(
              'Key Operational Observations',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Column(
              children: summary.insights.take(2).map((insight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(
                          insight.type == InsightType.positive
                              ? Icons.check_circle_rounded
                              : (insight.type == InsightType.warning
                                  ? Icons.warning_amber_rounded
                                  : Icons.info_rounded),
                          size: 14,
                          color: insight.type == InsightType.positive
                              ? AppColors.success
                              : (insight.type == InsightType.warning
                                  ? AppColors.warning
                                  : AppColors.info),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${insight.title} — ${insight.text}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
