import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/domain/services/pickup_scheduling_service.dart';
import 'package:lambac_app/features/pos/data/datasources/mock_pos_remote_datasource.dart';
import 'package:lambac_app/features/pos/data/models/pos_cart_item_model.dart';
import 'package:lambac_app/features/pos/data/models/pos_checkout_request.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_database.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOrderRemoteDataSource orderDataSource;
  late MockSalesRemoteDataSource salesDataSource;
  late MockProductDatabase productDb;
  late MockUserDatabase userDb;
  late MockPosRemoteDataSource posDataSource;
  late ScheduledPickup validSchedule;

  UserModel customer1() => userDb.getByEmail('coffee.lover@lambac.com')!.user;
  UserModel customer2() {
    // Second customer for cross-customer isolation tests
    final existing = userDb.getByEmail('customer2@lambac.com');
    if (existing != null) return existing.user;
    final u = const UserModel(
      id: 'cust_bob_999',
      email: 'customer2@lambac.com',
      fullName: 'Bob Smith',
      phoneNumber: '09189876543',
      role: UserRole.customer,
      isRegistrationVerified: true,
    );
    userDb.records['customer2@lambac.com'] = UserDatabaseRecord(user: u, passwordHash: 'hashed');
    return u;
  }
  UserModel baristaUser() => userDb.getByEmail('barista.staff@lambac.com')!.user;
  UserModel adminUser() => userDb.getByEmail('jmbautista0228@gmail.com')!.user;

  setUp(() {
    orderDataSource = MockOrderRemoteDataSource();
    orderDataSource.clearOrdersForTesting();
    orderDataSource.simulateSaleFailureForTesting = false;

    salesDataSource = MockSalesRemoteDataSource();
    salesDataSource.resetForTesting();

    productDb = MockProductDatabase();
    productDb.resetForTesting();

    userDb = MockUserDatabase();
    userDb.resetForTests();

    posDataSource = MockPosRemoteDataSource();
    validSchedule = PickupSchedulingService().getEarliestAvailableSchedule();

    userDb.setCurrentUser(customer1());
  });

  tearDown(() {
    orderDataSource.resetForTesting();
    salesDataSource.resetForTesting();
    productDb.resetForTesting();
    userDb.resetForTests();
  });

  CreateOrderRequest buildValidOrderRequest({
    required ProductModel product,
    int quantity = 1,
    String? idempotencyKey,
    double? overrideUnitPrice,
    String? customerName,
    String? customerPhone,
  }) {
    final cartItem = CartItemModel(
      id: '${product.id}_size-250g_grind-whole',
      productId: product.id,
      productName: product.name,
      origin: product.origin,
      roastLevel: product.roastLevel,
      unitPrice: overrideUnitPrice ?? product.basePrice,
      quantity: quantity,
    );

    return CreateOrderRequest(
      customerName: customerName ?? 'Maria Santos',
      customerPhone: customerPhone ?? '09171234567',
      items: [cartItem],
      pickupLocation: PickupLocationModel.flagship,
      pickupDate: validSchedule.dateDisplay,
      pickupTimeSlot: validSchedule.timeSlot,
      paymentMethod: 'Pay at Counter',
      paymentStatus: 'UNPAID',
      idempotencyKey: idempotencyKey ?? 'idemp_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  // =========================================================================
  // TEST A: Legitimate Customer Checkout
  // =========================================================================
  group('Test A — Legitimate Customer Checkout', () {
    test('Customer 1 successfully submits a pickup order with valid catalog item and schedule', () async {
      userDb.setCurrentUser(customer1());
      final product = productDb.getProductById('mt-apo-honey')!;

      final request = buildValidOrderRequest(product: product, quantity: 1);
      final result = await orderDataSource.createOrder(request);

      expect(result.isSuccess, isTrue);
      final createdOrder = result.dataOrNull!;

      // 1. Confirm order is persisted
      expect(createdOrder.id, isNotEmpty);
      expect(createdOrder.orderNumber, startsWith('LMB-'));

      // 2. Confirm order belongs to Customer 1's UID
      expect(createdOrder.customerId, equals(customer1().id));

      // 3. Confirm initial order status and payment status
      expect(createdOrder.status, equals(OrderStatus.pending));
      expect(createdOrder.paymentStatus, equals('UNPAID'));
      expect(createdOrder.isUnpaid, isTrue);

      // 4. Confirm total amount matches authoritative catalog pricing
      expect(createdOrder.totalAmount, equals(product.basePrice));

      // 5. Confirm order appears in Customer 1 order history
      final customerOrdersResult = await orderDataSource.getOrders();
      expect(customerOrdersResult.isSuccess, isTrue);
      final custOrders = customerOrdersResult.dataOrNull!.items;
      expect(custOrders.any((o) => o.id == createdOrder.id), isTrue);

      // 6. Confirm order appears in Barista queue
      userDb.setCurrentUser(baristaUser());
      final baristaOrdersResult = await orderDataSource.getOrders();
      expect(baristaOrdersResult.isSuccess, isTrue);
      final baristaOrders = baristaOrdersResult.dataOrNull!.items;
      expect(baristaOrders.any((o) => o.id == createdOrder.id), isTrue);
    });
  });

  // =========================================================================
  // TEST B: Cross-Customer Protection
  // =========================================================================
  group('Test B — Cross-Customer Protection', () {
    test('Customer 2 cannot read or access Customer 1 private order', () async {
      // Create order as Customer 1
      userDb.setCurrentUser(customer1());
      final product = productDb.getProductById('benguet-typica')!;
      final result = await orderDataSource.createOrder(buildValidOrderRequest(product: product));
      final order1 = result.dataOrNull!;

      // Switch to Customer 2
      userDb.setCurrentUser(customer2());

      // Customer 2 attempts direct lookup of Customer 1's order
      final getResult = await orderDataSource.getOrderById(order1.id);
      expect(getResult.isFailure, isTrue);
      expect(getResult.failureOrNull, isA<ForbiddenFailure>());

      // Customer 2 order list does NOT contain Customer 1's order
      final listResult = await orderDataSource.getOrders();
      expect(listResult.isSuccess, isTrue);
      expect(listResult.dataOrNull!.items.any((o) => o.id == order1.id), isFalse);
    });

    test('Customer 2 cannot cancel Customer 1 order', () async {
      userDb.setCurrentUser(customer1());
      final product = productDb.getProductById('benguet-typica')!;
      final order1 = (await orderDataSource.createOrder(buildValidOrderRequest(product: product))).dataOrNull!;

      // Switch to Customer 2
      userDb.setCurrentUser(customer2());
      final cancelResult = await orderDataSource.cancelOrder(order1.id);

      expect(cancelResult.isFailure, isTrue);
      expect(cancelResult.failureOrNull, isA<ForbiddenFailure>());
      expect(cancelResult.failureOrNull?.message, contains('Forbidden: You can only cancel your own orders'));
    });
  });

  // =========================================================================
  // TEST C: Protected Business Data & Privilege Escalation Prevention
  // =========================================================================
  group('Test C — Protected Business Data & Privilege Escalation Prevention', () {
    test('Customer cannot self-advance order status to completed or mark as paid', () async {
      userDb.setCurrentUser(customer1());
      final product = productDb.getProductById('mt-apo-honey')!;
      final order = (await orderDataSource.createOrder(buildValidOrderRequest(product: product))).dataOrNull!;

      // Customer attempts to call updateOrderStatus to completed
      final advanceResult = await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);
      expect(advanceResult.isFailure, isTrue);
      expect(advanceResult.failureOrNull, isA<ForbiddenFailure>());

      // Customer attempts to call updatePaymentStatus to paid
      final payResult = await orderDataSource.updatePaymentStatus(order.id, PaymentStatus.paid);
      expect(payResult.isFailure, isTrue);
      expect(payResult.failureOrNull, isA<ForbiddenFailure>());
    });

    test('Customer cannot create orders with tampered prices below catalog', () async {
      userDb.setCurrentUser(customer1());
      final product = productDb.getProductById('benguet-typica')!;

      final tamperedReq = buildValidOrderRequest(
        product: product,
        overrideUnitPrice: 50.0, // Catalog is 420.0
      );

      final result = await orderDataSource.createOrder(tamperedReq);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('Price change detected'));
    });
  });

  // =========================================================================
  // TEST D: Staff & Barista Workflow Regressions
  // =========================================================================
  group('Test D — Staff Regression & Order Lifecycle', () {
    test('Full Staff Lifecycle: Customer Order -> Barista Preparing -> Prepared -> Ready -> Completed', () async {
      // 1. Customer places order
      userDb.setCurrentUser(customer1());
      final product = productDb.getProductById('mt-apo-honey')!;
      final order = (await orderDataSource.createOrder(buildValidOrderRequest(product: product))).dataOrNull!;
      expect(order.status, equals(OrderStatus.pending));

      // 2. Barista marks Preparing
      userDb.setCurrentUser(baristaUser());
      final prepRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.preparing);
      expect(prepRes.isSuccess, isTrue);
      expect(prepRes.dataOrNull!.status, equals(OrderStatus.preparing));

      // 3. Barista marks Prepared
      final readyPrepRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.prepared);
      expect(readyPrepRes.isSuccess, isTrue);
      expect(readyPrepRes.dataOrNull!.status, equals(OrderStatus.prepared));

      // 4. Barista marks Ready for Pickup
      final readyRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.readyForPickup);
      expect(readyRes.isSuccess, isTrue);
      expect(readyRes.dataOrNull!.status, equals(OrderStatus.readyForPickup));

      // 5. Customer cannot cancel once Ready for Pickup
      userDb.setCurrentUser(customer1());
      final cancelAttempt = await orderDataSource.cancelOrder(order.id);
      expect(cancelAttempt.isFailure, isTrue);
      expect(cancelAttempt.failureOrNull, isA<ForbiddenFailure>());

      // 6. Admin completes the order upon pickup & payment at counter
      userDb.setCurrentUser(adminUser());
      final completeRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);
      expect(completeRes.isSuccess, isTrue);
      expect(completeRes.dataOrNull!.status, equals(OrderStatus.completed));
      expect(completeRes.dataOrNull!.isPaid, isTrue);

      // 7. Completed orders are terminal and cannot be reopened or cancelled
      final terminalCancel = await orderDataSource.cancelOrder(order.id);
      expect(terminalCancel.isFailure, isTrue);
      expect(terminalCancel.failureOrNull, isA<ValidationFailure>());
    });

    test('POS Counter Sale by Staff operates independently from mobile pickup channel', () async {
      userDb.setCurrentUser(adminUser());
      final product = productDb.getProductById('benguet-typica')!;

      final posReq = PosCheckoutRequest(
        idempotencyKey: 'pos_sec_test_1001',
        items: [
          PosCartItemModel.fromProduct(
            product: product,
            quantity: 1,
          ),
        ],
        paymentMethod: 'Cash',
        tenderedAmount: 500.0,
        changeAmount: 500.0 - product.basePrice,
        staffId: adminUser().id,
        staffName: adminUser().fullName,
      );

      final posRes = await posDataSource.completeSaleTransaction(posReq);
      expect(posRes.isSuccess, isTrue);
      expect(posRes.dataOrNull!.receiptNumber, startsWith('TX-POS-'));

      final posSales = (await salesDataSource.getSalesRecords(channel: SalesChannel.walkIn)).dataOrNull!;
      expect(posSales.any((s) => s.id == posRes.dataOrNull!.saleId), isTrue);
    });
  });

  // =========================================================================
  // TEST E: Failure Scenarios & Edge Cases
  // =========================================================================
  group('Test E — Failure Scenarios & Edge Cases', () {
    test('Unauthenticated user cannot place an order', () async {
      userDb.setCurrentUser(null);
      final product = productDb.getProductById('mt-apo-honey')!;

      final result = await orderDataSource.createOrder(buildValidOrderRequest(product: product));
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('Empty cart order submission is rejected', () async {
      userDb.setCurrentUser(customer1());
      final emptyReq = CreateOrderRequest(
        customerName: 'Maria',
        customerPhone: '09171234567',
        items: [],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: validSchedule.dateDisplay,
        pickupTimeSlot: validSchedule.timeSlot,
        paymentMethod: 'Pay at Counter',
      );

      final result = await orderDataSource.createOrder(emptyReq);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('empty cart'));
    });

    test('Duplicate submission with same idempotency key safely returns original order', () async {
      userDb.setCurrentUser(customer1());
      final product = productDb.getProductById('mt-apo-honey')!;
      const key = 'idemp_duplicate_tap_prevention_777';

      final req1 = buildValidOrderRequest(product: product, idempotencyKey: key);
      final res1 = await orderDataSource.createOrder(req1);
      expect(res1.isSuccess, isTrue);

      final req2 = buildValidOrderRequest(product: product, idempotencyKey: key);
      final res2 = await orderDataSource.createOrder(req2);
      expect(res2.isSuccess, isTrue);

      expect(res2.dataOrNull!.id, equals(res1.dataOrNull!.id));
      expect(res2.dataOrNull!.orderNumber, equals(res1.dataOrNull!.orderNumber));
    });

    test('Order for disabled product is rejected', () async {
      userDb.setCurrentUser(customer1());
      final product = productDb.getProductById('mt-apo-honey')!;
      productDb.setProductStatus(
        productId: product.id,
        isEnabled: false,
        customerVisibility: ProductVisibility.visible,
      );

      final result = await orderDataSource.createOrder(buildValidOrderRequest(product: product));
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('Order exceeding inventory stock is rejected', () async {
      userDb.setCurrentUser(customer1());
      final product = productDb.getProductById('mt-apo-honey')!;

      final result = await orderDataSource.createOrder(
        buildValidOrderRequest(product: product, quantity: product.stockQuantity + 50),
      );
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('Insufficient stock'));
    });

    test('First-order customer must use GCash (Pay at Counter rejected) and staff cannot manually mark unverified GCash as PAID', () async {
      final newCustomer = const UserModel(
        id: 'cust_brand_new_888',
        email: 'brandnew@lambac.com',
        fullName: 'Brand New Customer',
        phoneNumber: '09175551122',
        role: UserRole.customer,
        isRegistrationVerified: true,
        firstOrderGcashCompleted: false,
      );
      userDb.records['brandnew@lambac.com'] = UserDatabaseRecord(
        user: newCustomer,
        passwordHash: 'hashed',
      );
      userDb.setCurrentUser(newCustomer);

      final product = productDb.getProductById('mt-apo-honey')!;

      // 1. Attempting Pay at Counter on first order is rejected
      final counterReq = buildValidOrderRequest(product: product);
      final counterRes = await orderDataSource.createOrder(counterReq);
      expect(counterRes.isFailure, isTrue);
      expect(counterRes.failureOrNull, isA<ValidationFailure>());

      // 2. Creating valid first-order GCash order succeeds with PENDING status
      final gcashReq = CreateOrderRequest(
        customerName: newCustomer.fullName,
        customerPhone: newCustomer.phoneNumber ?? '09175551122',
        items: counterReq.items,
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: validSchedule.dateDisplay,
        pickupTimeSlot: validSchedule.timeSlot,
        paymentMethod: 'GCash',
        paymentStatus: 'PENDING',
        idempotencyKey: 'idemp_first_gcash_888',
      );
      final gcashRes = await orderDataSource.createOrder(gcashReq);
      expect(gcashRes.isSuccess, isTrue);
      expect(gcashRes.dataOrNull!.paymentStatus, equals('PENDING'));

      // 3. Barista cannot manually mark an unverified GCash order as PAID at counter
      userDb.setCurrentUser(baristaUser());
      final staffMarkPaid = await orderDataSource.updatePaymentStatus(
        gcashRes.dataOrNull!.id,
        PaymentStatus.paid,
      );
      expect(staffMarkPaid.isFailure, isTrue);
      expect(staffMarkPaid.failureOrNull, isA<ValidationFailure>());
    });
  });
}
