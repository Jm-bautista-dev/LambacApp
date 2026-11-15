import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';

void main() {
  group('Barista Collect & Complete Order Transaction Ordering & Idempotency Suite', () {
    late MockSalesRemoteDataSource salesDataSource;
    late MockOrderRemoteDataSource orderDataSource;
    late MockAdminRemoteDataSource adminDataSource;
    late AdminRepositoryImpl adminRepository;

    setUp(() {
      MockUserDatabase().seedDefaultUsers();
      MockUserDatabase().setCurrentUser(
        MockUserDatabase().getByEmail('jmbautista0228@gmail.com')!.user,
      );

      salesDataSource = MockSalesRemoteDataSource()..resetForTesting();
      orderDataSource = MockOrderRemoteDataSource()..resetForTesting();
      adminDataSource = MockAdminRemoteDataSource();
      adminRepository = AdminRepositoryImpl(remoteDataSource: adminDataSource);
    });

    OrderModel createReadyOrder({
      required String id,
      required String orderNumber,
      required double amount,
      String paymentStatus = 'UNPAID',
    }) {
      final now = DateTime.now();
      return OrderModel(
        id: id,
        orderNumber: orderNumber,
        customerId: 'cust_01',
        customerName: 'Katsu Customer',
        customerPhone: '09171234567',
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: 'Friday, November 13 • 8:00 AM',
        paymentMethod: 'Pay at Counter',
        paymentStatus: paymentStatus,
        items: [
          OrderItemModel(
            id: 'it_$id',
            productId: 'nitro-cold-brew',
            productName: 'Lambac Nitro Cold Brew Concentrate',
            origin: 'Benguet Reserve',
            size: '250g Bag',
            grind: 'Whole Bean',
            unitPrice: amount,
            quantity: 1,
            totalPrice: amount,
          ),
        ],
        subtotal: amount,
        totalAmount: amount,
        status: OrderStatus.readyForPickup,
        createdAt: now.subtract(const Duration(minutes: 25)),
      );
    }

    test('1. Ready for Pickup + Unpaid -> successful payment and completion via Collect & Complete', () async {
      // Order #LMB-9862 — ₱280.00 from user's screenshot
      final order = createReadyOrder(id: 'ord_lmb_9862', orderNumber: 'LMB-9862', amount: 280.0);
      orderDataSource.addOrder(order);

      final updateRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);
      expect(updateRes.isSuccess, isTrue);

      final completedOrder = updateRes.dataOrNull!;
      expect(completedOrder.status, OrderStatus.completed);
      expect(completedOrder.paymentStatus.toUpperCase(), 'PAID');
      expect(completedOrder.completedAt, isNotNull);

      // Verify sales ledger has recorded transaction
      final sales = salesDataSource.getAllSales();
      final sale = sales.firstWhere((s) => s.orderId == order.id);
      expect(sale.totalAmount, 280.0);
      expect(sale.channel, SalesChannel.mobileApp);
      expect(sale.transactionNumber, 'TX-MOB-LMB-9862');
    });

    test('2. Record Payment button records payment without completing order early', () async {
      // Order #LMB-3693 — ₱520.00
      final order = createReadyOrder(id: 'ord_lmb_3693', orderNumber: 'LMB-3693', amount: 520.0);
      orderDataSource.addOrder(order);

      final payRes = await orderDataSource.updatePaymentStatus(order.id, PaymentStatus.paid);
      expect(payRes.isSuccess, isTrue);

      final paidOrder = payRes.dataOrNull!;
      expect(paidOrder.paymentStatus.toUpperCase(), 'PAID');
      // Order remains in readyForPickup state until customer actually collects it
      expect(paidOrder.status, OrderStatus.readyForPickup);

      // No sales transaction recorded yet (only finalized upon completion)
      final sales = salesDataSource.getAllSales();
      expect(sales.any((s) => s.orderId == order.id), isFalse);
    });

    test('3. Collect & Complete records both payment and completion atomically', () async {
      final order = createReadyOrder(id: 'ord_lmb_9862_b', orderNumber: 'LMB-9862', amount: 280.0);
      orderDataSource.addOrder(order);

      final res = await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);
      expect(res.isSuccess, isTrue);
      final completed = res.dataOrNull!;
      expect(completed.status, OrderStatus.completed);
      expect(completed.paymentStatus.toUpperCase(), 'PAID');

      // Centralized Sales Ledger contains the MOBILE_APP_PICKUP transaction
      final ledgerResult = await salesDataSource.getSalesRecords(channel: SalesChannel.mobileApp);
      expect(ledgerResult.isSuccess, isTrue);
      final sale = ledgerResult.dataOrNull!.firstWhere((s) => s.orderId == order.id);
      expect(sale.totalAmount, 280.0);
      expect(sale.channel, SalesChannel.mobileApp);
    });

    test('4. Double-click Collect & Complete does NOT create duplicate payment or sale', () async {
      final order = createReadyOrder(id: 'ord_lmb_dbl_click', orderNumber: 'LMB-7777', amount: 350.0);
      orderDataSource.addOrder(order);

      // First click
      final res1 = await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);
      expect(res1.isSuccess, isTrue);

      // Immediate second click (double-tap simulation)
      final res2 = await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);
      expect(res2.isSuccess, isTrue);

      // Count sales entries for this order
      final allSales = salesDataSource.getAllSales();
      final orderSales = allSales.where((s) => s.orderId == order.id).toList();
      expect(orderSales.length, 1);

      // Today's Sales reflects ₱350 exactly once
      final metrics = await adminRepository.getBusinessMetrics();
      expect(metrics.dataOrNull!.todaySales, 350.0);
      expect(metrics.dataOrNull!.todayOrdersCount, 1);
    });

    test('5. Already Paid order: Collect & Complete finalizes completion without double charging', () async {
      final order = createReadyOrder(
        id: 'ord_already_paid',
        orderNumber: 'LMB-8888',
        amount: 400.0,
        paymentStatus: 'PAID',
      );
      orderDataSource.addOrder(order);

      final completeRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);
      expect(completeRes.isSuccess, isTrue);
      final completed = completeRes.dataOrNull!;
      expect(completed.status, OrderStatus.completed);
      expect(completed.paymentStatus.toUpperCase(), 'PAID');

      final orderSales = salesDataSource.getAllSales().where((s) => s.orderId == order.id).toList();
      expect(orderSales.length, 1);
      expect(orderSales.first.totalAmount, 400.0);
    });

    test('6. Already Completed order cannot be transitioned or modified again', () async {
      final order = createReadyOrder(id: 'ord_terminal', orderNumber: 'LMB-9999', amount: 300.0);
      orderDataSource.addOrder(order);

      await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);

      // Attempting to cancel or revert completed order fails
      final cancelRes = await orderDataSource.cancelOrder(order.id);
      expect(cancelRes.isFailure, isTrue);

      final revertRes = await orderDataSource.updateOrderStatus(order.id, OrderStatus.preparing);
      expect(revertRes.isFailure, isTrue);
    });

    test('7. Dashboard revenue reflects completed mobile order exactly once', () async {
      final order = createReadyOrder(id: 'ord_rev_test', orderNumber: 'LMB-5555', amount: 480.0);
      orderDataSource.addOrder(order);

      // Before completion -> todaySales is 0
      var metrics = await adminRepository.getBusinessMetrics();
      expect(metrics.dataOrNull!.todaySales, 0.0);

      // Complete order
      await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);

      // After completion -> todaySales is 480.0
      metrics = await adminRepository.getBusinessMetrics();
      expect(metrics.dataOrNull!.todaySales, 480.0);
      expect(metrics.dataOrNull!.todayOrdersCount, 1);
    });

    test('8. Centralized Sales Ledger contains exactly one MOBILE_APP_PICKUP transaction', () async {
      final order = createReadyOrder(id: 'ord_ledger_test', orderNumber: 'LMB-4444', amount: 500.0);
      orderDataSource.addOrder(order);

      await orderDataSource.updateOrderStatus(order.id, OrderStatus.completed);

      final ledgerRes = await salesDataSource.getSalesRecords(channel: SalesChannel.mobileApp);
      expect(ledgerRes.isSuccess, isTrue);
      final sales = ledgerRes.dataOrNull!;
      final matching = sales.where((s) => s.orderId == order.id).toList();
      expect(matching.length, 1);
      expect(matching.first.channel, SalesChannel.mobileApp);
      expect(matching.first.transactionNumber, 'TX-MOB-LMB-4444');
      expect(matching.first.totalAmount, 500.0);
    });
  });
}
