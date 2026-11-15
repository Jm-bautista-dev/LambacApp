import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/domain/services/order_queue_service.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOrderRemoteDataSource orderDataSource;
  late MockSalesRemoteDataSource salesDataSource;
  late MockUserDatabase userDatabase;
  late ProviderContainer container;

  const sampleItem = OrderItemModel(
    id: 'item_test_1',
    productId: 'mt-apo-honey',
    productName: 'Mount Apo Anaerobic Honey Reserve',
    origin: 'Davao del Sur',
    size: '250g Bag',
    grind: 'Whole Bean',
    unitPrice: 480.0,
    quantity: 1,
    totalPrice: 480.0,
  );

  OrderModel createTestOrder({
    required String id,
    OrderStatus status = OrderStatus.pending,
    String paymentStatus = 'UNPAID',
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id,
      orderNumber: 'LMB-${id.toUpperCase()}',
      customerId: 'usr_customer_demo',
      customerName: 'Kenji Takahashi',
      customerPhone: '09171234567',
      items: const [sampleItem],
      subtotal: 480.0,
      totalAmount: 480.0,
      status: status,
      pickupLocation: PickupLocationModel.flagship,
      pickupDate: 'Today',
      pickupTimeSlot: 'ASAP (~15-20 mins)',
      paymentMethod: 'Pay at Counter',
      paymentStatus: paymentStatus,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  void loginStaff() => userDatabase.setCurrentUser(userDatabase.getByEmail('barista.staff@lambac.com')?.user);

  setUp(() {
    orderDataSource = MockOrderRemoteDataSource();
    orderDataSource.simulateSaleFailureForTesting = false;
    orderDataSource.clearOrdersForTesting();
    salesDataSource = MockSalesRemoteDataSource();
    salesDataSource.resetForTesting();
    userDatabase = MockUserDatabase();
    userDatabase.resetForTests();
    loginStaff();

    final staffUser = userDatabase.getByEmail('barista.staff@lambac.com')!.user;
    container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(staffUser),
      orderRemoteDataSourceProvider.overrideWithValue(orderDataSource),
      adminRemoteDataSourceProvider.overrideWithValue(MockAdminRemoteDataSource()),
      storageServiceProvider.overrideWithValue(InMemoryStorageService()),
    ]);
    container.listen(ordersNotifierProvider, (_, __) {});
  });

  tearDown(() {
    container.dispose();
    orderDataSource.resetForTesting();
    salesDataSource.resetForTesting();
    userDatabase.resetForTests();
  });

  group('Lambac Order Queue & Completion Persistence Production Fix Suite', () {
    // -------------------------------------------------------------------------
    // Test 1 — Normal lifecycle
    // -------------------------------------------------------------------------
    test('Test 1 — Normal lifecycle: pending -> preparing -> ready_to_pick_up -> completed', () async {
      final order = createTestOrder(id: 'ord_lc_1', status: OrderStatus.pending);
      orderDataSource.setOrdersForTesting([order]);

      final controller = container.read(adminProductNotifierProvider);

      // Pending -> Preparing
      final prepRes = await controller.advanceOrderStatus('ord_lc_1', OrderStatus.preparing);
      expect(prepRes.isSuccess, isTrue);
      expect(prepRes.dataOrNull!.status, OrderStatus.preparing);

      // Preparing -> Ready for Pickup
      final readyRes = await controller.advanceOrderStatus('ord_lc_1', OrderStatus.readyForPickup);
      expect(readyRes.isSuccess, isTrue);
      expect(readyRes.dataOrNull!.status, OrderStatus.readyForPickup);

      // Ready for Pickup -> Completed
      final completeRes = await controller.advanceOrderStatus('ord_lc_1', OrderStatus.completed);
      expect(completeRes.isSuccess, isTrue);
      expect(completeRes.dataOrNull!.status, OrderStatus.completed);
      expect(completeRes.dataOrNull!.isPaid, isTrue);
      expect(completeRes.dataOrNull!.completedAt, isNotNull);
    });

    // -------------------------------------------------------------------------
    // Test 2 — Completion persistence
    // -------------------------------------------------------------------------
    test('Test 2 — Completion persistence: reloaded order from datasource remains completed', () async {
      final order = createTestOrder(id: 'ord_p2', status: OrderStatus.readyForPickup);
      orderDataSource.setOrdersForTesting([order]);

      final controller = container.read(adminProductNotifierProvider);
      final completeRes = await controller.advanceOrderStatus('ord_p2', OrderStatus.completed);
      expect(completeRes.isSuccess, isTrue);

      // Fetch freshly from datasource
      final reloadedRes = await orderDataSource.getOrderById('ord_p2');
      expect(reloadedRes.isSuccess, isTrue);
      expect(reloadedRes.dataOrNull!.status, OrderStatus.completed);
      expect(reloadedRes.dataOrNull!.paymentStatus, 'PAID');
    });

    // -------------------------------------------------------------------------
    // Test 3 — Rebuild
    // -------------------------------------------------------------------------
    test('Test 3 — Rebuild: complete the order, reload orders provider -> remains completed (not preparing)', () async {
      final order = createTestOrder(id: 'ord_rb3', status: OrderStatus.readyForPickup);
      orderDataSource.setOrdersForTesting([order]);

      final controller = container.read(adminProductNotifierProvider);
      await controller.advanceOrderStatus('ord_rb3', OrderStatus.completed);

      // Rebuild / refresh orders notifier
      await container.read(ordersNotifierProvider.notifier).loadOrders(isRefresh: true);
      final orders = container.read(ordersNotifierProvider).orders;

      final updated = orders.firstWhere((o) => o.id == 'ord_rb3');
      expect(updated.status, equals(OrderStatus.completed));
      expect(updated.status, isNot(equals(OrderStatus.preparing)));
    });

    // -------------------------------------------------------------------------
    // Test 4 — Realtime listener string deserialization
    // -------------------------------------------------------------------------
    test('Test 4 — Realtime listener / deserialization: handles all valid string formats symmetrically', () {
      expect(OrderStatus.fromString('completed'), OrderStatus.completed);
      expect(OrderStatus.fromString('complete'), OrderStatus.completed);
      expect(OrderStatus.fromString('picked_up'), OrderStatus.completed);
      expect(OrderStatus.fromString('readyForPickup'), OrderStatus.readyForPickup);
      expect(OrderStatus.fromString('ready_for_pickup'), OrderStatus.readyForPickup);
      expect(OrderStatus.fromString('ready_to_pick_up'), OrderStatus.readyForPickup);
      expect(OrderStatus.fromString('preparing'), OrderStatus.preparing);
      expect(OrderStatus.fromString('roasting'), OrderStatus.preparing);
      expect(OrderStatus.fromString('prepared'), OrderStatus.prepared);
      expect(OrderStatus.fromString('pending'), OrderStatus.pending);
      expect(OrderStatus.fromString('cancelled'), OrderStatus.cancelled);

      // Fallback behavior: unrecognized strings never silently become preparing
      expect(OrderStatus.fromString('unknown_status_xyz'), isNot(OrderStatus.preparing));
    });

    // -------------------------------------------------------------------------
    // Test 5 — No backward transition
    // -------------------------------------------------------------------------
    test('Test 5 — No backward transition: completed -> preparing is rejected and remains completed', () async {
      final order = createTestOrder(id: 'ord_bt5', status: OrderStatus.completed);
      orderDataSource.setOrdersForTesting([order]);

      // Attempt invalid regression
      final regressRes = await orderDataSource.updateOrderStatus('ord_bt5', OrderStatus.preparing);
      expect(regressRes.isFailure, isTrue);

      final current = (await orderDataSource.getOrderById('ord_bt5')).dataOrNull!;
      expect(current.status, OrderStatus.completed);
    });

    // -------------------------------------------------------------------------
    // Test 6 — Queue filtering
    // -------------------------------------------------------------------------
    test('Test 6 — Queue filtering: completed order leaves active queue but remains in past/history', () async {
      final orderA = createTestOrder(id: 'ord_active_1', status: OrderStatus.preparing);
      final orderB = createTestOrder(id: 'ord_active_2', status: OrderStatus.readyForPickup);
      orderDataSource.setOrdersForTesting([orderA, orderB]);

      await container.read(ordersNotifierProvider.notifier).loadOrders(isRefresh: true);
      expect(container.read(ordersNotifierProvider).activeOrders.length, 2);

      // Complete order B
      final controller = container.read(adminProductNotifierProvider);
      await controller.advanceOrderStatus('ord_active_2', OrderStatus.completed);

      final state = container.read(ordersNotifierProvider);
      final active = state.activeOrders;
      final past = state.pastOrders;

      expect(active.map((o) => o.id), contains('ord_active_1'));
      expect(active.map((o) => o.id), isNot(contains('ord_active_2')));
      expect(past.map((o) => o.id), contains('ord_active_2'));

      // Queue service metrics
      final metrics = OrderQueueService().calculateMetrics(state.orders);
      expect(metrics.activeCount, 1);
      expect(metrics.completedCount, 1);
    });

    // -------------------------------------------------------------------------
    // Test 7 — Customer synchronization
    // -------------------------------------------------------------------------
    test('Test 7 — Customer synchronization: customer realtime listener receives completed without regression', () async {
      final order = createTestOrder(id: 'ord_sync_7', status: OrderStatus.readyForPickup);
      orderDataSource.setOrdersForTesting([order]);

      final repository = container.read(orderRepositoryProvider);
      final emittedStatuses = <OrderStatus>[];

      final sub = repository.watchOrder('ord_sync_7').listen((o) {
        emittedStatuses.add(o.status);
      });

      // Admin completes order
      final controller = container.read(adminProductNotifierProvider);
      final completeRes = await controller.advanceOrderStatus('ord_sync_7', OrderStatus.completed);
      expect(completeRes.isSuccess, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emittedStatuses, contains(OrderStatus.completed));
      expect(emittedStatuses.last, equals(OrderStatus.completed));

      await sub.cancel();
    });

    // -------------------------------------------------------------------------
    // Test 8 — App restart / durable reload
    // -------------------------------------------------------------------------
    test('Test 8 — App restart: complete order, re-initialize container -> remains completed', () async {
      final order = createTestOrder(id: 'ord_rst_8', status: OrderStatus.readyForPickup);
      orderDataSource.setOrdersForTesting([order]);

      final controller = container.read(adminProductNotifierProvider);
      await controller.advanceOrderStatus('ord_rst_8', OrderStatus.completed);

      // Simulate app restart with a fresh ProviderContainer
      final staffUser = userDatabase.getByEmail('barista.staff@lambac.com')!.user;
      final newContainer = ProviderContainer(overrides: [
        currentUserProvider.overrideWithValue(staffUser),
        orderRemoteDataSourceProvider.overrideWithValue(orderDataSource),
        adminRemoteDataSourceProvider.overrideWithValue(MockAdminRemoteDataSource()),
        storageServiceProvider.overrideWithValue(InMemoryStorageService()),
      ]);
      newContainer.listen(ordersNotifierProvider, (_, __) {});

      await newContainer.read(ordersNotifierProvider.notifier).loadOrders(isRefresh: true);
      final orders = newContainer.read(ordersNotifierProvider).orders;

      final reloaded = orders.firstWhere((o) => o.id == 'ord_rst_8');
      expect(reloaded.status, OrderStatus.completed);
      newContainer.dispose();
    });

    // -------------------------------------------------------------------------
    // Test 9 — Repeated completion
    // -------------------------------------------------------------------------
    test('Test 9 — Repeated completion: duplicate completion requests are idempotent and do not corrupt order', () async {
      final order = createTestOrder(id: 'ord_dup_9', status: OrderStatus.readyForPickup);
      orderDataSource.setOrdersForTesting([order]);

      final controller = container.read(adminProductNotifierProvider);

      final res1 = await controller.advanceOrderStatus('ord_dup_9', OrderStatus.completed);
      expect(res1.isSuccess, isTrue);

      final res2 = await controller.advanceOrderStatus('ord_dup_9', OrderStatus.completed);
      expect(res2.isSuccess, isTrue);

      final res3 = await orderDataSource.updateOrderStatus('ord_dup_9', OrderStatus.completed);
      expect(res3.isSuccess, isTrue);
      expect(res3.dataOrNull!.status, OrderStatus.completed);

      // Exactly 1 sale recorded in sales ledger
      expect(salesDataSource.getAllSales().where((s) => s.orderId == 'ord_dup_9').length, 1);
    });
  });
}
