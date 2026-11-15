import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/features/auth/data/models/request_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/models/verify_register_otp_request.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:lambac_app/features/cart/presentation/screens/checkout_screen.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/features/orders/domain/services/paymongo_service.dart';
import 'package:lambac_app/features/orders/domain/services/pickup_scheduling_service.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_database.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryStorageService storageService;
  late MockOrderRemoteDataSource orderDataSource;
  late OrderRepositoryImpl orderRepository;
  late MockSalesRemoteDataSource salesDataSource;
  late MockProductDatabase productDb;
  late MockUserDatabase userDb;
  late MockAuthRemoteDataSource authDataSource;
  late PaymongoService paymongoService;
  late ScheduledPickup validSchedule;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = InMemoryStorageService();
    orderDataSource = MockOrderRemoteDataSource();
    orderDataSource.resetForTesting();
    orderDataSource.simulateSaleFailureForTesting = false;
    orderRepository = OrderRepositoryImpl(
      remoteDataSource: orderDataSource,
      storageService: storageService,
    );

    salesDataSource = MockSalesRemoteDataSource();
    salesDataSource.resetForTesting();

    productDb = MockProductDatabase();
    productDb.resetForTesting();

    userDb = MockUserDatabase();
    userDb.resetForTests();

    authDataSource = MockAuthRemoteDataSource();
    paymongoService = PaymongoService();
    validSchedule = PickupSchedulingService().getEarliestAvailableSchedule();
  });

  tearDown(() {
    orderDataSource.resetForTesting();
    salesDataSource.resetForTesting();
    productDb.resetForTesting();
    userDb.resetForTests();
  });

  UserModel createNewCustomerSynchronously({
    String id = 'usr_cust_new_2026',
    String email = 'new.customer@lambac.com',
    String fullName = 'Sofia Reyes',
    String phone = '09178889900',
  }) {
    final user = UserModel(
      id: id,
      email: email,
      fullName: fullName,
      phoneNumber: phone,
      role: UserRole.customer,
      isRegistrationVerified: true,
      firstOrderGcashCompleted: false,
    );
    userDb.records[email.toLowerCase()] = UserDatabaseRecord(
      user: user,
      passwordHash: 'Password123!',
    );
    userDb.setCurrentUser(user);
    orderDataSource.enforceFirstOrderRequirementForCustomer(user.id);
    return user;
  }

  Future<UserModel> registerAndLoginNewCustomer({
    String email = 'new.customer@lambac.com',
    String fullName = 'Sofia Reyes',
    String phone = '09178889900',
  }) async {
    authDataSource.resetCooldownForTesting(email);
    final otpReqRes = await authDataSource.requestRegisterOtp(
      RequestRegisterOtpRequest(
        fullName: fullName,
        email: email,
        phoneNumber: phone,
        password: 'Password123!',
      ),
    );
    expect(otpReqRes.isSuccess, isTrue);

    final rawOtp = authDataSource.getPendingOtpForTesting(email)!;
    final verifyRes = await authDataSource.verifyRegisterOtp(
      VerifyRegisterOtpRequest(email: email, otp: rawOtp),
    );
    expect(verifyRes.isSuccess, isTrue);

    final regRes = await authDataSource.register(
      RegisterRequest(
        fullName: fullName,
        email: email,
        phoneNumber: phone,
        password: 'Password123!',
        verificationToken: verifyRes.dataOrNull!.verificationToken,
      ),
    );
    expect(regRes.isSuccess, isTrue);
    final user = regRes.dataOrNull!.user;
    orderDataSource.enforceFirstOrderRequirementForCustomer(user.id);
    return user;
  }

  CreateOrderRequest buildOrderRequest({
    required ProductModel product,
    required String paymentMethod,
    int quantity = 1,
    String? idempotencyKey,
  }) {
    final cartItem = CartItemModel(
      id: '${product.id}_size-250g_grind-whole',
      productId: product.id,
      productName: product.name,
      origin: product.origin,
      roastLevel: product.roastLevel,
      unitPrice: product.basePrice,
      quantity: quantity,
    );

    return CreateOrderRequest(
      customerName: 'Sofia Reyes',
      customerPhone: '09178889900',
      items: [cartItem],
      pickupLocation: PickupLocationModel.flagship,
      pickupDate: validSchedule.dateDisplay,
      pickupTimeSlot: validSchedule.timeSlot,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'GCash' ? 'PENDING' : 'UNPAID',
      idempotencyKey: idempotencyKey,
    );
  }

  group('Task 2 — Mandatory GCash Payment for Customer First Order', () {
    // -------------------------------------------------------------------------
    // 1. Newly registered customer must use GCash (Backend + Checkout UI)
    // -------------------------------------------------------------------------
    testWidgets(
      '1. Newly registered customer must use GCash and Checkout UI enforces GCash while locking Pay at Counter',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final newUser = createNewCustomerSynchronously();
        expect(newUser.firstOrderGcashCompleted, isFalse);

        final eligibility = orderDataSource.getFirstOrderEligibilitySync(newUser.id);
        expect(eligibility.hasCompletedFirstOrder, isFalse);
        expect(eligibility.requiresFirstOrderGcash, isTrue);
        expect(eligibility.allowedPaymentMethods, equals(['GCash']));
        expect(eligibility.isPaymentMethodAllowed('GCash'), isTrue);
        expect(eligibility.isPaymentMethodAllowed('Pay at Counter'), isFalse);

        final product = productDb.getProductById('mt-apo-honey')!;
        final cartItem = CartItemModel(
          id: '${product.id}_250g',
          productId: product.id,
          productName: product.name,
          origin: product.origin,
          roastLevel: product.roastLevel,
          unitPrice: product.basePrice,
          quantity: 1,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(newUser),
              orderRepositoryProvider.overrideWithValue(orderRepository),
              cartNotifierProvider.overrideWith(
                (ref) => CartNotifier(storageService: storageService)
                  ..state = CartState(items: [cartItem]),
              ),
            ],
            child: const MaterialApp(
              home: CheckoutScreen(),
            ),
          ),
        );
        await tester.pump();

        // Required banner message is visible
        expect(find.byKey(const Key('first_order_gcash_required_banner')), findsOneWidget);
        expect(find.text('Your first order must be paid through GCash.'), findsOneWidget);
        expect(find.text('Required for 1st Order'), findsOneWidget);
        expect(find.text('Unavailable for 1st Order'), findsOneWidget);
        expect(find.text('Checkout will proceed to PayMongo GCash payment.'), findsOneWidget);
        expect(find.text('Pay with GCash'), findsOneWidget);

        // Attempting to tap Pay at Counter does NOT switch selection away from GCash
        final payAtCounterFinder = find.byKey(const Key('payment_option_pay_at_counter'));
        await tester.ensureVisible(payAtCounterFinder);
        await tester.tap(payAtCounterFinder, warnIfMissed: false);
        await tester.pump();

        expect(find.text('Pay with GCash'), findsOneWidget);
        expect(find.text('Confirm Pickup Order'), findsNothing);
      },
    );

    // -------------------------------------------------------------------------
    // 2. First-order Pay at Counter request is rejected by the backend
    // -------------------------------------------------------------------------
    test('2. First-order Pay at Counter request is strictly rejected by backend', () async {
      await registerAndLoginNewCustomer();
      final product = productDb.getProductById('mt-apo-honey')!;

      final counterRequest = buildOrderRequest(
        product: product,
        paymentMethod: 'Pay at Counter',
      );

      final result = await orderDataSource.createOrder(counterRequest);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull!.message,
        contains('Your first order must be paid through GCash'),
      );
    });

    // -------------------------------------------------------------------------
    // 3. First-order GCash checkout can be created
    // -------------------------------------------------------------------------
    test('3. First-order GCash checkout can be created with PENDING payment status', () async {
      final newUser = await registerAndLoginNewCustomer();
      final product = productDb.getProductById('mt-apo-honey')!;

      final gcashRequest = buildOrderRequest(
        product: product,
        paymentMethod: 'GCash',
      );

      final createRes = await orderDataSource.createOrder(gcashRequest);
      expect(createRes.isSuccess, isTrue);

      final createdOrder = createRes.dataOrNull!;
      expect(createdOrder.customerId, equals(newUser.id));
      expect(createdOrder.paymentMethod, equals('GCash'));
      expect(createdOrder.paymentStatus, equals('PENDING'));
      expect(createdOrder.isPaid, isFalse);

      // Initiate PayMongo Checkout Session
      final sessionRes = await paymongoService.createCheckoutSession(createdOrder.id);
      expect(sessionRes.isSuccess, isTrue);
      expect(sessionRes.dataOrNull!.checkoutSessionId, startsWith('cs_lmb_'));
      expect(sessionRes.dataOrNull!.checkoutUrl, startsWith('https://checkout.paymongo.com/'));
    });

    // -------------------------------------------------------------------------
    // 4. Pending GCash payment does not count as a completed first order
    // -------------------------------------------------------------------------
    test('4. Pending GCash payment does not count as a completed first order', () async {
      await registerAndLoginNewCustomer();
      final product = productDb.getProductById('mt-apo-honey')!;

      final firstReq = buildOrderRequest(product: product, paymentMethod: 'GCash');
      final firstRes = await orderDataSource.createOrder(firstReq);
      expect(firstRes.isSuccess, isTrue);
      expect(firstRes.dataOrNull!.paymentStatus, equals('PENDING'));

      // Check eligibility while first order is still PENDING
      final eligRes = await orderDataSource.checkFirstOrderEligibility();
      expect(eligRes.isSuccess, isTrue);
      expect(eligRes.dataOrNull!.hasCompletedFirstOrder, isFalse);
      expect(eligRes.dataOrNull!.requiresFirstOrderGcash, isTrue);
      expect(eligRes.dataOrNull!.activeFirstOrderId, equals(firstRes.dataOrNull!.id));

      // Attempting a Pay at Counter order while first GCash order is PENDING must be rejected
      final counterReq = buildOrderRequest(product: product, paymentMethod: 'Pay at Counter');
      final counterRes = await orderDataSource.createOrder(counterReq);
      expect(counterRes.isFailure, isTrue);
    });

    // -------------------------------------------------------------------------
    // 5. Failed GCash payment does not count and allows retry
    // -------------------------------------------------------------------------
    test('5. Failed GCash payment does not count as first order and allows retry with GCash', () async {
      await registerAndLoginNewCustomer();
      final product = productDb.getProductById('mt-apo-honey')!;

      final firstReq = buildOrderRequest(product: product, paymentMethod: 'GCash');
      final firstRes = await orderDataSource.createOrder(firstReq);
      expect(firstRes.isSuccess, isTrue);
      final order1 = firstRes.dataOrNull!;

      // Webhook reports payment.failed
      final webhookRes = await orderDataSource.processPaymongoWebhookEvent(
        orderId: order1.id,
        eventType: 'payment.failed',
        eventId: 'evt_failed_001',
        failureReason: 'Insufficient GCash balance.',
      );
      expect(webhookRes.isSuccess, isTrue);
      expect(webhookRes.dataOrNull!.paymentStatus, equals('FAILED'));

      // Eligibility: still requires first-order GCash, but active lock is released for retry
      final elig = orderDataSource.getFirstOrderEligibilitySync(null);
      expect(elig.hasCompletedFirstOrder, isFalse);
      expect(elig.requiresFirstOrderGcash, isTrue);
      expect(elig.activeFirstOrderId, isNull);

      // Pay at Counter is still blocked
      final counterAttempt = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'Pay at Counter'),
      );
      expect(counterAttempt.isFailure, isTrue);

      // Customer can retry creating a GCash order
      final retryGcash = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'GCash'),
      );
      expect(retryGcash.isSuccess, isTrue);
    });

    // -------------------------------------------------------------------------
    // 6. Expired GCash payment does not count and allows retry
    // -------------------------------------------------------------------------
    test('6. Expired GCash payment does not count as first order and allows retry with GCash', () async {
      await registerAndLoginNewCustomer();
      final product = productDb.getProductById('mt-apo-honey')!;

      final firstRes = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'GCash'),
      );
      expect(firstRes.isSuccess, isTrue);
      final order1 = firstRes.dataOrNull!;

      // Webhook reports checkout_session.expired
      final webhookRes = await orderDataSource.processPaymongoWebhookEvent(
        orderId: order1.id,
        eventType: 'checkout_session.expired',
        eventId: 'evt_expired_001',
      );
      expect(webhookRes.isSuccess, isTrue);
      expect(webhookRes.dataOrNull!.paymentStatus, equals('EXPIRED'));

      // Eligibility: still requires first-order GCash, active lock released
      final elig = orderDataSource.getFirstOrderEligibilitySync(null);
      expect(elig.hasCompletedFirstOrder, isFalse);
      expect(elig.requiresFirstOrderGcash, isTrue);
      expect(elig.activeFirstOrderId, isNull);

      // Pay at Counter is still blocked
      final counterAttempt = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'Pay at Counter'),
      );
      expect(counterAttempt.isFailure, isTrue);

      // Customer can retry with GCash
      final retryGcash = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'GCash'),
      );
      expect(retryGcash.isSuccess, isTrue);
    });

    // -------------------------------------------------------------------------
    // 7. Verified GCash payment completes the first-order requirement
    // -------------------------------------------------------------------------
    test('7. Verified PayMongo GCash payment completes the first-order requirement', () async {
      final newUser = await registerAndLoginNewCustomer();
      final product = productDb.getProductById('mt-apo-honey')!;

      final firstRes = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'GCash'),
      );
      expect(firstRes.isSuccess, isTrue);
      final order1 = firstRes.dataOrNull!;

      // PayMongo webhook verifies checkout_session.payment.paid
      final paidWebhook = await orderDataSource.processPaymongoWebhookEvent(
        orderId: order1.id,
        eventType: 'checkout_session.payment.paid',
        eventId: 'evt_paid_001',
        paymentId: 'pay_gcash_verified_777',
      );
      expect(paidWebhook.isSuccess, isTrue);
      expect(paidWebhook.dataOrNull!.paymentStatus, equals('PAID'));
      expect(paidWebhook.dataOrNull!.paymentProvider, equals('paymongo'));
      expect(paidWebhook.dataOrNull!.paymentReference, equals('pay_gcash_verified_777'));
      expect(paidWebhook.dataOrNull!.paidAt, isNotNull);

      final eligRes = await orderDataSource.checkFirstOrderEligibility();
      expect(eligRes.isSuccess, isTrue);
      final elig = eligRes.dataOrNull!;
      expect(elig.hasCompletedFirstOrder, isTrue);
      expect(elig.requiresFirstOrderGcash, isFalse);
      expect(elig.qualifyingOrderId, equals(order1.id));
      expect(elig.isPaymentMethodAllowed('Pay at Counter'), isTrue);
      expect(elig.isPaymentMethodAllowed('GCash'), isTrue);

      final updatedUser = userDb.getById(newUser.id)!.user;
      expect(updatedUser.firstOrderGcashCompleted, isTrue);
      expect(updatedUser.firstOrderCompletedOrderId, equals(order1.id));
    });

    // -------------------------------------------------------------------------
    // 8. Subsequent checkout recognizes the completed first-order requirement
    // -------------------------------------------------------------------------
    testWidgets(
      '8. Subsequent checkout after verified first GCash order allows Pay at Counter in both UI and backend',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final newUser = createNewCustomerSynchronously(
          id: 'usr_cust_subsequent_8',
          email: 'subsequent8@lambac.com',
        );
        final product = productDb.getProductById('mt-apo-honey')!;

        // Complete 1st order via verified PayMongo GCash inside tester.runAsync
        await tester.runAsync(() async {
          final order1Res = await orderDataSource.createOrder(
            buildOrderRequest(product: product, paymentMethod: 'GCash'),
          );
          expect(order1Res.isSuccess, isTrue);

          await orderDataSource.processPaymongoWebhookEvent(
            orderId: order1Res.dataOrNull!.id,
            eventType: 'checkout_session.payment.paid',
            eventId: 'evt_paid_subsequent',
            paymentId: 'pay_gcash_888',
          );

          // Backend now accepts Pay at Counter for the 2nd order
          final secondOrderRes = await orderDataSource.createOrder(
            buildOrderRequest(product: product, paymentMethod: 'Pay at Counter'),
          );
          expect(secondOrderRes.isSuccess, isTrue);
          expect(secondOrderRes.dataOrNull!.paymentMethod, equals('Pay at Counter'));
          expect(secondOrderRes.dataOrNull!.paymentStatus, equals('UNPAID'));
        });

        // Verify CheckoutScreen UI no longer shows the first-order restriction
        final refreshedUser = userDb.getById(newUser.id)!.user;
        final cartItem = CartItemModel(
          id: '${product.id}_250g',
          productId: product.id,
          productName: product.name,
          origin: product.origin,
          roastLevel: product.roastLevel,
          unitPrice: product.basePrice,
          quantity: 1,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWithValue(refreshedUser),
              orderRepositoryProvider.overrideWithValue(orderRepository),
              cartNotifierProvider.overrideWith(
                (ref) => CartNotifier(storageService: storageService)
                  ..state = CartState(items: [cartItem]),
              ),
            ],
            child: const MaterialApp(
              home: CheckoutScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('first_order_gcash_required_banner')), findsNothing);
        expect(find.text('Your first order must be paid through GCash.'), findsNothing);
        expect(find.text('Unavailable for 1st Order'), findsNothing);
        expect(find.text('Confirm Pickup Order'), findsOneWidget);
      },
    );

    // -------------------------------------------------------------------------
    // 9. Multiple simultaneous first-order requests cannot bypass the restriction
    // -------------------------------------------------------------------------
    test('9. Multiple simultaneous first-order requests cannot bypass the restriction', () async {
      await registerAndLoginNewCustomer();
      final product = productDb.getProductById('mt-apo-honey')!;

      final req1 = buildOrderRequest(
        product: product,
        paymentMethod: 'GCash',
        idempotencyKey: 'idemp_concurrent_1',
      );
      final req2 = buildOrderRequest(
        product: product,
        paymentMethod: 'GCash',
        idempotencyKey: 'idemp_concurrent_2',
      );
      final req3 = buildOrderRequest(
        product: product,
        paymentMethod: 'Pay at Counter',
        idempotencyKey: 'idemp_concurrent_3',
      );

      // Fire all 3 requests concurrently
      final results = await Future.wait([
        orderDataSource.createOrder(req1),
        orderDataSource.createOrder(req2),
        orderDataSource.createOrder(req3),
      ]);

      final successes = results.where((r) => r.isSuccess).toList();
      final failures = results.where((r) => r.isFailure).toList();

      // Strictly 1 GCash order succeeds; the second concurrent GCash order and Pay at Counter order are rejected
      expect(successes.length, equals(1));
      expect(failures.length, equals(2));
      expect(successes.first.dataOrNull!.paymentMethod, equals('GCash'));
      expect(successes.first.dataOrNull!.paymentStatus, equals('PENDING'));
    });

    // -------------------------------------------------------------------------
    // 10. Reinstalling the application does not reset the restriction
    // -------------------------------------------------------------------------
    test('10. Reinstalling the application (clearing all local storage) does not reset the restriction', () async {
      final newUser = await registerAndLoginNewCustomer();
      final product = productDb.getProductById('mt-apo-honey')!;

      // Simulate app reinstall: wipe all local SharedPreferences & session state
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      orderDataSource.clearSession();

      // Re-authenticate as the same customer
      userDb.setCurrentUser(newUser);

      // Eligibility is still enforced by backend
      final elig = await orderDataSource.checkFirstOrderEligibility();
      expect(elig.isSuccess, isTrue);
      expect(elig.dataOrNull!.requiresFirstOrderGcash, isTrue);

      final counterAttempt = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'Pay at Counter'),
      );
      expect(counterAttempt.isFailure, isTrue);
    });

    // -------------------------------------------------------------------------
    // 11. Logging in from another device does not reset the restriction
    // -------------------------------------------------------------------------
    test('11. Logging in from another device preserves backend first-order enforcement and completion state', () async {
      final newUser = await registerAndLoginNewCustomer();
      final product = productDb.getProductById('mt-apo-honey')!;

      // Device A: Customer logs in, has 0 paid orders -> Pay at Counter rejected
      final deviceAAttempt = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'Pay at Counter'),
      );
      expect(deviceAAttempt.isFailure, isTrue);

      // Customer logs out on Device A and logs in on Device B (fresh client state, even if client UserModel flag is tampered to true)
      final tamperedClientUser = newUser.copyWith(firstOrderGcashCompleted: true);
      userDb.setCurrentUser(tamperedClientUser);

      // Backend order datasource checks authoritative backend orders, not client memory flag
      final deviceBElig = orderDataSource.getFirstOrderEligibilitySync(tamperedClientUser.id);
      expect(deviceBElig.requiresFirstOrderGcash, isTrue);

      final deviceBCounterAttempt = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'Pay at Counter'),
      );
      expect(deviceBCounterAttempt.isFailure, isTrue);
    });

    // -------------------------------------------------------------------------
    // 12. Existing historical Pay at Counter orders remain intact
    // -------------------------------------------------------------------------
    test('12. Existing historical Pay at Counter orders and legacy accounts remain intact', () async {
      final demoCustomer = userDb.getByEmail('coffee.lover@lambac.com')!.user;
      userDb.setCurrentUser(demoCustomer);

      final ordersRes = await orderDataSource.getOrders();
      expect(ordersRes.isSuccess, isTrue);
      final orders = ordersRes.dataOrNull!.items;
      expect(orders.any((o) => o.orderNumber == 'LMB-1082' && o.paymentMethod == 'Pay at Counter'), isTrue);
      expect(orders.any((o) => o.orderNumber == 'LMB-0941' && o.paymentStatus == 'PAID'), isTrue);

      // Historical customer with completed & paid orders has completed first-order requirement
      final elig = orderDataSource.getFirstOrderEligibilitySync(demoCustomer.id);
      expect(elig.hasCompletedFirstOrder, isTrue);
      expect(elig.requiresFirstOrderGcash, isFalse);

      // Can continue placing Pay at Counter orders
      final product = productDb.getProductById('mt-apo-honey')!;
      final newCounterOrder = await orderDataSource.createOrder(
        buildOrderRequest(product: product, paymentMethod: 'Pay at Counter'),
      );
      expect(newCounterOrder.isSuccess, isTrue);
    });

    // -------------------------------------------------------------------------
    // 13. Existing admin and barista workflows continue functioning & block unverified GCash override
    // -------------------------------------------------------------------------
    test(
      '13. Admin and Barista workflows function for counter orders and block manual payment override on unverified GCash orders',
      () async {
        // Part A: New customer creates a first-order GCash order (PENDING)
        await registerAndLoginNewCustomer();
        final product = productDb.getProductById('mt-apo-honey')!;
        final gcashOrderRes = await orderDataSource.createOrder(
          buildOrderRequest(product: product, paymentMethod: 'GCash'),
        );
        expect(gcashOrderRes.isSuccess, isTrue);
        final gcashOrder = gcashOrderRes.dataOrNull!;

        // Switch to Barista account
        final barista = userDb.getByEmail('barista.staff@lambac.com')!.user;
        userDb.setCurrentUser(barista);

        // Barista can advance preparation status (preparing -> prepared -> readyForPickup)
        expect(
          (await orderDataSource.updateOrderStatus(gcashOrder.id, OrderStatus.preparing)).isSuccess,
          isTrue,
        );
        expect(
          (await orderDataSource.updateOrderStatus(gcashOrder.id, OrderStatus.prepared)).isSuccess,
          isTrue,
        );
        expect(
          (await orderDataSource.updateOrderStatus(gcashOrder.id, OrderStatus.readyForPickup)).isSuccess,
          isTrue,
        );

        // Barista CANNOT manually mark an unverified PENDING GCash order as PAID at counter
        final manualPaidAttempt = await orderDataSource.updatePaymentStatus(
          gcashOrder.id,
          PaymentStatus.paid,
        );
        expect(manualPaidAttempt.isFailure, isTrue);
        expect(manualPaidAttempt.failureOrNull, isA<ValidationFailure>());

        // Barista CANNOT complete an unverified PENDING GCash order
        final prematureCompleteAttempt = await orderDataSource.updateOrderStatus(
          gcashOrder.id,
          OrderStatus.completed,
        );
        expect(prematureCompleteAttempt.isFailure, isTrue);
        expect(prematureCompleteAttempt.failureOrNull, isA<ValidationFailure>());

        // Once PayMongo webhook verifies the GCash order as PAID, Barista CAN complete handover
        await orderDataSource.processPaymongoWebhookEvent(
          orderId: gcashOrder.id,
          eventType: 'checkout_session.payment.paid',
          eventId: 'evt_barista_handover_paid',
          paymentId: 'pay_gcash_999',
        );

        final verifiedCompleteRes = await orderDataSource.updateOrderStatus(
          gcashOrder.id,
          OrderStatus.completed,
        );
        expect(verifiedCompleteRes.isSuccess, isTrue);
        expect(verifiedCompleteRes.dataOrNull!.status, equals(OrderStatus.completed));
        expect(verifiedCompleteRes.dataOrNull!.paymentStatus, equals('PAID'));

        // Part B: Existing Pay at Counter order (LMB-1082) can still be prepared, paid, and completed by Barista
        expect(
          (await orderDataSource.updateOrderStatus('ord_lmb_1082', OrderStatus.prepared)).isSuccess,
          isTrue,
        );
        expect(
          (await orderDataSource.updateOrderStatus('ord_lmb_1082', OrderStatus.readyForPickup)).isSuccess,
          isTrue,
        );
        final counterCompleteRes = await orderDataSource.updateOrderStatus(
          'ord_lmb_1082',
          OrderStatus.completed,
        );
        expect(counterCompleteRes.isSuccess, isTrue);
        expect(counterCompleteRes.dataOrNull!.paymentStatus, equals('PAID'));
      },
    );
  });
}

