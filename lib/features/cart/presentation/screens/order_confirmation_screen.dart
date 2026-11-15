import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/providers/payment_provider.dart';

/// Production Order Confirmation & Success Screen
class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String? paymentReturnState;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    this.paymentReturnState,
  });

  @override
  ConsumerState<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen> {
  bool _didTriggerAutoVerify = false;

  @override
  void initState() {
    super.initState();
    // If returning from PayMongo checkout (e.g. ?payment=success), trigger authoritative server verification
    // Never mark the order as paid merely because the customer returned from PayMongo.
    if (widget.paymentReturnState == 'success' && widget.orderId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didTriggerAutoVerify) return;
        _didTriggerAutoVerify = true;
        ref.read(paymentNotifierProvider.notifier).verifyPayment(widget.orderId).then((res) {
          if (!mounted) return;
          ref.invalidate(orderDetailProvider(widget.orderId));
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderId = widget.orderId;
    final paymentState = ref.watch(paymentNotifierProvider);

    final fallbackOrderAsync = ref.watch(orderDetailProvider(orderId));
    OrderModel? order = fallbackOrderAsync.valueOrNull;

    try {
      final liveOrderAsync = ref.watch(orderPaymentStatusStreamProvider(orderId));
      if (liveOrderAsync.valueOrNull != null) {
        order = liveOrderAsync.valueOrNull;
      }
    } catch (_) {}

    if (order == null && fallbackOrderAsync.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        appBar: LambacAppBar(
          title: 'Order Confirmation',
          showBackButton: true,
          onBack: () => context.go(AppRoutes.home),
        ),
        body: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 480,
            padding: AppSpacing.screenPadding,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Order placed! (ID: $orderId)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  AppSpacing.vSpaceLg,
                  AppButton.primary(
                    text: 'Back to Home',
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final confirmedOrder = order;

    final isGcash = confirmedOrder.paymentMethod.toLowerCase().contains('gcash');
    final isPaid = confirmedOrder.isPaid;
    final isPending = isGcash && !isPaid;
    final isPaymentFailedOrExpired = isGcash && confirmedOrder.isPaymentFailed;
    final isCancelledReturn = widget.paymentReturnState == 'cancelled' && !isPaid;
    final hasValidCheckoutUrl = confirmedOrder.checkoutUrl != null &&
        confirmedOrder.checkoutUrl!.startsWith('https://') &&
        !isPaymentFailedOrExpired;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        title: 'Order Confirmation',
        showBackButton: true,
        onBack: () => context.go(AppRoutes.home),
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 600,
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Roastery Status Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: AppAnimations.medium,
                    curve: AppAnimations.spring,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: isPaid
                                ? CustomerLuxuryTheme.matchaSage.withOpacity(0.18)
                                : (isGcash
                                    ? const Color(0xFF007DFE).withOpacity(0.15)
                                    : (isDark ? AppColors.brandAmber.withOpacity(0.2) : const Color(0xFFF7EFE8))),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPaid
                                  ? CustomerLuxuryTheme.matchaSage
                                  : (isGcash ? const Color(0xFF007DFE) : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)),
                              width: 2,
                            ),
                            boxShadow: isDark ? AppShadows.cardDark : AppShadows.elevatedLight,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isPaid
                                ? Icons.verified_rounded
                                : (isGcash ? Icons.account_balance_wallet_rounded : Icons.check_rounded),
                            size: 44,
                            color: isPaid
                                ? CustomerLuxuryTheme.matchaSage
                                : (isGcash ? const Color(0xFF007DFE) : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)),
                          ),
                        ),
                      );
                    },
                  ),
                  AppSpacing.vSpaceXl,

                  // Header
                  Text(
                    'Your Order is Confirmed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isPaid) ...[
                    const SizedBox(height: 4),
                    Text(
                      '• Payment Verified via GCash (PayMongo) •',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CustomerLuxuryTheme.matchaSage,
                      ),
                    ),
                  ],
                  AppSpacing.vSpaceSm,
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Text(
                      isPaid
                          ? 'Thank you! Your GCash payment has been verified via PayMongo. Our baristas are preparing your freshly roasted order.'
                          : (isGcash
                              ? 'Your order is recorded in the roastery queue. Please complete your checkout on the GCash gateway to begin brewing.'
                              : 'Our baristas have received your order and are preparing your freshly roasted beans & brews for pickup.'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AppSpacing.vSpaceXl,

                  // If GCash and still pending: prominent Payment Action Card
                  if (isPending) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D253F) : const Color(0xFFEFF6FF),
                        borderRadius: AppRadius.radiusLg,
                        border: Border.all(
                          color: const Color(0xFF007DFE).withOpacity(0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPaymentFailedOrExpired || isCancelledReturn
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline_rounded,
                                color: const Color(0xFF007DFE),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isPaymentFailedOrExpired
                                      ? 'GCash Payment Session ${confirmedOrder.paymentStatus}'
                                      : (isCancelledReturn
                                          ? 'GCash Checkout Cancelled — Order Saved'
                                          : 'Awaiting GCash Payment Confirmation'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isPaymentFailedOrExpired
                                ? 'Your previous GCash checkout session did not complete. Tap "Retry GCash Payment" below to open a fresh PayMongo session.'
                                : (hasValidCheckoutUrl
                                    ? 'Click below if the GCash checkout page did not open automatically, or check payment status once completed.'
                                    : 'Tap "Retry GCash Payment" below to connect to PayMongo and complete your GCash payment.'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, actionConstraints) {
                              final primaryActionBtn = AppButton.primary(
                                text: hasValidCheckoutUrl
                                    ? 'Open GCash Checkout'
                                    : 'Retry GCash Payment',
                                size: AppButtonSize.small,
                                isLoading: paymentState.isCreatingCheckout,
                                onPressed: paymentState.isCreatingCheckout
                                    ? null
                                    : () async {
                                        if (hasValidCheckoutUrl) {
                                          final launchRes = await ref
                                              .read(paymentNotifierProvider.notifier)
                                              .reLaunchCheckout(confirmedOrder.checkoutUrl!);
                                          if (context.mounted && launchRes.isFailure) {
                                            AppToast.error(
                                              context,
                                              launchRes.failureOrNull!.userFriendlyMessage,
                                            );
                                          }
                                        } else {
                                          AppToast.info(context, 'Connecting to PayMongo GCash...');
                                          final retryRes = await ref
                                              .read(paymentNotifierProvider.notifier)
                                              .startGcashCheckout(
                                                confirmedOrder.id,
                                                forceNew: isPaymentFailedOrExpired,
                                              );
                                          if (!context.mounted) return;
                                          retryRes.when(
                                            success: (_) {
                                              ref.invalidate(orderDetailProvider(confirmedOrder.id));
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

                              final secondaryActionBtn = AppButton.secondary(
                                text: 'Check Status',
                                size: AppButtonSize.small,
                                isLoading: paymentState.isVerifying,
                                onPressed: paymentState.isVerifying
                                    ? null
                                    : () async {
                                        AppToast.info(context, 'Verifying payment status...');
                                        final res = await ref
                                            .read(paymentNotifierProvider.notifier)
                                            .verifyPayment(confirmedOrder.id);
                                        if (context.mounted) {
                                          res.when(
                                            success: (data) {
                                              ref.invalidate(orderDetailProvider(confirmedOrder.id));
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
                                            failure: (f) =>
                                                AppToast.error(context, f.userFriendlyMessage),
                                          );
                                        }
                                      },
                              );

                              if (actionConstraints.maxWidth < 400) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    primaryActionBtn,
                                    const SizedBox(height: 8),
                                    secondaryActionBtn,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: primaryActionBtn),
                                  const SizedBox(width: 8),
                                  Expanded(child: secondaryActionBtn),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vSpaceLg,
                  ],

                  // Order Summary Receipt Card
                  AppCard.elevated(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Number',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                  ),
                                ),
                                Text(
                                  confirmedOrder.orderNumber,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? CustomerLuxuryTheme.matchaSage.withOpacity(0.18)
                                    : (isGcash
                                        ? const Color(0xFF007DFE).withOpacity(0.15)
                                        : AppColors.brandAmber.withOpacity(0.15)),
                                borderRadius: AppRadius.radiusPill,
                              ),
                              child: Text(
                                isPaid
                                    ? 'PAID (GCash)'
                                    : (isGcash ? 'PENDING GCASH' : confirmedOrder.status.toDisplayString()),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isPaid
                                      ? CustomerLuxuryTheme.matchaSage
                                      : (isGcash ? const Color(0xFF007DFE) : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)),
                                ),
                              ),
                            ),
                          ],
                          ),
                        ),
                        const Divider(height: 24),

                        _buildReceiptRow('Pickup Location', confirmedOrder.pickupLocation.name, isDark),
                        AppSpacing.vSpaceSm,
                        _buildReceiptRow('Pickup Date', confirmedOrder.pickupDate, isDark),
                        AppSpacing.vSpaceSm,
                        _buildReceiptRow('Scheduled Time', confirmedOrder.pickupTimeSlot, isDark),
                        AppSpacing.vSpaceSm,
                        _buildReceiptRow(
                          'Fulfillment Status',
                          confirmedOrder.status.toDisplayString(),
                          isDark,
                        ),
                        AppSpacing.vSpaceSm,
                        _buildReceiptRow(
                          'Payment Method',
                          isGcash ? 'GCash (via PayMongo)' : confirmedOrder.paymentMethod,
                          isDark,
                        ),
                        AppSpacing.vSpaceSm,
                        _buildReceiptRow(
                          'Payment Status',
                          confirmedOrder.paymentStatus,
                          isDark,
                        ),
                        if (confirmedOrder.paymentReference != null && confirmedOrder.paymentReference!.isNotEmpty) ...[
                          AppSpacing.vSpaceSm,
                          _buildReceiptRow('Reference ID', confirmedOrder.paymentReference!, isDark),
                        ],
                        AppSpacing.vSpaceSm,
                        _buildReceiptRow(
                          isPaid
                              ? 'Total Paid via GCash'
                              : (isGcash ? 'Total Due Online' : 'Total Due at Counter'),
                          CurrencyFormatter.format(confirmedOrder.totalAmount),
                          isDark,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vSpaceXxl,

                  // Navigation Action Buttons
                  AppButton.primary(
                    text: 'Track Order Status',
                    onPressed: () => context.go(AppRoutes.orderDetailPath(confirmedOrder.id)),
                  ),
                  AppSpacing.vSpaceMd,
                  AppButton.outlined(
                    text: 'Back to Roastery Home',
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isDark, {bool isBold = false}) {
    final labelStyle = TextStyle(
      fontSize: 12,
      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
    );
    final valueStyle = TextStyle(
      fontSize: isBold ? 14 : 12,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 2),
              Text(value, style: valueStyle),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: Text(label, style: labelStyle),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: valueStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
