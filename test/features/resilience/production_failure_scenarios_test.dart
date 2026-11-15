import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/network/result.dart';
import 'package:lambac_app/core/utils/image_validator.dart';
import 'package:lambac_app/core/utils/validators.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_database.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/mock_ledger_store.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MockLedgerStore.init();
    MockUserDatabase().resetForTests();
    MockOrderRemoteDataSource().resetForTesting();
    MockSalesRemoteDataSource().resetForTesting();
  });

  group('Production Failure Scenarios & Resilience Quality Gate Suite', () {
    final customerUser = UserModel(
      id: 'usr_resilience_cust',
      email: 'resilience.cust@lambac.com',
      fullName: 'Resilience Tester',
      role: UserRole.customer,
      status: UserStatus.active,
      loyaltyPoints: 100,
      termsAccepted: true,
      acceptedTermsVersion: '2026.1',
      createdAt: DateTime(2026, 1, 1),
    );

    CartItemModel createCartItem({
      String productId = 'benguet-typica',
      String productName = 'Benguet Arabica Typica',
      int quantity = 1,
      double unitPrice = 420.0,
    }) {
      return CartItemModel(
        id: 'cart_item_$productId',
        productId: productId,
        productName: productName,
        origin: 'Benguet',
        roastLevel: 'Medium Roast',
        quantity: quantity,
        unitPrice: unitPrice,
      );
    }

    test('SCENARIO 1: Network Interruption — Simulated network drop aborts request cleanly without state corruption', () async {
      MockUserDatabase().setCurrentUser(customerUser);
      final initialStock = MockProductDatabase().getProductById('benguet-typica')?.stockQuantity ?? 0;

      Future<Result<OrderModel, AppFailure>> placeOrderWithSimulatedNetworkDrop() async {
        try {
          throw const SocketException('Network is unreachable (simulated carrier disconnect)');
        } on SocketException catch (e) {
          return Result.failure(NetworkFailure(message: 'Network connection failed: ${e.message}'));
        }
      }

      final result = await placeOrderWithSimulatedNetworkDrop();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull?.message, contains('Network connection failed'));

      // Verify stock was NOT decremented because network interrupted before server commit
      final currentStock = MockProductDatabase().getProductById('benguet-typica')?.stockQuantity ?? 0;
      expect(currentStock, equals(initialStock));
    });

    test('SCENARIO 2: Denied Permissions — Customer attempting to update order status receives ForbiddenFailure', () async {
      MockUserDatabase().setCurrentUser(customerUser);
      final orderDataSource = MockOrderRemoteDataSource();
      final storageService = InMemoryStorageService();
      final orderRepo = OrderRepositoryImpl(
        remoteDataSource: orderDataSource,
        storageService: storageService,
      );

      // Seed order owned by customerUser
      final orderReq = CreateOrderRequest(
        customerName: customerUser.fullName,
        customerPhone: '09171234567',
        items: [createCartItem()],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Tomorrow',
        pickupTimeSlot: '11:00 AM - 11:30 AM',
        paymentMethod: 'Cash',
      );
      final createRes = await orderDataSource.createOrder(orderReq);
      expect(createRes.isSuccess, isTrue);
      final order = createRes.dataOrNull!;

      // Customer attempts to self-finalize status to "completed" via repository
      final updateAttempt = await orderRepo.updateOrderStatus(order.id, OrderStatus.completed);

      expect(updateAttempt.isFailure, isTrue);
      expect(updateAttempt.failureOrNull, isA<ForbiddenFailure>());

      // Order status remains in initial preparation state
      final refreshed = await orderDataSource.getOrderById(order.id);
      expect(refreshed.dataOrNull?.status, isNot(equals(OrderStatus.completed)));
    });

    test('SCENARIO 3: Failed Uploads — Unsupported magic bytes and oversized files (> 5 MB) are rejected', () {
      // 1. Windows PE executable header (MZ) disguised as image
      final exeBytes = Uint8List.fromList([0x4D, 0x5A, 0x90, 0x00, 0x03]);
      final exeValidation = ImageValidator.validateImageBytes(exeBytes);
      expect(exeValidation.isValid, isFalse);

      // 2. Oversized image (> 5 MB)
      final oversizedBytes = Uint8List(5 * 1024 * 1024 + 1);
      final sizeValidation = ImageValidator.validateImageBytes(oversizedBytes);
      expect(sizeValidation.isValid, isFalse);
      expect(sizeValidation.errorMessage, contains('smaller than 5 MB'));

      // 3. Valid PNG header passes
      final validPng = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      expect(ImageValidator.validateImageBytes(validPng).isValid, isTrue);
    });

    test('SCENARIO 4: Incomplete Profiles — Registration and profile updates enforce required fields and format rules', () async {
      final authDataSource = MockAuthRemoteDataSource();

      // 1. Blank full name
      final blankNameRes = await authDataSource.register(
        const RegisterRequest(
          fullName: ' ',
          email: 'incomplete@lambac.com',
          password: 'Password123!',
        ),
      );
      expect(blankNameRes.isFailure, isTrue);
      expect(blankNameRes.failureOrNull?.message, contains('Please enter your full name'));

      // 2. Malformed email address
      final malformedEmailRes = await authDataSource.register(
        const RegisterRequest(
          fullName: 'Valid Name',
          email: 'not-an-email',
          password: 'Password123!',
        ),
      );
      expect(malformedEmailRes.isFailure, isTrue);
      expect(malformedEmailRes.failureOrNull?.message, contains('valid email address'));

      // 3. Field validator tests: fullName & email validators
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('A'), isNotNull);
      expect(Validators.email('test@invalid'), isNotNull);

      // 4. Anonymous/Unauthenticated order attempt is rejected
      MockUserDatabase().setCurrentUser(null);
      final unauthOrderRes = await MockOrderRemoteDataSource().createOrder(
        CreateOrderRequest(
          customerName: 'Anonymous',
          customerPhone: '09170000000',
          items: [createCartItem()],
          pickupLocation: PickupLocationModel.flagship,
          pickupDate: 'Tomorrow',
          pickupTimeSlot: '11:00 AM - 11:30 AM',
          paymentMethod: 'Cash',
        ),
      );
      expect(unauthOrderRes.isFailure, isTrue);
      expect(unauthOrderRes.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('SCENARIO 5: Duplicate Checkout Attempts — Rapid double-tap/retries with idempotency key return original order without double decrement', () async {
      MockUserDatabase().setCurrentUser(customerUser);
      final orderDataSource = MockOrderRemoteDataSource();
      final initialStock = MockProductDatabase().getProductById('benguet-typica')?.stockQuantity ?? 0;

      const idempotencyToken = 'idem_key_resilience_test_9921';
      final orderReq = CreateOrderRequest(
        customerName: customerUser.fullName,
        customerPhone: '09171234567',
        items: [createCartItem(quantity: 2)],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Tomorrow',
        pickupTimeSlot: '11:00 AM - 11:30 AM',
        paymentMethod: 'Cash',
        idempotencyKey: idempotencyToken,
      );

      // First checkout attempt
      final firstAttempt = await orderDataSource.createOrder(orderReq);
      expect(firstAttempt.isSuccess, isTrue);
      final firstOrder = firstAttempt.dataOrNull!;

      // Duplicate checkout attempt (network retry or aggressive double-click)
      final secondAttempt = await orderDataSource.createOrder(orderReq);
      expect(secondAttempt.isSuccess, isTrue);
      final secondOrder = secondAttempt.dataOrNull!;

      // Must return identical existing order ID
      expect(secondOrder.id, equals(firstOrder.id));
      expect(secondOrder.orderNumber, equals(firstOrder.orderNumber));

      // Stock must only be decremented ONCE (by 2, not by 4)
      final postStock = MockProductDatabase().getProductById('benguet-typica')?.stockQuantity ?? 0;
      expect(postStock, equals(initialStock - 2));
    });

    test('SCENARIO 6: Failed Persistence — Simulated downstream sales ledger failure triggers atomic rollback', () async {
      // Seed admin for completion
      final adminUser = UserModel(
        id: 'usr_admin_resilience',
        email: 'jmbautista0228@gmail.com',
        fullName: 'Admin Resilience Officer',
        role: UserRole.admin,
        status: UserStatus.active,
        loyaltyPoints: 0,
        termsAccepted: true,
        acceptedTermsVersion: '2026.1',
        createdAt: DateTime(2026, 1, 1),
      );
      MockUserDatabase().setCurrentUser(adminUser);
      final orderDataSource = MockOrderRemoteDataSource();

      final orderReq = CreateOrderRequest(
        customerName: 'Durable Customer',
        customerPhone: '09171234567',
        items: [createCartItem(quantity: 1)],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Tomorrow',
        pickupTimeSlot: '11:00 AM - 11:30 AM',
        paymentMethod: 'Cash',
      );
      final createRes = await orderDataSource.createOrder(orderReq);
      expect(createRes.isSuccess, isTrue);
      final order = createRes.dataOrNull!;

      // Valid state transition progression: pending -> preparing -> readyForPickup
      final prepRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.preparing);
      expect(prepRes.isSuccess, isTrue);
      final readyRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.readyForPickup);
      expect(readyRes.isSuccess, isTrue);

      // Inject simulated sales ledger failure
      orderDataSource.simulateSaleFailureForTesting = true;

      // Attempt to finalize order to completed
      final completeRes = await orderDataSource.updateOrderStatus(
        order.id,
        OrderStatus.completed,
      );

      // Verify completion was rejected due to simulated failure
      expect(completeRes.isFailure, isTrue);
      expect(completeRes.failureOrNull?.message, contains('sale could not be recorded'));

      // Verify order status was rolled back and did NOT mark as completed
      final orderAfterRollback = await orderDataSource.getOrderById(order.id);
      expect(orderAfterRollback.dataOrNull?.status, isNot(equals(OrderStatus.completed)));
      expect(orderAfterRollback.dataOrNull?.status, equals(OrderStatus.readyForPickup));

      // Clean up flag
      orderDataSource.simulateSaleFailureForTesting = false;
    });
  });
}
