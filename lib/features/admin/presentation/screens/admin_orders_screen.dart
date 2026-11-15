import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/domain/services/order_queue_service.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../providers/admin_provider.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';

/// Business Incoming Pickup Orders Queue Screen
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
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

    final sortedOrders = queueService.sortQueueOrders(filteredOrders);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        showBackButton: false,
        title: 'Pickup Queue',
        subtitle: '${metrics.activeCount} Active in Queue',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Queue',
            onPressed: () => ref.read(ordersNotifierProvider.notifier).loadOrders(isRefresh: true),
          ),
        ],
      ),
      body: CinematicRoasteryBackground.subtle(
        showAmbientParticles: false,
        showFloatingBean: false,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 720,
            child: Column(
            children: [
              // Operational Metrics Bar
              SingleChildScrollView(
                key: SpotlightKeys.adminOrdersQueue,
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

              // Status Tabs
              SingleChildScrollView(
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

              // Orders Queue List
              Expanded(
                child: sortedOrders.isEmpty
                    ? Center(
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
                                  ? 'No active orders require attention right now.'
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

                          return AppCard.elevated(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Order #${order.orderNumber}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                                    if (order.status.isActive)
                                      _buildUrgencyPill(urgency, urgencyText, isDark),
                                  ],
                                ),
                                AppSpacing.vSpaceSm,

                                // Customer & Pickup Details
                                Text(
                                  'Customer: ${order.customerName} (${order.customerPhone})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Pickup: ${order.pickupDate} • ${order.pickupTimeSlot}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        order.paymentMethod,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: order.paymentMethod.toLowerCase().contains('gcash')
                                              ? const Color(0xFF007DFE)
                                              : (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.notes != null && order.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Barista Notes: "${order.notes}"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                                      ),
                                    ),
                                  ),
                                ],
                                const Divider(height: 20),

                                // Items & Total
                                ...order.items.map((i) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${i.quantity}x ${i.productName} (${i.size ?? ""}, ${i.grind ?? ""})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            CurrencyFormatter.format(i.totalPrice),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                AppSpacing.vSpaceMd,

                                // Stage Advancement Action Button
                                _buildActionButtons(order, controller, context, isDark),
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

  Widget _buildActionButtons(OrderModel order, AdminProductController controller, BuildContext context, bool isDark) {
    if (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed) {
      return AppButton.primary(
        text: 'Start Preparing',
        size: AppButtonSize.small,
        onPressed: () async {
          final res = await controller.advanceOrderStatus(order.id, OrderStatus.preparing);
          if (context.mounted && res.isSuccess) {
            AppToast.info(context, 'Order #${order.orderNumber} is now Preparing');
          }
        },
      );
    } else if (order.status == OrderStatus.preparing) {
      return AppButton.primary(
        text: 'Mark as Prepared',
        size: AppButtonSize.small,
        onPressed: () async {
          final res = await controller.advanceOrderStatus(order.id, OrderStatus.prepared);
          if (context.mounted && res.isSuccess) {
            AppToast.info(context, 'Order #${order.orderNumber} marked Prepared');
          }
        },
      );
    } else if (order.status == OrderStatus.prepared) {
      return AppButton.primary(
        text: 'Mark Ready for Pickup',
        size: AppButtonSize.small,
        onPressed: () async {
          final res = await controller.advanceOrderStatus(order.id, OrderStatus.readyForPickup);
          if (context.mounted && res.isSuccess) {
            AppToast.success(context, 'Order #${order.orderNumber} is Ready for Pickup!');
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
                        if (context.mounted && res.isSuccess) {
                          AppToast.success(context, 'Counter payment recorded for Order #${order.orderNumber}');
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
                        if (context.mounted && !res.isSuccess) {
                          AppToast.error(context, res.failureOrNull?.message ?? 'Order could not be completed. Please try again.');
                        }
                        if (context.mounted && res.isSuccess) {
                          AppToast.success(context, 'Order #${order.orderNumber} completed & payment confirmed.');
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
                          ? 'GCash Payment Verified (PAID via PayMongo). Ready for handover.'
                          : 'Counter Payment Verified (PAID). Ready for handover.',
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
              text: 'Hand Over & Complete Order',
              size: AppButtonSize.small,
              onPressed: () async {
                final res = await controller.advanceOrderStatus(order.id, OrderStatus.completed);
                if (!context.mounted) return;
                if (res.isSuccess) {
                  AppToast.success(context, 'Order #${order.orderNumber} completed & handed over.');
                } else {
                  AppToast.error(context, res.failureOrNull?.message ?? 'Order could not be completed. Please try again.');
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
