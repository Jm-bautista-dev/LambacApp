import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/pending_add_to_cart_action.dart';

/// StateNotifier managing pending cart actions across authentication barriers
class PendingActionNotifier extends StateNotifier<PendingAddToCartAction?> {
  PendingActionNotifier() : super(null);

  /// Stores an intended add-to-cart action
  void setPendingAction(PendingAddToCartAction action) {
    state = action;
  }

  /// Consumes and immediately clears the pending action in one atomic step to prevent double execution
  PendingAddToCartAction? consumePendingAction() {
    final action = state;
    state = null;
    return action;
  }

  /// Clears any lingering pending action (e.g. upon user logout or cancellation)
  void clearPendingAction() {
    state = null;
  }
}

/// Provider for pending add-to-cart intent preservation
final pendingActionProvider =
    StateNotifierProvider<PendingActionNotifier, PendingAddToCartAction?>((ref) {
  return PendingActionNotifier();
});
