import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOrderRemoteDataSource orderDataSource;
  late MockSalesRemoteDataSource salesDataSource;
  late MockProductDatabase productDb;
  late MockUserDatabase userDb;
  late MockPosRemoteDataSource posDataSource;
  late ScheduledPickup validSchedule;

  void loginCustomer() {
    final customer = userDb.getByEmail('coffee.lover@lambac.com')?.user;
    userDb.setCurrentUser(customer);
  }

  void loginBarista() {
    final barista = userDb.getByEmail('barista.staff@lambac.com')?.user;
    userDb.setCurrentUser(barista);
  }

  void loginAdmin() {
    final admin = userDb.getByEmail('jmbautista0228@gmail.com')?.user;
    userDb.setCurrentUser(admin);
  }

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
    loginCustomer();
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
      customerName: 'Maria Santos',
      customerPhone: '09171234567',
      items: [cartItem],
      pickupLocation: PickupLocationModel.flagship,
      pickupDate: validSchedule.dateDisplay,
      pickupTimeSlot: validSchedule.timeSlot,
      paymentMethod: 'Pay at Counter',
      paymentStatus: 'UNPAID',
      idempotencyKey: idempotencyKey ?? 'idemp_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  group('Requirement 1 & 2 & 3: Authoritative Pricing, Catalog Validation & Business Rules', () {
    test('Checkout rejects manipulated or stale client-provided unit prices', () async {
      final product = productDb.getProductById('mt-apo-honey')!;
      final tamperedPrice = product.basePrice - 100.0; // Client attempts discount tampering

      final request = buildValidOrderRequest(
        product: product,
        overrideUnitPrice: tamperedPrice,
      );

      final result = await orderDataSource.createOrder(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Price change detected'));
    });

    test('Checkout rejects disabled or unavailable products', () async {
      final product = productDb.getProductById('mt-apo-honey')!;
      // Admin disables product
      productDb.setProductStatus(
        productId: product.id,
        isEnabled: false,
        customerVisibility: ProductVisibility.visible,
      );

      final request = buildValidOrderRequest(product: product);
      final result = await orderDataSource.createOrder(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('unavailable or sold out'));
    });

    test('Checkout rejects order when requested quantity exceeds available stock', () async {
      final product = productDb.getProductById('mt-apo-honey')!;
      final excessQuantity = product.stockQuantity + 50;

      final request = buildValidOrderRequest(
        product: product,
        quantity: excessQuantity,
      );

      final result = await orderDataSource.createOrder(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Insufficient stock'));
    });

    test('Valid checkout atomically decrements catalog stock quantity', () async {
      final product = productDb.getProductById('mt-apo-honey')!;
      final initialStock = product.stockQuantity;
      const orderQuantity = 2;

      final request = buildValidOrderRequest(product: product, quantity: orderQuantity);
      final result = await orderDataSource.createOrder(request);

      expect(result.isSuccess, isTrue);
      final updatedProduct = productDb.getProductById('mt-apo-honey')!;
      expect(updatedProduct.stockQuantity, equals(initialStock - orderQuantity));
    });

    test('Cancelling an order restores inventory back to the catalog', () async {
      final product = productDb.getProductById('mt-apo-honey')!;
      final initialStock = product.stockQuantity;
      const orderQuantity = 3;

      final request = buildValidOrderRequest(product: product, quantity: orderQuantity);
      final createResult = await orderDataSource.createOrder(request);
      final createdOrder = createResult.dataOrNull!;

      expect(productDb.getProductById('mt-apo-honey')!.stockQuantity, equals(initialStock - orderQuantity));

      // Customer cancels before preparation
      final cancelResult = await orderDataSource.cancelOrder(createdOrder.id);
      expect(cancelResult.isSuccess, isTrue);
      expect(cancelResult.dataOrNull!.status, equals(OrderStatus.cancelled));

      // Stock is completely restored
      final restoredProduct = productDb.getProductById('mt-apo-honey')!;
      expect(restoredProduct.stockQuantity, equals(initialStock));
    });
  });

  group('Requirement 5, 6, 7 & 8: Idempotency, Duplicate Submissions & Network Resilience', () {
    test('Repeated checkout with identical idempotencyKey returns existing order and prevents duplicate stock deduction', () async {
      final product = productDb.getProductById('benguet-typica')!;
      final initialStock = product.stockQuantity;
      const key = 'test_idemp_checkout_double_click_1001';

      final request1 = buildValidOrderRequest(product: product, quantity: 2, idempotencyKey: key);
      final result1 = await orderDataSource.createOrder(request1);

      expect(result1.isSuccess, isTrue);
      final order1 = result1.dataOrNull!;
      expect(productDb.getProductById('benguet-typica')!.stockQuantity, equals(initialStock - 2));

      // Immediate retry (e.g. double tap or retry after dropped ACK)
      final request2 = buildValidOrderRequest(product: product, quantity: 2, idempotencyKey: key);
      final result2 = await orderDataSource.createOrder(request2);

      expect(result2.isSuccess, isTrue);
      final order2 = result2.dataOrNull!;

      // Exactly the same order returned
      expect(order2.id, equals(order1.id));
      expect(order2.orderNumber, equals(order1.orderNumber));

      // Stock NOT deducted again
      expect(productDb.getProductById('benguet-typica')!.stockQuantity, equals(initialStock - 2));

      // Database contains strictly 1 order
      final allOrders = (await orderDataSource.getOrders()).dataOrNull!.items;
      expect(allOrders.where((o) => o.idempotencyKey == key).length, equals(1));
    });

    test('Network timeout recovery: Client retry retrieves previously committed order safely', () async {
      final product = productDb.getProductById('tokyo-blend')!;
      const key = 'test_idemp_timeout_network_retry_4004';

      final req = buildValidOrderRequest(product: product, quantity: 1, idempotencyKey: key);
      final res1 = await orderDataSource.createOrder(req);
      expect(res1.isSuccess, isTrue);

      // Simulate client re-sending after timeout
      final res2 = await orderDataSource.createOrder(req);
      expect(res2.isSuccess, isTrue);
      expect(res2.dataOrNull!.id, equals(res1.dataOrNull!.id));
    });
  });

  group('Requirement 9 & 10: Snapshot Pricing & Historical Immutability', () {
    test('Historical completed sales and orders do not mutate when product prices are updated', () async {
      final product = productDb.getProductById('barako-premium')!;
      final originalPrice = product.basePrice;

      final request = buildValidOrderRequest(product: product, quantity: 2);
      final createRes = await orderDataSource.createOrder(request);
      final order = createRes.dataOrNull!;

      // Complete order through barista
      loginBarista();
      await orderDataSource.updateOrderStatus(order.id, OrderStatus.preparing);
      await orderDataSource.updateOrderStatus(order.id, OrderStatus.readyForPickup);
      final completeRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);
      expect(completeRes.isSuccess, isTrue);

      // Verify line items captured exact historical price
      final completedOrder = completeRes.dataOrNull!;
      expect(completedOrder.items.first.unitPrice, equals(originalPrice));
      expect(completedOrder.totalAmount, equals(originalPrice * 2));

      // Admin updates product catalog price by +₱150
      loginAdmin();
      final updatedCatalogProduct = product.copyWith(basePrice: originalPrice + 150.0);
      productDb.updateProduct(updatedCatalogProduct);

      // Fetch completed order again - price remains unchanged
      loginCustomer();
      final fetchedOrders = (await orderDataSource.getOrders()).dataOrNull!.items;
      final historicalOrder = fetchedOrders.firstWhere((o) => o.id == order.id);
      expect(historicalOrder.items.first.unitPrice, equals(originalPrice));
      expect(historicalOrder.totalAmount, equals(originalPrice * 2));

      // Check centralized sales ledger - sale remains unchanged
      loginBarista();
      final sales = (await salesDataSource.getSalesRecords()).dataOrNull!;
      final recordedSale = sales.firstWhere((s) => s.orderId == order.id);
      expect(recordedSale.items.first.snapshotUnitPrice, equals(originalPrice));
      expect(recordedSale.totalAmount, equals(originalPrice * 2));
    });
  });

  group('Requirement 4 & 14: Authorization Boundaries & Order Status Lifecycle', () {
    test('Customer cannot mark an order completed or bypass barista preparation', () async {
      final product = productDb.getProductById('mt-apo-honey')!;
      final request = buildValidOrderRequest(product: product);
      final createRes = await orderDataSource.createOrder(request);
      final order = createRes.dataOrNull!;

      // Customer attempts to self-complete order
      final customerResult = await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);
      expect(customerResult.isFailure, isTrue);
      expect(customerResult.failureOrNull?.message, contains('Forbidden'));

      // Customer cannot skip directly to readyForPickup
      final skipResult = await orderDataSource.updateOrderStatus(order.id, OrderStatus.readyForPickup);
      expect(skipResult.isFailure, isTrue);
      expect(skipResult.failureOrNull?.message, contains('Forbidden'));
    });

    test('Customer cannot cancel order once marked ready for pickup', () async {
      final product = productDb.getProductById('mt-apo-honey')!;
      final request = buildValidOrderRequest(product: product);
      final createRes = await orderDataSource.createOrder(request);
      final order = createRes.dataOrNull!;

      loginBarista();
      await orderDataSource.updateOrderStatus(order.id, OrderStatus.preparing);
      await orderDataSource.updateOrderStatus(order.id, OrderStatus.readyForPickup);

      // Customer attempts cancellation
      loginCustomer();
      final cancelResult = await orderDataSource.cancelOrder(order.id);
      expect(cancelResult.isFailure, isTrue);
      expect(cancelResult.failureOrNull?.message, contains('cannot be cancelled'));
    });

    test('Completed orders are terminal and cannot be cancelled or reopened', () async {
      final product = productDb.getProductById('mt-apo-honey')!;
      final request = buildValidOrderRequest(product: product);
      final createRes = await orderDataSource.createOrder(request);
      final order = createRes.dataOrNull!;

      loginBarista();
      await orderDataSource.updateOrderStatus(order.id, OrderStatus.preparing);
      await orderDataSource.updateOrderStatus(order.id, OrderStatus.readyForPickup);
      await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);

      // Attempt cancellation
      final cancelResult = await orderDataSource.cancelOrder(order.id);
      expect(cancelResult.isFailure, isTrue);
      expect(cancelResult.failureOrNull?.message, contains('Completed orders cannot be cancelled'));

      // Attempt reopening back to preparing
      final reopenResult = await orderDataSource.updateOrderStatus(order.id, OrderStatus.preparing);
      expect(reopenResult.isFailure, isTrue);
      expect(reopenResult.failureOrNull?.message, contains('Cannot transition'));
    });
  });

  group('Requirement 12 & 13: POS vs Mobile Channel Distinction & Dashboard Single Count', () {
    test('POS counter sales record walk-in channel and TX-POS- prefix, and decrement stock', () async {
      final product = productDb.getProductById('sagada-natural')!;
      final initialStock = product.stockQuantity;
      const idempotencyKey = 'pos_tx_key_88921';

      final posItem = PosCartItemModel.fromProduct(
        product: product,
        quantity: 2,
      );

      final posRequest = PosCheckoutRequest(
        idempotencyKey: idempotencyKey,
        items: [posItem],
        paymentMethod: 'Cash',
        tenderedAmount: (product.basePrice * 2) + 200,
        changeAmount: 200.0,
        staffId: 'usr_barista_staff',
        staffName: 'Barista Staff',
        customerName: 'Counter Guest',
      );

      final posResult = await posDataSource.completeSaleTransaction(posRequest);
      expect(posResult.isSuccess, isTrue);

      final receipt = posResult.dataOrNull!;
      expect(receipt.receiptNumber, startsWith('TX-POS-'));
      expect(receipt.totalAmount, equals(product.basePrice * 2));

      // Check centralized sales record channel
      final sale = salesDataSource.getAllSales().firstWhere((s) => s.id == receipt.saleId);
      expect(sale.channel, equals(SalesChannel.walkIn));

      // Stock was decremented
      expect(productDb.getProductById('sagada-natural')!.stockQuantity, equals(initialStock - 2));

      // Repeated checkout with same idempotencyKey is idempotent and returns receipt without double deduction
      final posRetry = await posDataSource.completeSaleTransaction(posRequest);
      expect(posRetry.isSuccess, isTrue);
      expect(posRetry.dataOrNull!.receiptNumber, equals(receipt.receiptNumber));
      expect(productDb.getProductById('sagada-natural')!.stockQuantity, equals(initialStock - 2));
    });

    test('Dashboard metrics reconcile sales channels and count completed sales strictly once', () async {
      final adminRemote = MockAdminRemoteDataSource();
      loginAdmin();
      final initialMetrics = (await adminRemote.getBusinessMetrics()).dataOrNull!;
      final initialTodaySales = initialMetrics.todaySales;

      // 1. Place and complete a Mobile Pickup order as Customer
      loginCustomer();
      final product1 = productDb.getProductById('mt-apo-honey')!;
      final mobReq = buildValidOrderRequest(product: product1, quantity: 1);
      final mobOrderRes = await orderDataSource.createOrder(mobReq);
      final mobOrder = mobOrderRes.dataOrNull!;

      loginBarista();
      await orderDataSource.updateOrderStatus(mobOrder.id, OrderStatus.preparing);
      await orderDataSource.updateOrderStatus(mobOrder.id, OrderStatus.readyForPickup);
      await orderDataSource.updateOrderStatus(mobOrder.id, OrderStatus.completed);

      // Verify intermediate metrics: exactly product1.basePrice added
      final metricsAfterMobile = (await adminRemote.getBusinessMetrics()).dataOrNull!;
      expect(
        (metricsAfterMobile.todaySales - (initialTodaySales + product1.basePrice)).abs() < 0.01,
        isTrue,
      );

      // 2. Perform a POS Walk-in Sale
      final product2 = productDb.getProductById('cold-brew-concentrate')!;
      final posReq = PosCheckoutRequest(
        idempotencyKey: 'pos_metric_test_7761',
        items: [
          PosCartItemModel.fromProduct(
            product: product2,
            quantity: 1,
          ),
        ],
        paymentMethod: 'Cash',
        tenderedAmount: 500.0,
        changeAmount: 500.0 - product2.basePrice,
        staffId: 'usr_barista_staff',
        staffName: 'Barista Staff',
      );

      final posRes = await posDataSource.completeSaleTransaction(posReq);
      expect(posRes.isSuccess, isTrue);

      // 3. Verify final dashboard metrics: both sales counted exactly once
      final finalMetrics = (await adminRemote.getBusinessMetrics()).dataOrNull!;
      final expectedTotal = initialTodaySales + product1.basePrice + product2.basePrice;
      expect((finalMetrics.todaySales - expectedTotal).abs() < 0.01, isTrue);

      // Check centralized sales records filter by channel
      final mobileSales = (await salesDataSource.getSalesRecords(channel: SalesChannel.mobileApp)).dataOrNull!;
      final posSales = (await salesDataSource.getSalesRecords(channel: SalesChannel.walkIn)).dataOrNull!;

      expect(mobileSales.any((s) => s.orderId == mobOrder.id), isTrue);
      expect(posSales.any((s) => s.transactionNumber.startsWith('TX-POS-')), isTrue);
    });
  });

  group('Requirement 11: Inventory & Stock Race Condition Prevention', () {
    test('Concurrent checkout attempts for remaining stock reject orders exceeding available stock', () async {
      final product = productDb.getProductById('mt-apo-honey')!;
      // Artificially set remaining stock to 2 units
      productDb.updateStock(product.id, -(product.stockQuantity - 2));
      expect(productDb.getProductById(product.id)!.stockQuantity, equals(2));

      // Attempt 1: order 1 unit (succeeds, reduces stock to 1)
      final req1 = buildValidOrderRequest(product: product, quantity: 1, idempotencyKey: 'concurrent_race_order_1');
      final res1 = await orderDataSource.createOrder(req1);
      expect(res1.isSuccess, isTrue);
      expect(productDb.getProductById(product.id)!.stockQuantity, equals(1));

      // Attempt 2: order 2 units concurrently (should fail due to insufficient stock)
      final req2 = buildValidOrderRequest(product: product, quantity: 2, idempotencyKey: 'concurrent_race_order_2');
      final res2 = await orderDataSource.createOrder(req2);
      expect(res2.isFailure, isTrue);
      expect(res2.failureOrNull?.message, contains('Insufficient stock'));
      expect(productDb.getProductById(product.id)!.stockQuantity, equals(1));
    });
  });
}
