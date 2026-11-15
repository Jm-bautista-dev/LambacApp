import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/domain/services/pickup_scheduling_service.dart';
import 'package:lambac_app/features/orders/presentation/providers/order_tracking_provider.dart';
import 'package:lambac_app/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_database.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOrderRemoteDataSource orderDataSource;
  late MockSalesRemoteDataSource salesDataSource;
  late MockProductDatabase productDb;
  late MockUserDatabase userDb;
  late ScheduledPickup validSchedule;

  const newCustomer = UserModel(
    id: 'usr_audit_ailo',
    email: 'ailo.audit@lambac.com',
    fullName: 'Ailo Audit',
    phoneNumber: '09171234567',
    role: UserRole.customer,
    isRegistrationVerified: true,
    firstOrderGcashCompleted: false,
  );

  UserModel returningCustomer() => userDb.getByEmail('coffee.lover@lambac.com')!.user;
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
    userDb.records[newCustomer.email] = UserDatabaseRecord(
      user: newCustomer,
      passwordHash: 'hashed',
    );
    orderDataSource.enforceFirstOrderRequirementForCustomer(newCustomer.id);

    validSchedule = PickupSchedulingService().getEarliestAvailableSchedule();
  });

  tearDown(() {
    orderDataSource.resetForTesting();
    salesDataSource.resetForTesting();
    productDb.resetForTesting();
    userDb.resetForTests();
  });

  CreateOrderRequest buildOrderRequest({
    required String paymentMethod,
    String? idempotencyKey,
  }) {
    final product = productDb.getProductById('mt-apo-honey')!;
    return CreateOrderRequest(
      customerName: 'Ailo Audit',
      customerPhone: '09171234567',
      items: [
        CartItemModel(
          id: '${product.id}_size-250g_grind-whole',
          productId: product.id,
          productName: product.name,
          origin: product.origin,
          roastLevel: product.roastLevel,
          unitPrice: product.basePrice,
          quantity: 1,
        ),
      ],
      pickupLocation: PickupLocationModel.flagship,
      pickupDate: validSchedule.dateDisplay,
      pickupTimeSlot: validSchedule.timeSlot,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod.toLowerCase().contains('gcash') ? 'PENDING' : 'UNPAID',
      idempotencyKey: idempotencyKey ?? 'idemp_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  group('Order & Payment Status Integrity Audit — Complete Lifecycle Verification', () {
    test('0. Schema & Model Separation: OrderModel.fromJson never assumes status=completed means PAID', () {
      // Case A: status is completed, but payment_status is missing -> must NOT default to PAID
      final counterCompletedNoPaymentStatus = OrderModel.fromJson({
        'id': 'ord_test_schema_1',
        'order_number': 'LMB-9001',
        'customer_id': 'usr_1',
        'customer_name': 'Test User',
        'customer_phone': '09171234567',
        'status': 'completed',
        'payment_method': 'Pay at Counter',
        'subtotal': 380,
        'total_amount': 380,
        'items': const <dynamic>[],
      });
      expect(counterCompletedNoPaymentStatus.status, equals(OrderStatus.completed));
      expect(counterCompletedNoPaymentStatus.paymentStatus, equals('UNPAID'));
      expect(counterCompletedNoPaymentStatus.isPaid, isFalse);

      // Case B: GCash order with missing payment_status defaults to PENDING, never PAID
      final gcashNoPaymentStatus = OrderModel.fromJson({
        'id': 'ord_test_schema_2',
        'order_number': 'LMB-9002',
        'customer_id': 'usr_1',
        'customer_name': 'Test User',
        'customer_phone': '09171234567',
        'status': 'completed',
        'payment_method': 'GCash',
        'subtotal': 480,
        'total_amount': 480,
        'items': const <dynamic>[],
      });
      expect(gcashNoPaymentStatus.status, equals(OrderStatus.completed));
      expect(gcashNoPaymentStatus.paymentStatus, equals('PENDING'));
      expect(gcashNoPaymentStatus.isPaid, isFalse);

      // Case C: PaymentStatus enum supports UNPAID, PENDING, PAID, FAILED, EXPIRED, CANCELLED, REFUNDED
      expect(PaymentStatus.fromString('UNPAID').toDisplayString(), equals('UNPAID'));
      expect(PaymentStatus.fromString('PENDING').toDisplayString(), equals('PENDING'));
      expect(PaymentStatus.fromString('PAID').toDisplayString(), equals('PAID'));
      expect(PaymentStatus.fromString('FAILED').toDisplayString(), equals('FAILED'));
      expect(PaymentStatus.fromString('EXPIRED').toDisplayString(), equals('EXPIRED'));
      expect(PaymentStatus.fromString('CANCELLED').toDisplayString(), equals('CANCELLED'));
      expect(PaymentStatus.fromString('REFUNDED').toDisplayString(), equals('REFUNDED'));
    });

    test('1 & 2. New GCash order & Pending GCash payment: creating order and starting checkout never mark completed or PAID', () async {
      userDb.setCurrentUser(newCustomer);

      // Step 1: Create new GCash order
      final createRes = await orderDataSource.createOrder(buildOrderRequest(paymentMethod: 'GCash'));
      expect(createRes.isSuccess, isTrue);
      final created = createRes.dataOrNull!;

      // Rule 1: Creating an order must not automatically mark it completed or paid
      expect(created.status, equals(OrderStatus.pending));
      expect(created.paymentStatus, equals('PENDING'));
      expect(created.isPaid, isFalse);

      // Step 2: Start PayMongo checkout session
      final checkoutRes = await orderDataSource.createPaymongoCheckoutSession(created.id);
      expect(checkoutRes.isSuccess, isTrue);
      final afterCheckoutStart = checkoutRes.dataOrNull!;

      // Rule 2 & 3: Starting checkout or returning before webhook verification keeps status=pending, paymentStatus=PENDING
      expect(afterCheckoutStart.status, equals(OrderStatus.pending));
      expect(afterCheckoutStart.paymentStatus, equals('PENDING'));
      expect(afterCheckoutStart.isPaid, isFalse);
      expect(afterCheckoutStart.checkoutUrl, startsWith('https://checkout.paymongo.com/'));
    });

    test('3 & 8. Successful verified GCash payment + Barista preparation & pickup completion', () async {
      userDb.setCurrentUser(newCustomer);

      final created = (await orderDataSource.createOrder(buildOrderRequest(paymentMethod: 'GCash'))).dataOrNull!;
      await orderDataSource.createPaymongoCheckoutSession(created.id);

      // Rule 8: Barista cannot complete an unverified GCash order even if readyForPickup
      userDb.setCurrentUser(baristaUser());
      await orderDataSource.updateOrderStatus(created.id, OrderStatus.preparing);
      await orderDataSource.updateOrderStatus(created.id, OrderStatus.prepared);
      final readyUnpaid = (await orderDataSource.updateOrderStatus(created.id, OrderStatus.readyForPickup)).dataOrNull!;

      // Barista fulfillment transitions must NOT change paymentStatus from PENDING
      expect(readyUnpaid.status, equals(OrderStatus.readyForPickup));
      expect(readyUnpaid.paymentStatus, equals('PENDING'));
      expect(readyUnpaid.isPaid, isFalse);

      // Attempting to complete before PayMongo verification is blocked
      final prematureComplete = await orderDataSource.updateOrderStatus(created.id, OrderStatus.completed);
      expect(prematureComplete.isFailure, isTrue);
      expect(prematureComplete.failureOrNull, isA<ValidationFailure>());

      // Rule 4: Verified PayMongo webhook marks paymentStatus=PAID without automatically completing fulfillment
      final webhookRes = await orderDataSource.processPaymongoWebhookEvent(
        orderId: created.id,
        eventType: 'checkout_session.payment.paid',
        eventId: 'evt_paid_001',
        paymentId: 'pay_gcash_verified_001',
      );
      expect(webhookRes.isSuccess, isTrue);
      final verifiedOrder = webhookRes.dataOrNull!;
      expect(verifiedOrder.paymentStatus, equals('PAID'));
      expect(verifiedOrder.isPaid, isTrue);
      expect(verifiedOrder.status, equals(OrderStatus.readyForPickup)); // Fulfillment remains readyForPickup until handed off

      // Now barista completes pickup handoff
      final completeRes = await orderDataSource.updateOrderStatus(created.id, OrderStatus.completed);
      expect(completeRes.isSuccess, isTrue);
      expect(completeRes.dataOrNull!.status, equals(OrderStatus.completed));
      expect(completeRes.dataOrNull!.paymentStatus, equals('PAID'));
      expect(completeRes.dataOrNull!.paymentReference, equals('pay_gcash_verified_001'));
    });

    test('4. Failed GCash payment: marks paymentStatus=FAILED, does not mark completed, and blocks barista preparation', () async {
      userDb.setCurrentUser(newCustomer);

      final created = (await orderDataSource.createOrder(buildOrderRequest(paymentMethod: 'GCash'))).dataOrNull!;
      await orderDataSource.createPaymongoCheckoutSession(created.id);

      // PayMongo webhook reports payment.failed
      final failRes = await orderDataSource.processPaymongoWebhookEvent(
        orderId: created.id,
        eventType: 'payment.failed',
        eventId: 'evt_fail_001',
        failureReason: 'Insufficient GCash balance',
      );
      expect(failRes.isSuccess, isTrue);
      final failedOrder = failRes.dataOrNull!;

      // Rule 6: Failed payment must not be treated as successful or completed
      expect(failedOrder.status, equals(OrderStatus.pending));
      expect(failedOrder.paymentStatus, equals('FAILED'));
      expect(failedOrder.isPaid, isFalse);
      expect(failedOrder.isPaymentFailed, isTrue);

      // Barista cannot advance a FAILED GCash order into preparation
      userDb.setCurrentUser(baristaUser());
      final prepAttempt = await orderDataSource.updateOrderStatus(created.id, OrderStatus.preparing);
      expect(prepAttempt.isFailure, isTrue);
      expect(prepAttempt.failureOrNull, isA<ValidationFailure>());
    });

    test('5. Expired GCash payment: marks paymentStatus=EXPIRED, does not mark completed, and blocks barista preparation', () async {
      userDb.setCurrentUser(newCustomer);

      final created = (await orderDataSource.createOrder(buildOrderRequest(paymentMethod: 'GCash'))).dataOrNull!;
      await orderDataSource.createPaymongoCheckoutSession(created.id);

      // PayMongo webhook reports checkout_session.expired
      final expRes = await orderDataSource.processPaymongoWebhookEvent(
        orderId: created.id,
        eventType: 'checkout_session.expired',
        eventId: 'evt_exp_001',
      );
      expect(expRes.isSuccess, isTrue);
      final expiredOrder = expRes.dataOrNull!;

      expect(expiredOrder.status, equals(OrderStatus.pending));
      expect(expiredOrder.paymentStatus, equals('EXPIRED'));
      expect(expiredOrder.isPaid, isFalse);
      expect(expiredOrder.isPaymentFailed, isTrue);

      // Barista cannot advance an EXPIRED GCash order into preparation
      userDb.setCurrentUser(baristaUser());
      final prepAttempt = await orderDataSource.updateOrderStatus(created.id, OrderStatus.preparing);
      expect(prepAttempt.isFailure, isTrue);
      expect(prepAttempt.failureOrNull, isA<ValidationFailure>());
    });

    test('6. Customer cancellation: sets status=cancelled and paymentStatus=CANCELLED while releasing first-order lock', () async {
      userDb.setCurrentUser(newCustomer);

      final created = (await orderDataSource.createOrder(buildOrderRequest(paymentMethod: 'GCash'))).dataOrNull!;
      expect(created.status, equals(OrderStatus.pending));
      expect(created.paymentStatus, equals('PENDING'));

      final cancelRes = await orderDataSource.cancelOrder(created.id);
      expect(cancelRes.isSuccess, isTrue);
      final cancelled = cancelRes.dataOrNull!;

      expect(cancelled.status, equals(OrderStatus.cancelled));
      expect(cancelled.paymentStatus, equals('CANCELLED'));
      expect(cancelled.isPaid, isFalse);

      // Customer can now place a fresh first-order GCash order after cancellation
      final retryCreate = await orderDataSource.createOrder(
        buildOrderRequest(paymentMethod: 'GCash', idempotencyKey: 'idemp_retry_after_cancel'),
      );
      expect(retryCreate.isSuccess, isTrue);
    });

    test('7. Pay at Counter order: remains UNPAID through preparation and readyForPickup until collected upon completion', () async {
      userDb.setCurrentUser(returningCustomer());

      final created = (await orderDataSource.createOrder(buildOrderRequest(paymentMethod: 'Pay at Counter'))).dataOrNull!;
      expect(created.status, equals(OrderStatus.pending));
      expect(created.paymentStatus, equals('UNPAID'));
      expect(created.isUnpaid, isTrue);

      userDb.setCurrentUser(baristaUser());

      final confirmed = (await orderDataSource.updateOrderStatus(created.id, OrderStatus.confirmed)).dataOrNull!;
      expect(confirmed.status, equals(OrderStatus.confirmed));
      expect(confirmed.paymentStatus, equals('UNPAID'));

      final preparing = (await orderDataSource.updateOrderStatus(created.id, OrderStatus.preparing)).dataOrNull!;
      expect(preparing.status, equals(OrderStatus.preparing));
      expect(preparing.paymentStatus, equals('UNPAID'));

      final prepared = (await orderDataSource.updateOrderStatus(created.id, OrderStatus.prepared)).dataOrNull!;
      expect(prepared.status, equals(OrderStatus.prepared));
      expect(prepared.paymentStatus, equals('UNPAID'));

      final ready = (await orderDataSource.updateOrderStatus(created.id, OrderStatus.readyForPickup)).dataOrNull!;
      expect(ready.status, equals(OrderStatus.readyForPickup));
      expect(ready.paymentStatus, equals('UNPAID'));

      // Counter payment is collected when pickup is completed at the counter
      userDb.setCurrentUser(adminUser());
      final completed = (await orderDataSource.updateOrderStatus(created.id, OrderStatus.completed)).dataOrNull!;
      expect(completed.status, equals(OrderStatus.completed));
      expect(completed.paymentStatus, equals('PAID'));
      expect(completed.isPaid, isTrue);
    });

    test('9. Duplicate webhook delivery: idempotent and never downgrades PAID on out-of-order failure/expiry events', () async {
      userDb.setCurrentUser(newCustomer);

      final created = (await orderDataSource.createOrder(buildOrderRequest(paymentMethod: 'GCash'))).dataOrNull!;
      await orderDataSource.createPaymongoCheckoutSession(created.id);

      // First delivery of evt_idemp_999
      final firstDelivery = await orderDataSource.processPaymongoWebhookEvent(
        orderId: created.id,
        eventType: 'checkout_session.payment.paid',
        eventId: 'evt_idemp_999',
        paymentId: 'pay_idemp_999',
      );
      expect(firstDelivery.isSuccess, isTrue);
      expect(firstDelivery.dataOrNull!.paymentStatus, equals('PAID'));
      final firstPaidAt = firstDelivery.dataOrNull!.paidAt;

      // Duplicate delivery of evt_idemp_999 is a safe no-op
      final secondDelivery = await orderDataSource.processPaymongoWebhookEvent(
        orderId: created.id,
        eventType: 'checkout_session.payment.paid',
        eventId: 'evt_idemp_999',
        paymentId: 'pay_other_should_be_ignored',
      );
      expect(secondDelivery.isSuccess, isTrue);
      expect(secondDelivery.dataOrNull!.paymentReference, equals('pay_idemp_999'));
      expect(secondDelivery.dataOrNull!.paidAt, equals(firstPaidAt));

      // Out-of-order payment.failed or checkout_session.expired event never downgrades PAID
      final lateFail = await orderDataSource.processPaymongoWebhookEvent(
        orderId: created.id,
        eventType: 'payment.failed',
        eventId: 'evt_late_fail_1000',
      );
      expect(lateFail.isSuccess, isTrue);
      expect(lateFail.dataOrNull!.paymentStatus, equals('PAID'));
    });

    testWidgets('10. Rule 9 UI Verification: OrderDetailScreen displays Fulfillment Status and Payment Status separately and accurately', (tester) async {
      final gcashOrder = OrderModel(
        id: 'ord_ui_gcash_8819',
        orderNumber: 'LMB-8819',
        customerId: newCustomer.id,
        customerName: newCustomer.fullName,
        customerPhone: '09171234567',
        items: const [
          OrderItemModel(
            id: 'item_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            origin: 'Davao del Sur',
            size: '250g Bag',
            grind: 'Whole Bean',
            unitPrice: 480.0,
            quantity: 1,
            totalPrice: 480.0,
          ),
        ],
        subtotal: 480.0,
        totalAmount: 480.0,
        status: OrderStatus.readyForPickup,
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Sunday, November 15',
        pickupTimeSlot: '8:00 AM',
        paymentMethod: 'GCash',
        paymentStatus: 'PENDING',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderTrackingStreamProvider('ord_ui_gcash_8819').overrideWith(
              (ref) => Stream.value(gcashOrder),
            ),
          ],
          child: const MaterialApp(
            home: OrderDetailScreen(orderId: 'ord_ui_gcash_8819'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both fulfillment status badge and payment status badge are rendered separately
      expect(find.byKey(const Key('order_detail_fulfillment_status_badge')), findsOneWidget);
      expect(find.byKey(const Key('order_detail_payment_status_badge')), findsOneWidget);
      expect(find.text('Ready for Pickup'), findsWidgets);
      expect(find.text('PENDING GCASH'), findsWidgets);

      // Must NOT display misleading "settle payment at the counter" copy for a GCash order
      expect(find.textContaining('settle payment at the counter'), findsNothing);
      expect(
        find.textContaining('Please complete your online GCash payment verification before pickup.'),
        findsOneWidget,
      );
    });
  });
}
