import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/dialogs/app_dialog.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../reviews/presentation/providers/reviews_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/dashboard/executive_business_summary_card.dart';
import '../widgets/dashboard/executive_customer_feedback_card.dart';
import '../widgets/dashboard/executive_customer_insights_card.dart';
import '../widgets/dashboard/executive_header.dart';
import '../widgets/dashboard/executive_kpi_section.dart';
import '../widgets/dashboard/executive_messages_summary_card.dart';
import '../widgets/dashboard/executive_order_pipeline_card.dart';
import '../widgets/dashboard/executive_product_performance_card.dart';
import '../widgets/dashboard/executive_sales_performance_card.dart';
import '../widgets/dashboard/executive_team_performance_card.dart';
import '../widgets/dashboard/operational_alerts_section.dart';

/// Premium Executive Business Intelligence Dashboard for Lambac Coffee Roastery
/// Central command center and descriptive analytics overview.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {

  Future<void> _refreshAll() async {
    ref.invalidate(businessMetricsProvider);
    ref.invalidate(analyticsSummaryProvider);
    ref.invalidate(allReviewsStreamProvider);
    await ref.read(ordersNotifierProvider.notifier).loadOrders();
    await ref.read(inboxNotifierProvider.notifier).loadInbox();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final metricsAsync = ref.watch(businessMetricsProvider);
    final analyticsAsync = ref.watch(analyticsSummaryProvider);
    final ordersState = ref.watch(ordersNotifierProvider);
    final productsState = ref.watch(productsNotifierProvider);
    final inboxState = ref.watch(inboxNotifierProvider);

    // Live counts from state
    final orders = ordersState.orders;
    final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;
    final preparingCount = orders.where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.preparing).length;
    final readyCount = orders.where((o) => o.status == OrderStatus.readyForPickup || o.status == OrderStatus.prepared).length;
    final completedTodayCount = orders.where((o) => o.status == OrderStatus.completed).length;
    final unreadInboxCount = inboxState.conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        showBackButton: false,
        title: 'Executive Platform',
        subtitle: 'Command Center & Business Overview',
        actions: [
          Builder(
            builder: (context) {
              final screenW = MediaQuery.sizeOf(context).width;
              final showPosLabel = screenW >= 340;
              final isUltraCompact = screenW < 230;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: isUltraCompact ? 2 : 4,
                    ),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.pos),
                      borderRadius: AppRadius.radiusPill,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: showPosLabel ? 10 : 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.brandAmber.withValues(alpha: 0.22) : AppColors.brandAmber.withValues(alpha: 0.12),
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(
                            color: AppColors.brandAmber.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.point_of_sale_rounded, size: 16, color: AppColors.brandAmber),
                            if (showPosLabel) ...[
                              const SizedBox(width: 5),
                              Text(
                                'POS Register',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh Command Center',
                    visualDensity: isUltraCompact ? VisualDensity.compact : null,
                    constraints: isUltraCompact
                        ? const BoxConstraints(minWidth: 32, minHeight: 32)
                        : null,
                    padding: isUltraCompact ? const EdgeInsets.all(4) : null,
                    onPressed: _refreshAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    tooltip: 'Sign Out',
                    visualDensity: isUltraCompact ? VisualDensity.compact : null,
                    constraints: isUltraCompact
                        ? const BoxConstraints(minWidth: 32, minHeight: 32)
                        : null,
                    padding: isUltraCompact ? const EdgeInsets.all(4) : null,
                    onPressed: () async {
                      final confirm = await AppDialog.show(
                        context,
                        title: 'Sign Out',
                        message: 'Are you sure you want to sign out of the Business Platform?',
                        confirmText: 'Sign Out',
                        cancelText: 'Cancel',
                      );
                      if (confirm == true && context.mounted) {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) {
                          AppToast.info(context, 'Signed out of Business Platform.');
                          context.go(AppRoutes.login);
                        }
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: CinematicRoasteryBackground.subtle(
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 880,
            child: metricsAsync.when(
              data: (businessMetrics) {
                return RefreshIndicator(
                  color: AppColors.brandAmber,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  onRefresh: _refreshAll,
                  child: ListView(
                    padding: AppSpacing.screenPadding,
                    children: [
                      // ------------------------------------------------------
                      // SECTION 01: Executive Header
                      // ------------------------------------------------------
                      ExecutiveHeader(
                        unreadInboxCount: unreadInboxCount,
                      ),
                      AppSpacing.vSpaceLg,

                      // ------------------------------------------------------
                      // SECTION 02: 4 Primary KPI Cards
                      // ------------------------------------------------------
                      analyticsAsync.maybeWhen(
                        data: (summary) => ExecutiveKpiSection(
                          todaySales: businessMetrics.todaySales,
                          todayOrdersCount: businessMetrics.todayOrdersCount,
                          averageOrderValue: summary.averageOrderValue,
                          unreadInboxCount: unreadInboxCount,
                        ),
                        orElse: () => ExecutiveKpiSection(
                          todaySales: businessMetrics.todaySales,
                          todayOrdersCount: businessMetrics.todayOrdersCount,
                          averageOrderValue: 0.0,
                          unreadInboxCount: unreadInboxCount,
                        ),
                      ),
                      AppSpacing.vSpaceXl,

                      // ------------------------------------------------------
                      // SECTION 03: Operational Alerts ("Needs Your Attention")
                      // ------------------------------------------------------
                      OperationalAlertsSection(
                        unreadInboxCount: unreadInboxCount,
                        pendingOrdersCount: pendingCount,
                        preparingOrdersCount: preparingCount,
                        products: productsState.products,
                      ),
                      AppSpacing.vSpaceXl,

                      // ------------------------------------------------------
                      // SECTION 04: Sales Performance (Descriptive Analytics)
                      // ------------------------------------------------------
                      analyticsAsync.maybeWhen(
                        data: (summary) => ExecutiveSalesPerformanceCard(
                          totalSales: summary.totalSales,
                          growthPercent: summary.totalSalesChangePercent,
                          trends: summary.salesTrends,
                        ),
                        orElse: () => ExecutiveSalesPerformanceCard(
                          totalSales: businessMetrics.todaySales,
                          growthPercent: 0.0,
                          trends: const [],
                        ),
                      ),
                      AppSpacing.vSpaceXl,

                      // ------------------------------------------------------
                      // SECTION 05: Order Activity (Live Pipeline)
                      // ------------------------------------------------------
                      ExecutiveOrderPipelineCard(
                        pendingCount: pendingCount,
                        preparingCount: preparingCount,
                        readyCount: readyCount,
                        completedCount: completedTodayCount > 0
                            ? completedTodayCount
                            : businessMetrics.completedOrdersCount,
                      ),
                      AppSpacing.vSpaceXl,

                      // ------------------------------------------------------
                      // SECTION 06: Product Performance & Ranking
                      // ------------------------------------------------------
                      analyticsAsync.maybeWhen(
                        data: (summary) => ExecutiveProductPerformanceCard(
                          topProducts: summary.topProducts,
                          catalogProducts: productsState.products,
                        ),
                        orElse: () => ExecutiveProductPerformanceCard(
                          topProducts: const [],
                          catalogProducts: productsState.products,
                        ),
                      ),
                      AppSpacing.vSpaceXl,

                      // ------------------------------------------------------
                      // SECTION 07: Team & Barista Performance
                      // ------------------------------------------------------
                      ExecutiveTeamPerformanceCard(
                        totalOrdersToday: businessMetrics.todayOrdersCount,
                      ),
                      AppSpacing.vSpaceXl,

                      // ------------------------------------------------------
                      // SECTION 08: Customer Activity & Retention
                      // ------------------------------------------------------
                      analyticsAsync.maybeWhen(
                        data: (summary) => ExecutiveCustomerInsightsCard(
                          customerActivity: summary.customerActivity,
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      AppSpacing.vSpaceXl,

                      // ------------------------------------------------------
                      // SECTION 09: Customer Messages / Concierge Inquiries
                      // ------------------------------------------------------
                      ExecutiveMessagesSummaryCard(
                        unreadCount: unreadInboxCount,
                        conversations: inboxState.conversations,
                      ),
                      AppSpacing.vSpaceXl,

                      // ------------------------------------------------------
                      // SECTION 10: Customer Satisfaction & Feedback
                      // ------------------------------------------------------
                      const ExecutiveCustomerFeedbackCard(),
                      AppSpacing.vSpaceXl,

                      // ------------------------------------------------------
                      // SECTION 11: "The Business at a Glance" (Executive Briefing)
                      // ------------------------------------------------------
                      analyticsAsync.maybeWhen(
                        data: (summary) => ExecutiveBusinessSummaryCard(
                          summary: summary,
                          todaySales: businessMetrics.todaySales,
                          todayOrders: businessMetrics.todayOrdersCount,
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      AppSpacing.vSpaceXxl,
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: LambacRoasteryLoader.compact(
                  message: 'Synchronizing Executive Command Center...',
                ),
              ),
              error: (err, stackTrace) {
                final failure = ErrorHandler.handle(
                  err,
                  stackTrace: stackTrace,
                  operation: 'adminDashboard',
                  domain: FailureDomain.firestoreAccess,
                );
                return AppErrorView(
                  failure: failure,
                  onRetry: _refreshAll,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
