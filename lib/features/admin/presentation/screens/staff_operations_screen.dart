import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/domain/services/order_queue_service.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../providers/admin_provider.dart';

/// Production Staff & Bartender Daily Operations Hub
/// Focuses purely on operational order fulfillment, brewing status advancement, and station controls.
class StaffOperationsScreen extends ConsumerStatefulWidget {
  const StaffOperationsScreen({super.key});

  @override
  ConsumerState<StaffOperationsScreen> createState() => _StaffOperationsScreenState();
}

class _StaffOperationsScreenState extends ConsumerState<StaffOperationsScreen> {
  int _selectedTab = 0;
  final List<String> _statusTabs = ['Active Queue', 'New', 'Preparing', 'Ready', 'Completed', 'All'];


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ordersState = ref.watch(ordersNotifierProvider);
    final controller = ref.read(adminProductNotifierProvider);
    final queueService = OrderQueueService();

    final metrics = queueService.calculateMetrics(ordersState.orders);
    final pendingCount = ordersState.orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.confirmed).length;
    final preparingCount = ordersState.orders.where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.prepared).length;
    final readyCount = ordersState.orders.where((o) => o.status == OrderStatus.readyForPickup).length;
    final completedCount = metrics.completedCount;

    List<OrderModel> filteredOrders;
    if (_selectedTab == 0) {
      // Default: Live Active Queue (Actionable orders requiring staff attention)
      filteredOrders = ordersState.orders.where((o) => o.status.isActive).toList();
    } else if (_selectedTab == 1) {
      filteredOrders = ordersState.orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.confirmed).toList();
    } else if (_selectedTab == 2) {
      filteredOrders = ordersState.orders.where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.prepared).toList();
    } else if (_selectedTab == 3) {
      filteredOrders = ordersState.orders.where((o) => o.status == OrderStatus.readyForPickup).toList();
    } else if (_selectedTab == 4) {
      filteredOrders = ordersState.orders.where((o) => o.status == OrderStatus.completed).toList();
    } else {
      filteredOrders = ordersState.orders;
    }

    // Sort according to operational urgency and scheduled pickup time
    final sortedOrders = queueService.sortQueueOrders(filteredOrders);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        key: SpotlightKeys.staffQueueHeader,
        showBackButton: false,
        title: 'Barista Operations Queue',
        subtitle: 'Flagship Store • ${metrics.activeCount} Active in Queue',
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: InkWell(
              onTap: () => context.push(AppRoutes.pos),
              borderRadius: AppRadius.radiusPill,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Queue',
            onPressed: () => ref.read(ordersNotifierProvider.notifier).loadOrders(isRefresh: true),
          ),
        ],
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.subtleOperations,
        child: SafeArea(
          child: ResponsiveContentContainer(
          maxWidth: 780,
          child: Column(
            children: [
              // Operational Metrics Bar (Authoritative Database State)
              SingleChildScrollView(
                key: SpotlightKeys.staffMetricsBar,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _buildMetricChip(
                      label: 'Active Queue',
                      count: metrics.activeCount,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      label: 'Preparing',
                      count: preparingCount,
                      color: AppColors.brandAmber,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      label: 'Ready',
                      count: readyCount,
                      color: AppColors.matchaSage,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      label: 'Due / Alert',
                      count: metrics.overdueOrDueSoonCount,
                      color: metrics.overdueOrDueSoonCount > 0 ? AppColors.warning : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      label: 'Completed',
                      count: completedCount,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Filter Tabs (Filtering does NOT alter navigation badge or global metrics)
              SingleChildScrollView(
                key: SpotlightKeys.staffStatusTabs,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: List.generate(_statusTabs.length, (idx) {
                    final label = _statusTabs[idx];
                    int? tabCount;
                    if (idx == 0) tabCount = metrics.activeCount;
                    if (idx == 1) tabCount = pendingCount;
                    if (idx == 2) tabCount = preparingCount;
                    if (idx == 3) tabCount = readyCount;
                    if (idx == 4) tabCount = completedCount;
                    if (idx == 5) tabCount = metrics.totalCount;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label: tabCount != null ? '$label ($tabCount)' : label,
                        isSelected: _selectedTab == idx,
                        onSelected: (_) => setState(() => _selectedTab = idx),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 6),

              // Orders List
              Expanded(
                child: ordersState.isLoading && ordersState.orders.isEmpty
                    ? const Center(
                        child: LambacRoasteryLoader(
                          message: 'Loading live barista queue...',
                        ),
                      )
                    : ordersState.failure != null && ordersState.orders.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AppErrorView(
                              failure: ordersState.failure!,
                              onRetry: () => ref.read(ordersNotifierProvider.notifier).loadOrders(isRefresh: true),
                            ),
                          )
                        : sortedOrders.isEmpty
                            ? Center(
                                key: SpotlightKeys.staffEmptyQueueCard,
                                child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.coffee_maker_outlined,
                              size: 54,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                            AppSpacing.vSpaceSm,
                            Text(
                              _selectedTab == 0 ? "You're all caught up!" : 'No orders in this queue filter.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTab == 0
                                  ? 'No active orders require barista attention right now.'
                                  : 'Select another filter or refresh to view orders.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: AppSpacing.screenPadding,
                        itemCount: sortedOrders.length,
                        separatorBuilder: (_, __) => AppSpacing.vSpaceMd,
                        itemBuilder: (context, index) {
                          final order = sortedOrders[index];
                          final urgency = queueService.getOrderUrgency(order);
                          final urgencyText = queueService.getUrgencyDescription(order);
                          final isFirstItemInActiveQueue = _selectedTab == 0 && index == 0;

                          return AppCard.elevated(
                            key: isFirstItemInActiveQueue ? SpotlightKeys.staffFirstOrderCard : ValueKey('order_${order.id}'),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order Header: ORDER #... and Dual Status Badges
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ORDER #${order.orderNumber}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            key: isFirstItemInActiveQueue ? SpotlightKeys.staffOrderPickupBadge : null,
                                            children: [
                                              Icon(
                                                Icons.access_time_filled_rounded,
                                                size: 13,
                                                color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Pickup ${order.pickupDate} • ${order.pickupTimeSlot}',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (order.status.isActive) ...[
                                            const SizedBox(height: 4),
                                            _buildUrgencyPill(urgency, urgencyText, isDark),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusBadgeColor(order.status, isDark).withOpacity(0.18),
                                        borderRadius: AppRadius.radiusPill,
                                        border: Border.all(
                                          color: _getStatusBadgeColor(order.status, isDark).withOpacity(0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        'ORDER: ${order.status.toDisplayString()}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: _getStatusBadgeColor(order.status, isDark),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Payment Method & Status Badges
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // Method Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: order.paymentMethod.toLowerCase().contains('gcash')
                                            ? const Color(0xFF007DFE).withOpacity(0.18)
                                            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                                        borderRadius: AppRadius.radiusPill,
                                        border: Border.all(
                                          color: order.paymentMethod.toLowerCase().contains('gcash')
                                              ? const Color(0xFF007DFE).withOpacity(0.5)
                                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            order.paymentMethod.toLowerCase().contains('gcash')
                                                ? Icons.account_balance_wallet_rounded
                                                : Icons.point_of_sale_rounded,
                                            size: 11,
                                            color: order.paymentMethod.toLowerCase().contains('gcash')
                                                ? const Color(0xFF007DFE)
                                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            order.paymentMethod.toLowerCase().contains('gcash')
                                                ? 'GCASH (PayMongo)'
                                                : 'PAY AT COUNTER',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: order.paymentMethod.toLowerCase().contains('gcash')
                                                  ? const Color(0xFF007DFE)
                                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Payment Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: order.isPaid
                                            ? AppColors.matchaSage.withOpacity(0.18)
                                            : AppColors.warning.withOpacity(0.18),
                                        borderRadius: AppRadius.radiusPill,
                                        border: Border.all(
                                          color: order.isPaid
                                              ? AppColors.matchaSage.withOpacity(0.4)
                                              : AppColors.warning.withOpacity(0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            order.isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                            size: 11,
                                            color: order.isPaid ? AppColors.matchaSage : AppColors.warning,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'PAYMENT: ${order.paymentStatus}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: order.isPaid ? AppColors.matchaSage : AppColors.warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (order.paymentReference != null && order.paymentReference!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                                          borderRadius: AppRadius.radiusPill,
                                          border: Border.all(
                                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                            width: 0.6,
                                          ),
                                        ),
                                        child: Text(
                                          'Ref: ${order.paymentReference}',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Customer name & Date
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Customer: ${order.customerName} (${order.customerPhone})',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      order.pickupDate,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.notes != null && order.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.brandAmber.withOpacity(0.1)
                                          : AppColors.brandAmber.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.brandAmber.withOpacity(0.3)
                                            : AppColors.brandAmber.withOpacity(0.2),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.sticky_note_2_outlined, size: 14, color: AppColors.brandAmber),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Notes: "${order.notes}"',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Divider(height: 22),

                                // Items List (Clear counter format: "2 × Item Name")
                                ...order.items.map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item.quantity} ×',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.productName,
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                                if (item.size != null || item.grind != null)
                                                  Text(
                                                    '${item.size ?? ""} ${item.grind != null ? "• Grind: ${item.grind}" : ""}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(item.totalPrice),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                AppSpacing.vSpaceMd,

                                // Action Button for Barista Status Progression
                                KeyedSubtree(
                                  key: isFirstItemInActiveQueue ? SpotlightKeys.staffOrderActionBtn : null,
                                  child: _buildBaristaActionButton(order, controller, context, isDark),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildMetricChip({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusBadgeColor(OrderStatus status, bool isDark) {
    return switch (status) {
      OrderStatus.pending || OrderStatus.confirmed => AppColors.warning,
      OrderStatus.preparing => AppColors.brandAmber,
      OrderStatus.prepared => isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
      OrderStatus.readyForPickup => AppColors.matchaSage,
      OrderStatus.completed => AppColors.info,
      OrderStatus.cancelled => AppColors.error,
    };
  }

  Widget _buildBaristaActionButton(
    OrderModel order,
    AdminProductController controller,
    BuildContext context,
    bool isDark,
  ) {
    if (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed) {
      return AppButton.primary(
        text: 'Start Preparing',
        size: AppButtonSize.small,
        onPressed: () async {
          final res = await controller.advanceOrderStatus(order.id, OrderStatus.preparing);
          if (!context.mounted) return;
          if (res.isSuccess) {
            AppToast.info(context, 'Order #${order.orderNumber} is now Preparing');
          } else {
            AppToast.error(context, res.failureOrNull?.userFriendlyMessage ?? 'Failed to update order status');
          }
        },
      );
    } else if (order.status == OrderStatus.preparing) {
      return AppButton.primary(
        text: 'Mark as Prepared',
        size: AppButtonSize.small,
        onPressed: () async {
          final res = await controller.advanceOrderStatus(order.id, OrderStatus.prepared);
          if (!context.mounted) return;
          if (res.isSuccess) {
            AppToast.info(context, 'Order #${order.orderNumber} marked Prepared');
          } else {
            AppToast.error(context, res.failureOrNull?.userFriendlyMessage ?? 'Failed to update order status');
          }
        },
      );
    } else if (order.status == OrderStatus.prepared) {
      return AppButton.primary(
        text: 'Mark Ready for Pickup',
        size: AppButtonSize.small,
        onPressed: () async {
          final res = await controller.advanceOrderStatus(order.id, OrderStatus.readyForPickup);
          if (!context.mounted) return;
          if (res.isSuccess) {
            AppToast.success(context, 'Order #${order.orderNumber} is Ready for Pickup!');
          } else {
            AppToast.error(context, res.failureOrNull?.userFriendlyMessage ?? 'Failed to update order status');
          }
        },
      );
    } else if (order.status == OrderStatus.readyForPickup) {
      final isGcash = order.paymentMethod.toLowerCase().contains('gcash');

      if (!order.isPaid) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isGcash
                    ? const Color(0xFF007DFE).withOpacity(0.12)
                    : AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isGcash
                      ? const Color(0xFF007DFE).withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isGcash ? Icons.account_balance_wallet_rounded : Icons.point_of_sale_rounded,
                    size: 16,
                    color: isGcash ? const Color(0xFF007DFE) : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isGcash
                          ? 'Awaiting PayMongo GCash Verification (${order.paymentStatus}). Manual counter payment override is disabled for GCash orders.'
                          : 'Ready for Customer. Collect ${CurrencyFormatter.format(order.totalAmount)} at counter.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isGcash ? const Color(0xFF007DFE) : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isGcash)
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      text: 'Record Payment (${CurrencyFormatter.format(order.totalAmount)})',
                      size: AppButtonSize.small,
                      onPressed: () async {
                        final res = await controller.recordCounterPayment(order.id);
                        if (!context.mounted) return;
                        if (res.isSuccess) {
                          AppToast.success(context, 'Counter payment recorded for Order #${order.orderNumber}');
                        } else {
                          AppToast.error(context, res.failureOrNull?.userFriendlyMessage ?? 'Failed to record counter payment');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton.primary(
                      text: 'Collect & Complete',
                      size: AppButtonSize.small,
                      onPressed: () async {
                        final res = await controller.advanceOrderStatus(order.id, OrderStatus.completed);
                        if (!context.mounted) return;
                        if (res.isSuccess) {
                          AppToast.success(context, 'Order #${order.orderNumber} completed & payment settled.');
                        } else {
                          AppToast.error(context, res.failureOrNull?.userFriendlyMessage ?? 'Order could not be completed. Please try again.');
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.matchaSage.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.matchaSage.withOpacity(0.4), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.matchaSage),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isGcash
                          ? 'GCash Payment Verified (PAID via PayMongo). Hand over brews to customer.'
                          : 'Counter Payment Verified (PAID). Hand over brews to customer.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.matchaSage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppButton.primary(
              text: 'Handover & Complete Order',
              size: AppButtonSize.small,
              onPressed: () async {
                final res = await controller.advanceOrderStatus(order.id, OrderStatus.completed);
                if (!context.mounted) return;
                if (res.isSuccess) {
                  AppToast.success(context, 'Order #${order.orderNumber} completed!');
                } else {
                  AppToast.error(context, res.failureOrNull?.userFriendlyMessage ?? 'Failed to complete order.');
                }
              },
            ),
          ],
        );
      }
    } else if (order.status == OrderStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.matchaSage.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.matchaSage.withOpacity(0.3), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 14, color: AppColors.matchaSage),
            SizedBox(width: 6),
            Text(
              'Order Picked Up & Completed • PAID',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.matchaSage,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildUrgencyPill(OrderUrgency urgency, String urgencyText, bool isDark) {
    Color bg;
    Color border;
    Color text;
    IconData icon;

    switch (urgency) {
      case OrderUrgency.overdue:
        bg = AppColors.error.withOpacity(0.18);
        border = AppColors.error.withOpacity(0.5);
        text = AppColors.error;
        icon = Icons.warning_amber_rounded;
        break;
      case OrderUrgency.dueSoon:
        bg = AppColors.brandAmber.withOpacity(0.18);
        border = AppColors.brandAmber.withOpacity(0.5);
        text = isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark;
        icon = Icons.bolt_rounded;
        break;
      case OrderUrgency.upcoming:
        bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        text = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        icon = Icons.schedule_rounded;
        break;
      case OrderUrgency.later:
        bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        text = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
        icon = Icons.calendar_today_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusPill,
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 4),
          Text(
            urgencyText,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
