import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';
import '../../data/models/pos_cart_item_model.dart';
import 'pos_realtime_products_provider.dart';

/// POS Cart State with real-time discrepancy monitoring
class PosCartState extends Equatable {
  final List<PosCartItemModel> items;
  final double discountAmount;
  final String discountType; // 'none', 'pwd_senior', 'staff', 'promo'
  final String? customerName;
  final String? customerPhone;
  final String? notes;

  const PosCartState({
    this.items = const [],
    this.discountAmount = 0.0,
    this.discountType = 'none',
    this.customerName,
    this.customerPhone,
    this.notes,
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get total => (subtotal - discountAmount).clamp(0.0, double.infinity);
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Whether any item currently has a price discrepancy with authoritative live catalog
  bool get hasStalePrices => items.any((i) => i.isPriceStale);

  /// Whether any item in cart has been disabled or marked sold out in live catalog
  bool get hasUnavailableItems => items.any((i) => i.isUnavailable);

  int get staleItemsCount => items.where((i) => i.isPriceStale).length;
  int get unavailableItemsCount => items.where((i) => i.isUnavailable).length;

  /// Total difference if live prices are accepted
  double get priceDifferenceTotal {
    return items.fold(0.0, (sum, i) => sum + (i.liveLineTotal - i.lineTotal));
  }

  PosCartState copyWith({
    List<PosCartItemModel>? items,
    double? discountAmount,
    String? discountType,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) {
    return PosCartState(
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        items,
        discountAmount,
        discountType,
        customerName,
        customerPhone,
        notes,
      ];
}

/// Provider for POS Cart StateNotifier
final posCartNotifierProvider =
    StateNotifierProvider<PosCartNotifier, PosCartState>((ref) {
  final notifier = PosCartNotifier();

  // Listen to authoritative real-time Firestore product stream
  // Automatically reconciles cart items in real time whenever products are updated!
  ref.listen<AsyncValue<List<ProductModel>>>(
    posProductsStreamProvider,
    (previous, next) {
      next.whenData((liveProducts) {
        notifier.reconcileWithLiveProducts(liveProducts);
      });
    },
  );

  return notifier;
});

class PosCartNotifier extends StateNotifier<PosCartState> {
  PosCartNotifier() : super(const PosCartState());

  /// Add item to counter cart or increment quantity if matching variant exists
  void addItem({
    required ProductModel product,
    ProductVariantModel? sizeVariant,
    ProductVariantModel? grindVariant,
    int quantity = 1,
  }) {
    if (quantity <= 0) return;
    if (product.isSoldOut || !product.isEnabled) return;

    final newItem = PosCartItemModel.fromProduct(
      product: product,
      sizeVariant: sizeVariant,
      grindVariant: grindVariant,
      quantity: quantity,
    );

    final existingIndex = state.items.indexWhere((i) => i.id == newItem.id);

    List<PosCartItemModel> updated;
    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final merged = existing.copyWith(quantity: existing.quantity + quantity);
      updated = List<PosCartItemModel>.from(state.items)..[existingIndex] = merged;
    } else {
      updated = [...state.items, newItem];
    }

    state = state.copyWith(items: updated);
  }

  /// Increment item quantity
  void incrementQuantity(String cartItemId) {
    final idx = state.items.indexWhere((i) => i.id == cartItemId);
    if (idx < 0) return;

    final current = state.items[idx];
    final updatedItem = current.copyWith(quantity: current.quantity + 1);

    final updatedList = List<PosCartItemModel>.from(state.items)..[idx] = updatedItem;
    state = state.copyWith(items: updatedList);
  }

  /// Decrement item quantity or remove if drops to 0
  void decrementQuantity(String cartItemId) {
    final idx = state.items.indexWhere((i) => i.id == cartItemId);
    if (idx < 0) return;

    final current = state.items[idx];
    List<PosCartItemModel> updatedList;

    if (current.quantity > 1) {
      final updatedItem = current.copyWith(quantity: current.quantity - 1);
      updatedList = List<PosCartItemModel>.from(state.items)..[idx] = updatedItem;
    } else {
      updatedList = List<PosCartItemModel>.from(state.items)..removeAt(idx);
    }

    state = state.copyWith(items: updatedList);
  }

  /// Remove item completely from cart
  void removeItem(String cartItemId) {
    final updated = state.items.where((i) => i.id != cartItemId).toList();
    state = state.copyWith(items: updated);
  }

  /// Clear all cart items
  void clearCart() {
    state = const PosCartState();
  }

  /// Reconcile current cart items against live catalog from Firestore
  void reconcileWithLiveProducts(List<ProductModel> liveProducts) {
    if (state.items.isEmpty) return;

    final productMap = {for (final p in liveProducts) p.id: p};

    final reconciledItems = state.items.map((cartItem) {
      final liveProduct = productMap[cartItem.product.id];
      return cartItem.syncWithLiveProduct(liveProduct);
    }).toList();

    state = state.copyWith(items: reconciledItems);
  }

  /// Accept updated price for a single item
  void acceptPriceForItem(String cartItemId) {
    final idx = state.items.indexWhere((i) => i.id == cartItemId);
    if (idx < 0) return;

    final current = state.items[idx];
    final updated = current.acceptLivePrice();

    final updatedList = List<PosCartItemModel>.from(state.items)..[idx] = updated;
    state = state.copyWith(items: updatedList);
  }

  /// Accept all live price updates in the cart
  void acceptAllLivePrices() {
    final updated = state.items.map((i) => i.acceptLivePrice()).toList();
    state = state.copyWith(items: updated);
  }

  /// Remove all products currently flagged as unavailable or sold out
  void removeUnavailableItems() {
    final updated = state.items.where((i) => !i.isUnavailable).toList();
    state = state.copyWith(items: updated);
  }

  /// Apply discount (e.g. 20% senior/PWD, staff perk, custom promo)
  void applyDiscount(double amount, String type) {
    state = state.copyWith(
      discountAmount: amount.clamp(0.0, state.subtotal),
      discountType: type,
    );
  }

  /// Clear applied discount
  void clearDiscount() {
    state = state.copyWith(
      discountAmount: 0.0,
      discountType: 'none',
    );
  }

  /// Set optional customer information
  void setCustomerInfo({String? name, String? phone}) {
    state = state.copyWith(
      customerName: name,
      customerPhone: phone,
    );
  }

  /// Set transaction notes
  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }
}
