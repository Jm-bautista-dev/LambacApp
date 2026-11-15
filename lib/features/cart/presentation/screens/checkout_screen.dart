import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/buttons/app_scale_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/create_order_request.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/domain/services/pickup_scheduling_service.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/presentation/providers/payment_provider.dart';
import '../../data/models/pickup_location_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/pickup_scheduler_widget.dart';

/// Production Customer Pickup-Only Checkout Screen
/// Refactored with Editorial Styling, Precision Scheduling Validation, and Clear Counter Payment Disclosures
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final TextEditingController _notesController = TextEditingController();

  PresetPrepOption _selectedPreset = PresetPrepOption.oneHour;
  late String _selectedDate;
  late String _selectedTimeSlot;
  String _selectedPaymentMethod = 'Pay at Counter';
  bool _isSubmitting = false;
  String? _checkoutIdempotencyKey;
  OrderModel? _pendingCreatedGcashOrder;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '09171234567');

    final eligibility = ref.read(firstOrderEligibilityProvider);
    if (eligibility.requiresFirstOrderGcash) {
      _selectedPaymentMethod = 'GCash';
    }

    final initialScheduled = PickupSchedulingService().calculatePresetSchedule(
      preset: PresetPrepOption.oneHour,
      location: PickupLocationModel.flagship,
    );
    _selectedDate = initialScheduled.dateDisplay;
    _selectedTimeSlot = initialScheduled.timeSlot;

    // Pre-warm standalone PayMongo backend on checkout entry to mitigate free-tier cold start
    unawaited(ref.read(paymongoServiceProvider).checkBackendHealth());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmOrder() async {
    final paymentState = ref.read(paymentNotifierProvider);
    if (_isSubmitting || paymentState.isCreatingCheckout) return;
    if (!_formKey.currentState!.validate()) return;

    final cartState = ref.read(cartNotifierProvider);
    if (cartState.isEmpty && _pendingCreatedGcashOrder == null) {
      AppToast.error(context, 'Your cart is empty.');
      return;
    }

    // Client-side Business Hours, Preparation Buffer & Schedule Validation
    final validation = PickupSchedulingService().validateSchedule(
      dateStr: _selectedDate,
      timeSlotStr: _selectedTimeSlot,
      location: PickupLocationModel.flagship,
    );

    if (validation.isFailure) {
      AppToast.error(context, validation.failureOrNull!.message);
      return;
    }

    setState(() => _isSubmitting = true);

    final userId = ref.read(currentUserProvider)?.id ?? 'guest';
    final eligibility = ref.read(firstOrderEligibilityProvider);
    final effectivePaymentMethod = eligibility.requiresFirstOrderGcash ? 'GCash' : _selectedPaymentMethod;
    _checkoutIdempotencyKey ??= 'idemp_chk_${DateTime.now().millisecondsSinceEpoch}_$userId';

    // Reuse previously created order if retrying GCash session creation from this screen
    if (_pendingCreatedGcashOrder != null && effectivePaymentMethod == 'GCash') {
      final existingOrder = _pendingCreatedGcashOrder!;
      AppToast.info(context, 'Connecting to PayMongo GCash...');
      final checkoutRes = await ref.read(paymentNotifierProvider.notifier).startGcashCheckout(existingOrder.id);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      checkoutRes.when(
        success: (_) {
          _pendingCreatedGcashOrder = null;
          _checkoutIdempotencyKey = null;
          ref.read(cartNotifierProvider.notifier).clearCart();
          AppToast.success(context, 'Opening GCash payment gateway...');
          context.go('/order-confirmation?orderId=${existingOrder.id}');
        },
        failure: (failure) {
          ref.read(cartNotifierProvider.notifier).clearCart();
          AppToast.error(context, failure.userFriendlyMessage);
          context.go('/order-confirmation?orderId=${existingOrder.id}');
        },
      );
      return;
    }

    final request = CreateOrderRequest(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerEmail: ref.read(currentUserProvider)?.email,
      items: cartState.items,
      pickupLocation: PickupLocationModel.flagship,
      pickupDate: _selectedDate,
      pickupTimeSlot: _selectedTimeSlot,
      paymentMethod: effectivePaymentMethod,
      paymentStatus: effectivePaymentMethod == 'GCash' ? 'PENDING' : 'UNPAID',
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      idempotencyKey: _checkoutIdempotencyKey,
    );

    final result = await ref.read(ordersNotifierProvider.notifier).submitOrder(request);

    if (!mounted) return;

    await result.when(
      success: (order) async {
        if (effectivePaymentMethod == 'GCash') {
          _pendingCreatedGcashOrder = order;
          // Initiate PayMongo Hosted Checkout Session
          AppToast.info(context, 'Connecting to PayMongo GCash...');
          final checkoutRes = await ref.read(paymentNotifierProvider.notifier).startGcashCheckout(order.id);
          if (!mounted) return;
          setState(() => _isSubmitting = false);

          // Clear cart now that order is persisted and navigating to OrderConfirmationScreen
          _checkoutIdempotencyKey = null;
          _pendingCreatedGcashOrder = null;
          ref.read(cartNotifierProvider.notifier).clearCart();

          checkoutRes.when(
            success: (chk) {
              AppToast.success(context, 'Opening GCash payment gateway...');
              context.go('/order-confirmation?orderId=${order.id}');
            },
            failure: (failure) {
              AppToast.error(context, failure.userFriendlyMessage);
              context.go('/order-confirmation?orderId=${order.id}');
            },
          );
        } else {
          _checkoutIdempotencyKey = null;
          ref.read(cartNotifierProvider.notifier).clearCart();
          setState(() => _isSubmitting = false);
          AppToast.success(context, 'Order ${order.orderNumber} placed for pickup!');
          context.go('/order-confirmation?orderId=${order.id}');
        }
      },
      failure: (failure) {
        setState(() => _isSubmitting = false);
        AppToast.error(context, failure.userFriendlyMessage);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(cartNotifierProvider);
    final firstOrderEligibility = ref.watch(firstOrderEligibilityProvider);
    final requiresFirstOrderGcash = firstOrderEligibility.requiresFirstOrderGcash;
    final effectivePaymentMethod = requiresFirstOrderGcash ? 'GCash' : _selectedPaymentMethod;
    if (requiresFirstOrderGcash && _selectedPaymentMethod != 'GCash') {
      _selectedPaymentMethod = 'GCash';
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        title: 'Pickup Checkout',
        subtitle: 'Lambac Coffee Roastery',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.cart);
          }
        },
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.subtleOperations,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 720,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --------------------------------------------------
                          // Pickup Only Reminder Banner
                          // --------------------------------------------------
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF221A15) : const Color(0xFFF7EFE8),
                              borderRadius: AppRadius.radiusLg,
                              border: Border.all(
                                color: isDark
                                    ? CustomerLuxuryTheme.borderDark
                                    : CustomerLuxuryTheme.amberGold.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: 22,
                                    color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Roastery Pickup Order Only',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? CustomerLuxuryTheme.amberGoldLight : const Color(0xFFA35F30),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Your handcrafted brews will be freshly prepared for direct pickup at our flagship bar.',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------
                          // 1. Pickup Location Details
                          // --------------------------------------------------
                          _buildSectionHeader('Pickup Location', isDark),
                          AppSpacing.vSpaceSm,
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: CustomerLuxuryTheme.cardDecoration(
                              isDark: isDark,
                              borderRadius: AppRadius.radiusLg,
                              isElevated: true,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                    size: 22,
                                  ),
                                ),
                                AppSpacing.hSpaceMd,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        PickupLocationModel.flagship.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${PickupLocationModel.flagship.address}, ${PickupLocationModel.flagship.city}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Hours: ${PickupLocationModel.flagship.operatingHours}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.cremaGold : CustomerLuxuryTheme.amberGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------
                          // 2. Pickup Scheduling (Presets + Custom)
                          // --------------------------------------------------
                          _buildSectionHeader('Select Pickup Time', isDark),
                          AppSpacing.vSpaceSm,
                          PickupSchedulerWidget(
                            location: PickupLocationModel.flagship,
                            initialDate: _selectedDate,
                            initialTimeSlot: _selectedTimeSlot,
                            initialPreset: _selectedPreset,
                            onScheduleChanged: (dateDisplay, timeSlot, preset, fullDateTime) {
                              setState(() {
                                _selectedDate = dateDisplay;
                                _selectedTimeSlot = timeSlot;
                                _selectedPreset = preset;
                              });
                            },
                          ),
                          AppSpacing.vSpaceSm,
                          // Express quick slot shortcut for grab & go
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Express Grab & Go: ',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              AppScaleButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedPreset = PresetPrepOption.custom;
                                    _selectedDate = 'Today';
                                    _selectedTimeSlot = 'ASAP (~15-20 mins)';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _selectedTimeSlot == 'ASAP (~15-20 mins)'
                                        ? CustomerLuxuryTheme.amberGold.withOpacity(0.2)
                                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                                    borderRadius: AppRadius.radiusPill,
                                    border: Border.all(
                                      color: _selectedTimeSlot == 'ASAP (~15-20 mins)'
                                          ? (isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold)
                                          : (isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight),
                                      width: _selectedTimeSlot == 'ASAP (~15-20 mins)' ? 1.4 : 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flash_on_rounded,
                                        size: 13,
                                        color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ASAP (~15-20 mins)',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? CustomerLuxuryTheme.amberGoldLight : const Color(0xFFA35F30),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------
                          // 4. Customer Contact Information
                          // --------------------------------------------------
                          _buildSectionHeader('Contact Information', isDark),
                          AppSpacing.vSpaceSm,
                          AppTextField(
                            label: 'Full Name for Pickup Callout',
                            hint: 'Kenji Takahashi',
                            controller: _nameController,
                            validator: (v) => Validators.required(v, 'Please enter your name'),
                            prefix: const Icon(Icons.person_outline_rounded, size: 20),
                          ),
                          AppSpacing.vSpaceMd,
                          AppTextField(
                            label: 'Mobile Number for SMS Alert',
                            hint: '09171234567',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                            prefix: const Icon(Icons.phone_outlined, size: 20),
                          ),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------
                          // 5. Payment Method Selection (Pay at Counter & GCash)
                          // --------------------------------------------------
                          _buildSectionHeader('Payment Method', isDark),
                          AppSpacing.vSpaceSm,

                          // First-Order Mandatory GCash Notice Banner
                          if (requiresFirstOrderGcash) ...[
                            Container(
                              key: const Key('first_order_gcash_required_banner'),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0A1E36) : const Color(0xFFEFF6FF),
                                borderRadius: AppRadius.radiusMd,
                                border: Border.all(
                                  color: const Color(0xFF007DFE).withOpacity(0.55),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.verified_user_rounded,
                                      size: 20,
                                      color: Color(0xFF007DFE),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your first order must be paid through GCash.',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Pay at Counter will unlock automatically once your first GCash order is verified as PAID through PayMongo.',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.vSpaceSm,
                          ],

                          // Option A: GCash E-Wallet (via PayMongo)
                          AppScaleButton(
                            key: const Key('payment_option_gcash'),
                            onPressed: () {
                              setState(() {
                                _selectedPaymentMethod = 'GCash';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: effectivePaymentMethod == 'GCash'
                                    ? (isDark ? const Color(0xFF0D253F) : const Color(0xFFEFF6FF))
                                    : (isDark ? CustomerLuxuryTheme.darkElevatedSurface : Colors.white),
                                borderRadius: AppRadius.radiusLg,
                                border: Border.all(
                                  color: effectivePaymentMethod == 'GCash'
                                      ? const Color(0xFF007DFE) // Official GCash Blue Accent
                                      : (isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight),
                                  width: effectivePaymentMethod == 'GCash' ? 1.8 : 1.0,
                                ),
                                boxShadow: isDark ? CustomerLuxuryTheme.luxuryShadowDark : CustomerLuxuryTheme.luxuryShadowLight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF007DFE).withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          size: 20,
                                          color: Color(0xFF007DFE),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  'GCash E-Wallet',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF007DFE).withOpacity(0.15),
                                                    borderRadius: AppRadius.radiusPill,
                                                  ),
                                                  child: const Text(
                                                    'PayMongo Hosted',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF007DFE),
                                                    ),
                                                  ),
                                                ),
                                                if (requiresFirstOrderGcash)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF007DFE),
                                                      borderRadius: AppRadius.radiusPill,
                                                    ),
                                                    child: const Text(
                                                      'Required for 1st Order',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Instant online payment with official GCash e-wallet.',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Encrypted 256-bit checkout session powered by PayMongo.',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        effectivePaymentMethod == 'GCash'
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                        color: effectivePaymentMethod == 'GCash'
                                            ? const Color(0xFF007DFE)
                                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.vSpaceSm,

                          // Option B: Pay at Counter (Disabled & locked for first-order customers)
                          Opacity(
                            opacity: requiresFirstOrderGcash ? 0.52 : 1.0,
                            child: IgnorePointer(
                              ignoring: requiresFirstOrderGcash,
                              child: AppScaleButton(
                                key: const Key('payment_option_pay_at_counter'),
                                onPressed: requiresFirstOrderGcash
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedPaymentMethod = 'Pay at Counter';
                                        });
                                      },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: effectivePaymentMethod == 'Pay at Counter'
                                        ? (isDark ? CustomerLuxuryTheme.amberGold.withOpacity(0.12) : const Color(0xFFFBF7F2))
                                        : (isDark ? CustomerLuxuryTheme.darkElevatedSurface : Colors.white),
                                    borderRadius: AppRadius.radiusLg,
                                    border: Border.all(
                                      color: effectivePaymentMethod == 'Pay at Counter'
                                          ? (isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold)
                                          : (isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight),
                                      width: effectivePaymentMethod == 'Pay at Counter' ? 1.8 : 1.0,
                                    ),
                                    boxShadow: isDark ? CustomerLuxuryTheme.luxuryShadowDark : CustomerLuxuryTheme.luxuryShadowLight,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? CustomerLuxuryTheme.amberGold.withOpacity(0.2)
                                                  : CustomerLuxuryTheme.amberGold.withOpacity(0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              requiresFirstOrderGcash ? Icons.lock_outline_rounded : Icons.storefront_rounded,
                                              size: 20,
                                              color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Text(
                                                      '💳 Pay at Counter',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? CustomerLuxuryTheme.amberGoldLight : const Color(0xFFA35F30),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: requiresFirstOrderGcash
                                                            ? Colors.grey.withOpacity(0.25)
                                                            : CustomerLuxuryTheme.matchaSage.withOpacity(0.2),
                                                        borderRadius: AppRadius.radiusPill,
                                                      ),
                                                      child: Text(
                                                        requiresFirstOrderGcash ? 'Unavailable for 1st Order' : 'Pickup Only',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w700,
                                                          color: requiresFirstOrderGcash
                                                              ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                                                              : CustomerLuxuryTheme.matchaSage,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  'Pay when you pick up your order at the store.',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Payment will be collected when you pick up your order.',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            requiresFirstOrderGcash
                                                ? Icons.lock_rounded
                                                : (effectivePaymentMethod == 'Pay at Counter'
                                                    ? Icons.check_circle_rounded
                                                    : Icons.radio_button_unchecked_rounded),
                                            color: effectivePaymentMethod == 'Pay at Counter'
                                                ? CustomerLuxuryTheme.matchaSage
                                                : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------
                          // 6. Prominent Pickup & Payment Summary
                          // --------------------------------------------------
                          _buildSectionHeader('Pickup Order Summary', isDark),
                          AppSpacing.vSpaceSm,
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: CustomerLuxuryTheme.cardDecoration(
                              isDark: isDark,
                              borderRadius: AppRadius.radiusLg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isDark ? CustomerLuxuryTheme.amberGold.withOpacity(0.2) : CustomerLuxuryTheme.amberGold.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.storefront_rounded,
                                            size: 16,
                                            color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pickup',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                        borderRadius: AppRadius.radiusPill,
                                        border: Border.all(
                                          color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        _selectedPreset.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? CustomerLuxuryTheme.amberGoldLight : const Color(0xFFA35F30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                _buildSummaryItem('Date:', _selectedDate, Icons.calendar_today_rounded, isDark),
                                const SizedBox(height: 8),
                                _buildSummaryItem('Time:', _selectedTimeSlot, Icons.access_time_rounded, isDark),
                                const SizedBox(height: 8),
                                _buildSummaryItem(
                                  'Payment Method:',
                                  effectivePaymentMethod == 'GCash' ? 'GCash' : 'Pay at Counter',
                                  effectivePaymentMethod == 'GCash' ? Icons.account_balance_wallet_rounded : Icons.point_of_sale_rounded,
                                  isDark,
                                  isHighlight: true,
                                ),
                                const SizedBox(height: 8),
                                _buildSummaryItem(
                                  'Amount to be Paid:',
                                  CurrencyFormatter.format(cartState.subtotal),
                                  Icons.payments_outlined,
                                  isDark,
                                  isHighlight: true,
                                ),
                                const SizedBox(height: 8),
                                _buildSummaryItem('Location:', 'Flagship Roastery Bar', Icons.location_on_rounded, isDark),
                                if (effectivePaymentMethod == 'GCash') ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007DFE).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 14,
                                          color: Color(0xFF007DFE),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Checkout will proceed to PayMongo GCash payment.',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          AppSpacing.vSpaceXl,

                          // --------------------------------------------------
                          // 7. Special Barista Instructions / Notes
                          // --------------------------------------------------
                          _buildSectionHeader('Barista Instructions (Optional)', isDark),
                          AppSpacing.vSpaceSm,
                          AppTextField(
                            label: 'Special Notes',
                            hint: 'e.g. Leave beans unground in bag, separate ice...',
                            controller: _notesController,
                            maxLines: 2,
                          ),
                          AppSpacing.vSpaceXxl,
                        ],
                      ),
                    ),
                  ),
                ),

                // --------------------------------------------------------------
                // Checkout Confirmation Bottom Bar
                // --------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: isDark ? CustomerLuxuryTheme.darkElevatedSurface : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                        width: 1,
                      ),
                    ),
                    boxShadow: isDark ? CustomerLuxuryTheme.luxuryShadowDark : CustomerLuxuryTheme.luxuryShadowLight,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 360;
                      if (isCompact) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Total Payment Due',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      CurrencyFormatter.format(cartState.subtotal),
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.vSpaceSm,
                            AppButton.primary(
                              text: effectivePaymentMethod == 'GCash' ? 'Pay with GCash' : 'Confirm Pickup Order',
                              isLoading: _isSubmitting,
                              isFullWidth: true,
                              onPressed: _isSubmitting ? null : _handleConfirmOrder,
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Payment Due',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(cartState.subtotal),
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.cremaGold : const Color(0xFFA35F30),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton.primary(
                            text: effectivePaymentMethod == 'GCash' ? 'Pay with GCash' : 'Confirm Pickup Order',
                            isLoading: _isSubmitting,
                            isFullWidth: false,
                            width: 200,
                            onPressed: _isSubmitting ? null : _handleConfirmOrder,
                          ),
                        ],
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, bool isDark, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isHighlight
              ? (isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold)
              : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isHighlight
                  ? (isDark ? CustomerLuxuryTheme.amberGoldLight : const Color(0xFFA35F30))
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
