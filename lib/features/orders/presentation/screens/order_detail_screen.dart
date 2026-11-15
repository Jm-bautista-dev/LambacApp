import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../../data/models/order_model.dart';
import '../providers/order_tracking_provider.dart';
import '../providers/payment_provider.dart';

/// Production Order Details & Live Pickup Tracker Screen
/// Listens to real-time status updates with 0ms latency across Barista and Admin actions
/// Elevated with Apple-inspired minimalist precision and Lambac luxury editorial design
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  final String? paymentReturnState;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.paymentReturnState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paymentState = ref.watch(paymentNotifierProvider);

    // Watch real-time stream provider for automatic reactive updates
    final orderAsync = ref.watch(orderTrackingStreamProvider(orderId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : CustomerLuxuryTheme.warmCream,
      appBar: LambacAppBar(
        title: 'Order Status',
        subtitle: 'Pickup Tracker',
        fallbackRoute: AppRoutes.orders,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Sync Status',
            onPressed: () => ref.invalidate(orderTrackingStreamProvider(orderId)),
          ),
        ],
      ),
      body: CinematicRoasteryBackground.subtle(
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 720,
            child: orderAsync.when(
              data: (order) {
                final isReady = order.status == OrderStatus.readyForPickup;
                final isCompleted = order.status == OrderStatus.completed;
                final isGcash = order.paymentMethod.toLowerCase().contains('gcash');

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  children: [
                    // --------------------------------------------------------
                    // Prominent "Ready for Pickup" Alert Callout
                    // --------------------------------------------------------
                    if (isReady) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.matchaSage.withOpacity(0.15),
                          borderRadius: AppRadius.radiusLg,
                          border: Border.all(color: AppColors.matchaSage, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.matchaSage.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.matchaSage,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'READY FOR PICKUP!',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.matchaSage,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isGcash
                                        ? (order.isPaid
                                            ? 'Your handcrafted order is ready at the roastery bar. Please present Order #${order.orderNumber} to the barista for pickup (GCash payment verified).'
                                            : 'Your handcrafted order is ready at the roastery bar. Please complete your online GCash payment verification before pickup.')
                                        : (order.isPaid
                                            ? 'Your handcrafted order is ready at the roastery bar. Please present Order #${order.orderNumber} to the barista for pickup (Payment settled).'
                                            : 'Your handcrafted order is ready at the roastery bar. Please present Order #${order.orderNumber} to the barista and settle payment at the counter.'),
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // --------------------------------------------------------
                    // Completed Banner
                    // --------------------------------------------------------
                    if (isCompleted) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.12),
                          borderRadius: AppRadius.radiusLg,
                          border: Border.all(color: AppColors.info.withOpacity(0.6), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.info, size: 26),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Completed & Handed Off',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.info,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    order.isPaid
                                        ? (isGcash
                                            ? 'Thank you for visiting Lambac Coffee Roastery! GCash payment verified.'
                                            : 'Thank you for visiting Lambac Coffee Roastery! Counter payment settled.')
                                        : 'Order pickup completed. Payment status: ${order.paymentStatus}.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // --------------------------------------------------------
                    // Calm Real-Time Status Feedback Banner
                    // --------------------------------------------------------
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: AppRadius.radiusPill,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isReady
                                  ? AppColors.matchaSage
                                  : (isCompleted
                                      ? AppColors.info
                                      : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Live sync • Real-time status from Barista counter',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --------------------------------------------------------
                    // Status Header Card
                    // --------------------------------------------------------
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark, isElevated: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                'Order #${order.orderNumber}',
                                style: CustomerLuxuryTheme.editorialStyle(
                                  isDark: isDark,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    key: const Key('order_detail_fulfillment_status_badge'),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isReady
                                          ? AppColors.matchaSage.withOpacity(0.2)
                                          : (isCompleted
                                              ? AppColors.info.withOpacity(0.2)
                                              : AppColors.brandAmber.withOpacity(0.15)),
                                      borderRadius: AppRadius.radiusPill,
                                      border: isReady ? Border.all(color: AppColors.matchaSage, width: 1) : null,
                                    ),
                                    child: Text(
                                      order.status.toDisplayString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isReady
                                            ? AppColors.matchaSage
                                            : (isCompleted
                                                ? AppColors.info
                                                : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    key: const Key('order_detail_payment_status_badge'),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: order.isPaid
                                          ? AppColors.matchaSage.withOpacity(0.18)
                                          : (order.isPaymentFailed
                                              ? AppColors.error.withOpacity(0.18)
                                              : AppColors.warning.withOpacity(0.18)),
                                      borderRadius: AppRadius.radiusPill,
                                    ),
                                    child: Text(
                                      order.isPaid
                                          ? (isGcash ? 'PAID (GCash)' : 'PAID')
                                          : (isGcash
                                              ? (order.isPaymentFailed ? order.paymentStatus : 'PENDING GCASH')
                                              : order.paymentStatus),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: order.isPaid
                                            ? AppColors.matchaSage
                                            : (order.isPaymentFailed ? AppColors.error : AppColors.warning),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AppSpacing.vSpaceLg,

                          // Live Stage Stepper
                          _buildStatusStepper(order, isDark),
                        ],
                      ),
                    ),
                    AppSpacing.vSpaceLg,

                    // --------------------------------------------------------
                    // Pickup Location & Schedule Card
                    // --------------------------------------------------------
                    Text(
                      'Pickup Details',
                      style: CustomerLuxuryTheme.editorialStyle(
                        isDark: isDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.vSpaceSm,
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.brandAmber : AppColors.brandAmber).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.pickupLocation.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${order.pickupLocation.address}, ${order.pickupLocation.city}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pickup Date',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  order.pickupDate,
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Target Time Slot',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  order.pickupTimeSlot,
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vSpaceLg,

                    // --------------------------------------------------------
                    // Ordered Items List
                    // --------------------------------------------------------
                    Text(
                      'Ordered Items (${order.totalItemCount})',
                      style: CustomerLuxuryTheme.editorialStyle(
                        isDark: isDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.vSpaceSm,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                      child: Column(
                        children: order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.brandAmber : AppColors.brandAmber).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}x',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      if (item.size != null || item.grind != null)
                                        Text(
                                          '${item.size ?? ""} • ${item.grind ?? ""}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.totalPrice),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      AppSpacing.vSpaceMd,
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.note_alt_outlined, size: 16, color: AppColors.brandAmber),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Special Instructions: "${order.notes}"',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    AppSpacing.vSpaceLg,

                    // --------------------------------------------------------
                    // Payment & Total Summary (Pay at Counter / GCash PayMongo)
                    // --------------------------------------------------------
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Payment Method',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    order.paymentMethod.toLowerCase().contains('gcash')
                                        ? Icons.account_balance_wallet_rounded
                                        : Icons.storefront_rounded,
                                    size: 14,
                                    color: order.paymentMethod.toLowerCase().contains('gcash')
                                        ? const Color(0xFF007DFE)
                                        : AppColors.brandAmber,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      order.paymentMethod.toLowerCase().contains('gcash')
                                          ? 'GCash (via PayMongo)'
                                          : order.paymentMethod,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: order.paymentMethod.toLowerCase().contains('gcash')
                                            ? const Color(0xFF007DFE)
                                            : (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Payment Status',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: order.isPaid
                                      ? AppColors.matchaSage.withOpacity(0.18)
                                      : (order.isPaymentFailed
                                          ? AppColors.error.withOpacity(0.18)
                                          : AppColors.warning.withOpacity(0.18)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      order.isPaid
                                          ? Icons.check_circle_rounded
                                          : (order.isPaymentFailed
                                              ? Icons.error_outline_rounded
                                              : Icons.pending_rounded),
                                      size: 12,
                                      color: order.isPaid
                                          ? AppColors.matchaSage
                                          : (order.isPaymentFailed ? AppColors.error : AppColors.warning),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.isPaid
                                          ? (order.paymentMethod.toLowerCase().contains('gcash') ? 'PAID (GCash)' : 'PAID')
                                          : (order.paymentMethod.toLowerCase().contains('gcash')
                                              ? (order.isPaymentFailed ? 'FAILED' : 'PENDING GCASH')
                                              : order.paymentStatus),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: order.isPaid
                                            ? AppColors.matchaSage
                                            : (order.isPaymentFailed ? AppColors.error : AppColors.warning),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (order.paymentReference != null && order.paymentReference!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Payment Reference',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    order.paymentReference!,
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (order.paymentMethod.toLowerCase().contains('gcash') && !order.isPaid) ...[
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final isFailedOrExpired = order.isPaymentFailed;
                                final isCancelledReturn = paymentReturnState == 'cancelled';
                                final hasValidCheckoutUrl = order.checkoutUrl != null &&
                                    order.checkoutUrl!.startsWith('https://') &&
                                    !isFailedOrExpired;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0D253F) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF007DFE).withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isFailedOrExpired || isCancelledReturn
                                                ? Icons.warning_amber_rounded
                                                : Icons.info_outline_rounded,
                                            size: 16,
                                            color: const Color(0xFF007DFE),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isFailedOrExpired
                                                  ? 'GCash payment ${order.paymentStatus.toLowerCase()} — tap below to retry.'
                                                  : (isCancelledReturn
                                                      ? 'GCash checkout was cancelled. Your order is saved.'
                                                      : 'Online GCash payment is pending.'),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      LayoutBuilder(
                                        builder: (context, gcashActionConstraints) {
                                          final payBtn = AppButton.primary(
                                            text: hasValidCheckoutUrl
                                                ? 'Pay with GCash'
                                                : 'Retry GCash Payment',
                                            size: AppButtonSize.small,
                                            isLoading: paymentState.isCreatingCheckout,
                                            onPressed: paymentState.isCreatingCheckout
                                                ? null
                                                : () async {
                                                    if (hasValidCheckoutUrl) {
                                                      final launchRes = await ref
                                                          .read(paymentNotifierProvider.notifier)
                                                          .reLaunchCheckout(order.checkoutUrl!);
                                                      if (context.mounted && launchRes.isFailure) {
                                                        AppToast.error(
                                                          context,
                                                          launchRes.failureOrNull!.userFriendlyMessage,
                                                        );
                                                      }
                                                    } else {
                                                      AppToast.info(
                                                        context,
                                                        'Connecting to PayMongo GCash...',
                                                      );
                                                      final retryRes = await ref
                                                          .read(paymentNotifierProvider.notifier)
                                                          .startGcashCheckout(
                                                            order.id,
                                                            forceNew: isFailedOrExpired,
                                                          );
                                                      if (!context.mounted) return;
                                                      retryRes.when(
                                                        success: (_) {
                                                          ref.invalidate(
                                                            orderTrackingStreamProvider(order.id),
                                                          );
                                                          AppToast.success(
                                                            context,
                                                            'Opening GCash payment gateway...',
                                                          );
                                                        },
                                                        failure: (f) => AppToast.error(
                                                          context,
                                                          f.userFriendlyMessage,
                                                        ),
                                                      );
                                                    }
                                                  },
                                          );

                                          final checkBtn = AppButton.secondary(
                                            text: 'Check Status',
                                            size: AppButtonSize.small,
                                            isLoading: paymentState.isVerifying,
                                            onPressed: paymentState.isVerifying
                                                ? null
                                                : () async {
                                                    AppToast.info(
                                                      context,
                                                      'Verifying payment status...',
                                                    );
                                                    final res = await ref
                                                        .read(paymentNotifierProvider.notifier)
                                                        .verifyPayment(order.id);
                                                    if (!context.mounted) return;
                                                    res.when(
                                                      success: (data) {
                                                        ref.invalidate(
                                                          orderTrackingStreamProvider(order.id),
                                                        );
                                                        if (data['paymentStatus'] == 'PAID') {
                                                          AppToast.success(
                                                            context,
                                                            'Payment confirmed (PAID)!',
                                                          );
                                                        } else {
                                                          AppToast.info(
                                                            context,
                                                            'Status: ${data['paymentStatus'] ?? "Pending"}',
                                                          );
                                                        }
                                                      },
                                                      failure: (f) => AppToast.error(
                                                        context,
                                                        f.userFriendlyMessage,
                                                      ),
                                                    );
                                                  },
                                          );

                                          if (gcashActionConstraints.maxWidth < 310) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                payBtn,
                                                const SizedBox(height: 8),
                                                checkBtn,
                                              ],
                                            );
                                          }

                                          return Row(
                                            children: [
                                              Expanded(child: payBtn),
                                              const SizedBox(width: 8),
                                              Expanded(child: checkBtn),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ] else if (order.isUnpaid) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  width: 0.6,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 14, color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Payment will be collected when you pick up your order at the store.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(order.subtotal),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  order.isPaid
                                      ? 'Total Amount Paid'
                                      : (order.paymentMethod.toLowerCase().contains('gcash')
                                          ? 'Total Amount Due'
                                          : 'Total Due at Counter'),
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomerLuxuryTheme.editorialStyle(
                                    isDark: isDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(order.totalAmount),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vSpaceXxl,

                    // Barista Concierge Action
                    AppButton.outlined(
                      text: 'Message Barista About This Order',
                      leadingIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      onPressed: () => context.push(AppRoutes.chat),
                    ),
                    AppSpacing.vSpaceXxl,
                  ],
                );
              },
              loading: () => const Center(
                child: LambacRoasteryLoader(
                  message: 'Tracking Live Roastery Order...',
                ),
              ),
              error: (err, stackTrace) {
                final failure = ErrorHandler.handle(
                  err,
                  stackTrace: stackTrace,
                  operation: 'orderTracking',
                  domain: FailureDomain.orderCreation,
                  recordId: orderId,
                );
                return AppErrorView(
                  failure: failure,
                  onRetry: () => ref.invalidate(orderTrackingStreamProvider(orderId)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStepper(OrderModel order, bool isDark) {
    final status = order.status;
    final isGcash = order.paymentMethod.toLowerCase().contains('gcash');
    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORDER CANCELLED',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.isPaid
                        ? 'This order has been cancelled. Payment status: ${order.paymentStatus}.'
                        : 'This order has been cancelled. Payment was not collected.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final stages = [
      const (title: 'ORDER PLACED', statusLabel: 'Placed', subtitle: 'Order received and queued at roastery bar'),
      const (title: 'CONFIRMED', statusLabel: 'Confirmed', subtitle: 'Barista confirmed preparation queue'),
      const (title: 'PREPARING', statusLabel: 'Brewing', subtitle: 'Handcrafting single-origin roast & counter brew'),
      const (title: 'PREPARED', statusLabel: 'Prepared', subtitle: 'Brewing completed & packaged for pickup'),
      const (title: 'READY FOR PICKUP', statusLabel: 'Ready', subtitle: 'Waiting for you at the Flagship bar counter'),
      (
        title: 'COMPLETED',
        statusLabel: 'Completed',
        subtitle: isGcash
            ? 'Order picked up at the roastery bar'
            : 'Handed off & counter payment settled',
      ),
    ];

    final currentIndex = status.stepIndex;

    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;
        final isUpcoming = index > currentIndex;
        final isLast = index == stages.length - 1;
        final isReadyStage = index == 4 && isCurrent;

        Color dotColor;
        if (isReadyStage) {
          dotColor = AppColors.matchaSage;
        } else if (isCompleted || isCurrent) {
          dotColor = isDark ? AppColors.brandAmberLight : AppColors.brandAmber;
        } else {
          dotColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical timeline line + Dot indicator
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isReadyStage ? 26 : 22,
                      height: isReadyStage ? 26 : 22,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? dotColor
                            : (isCurrent
                                ? (isReadyStage ? AppColors.matchaSage : dotColor)
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isReadyStage ? AppColors.matchaSage : dotColor,
                          width: isReadyStage ? 2.5 : 1.5,
                        ),
                        boxShadow: isReadyStage
                            ? [
                                BoxShadow(
                                  color: AppColors.matchaSage.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: isDark ? AppColors.darkCanvas : Colors.white,
                            )
                          : isCurrent
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isReadyStage
                                        ? Colors.white
                                        : (isDark ? AppColors.darkCanvas : Colors.white),
                                  ),
                                )
                              : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 2,
                          color: index < currentIndex
                              ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Stage details content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: isReadyStage ? const EdgeInsets.all(10) : EdgeInsets.zero,
                    decoration: isReadyStage
                        ? BoxDecoration(
                            color: AppColors.matchaSage.withOpacity(0.12),
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(color: AppColors.matchaSage.withOpacity(0.4), width: 1),
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              stage.title,
                              style: TextStyle(
                                fontSize: isReadyStage ? 13.5 : 12.5,
                                fontWeight: (isCurrent || isReadyStage)
                                    ? FontWeight.w800
                                    : (isCompleted ? FontWeight.w700 : FontWeight.w500),
                                letterSpacing: 0.5,
                                color: isReadyStage
                                    ? AppColors.matchaSage
                                    : (isCurrent
                                        ? (isDark ? AppColors.cremaGold : AppColors.brandAmberDark)
                                        : (isCompleted
                                            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary))),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                stage.statusLabel,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                            if (isReadyStage)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.matchaSage,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NOW READY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.brandAmber : AppColors.brandAmber).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'IN PROGRESS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stage.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: isReadyStage
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                : (isUpcoming
                                    ? (isDark ? AppColors.darkTextTertiary.withOpacity(0.6) : AppColors.lightTextTertiary.withOpacity(0.6))
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
