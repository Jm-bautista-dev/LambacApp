import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../data/models/sales_trend_data_point.dart';
import '../providers/analytics_provider.dart';

/// Visual Sales Trend Chart Widget with Date Preset Selector
class SalesTrendChart extends ConsumerWidget {
  final List<SalesTrendDataPoint> trendPoints;

  const SalesTrendChart({
    super.key,
    required this.trendPoints,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedRange = ref.watch(analyticsDateRangeProvider);
    final presets = ['Today', '7D', '15D', '30D'];

    double maxSales = 1.0;
    for (final pt in trendPoints) {
      if (pt.salesAmount > maxSales) maxSales = pt.salesAmount;
    }

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Date Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue & Order Volume',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Historical sales trend performance',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: presets.map((preset) {
                    final isSelected = selectedRange == preset;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: AppChip(
                        label: preset,
                        isSelected: isSelected,
                        isSmall: true,
                        onSelected: (_) {
                          ref.read(analyticsDateRangeProvider.notifier).state = preset;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceLg,

          // Chart Visualization Bars
          if (trendPoints.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text(
                'No sales trend data available for this range.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trendPoints.map((pt) {
                  final heightRatio = (pt.salesAmount / maxSales).clamp(0.06, 1.0);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Tooltip(
                                message: '${pt.dateLabel}: ${CurrencyFormatter.format(pt.salesAmount)} (${pt.ordersCount} orders)',
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  height: 140 * heightRatio,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                    borderRadius: BorderRadius.vertical(top: AppRadius.radiusSm.topLeft),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pt.dateLabel,
                            style: TextStyle(
                              fontSize: trendPoints.length > 15 ? 8 : 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
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
}
