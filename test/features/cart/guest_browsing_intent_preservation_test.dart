import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/cart/domain/models/pending_add_to_cart_action.dart';
import 'package:lambac_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:lambac_app/features/cart/presentation/providers/pending_action_provider.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/products/data/models/product_variant_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Guest Browsing & Intent Preservation Acceptance Tests', () {
    late InMemoryStorageService storageService;

    const sampleProduct = ProductModel(
      id: 'prod-sagada-typica',
      name: 'Sagada Peaberry Micro-Lot',
      slug: 'sagada-peaberry',
      origin: 'Mountain Province',
      description: 'Floral aroma with sweet citrus aftertaste.',
      basePrice: 520.0,
      categoryId: 'single-origin',
      categoryName: 'Single Origin',
      roastLevel: 'Medium Roast',
      tastingNotes: 'Sweet Orange, Cocoa, Wild Honey',
      availability: ProductAvailability.available,
      stockQuantity: 25,
    );

    const size500g = ProductVariantModel(
      id: 'size-500g',
      name: '500g Bag',
      priceDelta: 450.0,
    );

    const grindFrenchPress = ProductVariantModel(
      id: 'grind-french-press',
      name: 'Coarse (French Press / Cold Brew)',
    );

    setUp(() {
      storageService = InMemoryStorageService();
    });

    test('Test A: Guest state is correctly identified as guest and not customer authenticated', () {
      final guest = UserModel.guest();
      expect(guest.isGuest, isTrue);
      expect(guest.isCustomer, isTrue);
      expect(guest.fullName, equals('Guest Coffee Enthusiast'));

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
      );
      addTearDown(container.dispose);

      // Set guest mode
      container.read(authNotifierProvider.notifier).continueAsGuest();
      final authState = container.read(authNotifierProvider);

      expect(authState.isAuthenticated, isTrue);
      expect(authState.isGuest, isTrue);
      expect(authState.isCustomerAuthenticated, isFalse);
      expect(container.read(isCustomerAuthenticatedProvider), isFalse);
    });

    test('Test B: Guest Add to Cart preserves intent and auto-adds item on Login', () async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
      );
      addTearDown(container.dispose);

      // 1. App starts as Guest
      container.read(authNotifierProvider.notifier).continueAsGuest();

      // 2. Guest attempts Add to Cart: Pending action is captured
      final pendingAction = PendingAddToCartAction(
        product: sampleProduct,
        sizeVariant: size500g,
        grindVariant: grindFrenchPress,
        quantity: 3,
        specialInstructions: 'Pack in airtight valve pouch please',
      );
      container.read(pendingActionProvider.notifier).setPendingAction(pendingAction);

      // Verify pending action is stored
      expect(container.read(pendingActionProvider), equals(pendingAction));

      // 3. User logs in successfully
      final loginResult = await container.read(authNotifierProvider.notifier).login(
            email: 'coffee.lover@lambac.com',
            password: 'password123',
          );

      expect(loginResult.isSuccess, isTrue);
      final loggedInUser = loginResult.dataOrNull!;
      expect(loggedInUser.isGuest, isFalse);
      expect(container.read(isCustomerAuthenticatedProvider), isTrue);

      // 4. Intent is consumed atomically and added to cart
      final consumed = container.read(pendingActionProvider.notifier).consumePendingAction();
      expect(consumed, isNotNull);
      expect(consumed!.product.id, equals('prod-sagada-typica'));
      expect(consumed.quantity, equals(3));
      expect(consumed.sizeVariant?.id, equals('size-500g'));
      expect(consumed.grindVariant?.id, equals('grind-french-press'));
      expect(consumed.specialInstructions, equals('Pack in airtight valve pouch please'));

      // Add to user cart
      container.read(cartNotifierProvider.notifier).addItem(
            product: consumed.product,
            sizeVariant: consumed.sizeVariant,
            grindVariant: consumed.grindVariant,
            quantity: consumed.quantity,
            specialInstructions: consumed.specialInstructions,
          );

      // 5. Verify cart contains exact item with preserved configuration
      final cartState = container.read(cartNotifierProvider);
      expect(cartState.items.length, equals(1));
      final cartItem = cartState.items.first;
      expect(cartItem.productId, equals('prod-sagada-typica'));
      expect(cartItem.productName, equals('Sagada Peaberry Micro-Lot'));
      expect(cartItem.quantity, equals(3));
      expect(cartItem.sizeVariant?.name, equals('500g Bag'));
      expect(cartItem.grindVariant?.name, equals('Coarse (French Press / Cold Brew)'));
      // Unit price: 520 (base) + 450 (size500g) = 970
      expect(cartItem.unitPrice, equals(970.0));
      expect(cartItem.totalPrice, equals(2910.0));
      expect(cartState.subtotal, equals(2910.0));

      // 6. Verify pending action was cleared (idempotency)
      expect(container.read(pendingActionProvider), isNull);
      expect(container.read(pendingActionProvider.notifier).consumePendingAction(), isNull);
    });

    test('Test C: Guest Add to Cart preserves intent and auto-adds item on Registration', () async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
      );
      addTearDown(container.dispose);

      // 1. App starts as Guest
      container.read(authNotifierProvider.notifier).continueAsGuest();

      // 2. Guest configures and attempts to add product
      final pendingAction = PendingAddToCartAction(
        product: sampleProduct,
        sizeVariant: size500g,
        grindVariant: grindFrenchPress,
        quantity: 2,
      );
      container.read(pendingActionProvider.notifier).setPendingAction(pendingAction);

      // 3. User registers a brand new account with OTP verification
      const regEmail = 'elena.rostova@example.com';
      await container.read(authNotifierProvider.notifier).requestRegisterOtp(
            fullName: 'Elena Rostova',
            email: regEmail,
            password: 'StrongPassword123!',
            phoneNumber: '+639171234567',
          );
      final otp = MockAuthRemoteDataSource().getPendingOtpForTesting(regEmail)!;
      final verifyRes = await container.read(authNotifierProvider.notifier).verifyRegisterOtp(
            email: regEmail,
            otp: otp,
          );
      expect(verifyRes.isSuccess, isTrue);

      final registerResult = await container.read(authNotifierProvider.notifier).register(
            fullName: 'Elena Rostova',
            email: regEmail,
            password: 'StrongPassword123!',
            phoneNumber: '+639171234567',
            verificationToken: verifyRes.dataOrNull!.verificationToken,
          );

      expect(registerResult.isSuccess, isTrue);
      final newUser = registerResult.dataOrNull!;
      expect(newUser.fullName, equals('Elena Rostova'));
      expect(newUser.isGuest, isFalse);
      expect(container.read(isCustomerAuthenticatedProvider), isTrue);

      // 4. Intent is consumed and added to new user's cart
      final consumed = container.read(pendingActionProvider.notifier).consumePendingAction();
      expect(consumed, isNotNull);

      container.read(cartNotifierProvider.notifier).addItem(
            product: consumed!.product,
            sizeVariant: consumed.sizeVariant,
            grindVariant: consumed.grindVariant,
            quantity: consumed.quantity,
          );

      // 5. Verify cart has item
      final cartState = container.read(cartNotifierProvider);
      expect(cartState.itemCount, equals(2));
      expect(cartState.items.first.productName, equals('Sagada Peaberry Micro-Lot'));
    });

    test('Test D: Account Cart Isolation (Account A vs Account B)', () async {
      // 1. Create cart for Account A
      final cartNotifierUserA = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_A',
      );

      cartNotifierUserA.addItem(
        product: sampleProduct,
        sizeVariant: size500g,
        quantity: 5,
      );
      expect(cartNotifierUserA.state.itemCount, equals(5));

      // 2. Instantiate Cart for Account B
      final cartNotifierUserB = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_B',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Account B must start with empty cart (no leakage from Account A)
      expect(cartNotifierUserB.state.isEmpty, isTrue);
      expect(cartNotifierUserB.state.itemCount, equals(0));

      // Account B adds 1 item
      cartNotifierUserB.addItem(
        product: sampleProduct,
        quantity: 1,
      );
      expect(cartNotifierUserB.state.itemCount, equals(1));

      // Re-read Account A from storage
      final reloadedCartA = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_A',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reloadedCartA.state.itemCount, equals(5));
    });

    test('Test E: Pending action model equality and props', () {
      final time = DateTime(2026, 10, 2, 12, 0);
      final action1 = PendingAddToCartAction(
        product: sampleProduct,
        sizeVariant: size500g,
        grindVariant: grindFrenchPress,
        quantity: 2,
        specialInstructions: 'Note A',
        timestamp: time,
      );

      final action2 = PendingAddToCartAction(
        product: sampleProduct,
        sizeVariant: size500g,
        grindVariant: grindFrenchPress,
        quantity: 2,
        specialInstructions: 'Note A',
        timestamp: time,
      );

      expect(action1, equals(action2));
      expect(action1.props.length, equals(6));
    });
  });
}
