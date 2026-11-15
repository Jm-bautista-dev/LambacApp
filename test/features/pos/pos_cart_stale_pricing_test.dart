import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/pos/data/models/pos_cart_item_model.dart';
import 'package:lambac_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/products/data/models/product_variant_model.dart';

void main() {
  group('POS Cart & Stale Pricing Validation Tests', () {
    late PosCartNotifier cartNotifier;

    final sampleCoffee = ProductModel(
      id: 'benguet-typica',
      name: 'Benguet Arabica Typica Heirloom',
      slug: 'benguet-typica',
      origin: 'Atok, Benguet',
      description: 'Single-origin heirloom coffee.',
      basePrice: 420.0,
      categoryId: 'coffee',
      categoryName: 'Coffee',
      roastLevel: 'Medium Roast',
      tastingNotes: 'Citrus, Brown Sugar',
      stockQuantity: 20,
      isEnabled: true,
      sizeVariants: const [
        ProductVariantModel(id: 'size_250g', name: '250g Bag', priceDelta: 0.0),
        ProductVariantModel(id: 'size_500g', name: '500g Bag', priceDelta: 380.0),
      ],
    );

    setUp(() {
      cartNotifier = PosCartNotifier();
    });

    test('Adding product to cart freezes captured unit price', () {
      cartNotifier.addItem(
        product: sampleCoffee,
        sizeVariant: sampleCoffee.sizeVariants.first,
        quantity: 2,
      );

      final state = cartNotifier.state;
      expect(state.itemCount, 2);
      expect(state.items.length, 1);
      final item = state.items.first;
      expect(item.capturedUnitPrice, 420.0);
      expect(item.lineTotal, 840.0);
      expect(item.isPriceStale, isFalse);
      expect(item.isUnavailable, isFalse);
    });

    test('Detects stale price when Admin updates product price in live catalog', () {
      cartNotifier.addItem(
        product: sampleCoffee,
        quantity: 1,
      );

      expect(cartNotifier.state.hasStalePrices, isFalse);

      // Admin reprices coffee from ₱420 to ₱460 in Firestore
      final repricedProduct = sampleCoffee.copyWith(basePrice: 460.0);
      cartNotifier.reconcileWithLiveProducts([repricedProduct]);

      final updatedState = cartNotifier.state;
      expect(updatedState.hasStalePrices, isTrue);
      expect(updatedState.staleItemsCount, 1);

      final cartItem = updatedState.items.first;
      expect(cartItem.isPriceStale, isTrue);
      expect(cartItem.capturedUnitPrice, 420.0); // original
      expect(cartItem.currentLiveUnitPrice, 460.0); // live authoritative price
      expect(updatedState.priceDifferenceTotal, 40.0); // +₱40 difference
    });

    test('Staff accepting live price updates captured unit price and clears warning', () {
      cartNotifier.addItem(product: sampleCoffee, quantity: 2);

      final repricedProduct = sampleCoffee.copyWith(basePrice: 450.0);
      cartNotifier.reconcileWithLiveProducts([repricedProduct]);

      expect(cartNotifier.state.hasStalePrices, isTrue);

      // Staff taps "Accept Updated Prices"
      cartNotifier.acceptAllLivePrices();

      final resolvedState = cartNotifier.state;
      expect(resolvedState.hasStalePrices, isFalse);
      expect(resolvedState.items.first.capturedUnitPrice, 450.0);
      expect(resolvedState.total, 900.0);
    });

    test('Disabling product while in cart flags item as unavailable', () {
      cartNotifier.addItem(product: sampleCoffee, quantity: 1);

      // Admin disables product or marks sold out
      final soldOutProduct = sampleCoffee.copyWith(
        isEnabled: false,
        availability: ProductAvailability.outOfStock,
      );
      cartNotifier.reconcileWithLiveProducts([soldOutProduct]);

      final state = cartNotifier.state;
      expect(state.hasUnavailableItems, isTrue);
      expect(state.unavailableItemsCount, 1);
      expect(state.items.first.isUnavailable, isTrue);

      // Removing unavailable items clears warning
      cartNotifier.removeUnavailableItems();
      expect(cartNotifier.state.isEmpty, isTrue);
    });

    test('Variant price additions are accurately computed', () {
      // 500g Bag (+₱380 delta)
      cartNotifier.addItem(
        product: sampleCoffee,
        sizeVariant: sampleCoffee.sizeVariants[1],
        quantity: 1,
      );

      final item = cartNotifier.state.items.first;
      expect(item.capturedUnitPrice, 420.0 + 380.0); // ₱800.00
      expect(item.lineTotal, 800.0);
    });

    test('Discount application safely calculates grand total', () {
      cartNotifier.addItem(product: sampleCoffee, quantity: 2); // ₱840.00 subtotal

      // Apply 20% senior discount (₱168.00)
      cartNotifier.applyDiscount(840.0 * 0.20, 'Senior/PWD (20%)');

      expect(cartNotifier.state.subtotal, 840.0);
      expect(cartNotifier.state.discountAmount, 168.0);
      expect(cartNotifier.state.total, 672.0);

      // Clear discount
      cartNotifier.clearDiscount();
      expect(cartNotifier.state.total, 840.0);
    });
  });
}
