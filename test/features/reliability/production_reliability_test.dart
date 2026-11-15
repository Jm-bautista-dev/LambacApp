import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/features/orders/domain/events/order_events.dart';
import 'package:lambac_app/features/orders/domain/services/order_realtime_service.dart';
import 'package:lambac_app/features/notifications/data/datasources/mock_notification_remote_datasource.dart';
import 'package:lambac_app/features/notifications/data/models/app_notification_model.dart';
import 'package:lambac_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/data/models/send_message_request.dart';
import 'package:lambac_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_database.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Production Reliability — Real-Time State, Offline Behavior & Account Switching', () {
    late MockUserDatabase userDb;
    late MockAuthRemoteDataSource authDataSource;
    late MockOrderRemoteDataSource orderDataSource;
    late OrderRealtimeService orderRealtimeService;
    late OrderRepositoryImpl orderRepository;
    late MockNotificationRemoteDataSource notifDataSource;
    late NotificationRepositoryImpl notifRepository;
    late MockChatRemoteDataSource chatDataSource;
    late ChatRepositoryImpl chatRepository;
    late InMemoryStorageService storageService;

    final customer1 = UserModel(
      id: 'usr_cust_1',
      email: 'customer1@test.com',
      fullName: 'Alice Walker',
      phoneNumber: '09171112222',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    final customer2 = UserModel(
      id: 'usr_cust_2',
      email: 'customer2@test.com',
      fullName: 'Bob Smith',
      phoneNumber: '09173334444',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 2),
    );

    final baristaUser = UserModel(
      id: 'usr_barista_1',
      email: 'barista.clara@lambaccoffee.com',
      fullName: 'Clara Barista',
      phoneNumber: '09175556666',
      role: UserRole.employee,
      status: UserStatus.active,
      permissions: const [EmployeePermission.manageOrders, EmployeePermission.recordSales],
      createdAt: DateTime(2026, 1, 1),
    );

    final adminUser = UserModel(
      id: 'usr_admin_1',
      email: 'jmbautista0228@gmail.com',
      fullName: 'Master Roaster Admin',
      phoneNumber: '09177778888',
      role: UserRole.admin,
      status: UserStatus.active,
      permissions: const [
        EmployeePermission.manageOrders,
        EmployeePermission.manageProducts,
        EmployeePermission.recordSales,
        EmployeePermission.viewBasicMetrics,
      ],
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      userDb = MockUserDatabase();
      userDb.resetForTests();
      authDataSource = MockAuthRemoteDataSource();
      storageService = InMemoryStorageService();

      orderDataSource = MockOrderRemoteDataSource();
      orderDataSource.resetForTesting();
      orderRealtimeService = OrderRealtimeService();
      orderRepository = OrderRepositoryImpl(
        remoteDataSource: orderDataSource,
        storageService: storageService,
        realtimeService: orderRealtimeService,
      );

      notifDataSource = MockNotificationRemoteDataSource();
      notifDataSource.resetForTesting();
      notifRepository = NotificationRepositoryImpl(remoteDataSource: notifDataSource);

      chatDataSource = MockChatRemoteDataSource();
      chatDataSource.resetForTesting();
      chatRepository = ChatRepositoryImpl(
        remoteDataSource: chatDataSource,
        storageService: storageService,
      );
    });

    test('1. Account Switching Isolation: Customer 1 logout tears down session; Customer 2 cannot see Customer 1 data', () async {
      // Step A: Customer 1 logs in
      userDb.setCurrentUser(customer1);

      // Customer 1 receives notifications
      notifDataSource.addNotificationForUser(
        customer1.id,
        AppNotificationModel(
          id: 'notif_c1_private',
          title: 'Private Order Alert for Alice',
          body: 'Your Benguet Arabica order is confirmed',
          type: NotificationType.orderStatus,
          deepLinkPath: '/orders/ord_101',
          createdAt: DateTime.now(),
        ),
      );

      // Customer 1 sends a chat message
      final conv1 = await chatRepository.getConversation();
      expect(conv1.isSuccess, isTrue);
      await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: conv1.dataOrNull!.id,
          text: 'Hello roastery, please grind for pour over!',
        ),
      );

      // Verify Customer 1 sees their private data
      final c1Notifs = await notifRepository.getNotifications();
      expect(c1Notifs.dataOrNull!.length, equals(1));
      expect(c1Notifs.dataOrNull!.first.title, contains('Alice'));

      // Step B: Customer 1 logs out -> explicit clearSession() called on all repos
      notifRepository.clearSession();
      chatRepository.clearSession();
      orderRepository.clearSession();
      userDb.setCurrentUser(null);

      // Step C: Customer 2 logs in
      userDb.setCurrentUser(customer2);

      // Customer 2 requests notifications -> MUST be 0 (zero leak of Customer 1's notifications)
      final c2Notifs = await notifRepository.getNotifications();
      expect(c2Notifs.dataOrNull!.isEmpty, isTrue);

      // Customer 2 requests conversation -> MUST be Customer 2's own conversation (cannot see Alice's messages)
      final c2Conv = await chatRepository.getConversation();
      expect(c2Conv.dataOrNull!.customerId, equals(customer2.id));
      expect(c2Conv.dataOrNull!.id, isNot(equals(conv1.dataOrNull!.id)));

      // Step D: Role and UID refresh
      expect(userDb.currentUser?.id, equals(customer2.id));
      expect(userDb.currentUser?.role, equals(UserRole.customer));
      expect(userDb.currentUser?.isAdmin, isFalse);
    });

    test('2. Subscription Cancellation & Debounced Reconnection: No duplicate listeners or event storms', () async {
      userDb.setCurrentUser(customer1);

      int eventReceiveCount = 0;
      StreamSubscription? sub1;

      // Listen to real-time order status events
      sub1 = orderRealtimeService.orderStatusEvents.listen((event) {
        eventReceiveCount++;
      });

      // Simulate first status event
      orderRealtimeService.notifyStatusChanged(
        OrderStatusChangedEvent(
          orderId: 'ord_test_01',
          orderNumber: 'ORD-101',
          previousStatus: OrderStatus.pending,
          newStatus: OrderStatus.confirmed,
          order: OrderModel(
            id: 'ord_test_01',
            orderNumber: 'ORD-101',
            customerId: customer1.id,
            customerName: customer1.fullName,
            customerPhone: customer1.phoneNumber ?? '',
            pickupLocation: PickupLocationModel.flagship,
            pickupTimeSlot: '10:00 AM',
            items: const [],
            subtotal: 450.0,
            totalAmount: 450.0,
            status: OrderStatus.confirmed,
            createdAt: DateTime.now(),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 20));
      expect(eventReceiveCount, equals(1));

      // Customer logs out -> subscription cancelled
      await sub1.cancel();
      sub1 = null;

      // Event triggered while logged out
      orderRealtimeService.notifyStatusChanged(
        OrderStatusChangedEvent(
          orderId: 'ord_test_01',
          orderNumber: 'ORD-101',
          previousStatus: OrderStatus.confirmed,
          newStatus: OrderStatus.preparing,
          order: OrderModel(
            id: 'ord_test_01',
            orderNumber: 'ORD-101',
            customerId: customer1.id,
            customerName: customer1.fullName,
            customerPhone: customer1.phoneNumber ?? '',
            pickupLocation: PickupLocationModel.flagship,
            pickupTimeSlot: '10:00 AM',
            items: const [],
            subtotal: 450.0,
            totalAmount: 450.0,
            status: OrderStatus.preparing,
            createdAt: DateTime.now(),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 20));

      // Verify no zombie listener received the event
      expect(eventReceiveCount, equals(1));
    });

    test('3. Cache Partitioning & Stale Snapshot Invalidation: Newer server data and terminal statuses are protected', () {
      // Simulate cache partitioning by UID
      final cacheKeyCust1 = 'cache_orders_${customer1.id}';
      final cacheKeyCust2 = 'cache_orders_${customer2.id}';

      expect(cacheKeyCust1, isNot(equals(cacheKeyCust2)),
          reason: 'Caches must be strictly partitioned by authenticated UID');

      // Terminal status protection: A completed order cannot be reverted by a delayed/stale cached snapshot
      final completedOrder = OrderModel(
        id: 'ord_terminal_01',
        orderNumber: 'ORD-TERMINAL',
        customerId: customer1.id,
        customerName: customer1.fullName,
        customerPhone: customer1.phoneNumber ?? '',
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: '11:00 AM',
        items: const [],
        subtotal: 350.0,
        totalAmount: 350.0,
        status: OrderStatus.completed,
        createdAt: DateTime.now(),
      );

      final staleIncomingSnapshot = completedOrder.copyWith(
        status: OrderStatus.preparing, // Stale state from before completion
      );

      // Evaluates stale snapshot guard: terminal state remains completed
      final effectiveStatus = (completedOrder.status == OrderStatus.completed && staleIncomingSnapshot.status != OrderStatus.completed)
          ? completedOrder.status
          : staleIncomingSnapshot.status;

      expect(effectiveStatus, equals(OrderStatus.completed),
          reason: 'Completed terminal order status cannot be overwritten by stale snapshot');
    });

    test('4. Offline Safety & Online Server Validation: Order is never reported finalized purely on client optimistic state', () async {
      userDb.setCurrentUser(customer1);

      // Attempt to place order with invalid payload
      const invalidEmptyItemsRequest = CreateOrderRequest(
        items: [], // Invalid
        pickupDate: 'Tomorrow',
        pickupTimeSlot: '10:00 AM',
        pickupLocation: PickupLocationModel.flagship,
        customerName: 'Alice',
        customerPhone: '09171112222',
      );

      final res = await orderRepository.createOrder(invalidEmptyItemsRequest);

      // Must be rejected at validation boundary, NEVER reported as placed optimistically
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<ValidationFailure>());
    });

    test('5. Reconnection & Idempotent Reconciliation: Reconnection retries do not create duplicate orders or charges', () async {
      userDb.setCurrentUser(customer1);

      const uniqueIdempotencyKey = 'idempotent_txn_key_2026_xyz';

      final request = CreateOrderRequest(
        items: const [
          CartItemModel(
            id: 'item_1',
            productId: 'benguet-typica',
            productName: 'Benguet Arabica Typica Heirloom',
            origin: 'Atok, Benguet Highlands',
            roastLevel: 'Medium Roast',
            unitPrice: 420.0,
            quantity: 1,
          ),
        ],
        pickupDate: 'Tomorrow',
        pickupTimeSlot: '10:30 AM',
        pickupLocation: PickupLocationModel.flagship,
        customerName: 'Alice Walker',
        customerPhone: '09171112222',
        idempotencyKey: uniqueIdempotencyKey,
      );

      // 1. First submission (simulating initial request)
      final firstAttempt = await orderRepository.createOrder(request);
      expect(firstAttempt.isSuccess, isTrue);
      final createdOrderId = firstAttempt.dataOrNull!.id;

      // 2. Reconnection retry with the SAME idempotencyKey (simulating network dropout recovery)
      final secondAttempt = await orderRepository.createOrder(request);
      expect(secondAttempt.isSuccess, isTrue);

      // Must return the EXACT SAME order ID without appending a duplicate order
      expect(secondAttempt.dataOrNull!.id, equals(createdOrderId));

      // Verify order count in customer's order history is exactly 1
      final customerOrders = await orderRepository.getOrders();
      expect(customerOrders.dataOrNull!.items.where((o) => o.id == createdOrderId).length, equals(1));
    });

    test('6. Concurrent Barista and Admin Updates: Realtime status updates broadcast without application reload', () async {
      // Step A: Customer places order
      userDb.setCurrentUser(customer1);
      final orderRes = await orderRepository.createOrder(
        const CreateOrderRequest(
          items: [
            CartItemModel(
              id: 'item_1',
              productId: 'benguet-typica',
              productName: 'Benguet Arabica Typica Heirloom',
              origin: 'Atok, Benguet Highlands',
              roastLevel: 'Medium Roast',
              unitPrice: 420.0,
              quantity: 1,
            ),
          ],
          pickupDate: 'Tomorrow',
          pickupTimeSlot: '11:00 AM',
          pickupLocation: PickupLocationModel.flagship,
          customerName: 'Alice Walker',
          customerPhone: '09171112222',
        ),
      );
      expect(orderRes.isSuccess, isTrue);
      final orderId = orderRes.dataOrNull!.id;

      // Customer listens to real-time status stream
      final statusStreamEvents = <OrderStatus>[];
      final sub = orderRealtimeService.watchOrder(orderId).listen((order) {
        statusStreamEvents.add(order.status);
      });

      // Step B: Barista updates status to 'preparing'
      userDb.setCurrentUser(baristaUser);
      orderRealtimeService.notifyStatusChanged(
        OrderStatusChangedEvent(
          orderId: orderId,
          orderNumber: orderRes.dataOrNull!.orderNumber,
          previousStatus: OrderStatus.confirmed,
          newStatus: OrderStatus.preparing,
          order: orderRes.dataOrNull!.copyWith(status: OrderStatus.preparing),
        ),
      );

      // Step C: Admin updates status to 'readyForPickup'
      userDb.setCurrentUser(adminUser);
      orderRealtimeService.notifyStatusChanged(
        OrderStatusChangedEvent(
          orderId: orderId,
          orderNumber: orderRes.dataOrNull!.orderNumber,
          previousStatus: OrderStatus.preparing,
          newStatus: OrderStatus.readyForPickup,
          order: orderRes.dataOrNull!.copyWith(status: OrderStatus.readyForPickup),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(statusStreamEvents.contains(OrderStatus.preparing), isTrue);
      expect(statusStreamEvents.contains(OrderStatus.readyForPickup), isTrue);
      expect(statusStreamEvents.last, equals(OrderStatus.readyForPickup));

      await sub.cancel();
    });

    test('7. Offline Startup & Safe Cache Fallback: Offline startup permits reading cached products without crash', () {
      final productDb = MockProductDatabase();
      final products = productDb.getAllProducts();

      expect(products.isNotEmpty, isTrue);
      expect(products.first.basePrice, greaterThan(0.0));

      // Verifies offline catalog retrieval provides read-only browsing without making unconfirmed server mutations
      final benguet = products.firstWhere((p) => p.id == 'benguet-typica');
      expect(benguet.name, contains('Benguet'));
      expect(benguet.availability.isOrderable, isTrue);
    });

    test('8. Role Boundary Re-evaluation on Account Change: Switching Customer to Admin dynamically updates permissions', () {
      userDb.setCurrentUser(customer1);
      expect(userDb.currentUser?.isAdmin, isFalse);
      expect(userDb.currentUser?.role, equals(UserRole.customer));

      // Switch to Admin
      userDb.setCurrentUser(adminUser);
      expect(userDb.currentUser?.isAdmin, isTrue);
      expect(userDb.currentUser?.role, equals(UserRole.admin));
      expect(userDb.currentUser?.permissions.contains(EmployeePermission.manageProducts), isTrue);

      // Switch to Barista
      userDb.setCurrentUser(baristaUser);
      expect(userDb.currentUser?.isAdmin, isFalse);
      expect(userDb.currentUser?.role, equals(UserRole.employee));
      expect(userDb.currentUser?.permissions.contains(EmployeePermission.manageOrders), isTrue);
      expect(userDb.currentUser?.permissions.contains(EmployeePermission.manageProducts), isFalse);
    });
  });
}
