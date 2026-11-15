import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/network/result.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:lambac_app/features/admin/presentation/screens/staff_operations_screen.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:lambac_app/features/cart/presentation/screens/checkout_screen.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lambac Coffee Roastery — Pickup Payment Workflow & 10-Step Acceptance Criteria', () {
    late InMemoryStorageService storageService;
    late MockOrderRemoteDataSource orderRemoteDataSource;
    late OrderRepositoryImpl orderRepository;
    late MockAdminRemoteDataSource adminRemoteDataSource;
    late AdminRepositoryImpl adminRepository;

    final customerUser = UserModel(
      id: 'usr_customer_demo',
      email: 'customer@lambac.ph',
      fullName: 'Kenji Takahashi',
      phoneNumber: '09171234567',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );

    final staffUser = UserModel(
      id: 'usr_staff_bartender',
      email: 'barista@lambac.ph',
      fullName: 'Marco Barista',
      phoneNumber: '09181234567',
      role: UserRole.staff,
      createdAt: DateTime.now(),
    );

    final adminUser = UserModel(
      id: 'usr_admin_owner',
      email: 'admin@lambac.ph',
      fullName: 'Master Roaster',
      phoneNumber: '09191234567',
      role: UserRole.admin,
      createdAt: DateTime.now(),
    );

    setUp(() {
      storageService = InMemoryStorageService();
      orderRemoteDataSource = MockOrderRemoteDataSource();
      orderRepository = OrderRepositoryImpl(
        remoteDataSource: orderRemoteDataSource,
        storageService: storageService,
      );
      adminRemoteDataSource = MockAdminRemoteDataSource();
      adminRepository = AdminRepositoryImpl(
        remoteDataSource: adminRemoteDataSource,
      );
    });

    tearDown(() {
      MockUserDatabase().setCurrentUser(null);
    });

    test('Strict 10-Step Pickup Payment Lifecycle Acceptance Test', () async {
      // =======================================================================
      // Step 1: Customer creates pickup order
      // =======================================================================
      MockUserDatabase().setCurrentUser(customerUser);

      final orderRequest = CreateOrderRequest(
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
        customerEmail: 'customer@lambac.ph',
        items: const [
          CartItemModel(
            id: 'item_wf_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            origin: 'Davao del Sur',
            roastLevel: 'Light Roast',
            unitPrice: 480.0,
            quantity: 2,
          ),
        ],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Tomorrow, Sep 25',
        pickupTimeSlot: '10:00 AM - 10:30 AM',
        paymentMethod: 'Pay at Counter',
        notes: 'Less ice please',
      );

      final createResult = await orderRepository.createOrder(orderRequest);
      expect(createResult.isSuccess, isTrue);

      final order = createResult.dataOrNull!;
      final orderId = order.id;

      // =======================================================================
      // Step 2: Payment is strictly UNPAID upon creation
      // =======================================================================
      expect(order.paymentMethod, equals('Pay at Counter'));
      expect(order.paymentStatus, equals('UNPAID'), reason: 'Order placement must NEVER treat order as paid.');
      expect(order.isUnpaid, isTrue);
      expect(order.isPaid, isFalse);
      expect(order.status, equals(OrderStatus.pending));

      // =======================================================================
      // Step 3: Staff prepares order
      // =======================================================================
      MockUserDatabase().setCurrentUser(staffUser);

      final prepResult = await orderRepository.updateOrderStatus(orderId, OrderStatus.preparing);
      expect(prepResult.isSuccess, isTrue);
      final preparingOrder = prepResult.dataOrNull!;
      expect(preparingOrder.status, equals(OrderStatus.preparing));
      // Verify payment status remains UNPAID during preparation
      expect(preparingOrder.paymentStatus, equals('UNPAID'));
      expect(preparingOrder.isUnpaid, isTrue);

      final preparedResult = await orderRepository.updateOrderStatus(orderId, OrderStatus.prepared);
      expect(preparedResult.isSuccess, isTrue);
      final preparedOrder = preparedResult.dataOrNull!;
      expect(preparedOrder.status, equals(OrderStatus.prepared));
      expect(preparedOrder.paymentStatus, equals('UNPAID'));
      expect(preparedOrder.isUnpaid, isTrue);

      // =======================================================================
      // Step 4: Order becomes READY FOR PICKUP
      // =======================================================================
      final readyResult = await orderRepository.updateOrderStatus(orderId, OrderStatus.readyForPickup);
      expect(readyResult.isSuccess, isTrue);
      final readyOrder = readyResult.dataOrNull!;
      expect(readyOrder.status, equals(OrderStatus.readyForPickup));

      // =======================================================================
      // Step 5: Payment remains UNPAID when Ready for Pickup
      // =======================================================================
      expect(readyOrder.paymentStatus, equals('UNPAID'),
          reason: 'Do NOT automatically mark order paid simply because staff marked it Ready for Pickup.');
      expect(readyOrder.isUnpaid, isTrue);
      expect(readyOrder.isPaid, isFalse);

      // =======================================================================
      // Step 6: Customer arrives at counter
      // Staff verifies order number, customer, ordered products, total (₱960.00)
      // =======================================================================
      expect(readyOrder.totalAmount, equals(960.0));
      expect(readyOrder.customerName, equals('Kenji Takahashi'));

      // =======================================================================
      // Step 7: Staff records counter payment
      // =======================================================================
      final payResult = await orderRepository.updatePaymentStatus(orderId, PaymentStatus.paid);
      expect(payResult.isSuccess, isTrue);
      final paidOrder = payResult.dataOrNull!;

      // =======================================================================
      // Step 8: Payment becomes PAID (while order status remains Ready for Pickup)
      // =======================================================================
      expect(paidOrder.paymentStatus, equals('PAID'));
      expect(paidOrder.isPaid, isTrue);
      expect(paidOrder.isUnpaid, isFalse);
      expect(paidOrder.status, equals(OrderStatus.readyForPickup),
          reason: 'Recording payment updates payment status while preserving pickup stage until physical handover.');

      // =======================================================================
      // Step 9 & 10: Order is handed to customer -> Order becomes COMPLETED
      // =======================================================================
      final completeResult = await orderRepository.updateOrderStatus(orderId, OrderStatus.completed);
      expect(completeResult.isSuccess, isTrue);
      final completedOrder = completeResult.dataOrNull!;

      expect(completedOrder.status, equals(OrderStatus.completed));
      expect(completedOrder.paymentStatus, equals('PAID'));
      expect(completedOrder.isPaid, isTrue);
      expect(completedOrder.isUnpaid, isFalse);
    });

    test('Edge Case: Customer does not pick up — Order never automatically becomes paid', () async {
      MockUserDatabase().setCurrentUser(customerUser);

      final orderRequest = CreateOrderRequest(
        customerName: 'No Show Customer',
        customerPhone: '09170000000',
        items: const [
          CartItemModel(
            id: 'item_no_show',
            productId: 'benguet-typica',
            productName: 'Benguet Arabica Typica',
            origin: 'Benguet',
            roastLevel: 'Medium Roast',
            unitPrice: 420.0,
            quantity: 1,
          ),
        ],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Tomorrow, Sep 25',
        pickupTimeSlot: '10:00 AM - 10:30 AM',
      );

      final createRes = await orderRepository.createOrder(orderRequest);
      expect(createRes.isSuccess, isTrue);
      final orderId = createRes.dataOrNull!.id;

      MockUserDatabase().setCurrentUser(staffUser);
      await orderRepository.updateOrderStatus(orderId, OrderStatus.preparing);
      await orderRepository.updateOrderStatus(orderId, OrderStatus.prepared);
      final readyRes = await orderRepository.updateOrderStatus(orderId, OrderStatus.readyForPickup);

      final order = readyRes.dataOrNull!;
      expect(order.status, equals(OrderStatus.readyForPickup));
      expect(order.paymentStatus, equals('UNPAID'),
          reason: 'Order must stay UNPAID if customer never arrives.');
      expect(order.isUnpaid, isTrue);
    });

    test('Edge Case: Staff cancels an order — Payment remains UNPAID', () async {
      MockUserDatabase().setCurrentUser(customerUser);

      final orderRequest = CreateOrderRequest(
        customerName: 'Cancel Test',
        customerPhone: '09170000001',
        items: const [
          CartItemModel(
            id: 'item_cancel',
            productId: 'tokyo-blend',
            productName: 'Tokyo Blend',
            origin: 'Lambac Blend',
            roastLevel: 'Dark Roast',
            unitPrice: 380.0,
            quantity: 1,
          ),
        ],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Tomorrow, Sep 25',
        pickupTimeSlot: '10:00 AM - 10:30 AM',
      );

      final createRes = await orderRepository.createOrder(orderRequest);
      expect(createRes.isSuccess, isTrue);
      final orderId = createRes.dataOrNull!.id;

      MockUserDatabase().setCurrentUser(staffUser);
      final cancelRes = await orderRepository.cancelOrder(orderId);
      expect(cancelRes.isSuccess, isTrue);

      final cancelledOrder = cancelRes.dataOrNull!;
      expect(cancelledOrder.status, equals(OrderStatus.cancelled));
      expect(cancelledOrder.paymentStatus, equals('UNPAID'),
          reason: 'Cancelled order must remain UNPAID.');
      expect(cancelledOrder.isUnpaid, isTrue);
    });

    test('Edge Case: Customer cannot record counter payment directly (Forbidden)', () async {
      MockUserDatabase().setCurrentUser(customerUser);

      final orderRequest = CreateOrderRequest(
        customerName: 'Customer Tamper Test',
        customerPhone: '09171112222',
        items: const [
          CartItemModel(
            id: 'item_tamper',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            origin: 'Davao',
            roastLevel: 'Light Roast',
            unitPrice: 480.0,
            quantity: 1,
          ),
        ],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Tomorrow, Sep 25',
        pickupTimeSlot: '10:00 AM - 10:30 AM',
      );

      final createRes = await orderRepository.createOrder(orderRequest);
      expect(createRes.isSuccess, isTrue);
      final orderId = createRes.dataOrNull!.id;

      // Customer attempts to self-mark payment as paid
      final tamperRes = await orderRepository.updatePaymentStatus(orderId, PaymentStatus.paid);
      expect(tamperRes.isFailure, isTrue,
          reason: 'Customers are forbidden from directly marking counter payment as paid.');
    });

    testWidgets('UI Test: Checkout Screen displays Pay at Counter and exact supporting explanation', (WidgetTester tester) async {
      final cartWithItem = const CartState(
        items: [
          CartItemModel(
            id: 'item_ui_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            origin: 'Davao del Sur',
            roastLevel: 'Light Roast',
            unitPrice: 480.0,
            quantity: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => MockUserDatabase().currentUser),
            orderRepositoryProvider.overrideWithValue(orderRepository),
            cartNotifierProvider.overrideWith(
              (ref) => CartNotifier(storageService: storageService)..state = cartWithItem,
            ),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check payment section title and options
      expect(find.text('PAYMENT METHOD'), findsNothing); // Heading is 'Payment Method'
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.textContaining('Pay at Counter'), findsWidgets);
      expect(find.text('Pay when you pick up your order at the store.'), findsOneWidget);
      expect(find.text('Payment will be collected when you pick up your order.'), findsOneWidget);

      // Verify NO online payment forms (Credit card inputs, Stripe, etc.) exist
      expect(find.text('Credit Card Number'), findsNothing);
      expect(find.text('CVV'), findsNothing);
      expect(find.text('Online Payment'), findsNothing);
    });

    testWidgets('UI Test: Staff Operations Screen clearly distinguishes ORDER and PAYMENT chips', (WidgetTester tester) async {
      MockUserDatabase().setCurrentUser(staffUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => MockUserDatabase().currentUser),
            orderRepositoryProvider.overrideWithValue(orderRepository),
            adminRepositoryProvider.overrideWithValue(adminRepository),
          ],
          child: const MaterialApp(
            home: StaffOperationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify presence of separate ORDER and PAYMENT badges
      expect(find.textContaining('ORDER:'), findsWidgets);
      expect(find.textContaining('PAYMENT:'), findsWidgets);
    });
  });
}
