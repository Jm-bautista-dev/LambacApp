import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/theme/app_theme.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:lambac_app/features/admin/presentation/screens/staff_operations_screen.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/domain/events/order_events.dart';
import 'package:lambac_app/features/orders/domain/services/order_queue_service.dart';
import 'package:lambac_app/features/orders/domain/services/order_realtime_service.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_database.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  late MockOrderRemoteDataSource orderRemoteDataSource;
  late MockUserDatabase userDatabase;
  late OrderQueueService queueService;

  final sampleItem = OrderItemModel(
    id: 'item_sample_1',
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
    required String orderNumber,
    required OrderStatus status,
    String pickupDate = 'Today',
    String pickupTimeSlot = '2:00 PM',
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      customerId: 'usr_customer_demo',
      customerName: 'Maria Santos',
      customerPhone: '09171234567',
      items: [sampleItem],
      subtotal: 480.0,
      totalAmount: 480.0,
      status: status,
      pickupLocation: PickupLocationModel.flagship,
      pickupDate: pickupDate,
      pickupTimeSlot: pickupTimeSlot,
      paymentMethod: 'Pay at Counter',
      paymentStatus: status == OrderStatus.completed ? 'PAID' : 'UNPAID',
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  void loginStaff() {
    final staff = userDatabase.getByEmail('barista.staff@lambac.com')?.user;
    userDatabase.setCurrentUser(staff);
  }

  void loginAdmin() {
    final admin = userDatabase.getByEmail('jmbautista0228@gmail.com')?.user;
    userDatabase.setCurrentUser(admin);
  }

  void loginCustomer() {
    final customer = userDatabase.getByEmail('coffee.lover@lambac.com')?.user;
    userDatabase.setCurrentUser(customer);
  }

  setUp(() {
    orderRemoteDataSource = MockOrderRemoteDataSource();
    orderRemoteDataSource.clearOrdersForTesting();
    userDatabase = MockUserDatabase();
    userDatabase.resetForTests();
    loginStaff();
    queueService = OrderQueueService();
    MockProductDatabase().resetForTesting();
  });

  tearDown(() {
    orderRemoteDataSource.resetForTesting();
    userDatabase.resetForTests();
  });

  Widget buildTestApp(Widget child, {ProviderContainer? customContainer}) {
    return customContainer != null
        ? UncontrolledProviderScope(
            container: customContainer,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: child,
            ),
          )
        : ProviderScope(
            overrides: [
              currentUserProvider.overrideWith((ref) => MockUserDatabase().currentUser),
              orderRemoteDataSourceProvider.overrideWithValue(orderRemoteDataSource),
              adminRemoteDataSourceProvider.overrideWithValue(
                MockAdminRemoteDataSource(orderRemoteDataSource: orderRemoteDataSource),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: child,
            ),
          );
  }

  group('Lambac Coffee Roastery — Production-Ready Order Queue Suite', () {
    // ------------------------------------------------------------------------
    // TEST 1 — No Active Orders (Completed/Cancelled only)
    // ------------------------------------------------------------------------
    test('TEST 1: When DB contains only completed/cancelled orders, active count is strictly 0', () {
      final orders = [
        createTestOrder(id: 'ord_1', orderNumber: 'LMB-101', status: OrderStatus.completed),
        createTestOrder(id: 'ord_2', orderNumber: 'LMB-102', status: OrderStatus.completed),
        createTestOrder(id: 'ord_3', orderNumber: 'LMB-103', status: OrderStatus.cancelled),
      ];
      orderRemoteDataSource.setOrdersForTesting(orders);

      final metrics = queueService.calculateMetrics(orders);
      expect(metrics.activeCount, equals(0));
      expect(metrics.completedCount, equals(2));
      expect(orders.where((o) => o.status.isActive).length, equals(0));
    });

    // ------------------------------------------------------------------------
    // TEST 2 — One New Order Dynamically Enters Queue
    // ------------------------------------------------------------------------
    test('TEST 2: Placing a new pickup order increments active queue count to 1', () async {
      loginCustomer();
      final request = CreateOrderRequest(
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
        items: const [
          CartItemModel(
            id: 'cart_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            origin: 'Davao del Sur',
            roastLevel: 'Light-Medium Roast',
            quantity: 1,
            unitPrice: 480.0,
          ),
        ],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Tomorrow',
        pickupTimeSlot: '10:00 AM',
        paymentMethod: 'Pay at Counter',
      );

      final result = await orderRemoteDataSource.createOrder(request);
      expect(result.isSuccess, isTrue);

      final allOrders = orderRemoteDataSource.allOrders;
      final activeOrders = allOrders.where((o) => o.status.isActive).toList();
      expect(activeOrders.length, equals(1));
      expect(activeOrders.first.orderNumber, startsWith('LMB-'));
      expect(activeOrders.first.status, equals(OrderStatus.pending));
    });

    // ------------------------------------------------------------------------
    // TEST 3 — Multiple Orders Status Partitioning
    // ------------------------------------------------------------------------
    test('TEST 3: Active queue strictly filters Pending, Preparing, Ready (Excludes Completed & Cancelled)', () {
      final orders = [
        createTestOrder(id: 'ord_p1', orderNumber: 'LMB-201', status: OrderStatus.pending),
        createTestOrder(id: 'ord_p2', orderNumber: 'LMB-202', status: OrderStatus.preparing),
        createTestOrder(id: 'ord_p3', orderNumber: 'LMB-203', status: OrderStatus.readyForPickup),
        createTestOrder(id: 'ord_p4', orderNumber: 'LMB-204', status: OrderStatus.completed),
        createTestOrder(id: 'ord_p5', orderNumber: 'LMB-205', status: OrderStatus.cancelled),
      ];
      orderRemoteDataSource.setOrdersForTesting(orders);

      final activeOrders = orders.where((o) => o.status.isActive).toList();
      expect(activeOrders.length, equals(3));
      expect(activeOrders.map((o) => o.status), containsAll([
        OrderStatus.pending,
        OrderStatus.preparing,
        OrderStatus.readyForPickup,
      ]));
    });

    // ------------------------------------------------------------------------
    // TEST 4 — Complete an Order (Active count decreases by 1)
    // ------------------------------------------------------------------------
    test('TEST 4: Advancing an order from Preparing to Completed removes it from active queue', () async {
      loginStaff();
      final preparingOrder = createTestOrder(id: 'ord_prep_1', orderNumber: 'LMB-301', status: OrderStatus.preparing);
      orderRemoteDataSource.setOrdersForTesting([preparingOrder]);

      expect(orderRemoteDataSource.allOrders.where((o) => o.status.isActive).length, equals(1));

      // Advance Preparing -> Prepared -> Ready -> Completed
      await orderRemoteDataSource.updateOrderStatus('ord_prep_1', OrderStatus.prepared);
      await orderRemoteDataSource.updateOrderStatus('ord_prep_1', OrderStatus.readyForPickup);
      await orderRemoteDataSource.updateOrderStatus('ord_prep_1', OrderStatus.completed);

      final activeRemaining = orderRemoteDataSource.allOrders.where((o) => o.status.isActive).length;
      expect(activeRemaining, equals(0));
    });

    // ------------------------------------------------------------------------
    // TEST 5 — Cancel an Order (Active count decreases by 1)
    // ------------------------------------------------------------------------
    test('TEST 5: Cancelling an active order immediately decrements active queue count', () async {
      loginStaff();
      final pendingOrder = createTestOrder(id: 'ord_canc_1', orderNumber: 'LMB-401', status: OrderStatus.pending);
      orderRemoteDataSource.setOrdersForTesting([pendingOrder]);

      expect(orderRemoteDataSource.allOrders.where((o) => o.status.isActive).length, equals(1));

      await orderRemoteDataSource.cancelOrder('ord_canc_1');

      final activeRemaining = orderRemoteDataSource.allOrders.where((o) => o.status.isActive).length;
      expect(activeRemaining, equals(0));
    });

    // ------------------------------------------------------------------------
    // TEST 6 — Ready for Pickup Remains in Active Queue
    // ------------------------------------------------------------------------
    test('TEST 6: Ready for Pickup orders remain in active queue until customer pickup handover', () async {
      loginStaff();
      final order = createTestOrder(id: 'ord_ready_1', orderNumber: 'LMB-501', status: OrderStatus.prepared);
      orderRemoteDataSource.setOrdersForTesting([order]);

      await orderRemoteDataSource.updateOrderStatus('ord_ready_1', OrderStatus.readyForPickup);

      final active = orderRemoteDataSource.allOrders.where((o) => o.status.isActive).toList();
      expect(active.length, equals(1));
      expect(active.first.status, equals(OrderStatus.readyForPickup));
    });

    // ------------------------------------------------------------------------
    // TEST 7 — Customer Handover & Payment Completion Leaves Active Queue
    // ------------------------------------------------------------------------
    test('TEST 7: Handing over Ready order to customer completes and removes from active queue', () async {
      loginStaff();
      final order = createTestOrder(id: 'ord_handover_1', orderNumber: 'LMB-601', status: OrderStatus.readyForPickup);
      orderRemoteDataSource.setOrdersForTesting([order]);

      expect(orderRemoteDataSource.allOrders.where((o) => o.status.isActive).length, equals(1));

      await orderRemoteDataSource.updateOrderStatus('ord_handover_1', OrderStatus.completed);

      final active = orderRemoteDataSource.allOrders.where((o) => o.status.isActive).toList();
      expect(active.length, equals(0));
      expect(orderRemoteDataSource.allOrders.first.paymentStatus, equals('PAID'));
    });

    // ------------------------------------------------------------------------
    // TEST 8 — Admin vs Barista Consistency
    // ------------------------------------------------------------------------
    test('TEST 8: Admin and Barista see consistent underlying order states and counts', () async {
      final activeOrder = createTestOrder(id: 'ord_cons_1', orderNumber: 'LMB-701', status: OrderStatus.preparing);
      final completedOrder = createTestOrder(id: 'ord_cons_2', orderNumber: 'LMB-702', status: OrderStatus.completed);
      orderRemoteDataSource.setOrdersForTesting([activeOrder, completedOrder]);

      // Staff query
      loginStaff();
      final staffOrdersRes = await orderRemoteDataSource.getOrders();
      expect(staffOrdersRes.dataOrNull!.items.where((o) => o.status.isActive).length, equals(1));

      // Admin query
      loginAdmin();
      final adminOrdersRes = await orderRemoteDataSource.getOrders();
      expect(adminOrdersRes.dataOrNull!.items.where((o) => o.status.isActive).length, equals(1));
      expect(adminOrdersRes.dataOrNull!.items.first.id, equals(staffOrdersRes.dataOrNull!.items.first.id));
    });

    // ------------------------------------------------------------------------
    // TEST 9 — Filter Independence (UI filter does not corrupt active badge)
    // ------------------------------------------------------------------------
    testWidgets('TEST 9: Changing UI tabs on StaffOperationsScreen does NOT alter global metrics/badge', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final orders = [
        createTestOrder(id: 'ord_f1', orderNumber: 'LMB-801', status: OrderStatus.pending),
        createTestOrder(id: 'ord_f2', orderNumber: 'LMB-802', status: OrderStatus.preparing),
        createTestOrder(id: 'ord_f3', orderNumber: 'LMB-803', status: OrderStatus.readyForPickup),
        createTestOrder(id: 'ord_f4', orderNumber: 'LMB-804', status: OrderStatus.completed),
      ];
      orderRemoteDataSource.setOrdersForTesting(orders);

      await tester.pumpWidget(buildTestApp(const StaffOperationsScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Header should show 3 Active in Queue
      expect(find.text('Flagship Store • 3 Active in Queue'), findsOneWidget);

      // Tap 'Ready' filter tab
      final readyChip = find.text('Ready (1)');
      expect(readyChip, findsOneWidget);
      await tester.tap(readyChip);
      await tester.pump(const Duration(milliseconds: 100));

      // Header remains 3 Active in Queue (unaffected by tab filter!)
      expect(find.text('Flagship Store • 3 Active in Queue'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // TEST 10 — Real-Time Event Sync across Queue Notifier
    // ------------------------------------------------------------------------
    test('TEST 10: OrdersNotifier active count updates in real time upon new order placement and completion', () async {
      loginStaff();
      orderRemoteDataSource.clearOrdersForTesting();

      final staffUser = userDatabase.getByEmail('barista.staff@lambac.com')!.user;
      final inMemoryStorage = InMemoryStorageService();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(staffUser),
          orderRemoteDataSourceProvider.overrideWithValue(orderRemoteDataSource),
          storageServiceProvider.overrideWithValue(inMemoryStorage),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(ordersNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(ordersNotifierProvider.notifier);
      await notifier.loadOrders();

      expect(container.read(ordersNotifierProvider).activeOrders.length, equals(0));

      // Simulate order placed in real-time
      final newOrder = createTestOrder(id: 'ord_rt_1', orderNumber: 'LMB-901', status: OrderStatus.pending);
      OrderRealtimeService().notifyOrderCreated(OrderCreatedEvent(order: newOrder));

      // Wait a microtask for stream event delivery
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(ordersNotifierProvider).activeOrders.length, equals(1));

      // Simulate status changed to completed in real-time
      final completedOrder = newOrder.copyWith(status: OrderStatus.completed);
      OrderRealtimeService().notifyStatusChanged(
        OrderStatusChangedEvent(
          orderId: newOrder.id,
          orderNumber: newOrder.orderNumber,
          previousStatus: OrderStatus.pending,
          newStatus: OrderStatus.completed,
          order: completedOrder,
          updatedByRole: 'staff',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(ordersNotifierProvider).activeOrders.length, equals(0));
    });

    // ------------------------------------------------------------------------
    // TEST 11 — Order Queue Urgency & Prioritization
    // ------------------------------------------------------------------------
    test('TEST 11: Queue prioritizes Overdue orders first, followed by earliest pickup time', () {
      final now = DateTime(2026, 10, 5, 14, 0); // 2:00 PM

      final overdueOrder = createTestOrder(
        id: 'ord_overdue',
        orderNumber: 'LMB-OD1',
        status: OrderStatus.preparing,
        pickupDate: 'Today',
        pickupTimeSlot: '1:30 PM', // 30 min ago
        createdAt: now.subtract(const Duration(hours: 1)),
      );

      final soonOrder = createTestOrder(
        id: 'ord_soon',
        orderNumber: 'LMB-SN1',
        status: OrderStatus.pending,
        pickupDate: 'Today',
        pickupTimeSlot: '2:15 PM', // in 15 mins
        createdAt: now.subtract(const Duration(minutes: 10)),
      );

      final laterOrder = createTestOrder(
        id: 'ord_later',
        orderNumber: 'LMB-LT1',
        status: OrderStatus.pending,
        pickupDate: 'Today',
        pickupTimeSlot: '6:00 PM', // in 4 hours
        createdAt: now.subtract(const Duration(minutes: 5)),
      );

      final sorted = queueService.sortQueueOrders([laterOrder, overdueOrder, soonOrder], now);

      expect(sorted[0].id, equals('ord_overdue'));
      expect(sorted[1].id, equals('ord_soon'));
      expect(sorted[2].id, equals('ord_later'));

      expect(queueService.getOrderUrgency(overdueOrder, now), equals(OrderUrgency.overdue));
      expect(queueService.getOrderUrgency(soonOrder, now), equals(OrderUrgency.dueSoon));
      expect(queueService.getOrderUrgency(laterOrder, now), equals(OrderUrgency.upcoming));
    });

    // ------------------------------------------------------------------------
    // TEST 12 — Large Historical Completed Orders do not Inflate Active Queue
    // ------------------------------------------------------------------------
    test('TEST 12: 100 completed historical orders do not inflate the active queue count', () {
      final historicalList = List.generate(
        100,
        (i) => createTestOrder(
          id: 'hist_$i',
          orderNumber: 'LMB-HIST-$i',
          status: OrderStatus.completed,
          pickupDate: 'Aug 1, 2026',
          pickupTimeSlot: '10:00 AM',
        ),
      );

      final activeOrder = createTestOrder(
        id: 'active_1',
        orderNumber: 'LMB-ACTIVE-1',
        status: OrderStatus.preparing,
      );

      final fullDb = [activeOrder, ...historicalList];
      orderRemoteDataSource.setOrdersForTesting(fullDb);

      final metrics = queueService.calculateMetrics(fullDb);
      expect(metrics.activeCount, equals(1));
      expect(metrics.completedCount, equals(100));
      expect(metrics.totalCount, equals(101));
    });
  });
}
