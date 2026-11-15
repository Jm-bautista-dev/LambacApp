import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';
import '../../data/models/cart_item_model.dart';

/// Global Cart State Container
class CartState extends Equatable {
  final List<CartItemModel> items;
  final bool isLoading;

  const CartState({
    this.items = const [],
    this.isLoading = false,
  });

  double get subtotal => items.fold(0.0, (acc, item) => acc + item.totalPrice);
  int get itemCount => items.fold(0, (acc, item) => acc + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartState copyWith({
    List<CartItemModel>? items,
    bool? isLoading,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [items, isLoading];
}

/// User-Scoped Cart State Notifier Provider
final cartNotifierProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  return CartNotifier(
    storageService: storageService,
    userId: currentUser?.id,
  );
});

/// Cart Notifier managing item addition, quantities, and user-scoped local persistence
class CartNotifier extends StateNotifier<CartState> {
  final StorageService _storageService;
  final String? _userId;

  CartNotifier({
    required StorageService storageService,
    String? userId,
  })  : _storageService = storageService,
        _userId = userId,
        super(const CartState(isLoading: true)) {
    _restoreCart();
  }

  String get _cartStorageKey => 'lambac_cart_${_userId ?? "guest"}_v1';

  Future<void> _restoreCart() async {
    try {
      final jsonString = await _storageService.getString(_cartStorageKey);
      if (!mounted) return;
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        final restoredItems = decoded
            .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(items: restoredItems, isLoading: false);
      } else {
        state = state.copyWith(items: [], isLoading: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(items: [], isLoading: false);
      }
    }
  }

  Future<void> _persistCart() async {
    try {
      final jsonString = jsonEncode(state.items.map((e) => e.toJson()).toList());
      await _storageService.setString(_cartStorageKey, jsonString);
    } catch (_) {
      // Ignore write errors
    }
  }

  /// Add product to cart with chosen size & grind variants
  void addItem({
    required ProductModel product,
    ProductVariantModel? sizeVariant,
    ProductVariantModel? grindVariant,
    int quantity = 1,
    String? specialInstructions,
  }) {
    if (quantity <= 0) return;

    final newItem = CartItemModel.fromProduct(
      product: product,
      sizeVariant: sizeVariant,
      grindVariant: grindVariant,
      quantity: quantity,
      specialInstructions: specialInstructions,
    );

    final existingIndex = state.items.indexWhere((item) => item.id == newItem.id);

    List<CartItemModel> updatedItems;
    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final merged = existing.copyWith(
        quantity: existing.quantity + quantity,
        specialInstructions: specialInstructions ?? existing.specialInstructions,
      );
      updatedItems = List<CartItemModel>.from(state.items)..[existingIndex] = merged;
    } else {
      updatedItems = [...state.items, newItem];
    }

    state = state.copyWith(items: updatedItems);
    _persistCart();
  }

  /// Increment item quantity by 1
  void incrementQuantity(String cartItemId) {
    final index = state.items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) return;

    final current = state.items[index];
    final updated = current.copyWith(quantity: current.quantity + 1);

    final updatedItems = List<CartItemModel>.from(state.items)..[index] = updated;
    state = state.copyWith(items: updatedItems);
    _persistCart();
  }

  /// Decrement item quantity or remove if it drops to 0
  void decrementQuantity(String cartItemId) {
    final index = state.items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) return;

    final current = state.items[index];
    List<CartItemModel> updatedItems;

    if (current.quantity > 1) {
      final updated = current.copyWith(quantity: current.quantity - 1);
      updatedItems = List<CartItemModel>.from(state.items)..[index] = updated;
    } else {
      updatedItems = List<CartItemModel>.from(state.items)..removeAt(index);
    }

    state = state.copyWith(items: updatedItems);
    _persistCart();
  }

  /// Remove item completely from cart
  void removeItem(String cartItemId) {
    final updatedItems = state.items.where((item) => item.id != cartItemId).toList();
    state = state.copyWith(items: updatedItems);
    _persistCart();
  }

  /// Clear all items in cart (called only after order confirmation)
  void clearCart() {
    state = state.copyWith(items: []);
    _persistCart();
  }
}
