import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/products/data/models/product_variant_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('CartNotifier & User-Scoped Persistence Unit Tests', () {
    late InMemoryStorageService storageService;

    const testProductA = ProductModel(
      id: 'test-apo',
      name: 'Mount Apo Anaerobic Honey Reserve',
      slug: 'test-apo',
      origin: 'Davao del Sur',
      description: 'Handcrafted roast',
      basePrice: 480.0,
      categoryId: 'single-origin',
      categoryName: 'Single Origin',
      roastLevel: 'Light Roast',
      tastingNotes: 'Wild raspberry',
      availability: ProductAvailability.available,
      stockQuantity: 20,
    );

    const testProductB = ProductModel(
      id: 'test-matutum',
      name: 'Mount Matutum Washed Typica',
      slug: 'test-matutum',
      origin: 'South Cotabato',
      description: 'Bright citrus finish',
      basePrice: 420.0,
      categoryId: 'single-origin',
      categoryName: 'Single Origin',
      roastLevel: 'Medium-Light Roast',
      tastingNotes: 'Bergamot & Jasmine',
      availability: ProductAvailability.available,
      stockQuantity: 15,
    );

    const size500g = ProductVariantModel(
      id: 'size-500g',
      name: '500g Bag',
      priceDelta: 420.0,
    );

    const grindV60 = ProductVariantModel(
      id: 'grind-v60',
      name: 'V60 Pourover',
    );

    const grindEspresso = ProductVariantModel(
      id: 'grind-espresso',
      name: 'Espresso',
    );

    setUp(() {
      storageService = InMemoryStorageService();
    });

    test('1. Initial cart is empty and has 0 subtotal', () {
      final cartNotifier = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      expect(cartNotifier.state.isEmpty, isTrue);
      expect(cartNotifier.state.itemCount, equals(0));
      expect(cartNotifier.state.subtotal, equals(0.0));
    });

    test('2. addItem adds item with correct unit price and subtotal calculation', () {
      final cartNotifier = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      cartNotifier.addItem(
        product: testProductA,
        sizeVariant: size500g, // 480 + 420 = 900
        grindVariant: grindV60,
        quantity: 2,
      );

      expect(cartNotifier.state.items.length, equals(1));
      expect(cartNotifier.state.itemCount, equals(2));
      expect(cartNotifier.state.subtotal, equals(1800.0));
    });

    test('3. Duplicate product with identical variants merges quantity rather than creating duplicate row', () {
      final cartNotifier = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      cartNotifier.addItem(
        product: testProductA,
        sizeVariant: size500g,
        grindVariant: grindV60,
        quantity: 1,
      );
      cartNotifier.addItem(
        product: testProductA,
        sizeVariant: size500g,
        grindVariant: grindV60,
        quantity: 2,
      );

      expect(cartNotifier.state.items.length, equals(1));
      expect(cartNotifier.state.itemCount, equals(3));
      expect(cartNotifier.state.subtotal, equals(2700.0));
    });

    test('4. Different grind variants for same product create distinct cart items', () {
      final cartNotifier = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      cartNotifier.addItem(
        product: testProductA,
        sizeVariant: size500g,
        grindVariant: grindV60,
        quantity: 1,
      );

      cartNotifier.addItem(
        product: testProductA,
        sizeVariant: size500g,
        grindVariant: grindEspresso,
        quantity: 1,
      );

      expect(cartNotifier.state.items.length, equals(2));
      expect(cartNotifier.state.itemCount, equals(2));
    });

    test('5. Multiple distinct products accumulate in cart', () {
      final cartNotifier = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      cartNotifier.addItem(product: testProductA, quantity: 1);
      cartNotifier.addItem(product: testProductB, quantity: 2);

      expect(cartNotifier.state.items.length, equals(2));
      expect(cartNotifier.state.itemCount, equals(3));
      expect(cartNotifier.state.subtotal, equals(480.0 + (420.0 * 2)));
    });

    test('6. incrementQuantity, decrementQuantity, and removeItem work properly', () {
      final cartNotifier = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      cartNotifier.addItem(product: testProductA, quantity: 1);
      final itemId = cartNotifier.state.items.first.id;

      cartNotifier.incrementQuantity(itemId);
      expect(cartNotifier.state.itemCount, equals(2));
      expect(cartNotifier.state.subtotal, equals(960.0));

      cartNotifier.decrementQuantity(itemId);
      expect(cartNotifier.state.itemCount, equals(1));
      expect(cartNotifier.state.subtotal, equals(480.0));

      // Decrementing at quantity 1 removes the item
      cartNotifier.decrementQuantity(itemId);
      expect(cartNotifier.state.isEmpty, isTrue);
    });

    test('7. Local storage persistence restores user cart upon app restart', () async {
      // 1. Customer 1 adds item
      final cart1 = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      cart1.addItem(product: testProductA, quantity: 3);

      // 2. Simulate app restart for Customer 1
      final cart1Restored = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      // Allow async restore to complete
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cart1Restored.state.items.length, equals(1));
      expect(cart1Restored.state.itemCount, equals(3));
      expect(cart1Restored.state.subtotal, equals(1440.0));
    });

    test('8. Strict Customer Isolation: Customer 2 never sees Customer 1 cart', () async {
      // 1. Customer 1 adds Product A
      final cartCustomer1 = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      cartCustomer1.addItem(product: testProductA, quantity: 2);

      // 2. Customer 2 logs in
      final cartCustomer2 = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_2',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Customer 2 MUST have an empty cart!
      expect(cartCustomer2.state.isEmpty, isTrue);
      expect(cartCustomer2.state.itemCount, equals(0));

      // 3. Customer 2 adds Product B
      cartCustomer2.addItem(product: testProductB, quantity: 5);
      expect(cartCustomer2.state.itemCount, equals(5));

      // 4. Switch back to Customer 1
      final cartCustomer1Switched = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Customer 1 still has their 2 items of Product A, 0 of Product B
      expect(cartCustomer1Switched.state.items.length, equals(1));
      expect(cartCustomer1Switched.state.items.first.productId, equals('test-apo'));
      expect(cartCustomer1Switched.state.itemCount, equals(2));
    });

    test('9. clearCart empties all items', () {
      final cartNotifier = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_1',
      );
      cartNotifier.addItem(product: testProductA, quantity: 3);
      expect(cartNotifier.state.isNotEmpty, isTrue);

      cartNotifier.clearCart();
      expect(cartNotifier.state.isEmpty, isTrue);
      expect(cartNotifier.state.subtotal, equals(0.0));
    });
  });
}
