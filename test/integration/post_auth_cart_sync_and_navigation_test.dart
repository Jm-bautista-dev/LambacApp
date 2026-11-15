import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
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
  group('Post-Authentication Cart Synchronization, Navigation & State Integrity Tests', () {
    late InMemoryStorageService storageService;

    const microLotProduct = ProductModel(
      id: 'lot-apo-honey-reserve',
      name: 'Mount Apo Anaerobic Honey Reserve',
      slug: 'apo-honey-reserve',
      origin: 'Bansalan, Davao del Sur',
      description: 'Single-producer anaerobic natural micro-lot.',
      basePrice: 580.0,
      categoryId: 'micro-lot',
      categoryName: 'Micro-Lot',
      roastLevel: 'Light-Medium Roast',
      tastingNotes: 'Wild Blackberry, Bergamot, Raw Honey',
      availability: ProductAvailability.available,
      stockQuantity: 18,
    );

    const size1000g = ProductVariantModel(
      id: 'size-1kg',
      name: '1kg Whole Bean Bag',
      priceDelta: 980.0,
    );

    const grindEspresso = ProductVariantModel(
      id: 'grind-fine-espresso',
      name: 'Fine Grind (Espresso Machine)',
    );

    setUp(() {
      storageService = InMemoryStorageService();
    });

    test('1. Guest Browse: Unauthenticated guest can browse menu and view products', () {
      final guestUser = UserModel.guest();
      expect(guestUser.isGuest, isTrue);
      expect(guestUser.fullName, equals('Guest Coffee Enthusiast'));

      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
      );
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).continueAsGuest();
      final authState = container.read(authNotifierProvider);

      expect(authState.isAuthenticated, isTrue);
      expect(authState.isGuest, isTrue);
      expect(authState.isCustomerAuthenticated, isFalse);
    });

    test('2. Guest Add to Cart: Action is captured in pending state with all variants and instructions', () {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
      );
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).continueAsGuest();

      final pendingAction = PendingAddToCartAction(
        product: microLotProduct,
        sizeVariant: size1000g,
        grindVariant: grindEspresso,
        quantity: 2,
        specialInstructions: 'Please grind on Mahlkönig EK43 for portafilter basket',
      );

      container.read(pendingActionProvider.notifier).setPendingAction(pendingAction);

      final storedAction = container.read(pendingActionProvider);
      expect(storedAction, isNotNull);
      expect(storedAction!.product.name, equals('Mount Apo Anaerobic Honey Reserve'));
      expect(storedAction.sizeVariant?.name, equals('1kg Whole Bean Bag'));
      expect(storedAction.grindVariant?.name, equals('Fine Grind (Espresso Machine)'));
      expect(storedAction.quantity, equals(2));
      expect(storedAction.specialInstructions, equals('Please grind on Mahlkönig EK43 for portafilter basket'));
    });

    test('3. Login Success: Restores pending action and synchronizes user cart', () async {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
      );
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).continueAsGuest();

      // Guest adds custom lot
      final pendingAction = PendingAddToCartAction(
        product: microLotProduct,
        sizeVariant: size1000g,
        grindVariant: grindEspresso,
        quantity: 2,
        specialInstructions: 'Degas for 7 days before vacuum seal',
      );
      container.read(pendingActionProvider.notifier).setPendingAction(pendingAction);

      // Customer logs in
      final loginResult = await container.read(authNotifierProvider.notifier).login(
            email: 'coffee.lover@lambac.com',
            password: 'password123',
          );
      expect(loginResult.isSuccess, isTrue);
      expect(container.read(isCustomerAuthenticatedProvider), isTrue);

      // Atomic single-consumption
      final consumed = container.read(pendingActionProvider.notifier).consumePendingAction();
      expect(consumed, isNotNull);

      // Add to user cart
      container.read(cartNotifierProvider.notifier).addItem(
            product: consumed!.product,
            sizeVariant: consumed.sizeVariant,
            grindVariant: consumed.grindVariant,
            quantity: consumed.quantity,
            specialInstructions: consumed.specialInstructions,
          );

      final cartState = container.read(cartNotifierProvider);
      expect(cartState.items.length, equals(1));
      final cartItem = cartState.items.first;
      expect(cartItem.productName, equals('Mount Apo Anaerobic Honey Reserve'));
      expect(cartItem.quantity, equals(2));
      // Base: 580 + Size Delta: 980 = 1560
      expect(cartItem.unitPrice, equals(1560.0));
      expect(cartItem.totalPrice, equals(3120.0));
      expect(cartItem.specialInstructions, equals('Degas for 7 days before vacuum seal'));
      expect(cartState.subtotal, equals(3120.0));
    });

    test('4. Register Success: Authenticates newly created customer and synchronizes cart', () async {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
      );
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).continueAsGuest();

      final pendingAction = PendingAddToCartAction(
        product: microLotProduct,
        sizeVariant: size1000g,
        quantity: 1,
      );
      container.read(pendingActionProvider.notifier).setPendingAction(pendingAction);

      // Register new user via OTP flow
      const email = 'mateo.deleon@example.com';
      await container.read(authNotifierProvider.notifier).requestRegisterOtp(
            fullName: 'Mateo De Leon',
            email: email,
            password: 'SecurePassword2026!',
            phoneNumber: '09178889999',
          );

      final remoteDs = container.read(authRemoteDataSourceProvider) as MockAuthRemoteDataSource;
      final otp = remoteDs.getPendingOtpForTesting(email)!;
      final verifyRes = await container.read(authNotifierProvider.notifier).verifyRegisterOtp(
            email: email,
            otp: otp,
          );
      expect(verifyRes.isSuccess, isTrue);

      final regResult = await container.read(authNotifierProvider.notifier).register(
            fullName: 'Mateo De Leon',
            email: email,
            password: 'SecurePassword2026!',
            phoneNumber: '09178889999',
            verificationToken: verifyRes.dataOrNull!.verificationToken,
          );
      expect(regResult.isSuccess, isTrue);
      expect(container.read(isCustomerAuthenticatedProvider), isTrue);

      final consumed = container.read(pendingActionProvider.notifier).consumePendingAction();
      expect(consumed, isNotNull);

      container.read(cartNotifierProvider.notifier).addItem(
            product: consumed!.product,
            sizeVariant: consumed.sizeVariant,
            quantity: consumed.quantity,
          );

      expect(container.read(cartNotifierProvider).itemCount, equals(1));
      expect(container.read(cartNotifierProvider).items.first.productName, equals('Mount Apo Anaerobic Honey Reserve'));
    });

    test('5. Duplicate Submission Protection: Pending action is consumed strictly once (idempotent)', () {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
      );
      addTearDown(container.dispose);

      final pendingAction = PendingAddToCartAction(
        product: microLotProduct,
        quantity: 3,
      );
      container.read(pendingActionProvider.notifier).setPendingAction(pendingAction);

      // First consumption succeeds
      final firstConsumption = container.read(pendingActionProvider.notifier).consumePendingAction();
      expect(firstConsumption, isNotNull);
      expect(firstConsumption!.quantity, equals(3));

      // Second consumption returns null (prevents duplicate adding)
      final secondConsumption = container.read(pendingActionProvider.notifier).consumePendingAction();
      expect(secondConsumption, isNull);

      // Third consumption returns null
      final thirdConsumption = container.read(pendingActionProvider.notifier).consumePendingAction();
      expect(thirdConsumption, isNull);
    });

    test('6. Wrong Credentials: Login fails, user remains unauthenticated, pending action is retained', () async {
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
      );
      addTearDown(container.dispose);

      final pendingAction = PendingAddToCartAction(
        product: microLotProduct,
        quantity: 1,
      );
      container.read(pendingActionProvider.notifier).setPendingAction(pendingAction);

      // Attempt login with invalid password
      final failResult = await container.read(authNotifierProvider.notifier).login(
            email: 'coffee.lover@lambac.com',
            password: 'wrong_password',
          );

      expect(failResult.isFailure, isTrue);
      expect(failResult.failureOrNull, isA<UnauthorizedFailure>());
      expect(container.read(isCustomerAuthenticatedProvider), isFalse);

      // Pending action is preserved for subsequent retry
      expect(container.read(pendingActionProvider), equals(pendingAction));
    });

    test('7. Logout & Cart State Isolation: Logging out safely detaches authenticated user cart', () async {
      // 1. Account A logs in and adds items
      final cartNotifierA = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_A',
      );
      cartNotifierA.addItem(product: microLotProduct, quantity: 4);
      expect(cartNotifierA.state.itemCount, equals(4));

      // 2. User logs out: Guest cart is loaded and is empty
      final guestCart = CartNotifier(
        storageService: storageService,
        userId: null,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(guestCart.state.isEmpty, isTrue);
      expect(guestCart.state.itemCount, equals(0));

      // 3. Re-logging as Account A restores 4 items
      final reloadedCartA = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_A',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reloadedCartA.state.itemCount, equals(4));
    });

    test('8. Account Switching Isolation: Account B cannot access Account A cart data', () async {
      // Account A creates cart with 3 items
      final cartA = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_A',
      );
      cartA.addItem(product: microLotProduct, quantity: 3);

      // Account B logs in
      final cartB = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_B',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Account B must be completely isolated
      expect(cartB.state.isEmpty, isTrue);
      expect(cartB.state.itemCount, equals(0));

      // Account B adds 1 item
      cartB.addItem(product: microLotProduct, quantity: 1);
      expect(cartB.state.itemCount, equals(1));

      // Account A remains untouched at 3 items
      final verifiedCartA = CartNotifier(
        storageService: storageService,
        userId: 'usr_customer_A',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(verifiedCartA.state.itemCount, equals(3));
    });

    test('9. App Restart & Session Restoration: Cart restores persisted items from storage key', () async {
      // Session 1: User adds items
      final session1Cart = CartNotifier(
        storageService: storageService,
        userId: 'usr_persistent_customer',
      );
      session1Cart.addItem(
        product: microLotProduct,
        sizeVariant: size1000g,
        quantity: 2,
      );
      expect(session1Cart.state.itemCount, equals(2));

      // Session 2: App restarts (new CartNotifier initialized with same userId)
      final session2Cart = CartNotifier(
        storageService: storageService,
        userId: 'usr_persistent_customer',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(session2Cart.state.items.length, equals(1));
      expect(session2Cart.state.items.first.productName, equals('Mount Apo Anaerobic Honey Reserve'));
      expect(session2Cart.state.items.first.quantity, equals(2));
      expect(session2Cart.state.items.first.sizeVariant?.name, equals('1kg Whole Bean Bag'));
    });
  });
}
