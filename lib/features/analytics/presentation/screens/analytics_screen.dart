import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_kpi_card.dart';
import '../widgets/business_insights_card.dart';
import '../widgets/order_status_distribution.dart';
import '../widgets/product_performance_list.dart';
import '../widgets/sales_channel_breakdown_card.dart';
import '../widgets/sales_trend_chart.dart';

/// Production Descriptive Business Analytics Dashboard Screen
class AnalyticsScreen extends ConsumerWidget {
  final bool showAppBar;

  const AnalyticsScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final analyticsAsync = ref.watch(analyticsSummaryProvider);
    final selectedDateRange = ref.watch(analyticsDateRangeProvider);

    final standardOptions = [
      (label: 'Today', value: 'Today'),
      (label: '7 Days', value: '7D'),
      (label: '15 Days', value: '15D'),
      (label: '30 Days', value: '30D'),
    ];

    final isCustom = selectedDateRange.startsWith('Custom:');

    final content = SafeArea(
      child: ResponsiveContentContainer(
        maxWidth: 840,
        child: Column(
          children: [
            // Sticky Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    width: 0.8,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...standardOptions.map((opt) {
                      final isSelected = selectedDateRange == opt.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppChip(
                          label: opt.label,
                          isSelected: isSelected,
                          isSmall: true,
                          onSelected: (_) {
                            ref.read(analyticsDateRangeProvider.notifier).state = opt.value;
                          },
                        ),
                      );
                    }),
                    // Custom Range Chip
                    AppChip(
                      label: isCustom ? _formatCustomLabel(selectedDateRange) : 'Custom Range',
                      isSelected: isCustom,
                      isSmall: true,
                      icon: const Icon(Icons.date_range_rounded, size: 14),
                      onSelected: (_) async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: now.subtract(const Duration(days: 180)),
                          lastDate: now,
                          initialDateRange: DateTimeRange(
                            start: now.subtract(const Duration(days: 7)),
                            end: now,
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: theme.copyWith(
                                colorScheme: theme.colorScheme.copyWith(
                                  primary: AppColors.brandAmber,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          final startStr = DateFormat('yyyy-MM-dd').format(picked.start);
                          final endStr = DateFormat('yyyy-MM-dd').format(picked.end);
                          ref.read(analyticsDateRangeProvider.notifier).state = 'Custom:$startStr:$endStr';
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Main Analytics View
            Expanded(
              child: analyticsAsync.when(
                data: (summary) {
                  final kpis = [
                    AnalyticsKpiCard(
                      title: 'Total Revenue',
                      value: CurrencyFormatter.format(summary.totalSales),
                      icon: Icons.monetization_on_rounded,
                      trendPercent: summary.totalSalesChangePercent,
                      subtitle: 'vs prior period',
                    ),
                    AnalyticsKpiCard(
                      title: 'Total Orders',
                      value: '${summary.totalOrders}',
                      icon: Icons.shopping_bag_rounded,
                      trendPercent: summary.totalOrdersChangePercent,
                      subtitle: 'fulfillment count',
                    ),
                    AnalyticsKpiCard(
                      title: 'Average Order Value',
                      value: CurrencyFormatter.format(summary.averageOrderValue),
                      icon: Icons.receipt_rounded,
                      accentColor: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                      subtitle: 'per customer transaction',
                    ),
                    AnalyticsKpiCard(
                      title: 'Top Product',
                      value: summary.topProductName,
                      icon: Icons.star_rounded,
                      accentColor: AppColors.brandAmber,
                      subtitle: 'highest grossing bean',
                    ),
                    AnalyticsKpiCard(
                      title: 'Unique Customers',
                      value: '${summary.customerActivity.uniqueCustomersCount}',
                      icon: Icons.group_rounded,
                      accentColor: AppColors.info,
                      subtitle: '${summary.customerActivity.repeatRatio.toStringAsFixed(1)}% repeat rate',
                    ),
                    AnalyticsKpiCard(
                      title: 'Order Completion',
                      value: '${summary.statusBreakdown.completionRate.toStringAsFixed(1)}%',
                      icon: Icons.check_circle_rounded,
                      accentColor: AppColors.success,
                      subtitle: 'fulfillment rate',
                    ),
                  ];

                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(analyticsSummaryProvider),
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    child: ListView(
                      padding: AppSpacing.screenPadding,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        // Header Subtitle & Date Range Filter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Performance: ${summary.dateRangeLabel}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              summary.totalOrders > 0 ? '${summary.totalOrders} transactions' : '0 sales',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // --------------------------------------------------------
                        // 1. KPI Cards Grid
                        // --------------------------------------------------------
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 116,
                          ),
                          itemCount: kpis.length,
                          itemBuilder: (context, index) => kpis[index],
                        ),
                        AppSpacing.vSpaceXl,

                          // --------------------------------------------------------
                          // 2. Centralized Sales by Channel (Mobile vs POS)
                          // --------------------------------------------------------
                          SalesChannelBreakdownCard(summary: summary),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------------
                          // 3. Sales & Volume Trend Visualization
                          // --------------------------------------------------------
                          SalesTrendChart(trendPoints: summary.salesTrends),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------------
                          // 4. Product Performance Breakdown
                          // --------------------------------------------------------
                          ProductPerformanceList(
                            topProducts: summary.topProducts,
                            lowestProducts: summary.lowestProducts,
                          ),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------------
                          // 5. Order Status Distribution Breakdown
                          // --------------------------------------------------------
                          OrderStatusDistributionCard(breakdown: summary.statusBreakdown),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------------
                          // 6. Data-Driven Business Insights
                          // --------------------------------------------------------
                          BusinessInsightsCard(insights: summary.insights),
                          AppSpacing.vSpaceXxl,
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => AppErrorView(
                    title: 'Unable to Load Analytics',
                    message: err.toString(),
                    onRetry: () => ref.refresh(analyticsSummaryProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

    if (!showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        title: 'Descriptive Analytics',
        subtitle: 'Lambac Coffee Roastery',
        fallbackRoute: AppRoutes.adminDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Analytics',
            onPressed: () => ref.refresh(analyticsSummaryProvider),
          ),
        ],
      ),
      body: content,
    );
  }

  String _formatCustomLabel(String customString) {
    final parts = customString.split(':');
    if (parts.length >= 3) {
      final start = DateTime.tryParse(parts[1]);
      final end = DateTime.tryParse(parts[2]);
      if (start != null && end != null) {
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
      }
    }
    return 'Custom';
  }
}
