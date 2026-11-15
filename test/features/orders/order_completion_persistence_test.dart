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
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

/// Verifies the order lifecycle is persisted by the backend ledger (source of truth),
/// completion + sale recording are atomic and idempotent, and the dashboard never
/// serves stale sales after a completion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOrderRemoteDataSource orders;
  late MockSalesRemoteDataSource sales;
  late MockUserDatabase users;
  late ProviderContainer container;

  const item = OrderItemModel(
    id: 'item_p1',
    productId: 'mt-apo-honey',
    productName: 'Mount Apo Anaerobic Honey Reserve',
    origin: 'Davao del Sur',
    size: '250g Bag',
    grind: 'Whole Bean',
    unitPrice: 480.0,
    quantity: 1,
    totalPrice: 480.0,
  );

  OrderModel makeOrder(String id, OrderStatus status, {DateTime? createdAt, double total = 480.0}) {
    return OrderModel(
      id: id,
      orderNumber: 'LMB-${id.toUpperCase()}',
      customerId: 'usr_customer_demo',
      customerName: 'Maria Santos',
      customerPhone: '09171234567',
      items: [item],
      subtotal: total,
      totalAmount: total,
      status: status,
      pickupLocation: PickupLocationModel.flagship,
      pickupTimeSlot: '2:00 PM',
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  void loginStaff() => users.setCurrentUser(users.getByEmail('barista.staff@lambac.com')?.user);
  void loginAdmin() => users.setCurrentUser(users.getByEmail('jmbautista0228@gmail.com')?.user);

  Future<List<OrderModel>> fetchOrders() async {
    final res = await orders.getOrders();
    return res.dataOrNull!.items;
  }

  Future<OrderStatus> persistedStatus(String id) async {
    final all = await fetchOrders();
    return all.firstWhere((o) => o.id == id).status;
  }

  Future<double> todaySales() async {
    final res = await MockAdminRemoteDataSource().getBusinessMetrics();
    return res.dataOrNull!.todaySales;
  }

  setUp(() {
    orders = MockOrderRemoteDataSource();
    orders.simulateSaleFailureForTesting = false;
    orders.clearOrdersForTesting();
    sales = MockSalesRemoteDataSource();
    sales.resetForTesting();
    users = MockUserDatabase();
    users.resetForTests();
    loginStaff();

    final staffUser = users.getByEmail('barista.staff@lambac.com')!.user;
    container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(staffUser),
      orderRemoteDataSourceProvider.overrideWithValue(orders),
      adminRemoteDataSourceProvider.overrideWithValue(MockAdminRemoteDataSource()),
      storageServiceProvider.overrideWithValue(InMemoryStorageService()),
    ]);
    // Keep the auto-dispose orders notifier alive like a mounted screen would
    container.listen(ordersNotifierProvider, (_, __) {});
  });

  tearDown(() {
    container.dispose();
    orders.simulateSaleFailureForTesting = false;
    orders.resetForTesting();
    sales.resetForTesting();
    users.resetForTests();
  });

  group('Order completion persistence', () {
    test('TEST 1/4: every transition is persisted; completed order is stamped, paid and leaves the active queue', () async {
      orders.setOrdersForTesting([makeOrder('p1', OrderStatus.pending)]);
      final controller = container.read(adminProductNotifierProvider);

      expect((await controller.advanceOrderStatus('p1', OrderStatus.preparing)).isSuccess, isTrue);
      expect(await persistedStatus('p1'), OrderStatus.preparing);

      expect((await controller.advanceOrderStatus('p1', OrderStatus.readyForPickup)).isSuccess, isTrue);
      expect(await persistedStatus('p1'), OrderStatus.readyForPickup);

      final done = await controller.advanceOrderStatus('p1', OrderStatus.completed);
      expect(done.isSuccess, isTrue);

      final reloaded = (await fetchOrders()).firstWhere((o) => o.id == 'p1');
      expect(reloaded.status, OrderStatus.completed);
      expect(reloaded.completedAt, isNotNull);
      expect(reloaded.paymentStatus, 'PAID');
      expect((await fetchOrders()).where((o) => o.status.isActive), isEmpty);
    });

    test('TEST 2: logout/login does not resurrect a completed order as NEW', () async {
      orders.setOrdersForTesting([makeOrder('p2', OrderStatus.readyForPickup)]);
      final controller = container.read(adminProductNotifierProvider);
      expect((await controller.advanceOrderStatus('p2', OrderStatus.completed)).isSuccess, isTrue);

      users.setCurrentUser(null); // logout
      loginAdmin(); // login as a different role

      expect(await persistedStatus('p2'), OrderStatus.completed);
      expect((await fetchOrders()).where((o) => o.status == OrderStatus.pending), isEmpty);
    });

    test('TEST 3: dashboard Today\'s Sales reflects the completed order and is never stale', () async {
      orders.setOrdersForTesting([makeOrder('p3', OrderStatus.readyForPickup, total: 500.0)]);

      // Prime the dashboard cache BEFORE completion (this is where the stale ₱0.00 came from)
      final before = (await container.read(businessMetricsProvider.future)).todaySales;

      final controller = container.read(adminProductNotifierProvider);
      expect((await controller.advanceOrderStatus('p3', OrderStatus.completed)).isSuccess, isTrue);

      final after = (await container.read(businessMetricsProvider.future)).todaySales;
      expect(after, closeTo(before + 500.0, 0.001));
    });

    test('TEST 5: duplicate completion (double click / retry) records exactly one sale', () async {
      orders.setOrdersForTesting([makeOrder('p5', OrderStatus.readyForPickup)]);
      final controller = container.read(adminProductNotifierProvider);

      final results = await Future.wait([
        controller.advanceOrderStatus('p5', OrderStatus.completed),
        controller.advanceOrderStatus('p5', OrderStatus.completed),
      ]);
      expect(results.every((r) => r.isSuccess), isTrue);

      // Late retry that reaches the backend again is also a safe no-op
      final retry = await orders.updateOrderStatus('p5', OrderStatus.completed);
      expect(retry.isSuccess, isTrue);

      expect(sales.getAllSales().where((s) => s.orderId == 'p5').length, 1);
    });

    test('TEST 6: failed completion rolls back - no success, status unchanged, no partial sale, no fake revenue', () async {
      orders.setOrdersForTesting([makeOrder('p6', OrderStatus.readyForPickup)]);
      final controller = container.read(adminProductNotifierProvider);
      final salesBefore = await todaySales();

      orders.simulateSaleFailureForTesting = true;
      final failed = await controller.advanceOrderStatus('p6', OrderStatus.completed);

      expect(failed.isFailure, isTrue);
      expect(await persistedStatus('p6'), OrderStatus.readyForPickup);
      expect(sales.getAllSales().where((s) => s.orderId == 'p6'), isEmpty);
      expect(await todaySales(), salesBefore);

      // Safe retry once the ledger recovers
      orders.simulateSaleFailureForTesting = false;
      expect((await controller.advanceOrderStatus('p6', OrderStatus.completed)).isSuccess, isTrue);
      expect(await persistedStatus('p6'), OrderStatus.completed);
      expect(sales.getAllSales().where((s) => s.orderId == 'p6').length, 1);
    });

    test('TEST 7: multiple orders - queue is B, C, D; completed A never returns as New', () async {
      orders.setOrdersForTesting([
        makeOrder('a', OrderStatus.readyForPickup),
        makeOrder('b', OrderStatus.preparing),
        makeOrder('c', OrderStatus.readyForPickup),
        makeOrder('d', OrderStatus.pending),
      ]);
      final controller = container.read(adminProductNotifierProvider);
      expect((await controller.advanceOrderStatus('a', OrderStatus.completed)).isSuccess, isTrue);

      final active = (await fetchOrders()).where((o) => o.status.isActive).map((o) => o.id).toSet();
      expect(active, {'b', 'c', 'd'});
      expect(await persistedStatus('a'), OrderStatus.completed);
    });

    test('TEST 8: sale is dated by completion time - old order completed today counts today, old sales do not', () async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      orders.setOrdersForTesting([makeOrder('old', OrderStatus.readyForPickup, createdAt: threeDaysAgo, total: 480.0)]);
      final before = await todaySales();

      final controller = container.read(adminProductNotifierProvider);
      expect((await controller.advanceOrderStatus('old', OrderStatus.completed)).isSuccess, isTrue);

      final sale = sales.getAllSales().firstWhere((s) => s.orderId == 'old');
      final now = DateTime.now();
      expect(sale.createdAt.year, now.year);
      expect(sale.createdAt.month, now.month);
      expect(sale.createdAt.day, now.day);
      expect(await todaySales(), closeTo(before + 480.0, 0.001));
    });

    test('Backend enforces workflow: cannot skip steps or reopen a completed order', () async {
      orders.setOrdersForTesting([
        makeOrder('s1', OrderStatus.preparing),
        makeOrder('s2', OrderStatus.completed),
      ]);

      final skip = await orders.updateOrderStatus('s1', OrderStatus.completed);
      expect(skip.isFailure, isTrue);
      expect(await persistedStatus('s1'), OrderStatus.preparing);
      expect(sales.getAllSales().where((s) => s.orderId == 's1'), isEmpty);

      final reopen = await orders.updateOrderStatus('s2', OrderStatus.pending);
      expect(reopen.isFailure, isTrue);
      expect(await persistedStatus('s2'), OrderStatus.completed);
    });
  });
}
