import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/orders/domain/services/order_realtime_service.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Lambac Roastery — Production Order Lifecycle & Real-Time Status Suite', () {
    late InMemoryStorageService storageService;
    late MockOrderRemoteDataSource orderDataSource;
    late OrderRepositoryImpl orderRepository;
    late MockAdminRemoteDataSource adminDataSource;
    late AdminRepositoryImpl adminRepository;
    late OrderRealtimeService realtimeService;

    const customerUser = UserModel(
      id: 'usr_customer_demo',
      email: 'customer@lambac.ph',
      fullName: 'Juan Dela Cruz',
      phoneNumber: '09171234567',
      role: UserRole.customer,
      status: UserStatus.active,
    );

    const staffUser = UserModel(
      id: 'usr_staff_demo',
      email: 'barista@lambac.ph',
      fullName: 'Staff Barista Carlos',
      phoneNumber: '09187654321',
      role: UserRole.employee,
      status: UserStatus.active,
    );

    const adminUser = UserModel(
      id: 'usr_admin_demo',
      email: 'admin@lambac.ph',
      fullName: 'Admin Roaster Maria',
      phoneNumber: '09179998888',
      role: UserRole.admin,
      status: UserStatus.active,
    );

    setUp(() {
      storageService = InMemoryStorageService();
      orderDataSource = MockOrderRemoteDataSource();
      realtimeService = OrderRealtimeService();
      orderRepository = OrderRepositoryImpl(
        remoteDataSource: orderDataSource,
        storageService: storageService,
        realtimeService: realtimeService,
      );
      adminDataSource = MockAdminRemoteDataSource();
      adminRepository = AdminRepositoryImpl(remoteDataSource: adminDataSource);
    });

    test('Full 11-Step Production Lifecycle: Customer Order -> Staff Preparing -> Barista Prepared -> Admin Ready -> Picked Up / Completed', () async {
      // -----------------------------------------------------------------------
      // Step 1: Customer places pickup order with Pickup Date, Time & Pay at Counter
      // -----------------------------------------------------------------------
      MockUserDatabase().setCurrentUser(customerUser);

      final orderRequest = CreateOrderRequest(
        customerName: customerUser.fullName,
        customerPhone: customerUser.phoneNumber ?? '09171234567',
        items: const [
          CartItemModel(
            id: 'cart_item_apo',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            origin: 'Davao del Sur',
            roastLevel: 'Medium Roast',
            unitPrice: 480.0,
            quantity: 2,
          ),
        ],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Tomorrow, Sep 25',
        pickupTimeSlot: '10:00 AM - 10:30 AM',
        paymentMethod: 'Pay at Counter',
        notes: 'Please pack in paper tote.',
      );

      final createResult = await orderRepository.createOrder(orderRequest);
      expect(createResult.isSuccess, isTrue);
      final createdOrder = createResult.dataOrNull!;

      expect(createdOrder.orderNumber, startsWith('LMB-'));
      expect(createdOrder.status, equals(OrderStatus.pending));
      expect(createdOrder.pickupDate, equals('Tomorrow, Sep 25'));
      expect(createdOrder.pickupTimeSlot, equals('10:00 AM - 10:30 AM'));
      expect(createdOrder.paymentMethod, equals('Pay at Counter'));
      expect(createdOrder.paymentStatus, equals('UNPAID'));
      expect(createdOrder.isUnpaid, isTrue);
      expect(createdOrder.isPaid, isFalse);
      expect(createdOrder.totalAmount, equals(960.0));

      final orderId = createdOrder.id;

      // -----------------------------------------------------------------------
      // Customer subscribes to real-time status stream (0ms event-driven updates)
      // -----------------------------------------------------------------------
      final customerStatusEvents = <OrderStatus>[];
      final streamSubscription = orderRepository.watchOrder(orderId).listen((order) {
        customerStatusEvents.add(order.status);
      });

      // -----------------------------------------------------------------------
      // Step 2 & 3: Order appears in internal operations; Staff marks as PREPARING
      // -----------------------------------------------------------------------
      MockUserDatabase().setCurrentUser(staffUser);

      final prepResult = await orderRepository.updateOrderStatus(orderId, OrderStatus.preparing);
      expect(prepResult.isSuccess, isTrue);
      expect(prepResult.dataOrNull!.status, equals(OrderStatus.preparing));

      // Wait a tick for event broadcast delivery
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(customerStatusEvents.last, equals(OrderStatus.preparing),
          reason: 'Customer must receive PREPARING status in real-time without refreshing.');

      // -----------------------------------------------------------------------
      // Step 5 & 6: Barista finishes roast preparation and marks as PREPARED
      // -----------------------------------------------------------------------
      final preparedResult = await orderRepository.updateOrderStatus(orderId, OrderStatus.prepared);
      expect(preparedResult.isSuccess, isTrue);
      expect(preparedResult.dataOrNull!.status, equals(OrderStatus.prepared));

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(customerStatusEvents.last, equals(OrderStatus.prepared),
          reason: 'Customer must receive PREPARED status in real-time.');

      // -----------------------------------------------------------------------
      // Step 7 & 8: Admin marks as READY FOR PICKUP
      // -----------------------------------------------------------------------
      MockUserDatabase().setCurrentUser(adminUser);

      // Admin uses AdminRepository which shares the single source of truth
      final readyResult = await adminRepository.updateOrderStatus(orderId, OrderStatus.readyForPickup);
      expect(readyResult.isSuccess, isTrue);
      expect(readyResult.dataOrNull!.status, equals(OrderStatus.readyForPickup));

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(customerStatusEvents.last, equals(OrderStatus.readyForPickup),
          reason: 'Customer must receive READY FOR PICKUP status in real-time.');

      // -----------------------------------------------------------------------
      // Step 9, 10 & 11: Customer arrives at counter, pays at counter, Staff/Admin completes
      // -----------------------------------------------------------------------
      final completeResult = await adminRepository.updateOrderStatus(orderId, OrderStatus.completed);
      expect(completeResult.isSuccess, isTrue);
      final completedOrder = completeResult.dataOrNull!;
      expect(completedOrder.status, equals(OrderStatus.completed));
      expect(completedOrder.paymentMethod, equals('Pay at Counter'));
      expect(completedOrder.paymentStatus, equals('PAID'));
      expect(completedOrder.isPaid, isTrue);
      expect(completedOrder.isUnpaid, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(customerStatusEvents.last, equals(OrderStatus.completed),
          reason: 'Customer must receive COMPLETED status in real-time.');

      // Verify sequence of statuses received by customer in real-time
      expect(customerStatusEvents, equals([
        OrderStatus.preparing,
        OrderStatus.prepared,
        OrderStatus.readyForPickup,
        OrderStatus.completed,
      ]));

      await streamSubscription.cancel();
    });

    test('Status Validation prevents invalid backwards or illegal transitions', () async {
      MockUserDatabase().setCurrentUser(customerUser);

      final createResult = await orderRepository.createOrder(
        const CreateOrderRequest(
          customerName: 'Juan Dela Cruz',
          customerPhone: '09171234567',
          items: [
            CartItemModel(
              id: 'cart_item_test',
              productId: 'benguet-typica',
              productName: 'Benguet Arabica',
              origin: 'Benguet Highlands',
              roastLevel: 'Medium Roast',
              unitPrice: 420.0,
              quantity: 1,
            ),
          ],
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'Pay at Counter',
        ),
      );

      final order = createResult.dataOrNull!;
      final orderId = order.id;

      MockUserDatabase().setCurrentUser(staffUser);

      // 1. Advance to Ready for Pickup
      await orderRepository.updateOrderStatus(orderId, OrderStatus.preparing);
      await orderRepository.updateOrderStatus(orderId, OrderStatus.prepared);
      final readyResult = await orderRepository.updateOrderStatus(orderId, OrderStatus.readyForPickup);
      expect(readyResult.isSuccess, isTrue);

      // 2. Attempt illegal transition: READY FOR PICKUP -> PREPARING (must fail)
      final illegalBackwards = await orderRepository.updateOrderStatus(orderId, OrderStatus.preparing);
      expect(illegalBackwards.isFailure, isTrue);
      expect(illegalBackwards.failureOrNull, isA<ValidationFailure>());

      // 3. Attempt illegal transition: READY FOR PICKUP -> PENDING (must fail)
      final illegalPending = await orderRepository.updateOrderStatus(orderId, OrderStatus.pending);
      expect(illegalPending.isFailure, isTrue);
      expect(illegalPending.failureOrNull, isA<ValidationFailure>());

      // 4. Mark Completed
      final completeResult = await orderRepository.updateOrderStatus(orderId, OrderStatus.completed);
      expect(completeResult.isSuccess, isTrue);

      // 5. Attempt transition from completed (terminal state) to anything else (must fail)
      final afterCompleted = await orderRepository.updateOrderStatus(orderId, OrderStatus.readyForPickup);
      expect(afterCompleted.isFailure, isTrue);
      expect(afterCompleted.failureOrNull, isA<ValidationFailure>());
    });

    test('RBAC Authorization: Customer cannot manipulate order status', () async {
      MockUserDatabase().setCurrentUser(customerUser);

      final result = await orderRepository.updateOrderStatus('ord_lmb_1082', OrderStatus.completed);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });

    test('Fallback Polling and Backend Source of Truth synchronization', () async {
      // Direct inspection of backend state matches getOrderById
      MockUserDatabase().setCurrentUser(staffUser);
      final initialFetch = await orderRepository.getOrderById('ord_lmb_1082');
      expect(initialFetch.isSuccess, isTrue);
      final initialOrder = initialFetch.dataOrNull!;

      // Change status to preparing (if not already) or next valid state
      final target = initialOrder.status == OrderStatus.preparing
          ? OrderStatus.prepared
          : OrderStatus.preparing;

      final updateRes = await orderRepository.updateOrderStatus('ord_lmb_1082', target);
      expect(updateRes.isSuccess, isTrue);

      // Re-fetch proves backend is the undisputed source of truth
      final syncFetch = await orderRepository.getOrderById('ord_lmb_1082');
      expect(syncFetch.isSuccess, isTrue);
      expect(syncFetch.dataOrNull!.status, equals(target));
    });
  });
}
