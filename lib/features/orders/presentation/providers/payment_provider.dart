import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/first_order_eligibility_model.dart';
import '../../data/models/order_model.dart';
import '../../domain/services/paymongo_service.dart';
import 'orders_provider.dart';

/// Provider for PaymongoService
final paymongoServiceProvider = Provider<PaymongoService>((ref) {
  return PaymongoService();
});

/// Trigger counter to force re-evaluation of firstOrderEligibilityProvider when orders change
final firstOrderEligibilityTriggerProvider = StateProvider<int>((ref) => 0);

/// Authoritative First-Order GCash Eligibility Provider
/// Recomputes whenever the authenticated user or backend orders state changes.
/// Never relies on local storage or client-editable flags.
final firstOrderEligibilityProvider = Provider<FirstOrderEligibility>((ref) {
  ref.watch(firstOrderEligibilityTriggerProvider);
  final user = ref.watch(currentUserProvider);
  final orderRepo = ref.watch(orderRepositoryProvider);

  if (user == null) {
    return FirstOrderEligibility.completed(customerId: '');
  }

  // Staff / Admin accounts are not subject to customer first-order restriction
  if (user.isBusinessUser) {
    return FirstOrderEligibility.completed(
      customerId: user.id,
      qualifyingOrderId: 'staff_exempt',
    );
  }

  // 1. Evaluate synchronous backend repository eligibility (queries authoritative orders ledger)
  final repoEligibility = orderRepo.getFirstOrderEligibilitySync(user.id);
  if (repoEligibility.hasCompletedFirstOrder) {
    return repoEligibility;
  }

  // 2. Check user profile flag if verified by backend
  if (user.firstOrderGcashCompleted) {
    return FirstOrderEligibility.completed(
      customerId: user.id,
      qualifyingOrderId: user.firstOrderCompletedOrderId,
    );
  }

  return repoEligibility;
});

/// Payment Controller State
class PaymentControllerState {
  final bool isCreatingCheckout;
  final bool isVerifying;
  final String? checkoutUrl;
  final String? error;
  final OrderModel? order;

  const PaymentControllerState({
    this.isCreatingCheckout = false,
    this.isVerifying = false,
    this.checkoutUrl,
    this.error,
    this.order,
  });

  PaymentControllerState copyWith({
    bool? isCreatingCheckout,
    bool? isVerifying,
    String? checkoutUrl,
    String? error,
    bool clearError = false,
    OrderModel? order,
  }) {
    return PaymentControllerState(
      isCreatingCheckout: isCreatingCheckout ?? this.isCreatingCheckout,
      isVerifying: isVerifying ?? this.isVerifying,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      error: clearError ? null : (error ?? this.error),
      order: order ?? this.order,
    );
  }
}

/// StateNotifier for managing active PayMongo GCash checkout and verification
class PaymentNotifier extends StateNotifier<PaymentControllerState> {
  final PaymongoService _paymongoService;

  PaymentNotifier({required PaymongoService paymongoService})
      : _paymongoService = paymongoService,
        super(const PaymentControllerState());

  /// Initiate GCash checkout for a created order
  Future<Result<PaymongoCheckoutResponse, AppFailure>> startGcashCheckout(
    String orderId, {
    bool forceNew = false,
  }) async {
    state = state.copyWith(isCreatingCheckout: true, clearError: true);

    final result = await _paymongoService.createCheckoutSession(
      orderId,
      forceNew: forceNew,
    );

    await result.when(
      success: (response) async {
        state = state.copyWith(
          isCreatingCheckout: false,
          checkoutUrl: response.checkoutUrl,
        );
        // Automatically launch checkout URL in browser / external application
        await _paymongoService.launchCheckoutUrl(response.checkoutUrl);
      },
      failure: (failure) async {
        state = state.copyWith(
          isCreatingCheckout: false,
          error: failure.userFriendlyMessage,
        );
      },
    );

    return result;
  }

  /// Launch existing checkout URL again (e.g. from Order Confirmation or Order Details screen)
  Future<Result<bool, AppFailure>> reLaunchCheckout(String checkoutUrl) async {
    return _paymongoService.launchCheckoutUrl(checkoutUrl);
  }

  /// Manually trigger verification check
  Future<Result<Map<String, dynamic>, AppFailure>> verifyPayment(String orderId, {String? checkoutSessionId}) async {
    state = state.copyWith(isVerifying: true, clearError: true);
    final result = await _paymongoService.verifyPaymentSession(orderId, checkoutSessionId: checkoutSessionId);
    state = state.copyWith(isVerifying: false);
    return result;
  }
}

/// Provider for PaymentNotifier
final paymentNotifierProvider = StateNotifierProvider<PaymentNotifier, PaymentControllerState>((ref) {
  final service = ref.watch(paymongoServiceProvider);
  return PaymentNotifier(paymongoService: service);
});

/// StreamProvider for real-time live order payment status
final orderPaymentStatusStreamProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final service = ref.watch(paymongoServiceProvider);
  return service.watchOrderPayment(orderId);
});

