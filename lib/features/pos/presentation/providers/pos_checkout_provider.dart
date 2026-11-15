import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../data/models/pos_checkout_request.dart';
import '../../data/models/pos_receipt_model.dart';
import 'pos_cart_provider.dart';
import 'pos_repository_provider.dart';

/// Checkout submission state container
class PosCheckoutState extends Equatable {
  final bool isSubmitting;
  final PosReceiptModel? lastCompletedReceipt;
  final AppFailure? failure;

  const PosCheckoutState({
    this.isSubmitting = false,
    this.lastCompletedReceipt,
    this.failure,
  });

  PosCheckoutState copyWith({
    bool? isSubmitting,
    PosReceiptModel? lastCompletedReceipt,
    AppFailure? failure,
    bool clearReceipt = false,
    bool clearFailure = false,
  }) {
    return PosCheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastCompletedReceipt: clearReceipt ? null : (lastCompletedReceipt ?? this.lastCompletedReceipt),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [isSubmitting, lastCompletedReceipt, failure];
}

/// Provider for POS Checkout Notifier
final posCheckoutNotifierProvider =
    StateNotifierProvider<PosCheckoutNotifier, PosCheckoutState>((ref) {
  return PosCheckoutNotifier(ref: ref);
});

class PosCheckoutNotifier extends StateNotifier<PosCheckoutState> {
  final Ref _ref;
  final _uuid = const Uuid();

  PosCheckoutNotifier({required Ref ref})
      : _ref = ref,
        super(const PosCheckoutState());

  /// Executes atomic checkout with idempotency and duplicate prevention
  Future<Result<PosReceiptModel, AppFailure>> submitCheckout({
    required String paymentMethod,
    double? tenderedAmount,
    double? changeAmount,
  }) async {
    final cartState = _ref.read(posCartNotifierProvider);

    if (cartState.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Cannot checkout with an empty cart.'),
      );
    }

    if (cartState.hasUnavailableItems) {
      return const Result.failure(
        ValidationFailure(
          message: 'Cart contains unavailable or sold-out items. Please remove them before checkout.',
        ),
      );
    }

    if (cartState.hasStalePrices) {
      return const Result.failure(
        ValidationFailure(
          message: 'Product prices have been updated by an Administrator. Please review and accept updated prices before completing the sale.',
        ),
      );
    }

    // Cash tendered validation
    if (paymentMethod.toLowerCase() == 'cash') {
      if (tenderedAmount == null || tenderedAmount < cartState.total) {
        return Result.failure(
          ValidationFailure(
            message: 'Tendered cash (₱${tenderedAmount?.toStringAsFixed(2) ?? "0.00"}) must be at least ₱${cartState.total.toStringAsFixed(2)}.',
          ),
        );
      }
    }

    // Prevent duplicate submission if already processing
    if (state.isSubmitting) {
      return const Result.failure(
        ConflictFailure(message: 'Transaction is already being processed. Please wait.'),
      );
    }

    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final currentUser = _ref.read(currentUserProvider);
    final staffId = currentUser?.id ?? 'staff_current';
    final staffName = currentUser?.fullName.isNotEmpty == true ? currentUser!.fullName : 'Staff Member';

    // Unique transaction key ensuring strict duplicate submission prevention
    final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';

    final request = PosCheckoutRequest(
      items: cartState.items,
      paymentMethod: paymentMethod,
      tenderedAmount: tenderedAmount,
      changeAmount: changeAmount ?? (tenderedAmount != null ? (tenderedAmount - cartState.total).clamp(0.0, double.infinity) : null),
      discountAmount: cartState.discountAmount,
      discountType: cartState.discountType,
      customerName: cartState.customerName,
      customerPhone: cartState.customerPhone,
      notes: cartState.notes,
      staffId: staffId,
      staffName: staffName,
      idempotencyKey: idempotencyKey,
    );

    final repository = _ref.read(posRepositoryProvider);
    final result = await repository.completeSaleTransaction(request);

    return result.when(
      success: (receipt) {
        // Reset the cart only after backend confirmation!
        _ref.read(posCartNotifierProvider.notifier).clearCart();

        // Refresh centralized sales ledger and dashboard metrics
        _ref.read(salesNotifierProvider.notifier).loadSales();
        _ref.invalidate(businessMetricsProvider);
        _ref.invalidate(analyticsSummaryProvider);

        state = state.copyWith(
          isSubmitting: false,
          lastCompletedReceipt: receipt,
          clearFailure: true,
        );
        return Result.success(receipt);
      },
      failure: (failure) {
        // Cart is intentionally preserved on failure for safe barista retry
        state = state.copyWith(
          isSubmitting: false,
          failure: failure,
        );
        return Result.failure(failure);
      },
    );
  }

  void dismissReceipt() {
    state = state.copyWith(clearReceipt: true);
  }

  void clearError() {
    state = state.copyWith(clearFailure: true);
  }
}
