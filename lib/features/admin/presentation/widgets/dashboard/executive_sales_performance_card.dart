import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/chips/app_chip.dart';
import '../../../../analytics/data/models/sales_trend_data_point.dart';
import '../../../../analytics/presentation/providers/analytics_provider.dart';

/// Executive Sales Performance Descriptive Analytics Visualization
class ExecutiveSalesPerformanceCard extends ConsumerStatefulWidget {
  final double totalSales;
  final double growthPercent;
  final List<SalesTrendDataPoint> trends;

  const ExecutiveSalesPerformanceCard({
    super.key,
    required this.totalSales,
    required this.growthPercent,
    required this.trends,
  });

  @override
  ConsumerState<ExecutiveSalesPerformanceCard> createState() =>
      _ExecutiveSalesPerformanceCardState();
}

class _ExecutiveSalesPerformanceCardState
    extends ConsumerState<ExecutiveSalesPerformanceCard> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedRange = ref.watch(analyticsDateRangeProvider);
    final rangeOptions = [
      (label: 'Today', value: 'Today'),
      (label: '7 Days', value: '7D'),
      (label: '30 Days', value: '30D'),
      (label: '3 Months', value: '3M'),
    ];

    final trendPoints = widget.trends;

    double maxSales = 1.0;
    double minSales = double.infinity;
    double sumSales = 0.0;
    SalesTrendDataPoint? peakPoint;

    for (final pt in trendPoints) {
      if (pt.salesAmount > maxSales) {
        maxSales = pt.salesAmount;
        peakPoint = pt;
      }
      if (pt.salesAmount < minSales) {
        minSales = pt.salesAmount;
      }
      sumSales += pt.salesAmount;
    }

    final avgDaily = trendPoints.isNotEmpty ? sumSales / trendPoints.length : 0.0;
    final totalRevenue = widget.totalSales > 0 ? widget.totalSales : sumSales;

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Time Range Filter
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 440;

              final titleWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        size: 18,
                        color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Sales Performance',
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
                  const SizedBox(height: 2),
                  Text(
                    'Descriptive revenue curve & order fulfillment velocity',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              );

              final filterChips = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: rangeOptions.map((opt) {
                    final isSelected = selectedRange == opt.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: AppChip(
                        label: opt.label,
                        isSelected: isSelected,
                        isSmall: true,
                        onSelected: (_) {
                          ref.read(analyticsDateRangeProvider.notifier).state = opt.value;
                        },
                      ),
                    );
                  }).toList(),
                ),
              );

              if (isStacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 10),
                    filterChips,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: 8),
                  filterChips,
                ],
              );
            },
          ),
          AppSpacing.vSpaceMd,

          // Key Stats Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.brandAmber.withValues(alpha: 0.08)
                  : AppColors.brandAmber.withValues(alpha: 0.05),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: AppColors.brandAmber.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _SummaryPill(
                  label: 'TOTAL SALES',
                  value: CurrencyFormatter.format(totalRevenue),
                  accentColor: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                ),
                _SummaryPill(
                  label: 'DAILY AVERAGE',
                  value: CurrencyFormatter.format(avgDaily),
                  accentColor: AppColors.matchaSage,
                ),
                if (peakPoint != null)
                  _SummaryPill(
                    label: 'PEAK DAY',
                    value: '${peakPoint.dateLabel} (${CurrencyFormatter.format(peakPoint.salesAmount)})',
                    accentColor: AppColors.info,
                  ),
                _SummaryPill(
                  label: 'GROWTH',
                  value: '${widget.growthPercent >= 0 ? '+' : ''}${widget.growthPercent.toStringAsFixed(1)}%',
                  accentColor: widget.growthPercent >= 0 ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),
          AppSpacing.vSpaceLg,

          // Interactive Chart Visualization
          if (trendPoints.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text(
                'No sales records logged for this selected timeframe.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(trendPoints.length, (index) {
                        final pt = trendPoints[index];
                        final heightRatio = (pt.salesAmount / maxSales).clamp(0.08, 1.0);
                        final isHovered = _hoveredIndex == index;

                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _hoveredIndex = _hoveredIndex == index ? null : index;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isHovered)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                        borderRadius: AppRadius.radiusSm,
                                        border: Border.all(
                                          color: AppColors.brandAmber,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        CurrencyFormatter.format(pt.salesAmount),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandAmber,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Tooltip(
                                        message: '${pt.dateLabel}\nSales: ${CurrencyFormatter.format(pt.salesAmount)}\nOrders: ${pt.ordersCount}',
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 350),
                                          height: 140 * heightRatio,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: isHovered
                                                  ? [AppColors.cremaGold, AppColors.brandAmberDark]
                                                  : [
                                                      isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                                      isDark ? AppColors.brandAmber.withValues(alpha: 0.4) : AppColors.brandAmberDark.withValues(alpha: 0.7),
                                                    ],
                                            ),
                                            borderRadius: BorderRadius.vertical(top: AppRadius.radiusSm.topLeft),
                                            boxShadow: isHovered
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.brandAmber.withValues(alpha: 0.4),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, -2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    pt.dateLabel,
                                    style: TextStyle(
                                      fontSize: trendPoints.length > 14 ? 8 : 10,
                                      fontWeight: isHovered ? FontWeight.w800 : FontWeight.w500,
                                      color: isHovered
                                          ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}
