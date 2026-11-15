import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/pagination/paged_load_more_footer.dart';
import '../../../../core/pagination/pagination_scroll_listener.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_empty_states.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

/// Production Orders List Screen with Live Active Tracking and Order History
/// Elevated with Lambac Editorial Luxury Aesthetics and Real-time Status Streams
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      PaginationScrollHelper.createScrollListener(
        scrollController: _scrollController,
        canLoadMore: () {
          final s = ref.read(ordersNotifierProvider);
          return !s.isLoading && !s.isLoadingMore && s.hasMore;
        },
        onLoadMore: () {
          ref.read(ordersNotifierProvider.notifier).loadMoreOrders();
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final isGuest = currentUser == null || currentUser.isGuest;

    if (isGuest) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkCanvas : CustomerLuxuryTheme.warmCream,
        appBar: const LambacAppBar(showBackButton: false, title: 'Orders'),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.brandAmber : AppColors.brandAmber).withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.brandAmberLight.withOpacity(0.3) : AppColors.brandAmber.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 34,
                          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                        ),
                      ),
                      AppSpacing.vSpaceLg,
                      Text(
                        'Sign In to View Orders',
                        style: CustomerLuxuryTheme.editorialStyle(
                          isDark: isDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.vSpaceSm,
                      Text(
                        'Track live espresso & pour-over preparation and review your past micro-lot purchases.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.45,
                        ),
                      ),
                      AppSpacing.vSpaceXl,
                      AppButton.primary(
                        text: 'Sign In / Register',
                        leadingIcon: const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                        onPressed: () => context.push('${AppRoutes.login}?redirect=${Uri.encodeComponent(AppRoutes.orders)}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final ordersState = ref.watch(ordersNotifierProvider);
    final ordersNotifier = ref.read(ordersNotifierProvider.notifier);

    if (ordersState.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkCanvas : CustomerLuxuryTheme.warmCream,
        appBar: const LambacAppBar(showBackButton: false, title: 'Orders'),
        body: const Center(
          child: LambacRoasteryLoader(message: 'Fetching fresh orders...'),
        ),
      );
    }

    if (ordersState.failure != null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkCanvas : CustomerLuxuryTheme.warmCream,
        appBar: const LambacAppBar(showBackButton: false, title: 'Orders'),
        body: AppErrorView(
          failure: ordersState.failure,
          onRetry: () => ordersNotifier.loadOrders(isRefresh: true),
        ),
      );
    }

    if (ordersState.orders.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkCanvas : CustomerLuxuryTheme.warmCream,
        appBar: const LambacAppBar(showBackButton: false, title: 'Orders'),
        body: AppEmptyOrdersState(
          onOrderNow: () => context.go(AppRoutes.products),
        ),
      );
    }

    final activeOrders = ordersState.activeOrders;
    final pastOrders = ordersState.pastOrders;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : CustomerLuxuryTheme.warmCream,
      appBar: LambacAppBar(
        showBackButton: false,
        title: 'Order Status & History',
        subtitle: '${ordersState.orders.length} Roastery Orders',
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.warmDiscovery,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 720,
            child: RefreshIndicator(
              onRefresh: () => ordersNotifier.loadOrders(isRefresh: true),
              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  // --------------------------------------------------------------
                  // Active Live Pickup Order Cards
                  // --------------------------------------------------------------
                  if (activeOrders.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cremaGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ACTIVE PICKUP ORDERS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.brandAmber : AppColors.brandAmber).withOpacity(0.12),
                            borderRadius: AppRadius.radiusPill,
                          ),
                          child: Text(
                            '${activeOrders.length} LIVE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSpaceSm,
                    ...activeOrders.map((order) {
                      final itemsSummary = order.items
                          .map((i) => '${i.quantity}x ${i.productName}')
                          .join(', ');
                      final isReady = order.status == OrderStatus.readyForPickup;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.orderDetailPath(order.id)),
                            borderRadius: AppRadius.radiusLg,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: CustomerLuxuryTheme.cardDecoration(
                                isDark: isDark,
                                isElevated: true,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isReady
                                              ? AppColors.matchaSage.withOpacity(0.18)
                                              : (isDark
                                                  ? AppColors.brandAmber.withOpacity(0.2)
                                                  : AppColors.brandAmber.withOpacity(0.12)),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isReady
                                              ? Icons.notifications_active_rounded
                                              : Icons.local_fire_department_rounded,
                                          size: 20,
                                          color: isReady
                                              ? AppColors.matchaSage
                                              : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              alignment: WrapAlignment.spaceBetween,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  'Order #${order.orderNumber}',
                                                  style: CustomerLuxuryTheme.editorialStyle(
                                                    isDark: isDark,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isReady
                                                        ? AppColors.matchaSage.withOpacity(0.2)
                                                        : AppColors.brandAmber.withOpacity(0.15),
                                                    borderRadius: AppRadius.radiusPill,
                                                    border: isReady
                                                        ? Border.all(color: AppColors.matchaSage, width: 1)
                                                        : null,
                                                  ),
                                                  child: Text(
                                                    order.status.toDisplayString(),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: isReady
                                                          ? AppColors.matchaSage
                                                          : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.schedule_rounded,
                                                  size: 12,
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Pickup: ${order.pickupDate.isNotEmpty ? '${order.pickupDate} • ' : ''}${order.pickupTimeSlot}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Wrap(
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 5,
                                              runSpacing: 2,
                                              children: [
                                                Icon(
                                                  Icons.point_of_sale_rounded,
                                                  size: 12,
                                                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                                ),
                                                Text(
                                                  order.paymentMethod,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: order.isPaid
                                                        ? AppColors.matchaSage.withOpacity(0.18)
                                                        : AppColors.warning.withOpacity(0.18),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    order.paymentStatus,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: order.isPaid ? AppColors.matchaSage : AppColors.warning,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.vSpaceMd,
                                  Text(
                                    itemsSummary,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  AppSpacing.vSpaceMd,
                                  ClipRRect(
                                    borderRadius: AppRadius.radiusPill,
                                    child: LinearProgressIndicator(
                                      value: ((order.status.stepIndex + 1) / 6.0).clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isReady
                                            ? AppColors.matchaSage
                                            : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
                                      ),
                                    ),
                                  ),
                                  AppSpacing.vSpaceSm,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isReady
                                              ? 'Ready! Pick up at the counter'
                                              : order.status == OrderStatus.prepared
                                                  ? 'Prepared & waiting for pickup'
                                                  : order.status == OrderStatus.preparing
                                                      ? 'Brewing fresh in roastery'
                                                      : 'Order received & queued',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isReady
                                                ? AppColors.matchaSage
                                                : (isDark ? AppColors.cremaGold : AppColors.brandAmber),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Track Live >',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    AppSpacing.vSpaceLg,
                  ],

                  // --------------------------------------------------------------
                  // Past Completed Orders History
                  // --------------------------------------------------------------
                  if (pastOrders.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PAST ROASTERY ORDERS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSpaceSm,
                    ...pastOrders.map((order) {
                      final itemsSummary = order.items
                          .map((i) => '${i.quantity}x ${i.productName}')
                          .join(', ');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.orderDetailPath(order.id)),
                            borderRadius: AppRadius.radiusLg,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Order #${order.orderNumber}',
                                          style: CustomerLuxuryTheme.editorialStyle(
                                            isDark: isDark,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: order.status == OrderStatus.cancelled
                                              ? AppColors.error.withOpacity(0.14)
                                              : AppColors.matchaSage.withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          order.status.toDisplayString(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: order.status == OrderStatus.cancelled
                                                ? AppColors.error
                                                : AppColors.matchaSage,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: order.isPaid
                                              ? AppColors.matchaSage.withOpacity(0.14)
                                              : (order.isPaymentFailed
                                                  ? AppColors.error.withOpacity(0.14)
                                                  : AppColors.warning.withOpacity(0.14)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          order.paymentStatus,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: order.isPaid
                                                ? AppColors.matchaSage
                                                : (order.isPaymentFailed ? AppColors.error : AppColors.warning),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.vSpaceSm,
                                  Text(
                                    itemsSummary,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  AppSpacing.vSpaceMd,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${order.pickupDate.isNotEmpty ? '${order.pickupDate} • ' : ''}${order.pickupTimeSlot}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        CurrencyFormatter.format(order.totalAmount),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  PagedLoadMoreFooter(
                    isLoadingMore: ordersState.isLoadingMore,
                    hasMore: ordersState.hasMore,
                    errorMessage: ordersState.loadMoreError,
                    onRetry: () => ordersNotifier.loadMoreOrders(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
