import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/utils/business_time_service.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_item_model.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_model.dart';

void main() {
  group('PRODUCTION IMPLEMENTATION — Centralized Sales Ledger Integration Suite', () {
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

    test('1. SalesChannel enum exposes canonical keys and handles backward-compatible strings', () {
      expect(SalesChannel.walkIn.canonicalKey, 'WALK_IN');
      expect(SalesChannel.mobileApp.canonicalKey, 'MOBILE_APP_PICKUP');

      expect(SalesChannel.fromString('WALK_IN'), SalesChannel.walkIn);
      expect(SalesChannel.fromString('walk_in'), SalesChannel.walkIn);
      expect(SalesChannel.fromString('walkIn'), SalesChannel.walkIn);
      expect(SalesChannel.fromString('pos'), SalesChannel.walkIn);

      expect(SalesChannel.fromString('MOBILE_APP_PICKUP'), SalesChannel.mobileApp);
      expect(SalesChannel.fromString('mobile_app_pickup'), SalesChannel.mobileApp);
      expect(SalesChannel.fromString('mobileApp'), SalesChannel.mobileApp);
      expect(SalesChannel.fromString('mobile'), SalesChannel.mobileApp);
    });

    test('2. Walk-In POS transaction persists with WALK_IN channel and appears in ledger', () async {
      final now = DateTime.now();
      final walkInSale = SalesRecordModel(
        id: 'sale_pos_test_1',
        transactionNumber: 'TX-POS-2026-0001',
        channel: SalesChannel.walkIn,
        items: const [
          SalesRecordItemModel(
            id: 'item_1',
            productId: 'benguet-typica',
            productName: 'Benguet Arabica Typica',
            size: '250g',
            grind: 'Whole Bean',
            snapshotUnitPrice: 420.0,
            quantity: 1,
            totalPrice: 420.0,
          ),
        ],
        subtotal: 420.0,
        totalAmount: 420.0,
        paymentMethod: 'Cash',
        recordedByStaffId: 'usr_admin_01',
        recordedByStaffName: 'Admin Barista',
        createdAt: now,
      );

      salesDataSource.recordDirectSale(walkInSale);

      // Ledger query with WALK_IN filter
      final walkInResult = await salesDataSource.getSalesRecords(
        channel: SalesChannel.walkIn,
      );
      expect(walkInResult.isSuccess, isTrue);
      final walkInSales = walkInResult.dataOrNull!;
      expect(walkInSales.any((s) => s.id == 'sale_pos_test_1'), isTrue);

      // Ledger query with MOBILE_APP filter excludes it
      final mobileResult = await salesDataSource.getSalesRecords(
        channel: SalesChannel.mobileApp,
      );
      expect(mobileResult.isSuccess, isTrue);
      expect(mobileResult.dataOrNull!.any((s) => s.id == 'sale_pos_test_1'), isFalse);

      // Today's Sales metric includes it
      final metrics = await adminRepository.getBusinessMetrics();
      expect(metrics.isSuccess, isTrue);
      expect(metrics.dataOrNull!.todaySales, 420.0);
      expect(metrics.dataOrNull!.todayOrdersCount, 1);
    });

    test('3. Customer Mobile Pickup order completed by staff persists as MOBILE_APP_PICKUP', () async {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'ord_mob_1001',
        orderNumber: 'LMB-1001',
        customerId: 'cust_01',
        customerName: 'Mobile Customer',
        customerPhone: '09170000001',
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: 'ASAP',
        paymentMethod: 'Pay at Counter',
        paymentStatus: 'PAID',
        items: const [
          OrderItemModel(
            id: 'item_ord_1',
            productId: 'tokyo-blend',
            productName: 'Tokyo Kissaten Signature Blend',
            origin: 'Tokyo Blend',
            unitPrice: 380.0,
            quantity: 2,
            totalPrice: 760.0,
          ),
        ],
        subtotal: 760.0,
        totalAmount: 760.0,
        status: OrderStatus.completed,
        createdAt: now.subtract(const Duration(minutes: 30)),
        completedAt: now,
      );

      final recorded = salesDataSource.recordCompletedOrderSale(order);
      expect(recorded, isTrue);

      // Ledger query with MOBILE_APP filter
      final mobileResult = await salesDataSource.getSalesRecords(
        channel: SalesChannel.mobileApp,
      );
      expect(mobileResult.isSuccess, isTrue);
      final mobileSales = mobileResult.dataOrNull!;
      expect(mobileSales.any((s) => s.orderId == 'ord_mob_1001'), isTrue);
      final saleRecord = mobileSales.firstWhere((s) => s.orderId == 'ord_mob_1001');
      expect(saleRecord.channel, SalesChannel.mobileApp);
      expect(saleRecord.transactionNumber, 'TX-MOB-LMB-1001');
      expect(saleRecord.totalAmount, 760.0);

      // Today's Sales metric includes mobile order revenue
      final metrics = await adminRepository.getBusinessMetrics();
      expect(metrics.isSuccess, isTrue);
      expect(metrics.dataOrNull!.todaySales, 760.0);
      expect(metrics.dataOrNull!.todayOrdersCount, 1);
    });

    test('4. Both channels combine cleanly in Today\'s Sales and All Transactions filter', () async {
      final now = DateTime.now();

      // 1 Walk-In POS sale: ₱420
      salesDataSource.recordDirectSale(
        SalesRecordModel(
          id: 'sale_pos_walkin_combined',
          transactionNumber: 'TX-POS-COMB-1',
          channel: SalesChannel.walkIn,
          items: const [
            SalesRecordItemModel(
              id: 'it_1',
              productId: 'p_1',
              productName: 'Coffee 1',
              snapshotUnitPrice: 420.0,
              quantity: 1,
              totalPrice: 420.0,
            ),
          ],
          subtotal: 420.0,
          totalAmount: 420.0,
          paymentMethod: 'Cash',
          createdAt: now,
        ),
      );

      // 1 Mobile Pickup completed order: ₱580
      salesDataSource.recordDirectSale(
        SalesRecordModel(
          id: 'sale_mob_combined',
          transactionNumber: 'TX-MOB-COMB-2',
          channel: SalesChannel.mobileApp,
          orderId: 'ord_comb_2',
          items: const [
            SalesRecordItemModel(
              id: 'it_2',
              productId: 'p_2',
              productName: 'Coffee 2',
              snapshotUnitPrice: 580.0,
              quantity: 1,
              totalPrice: 580.0,
            ),
          ],
          subtotal: 580.0,
          totalAmount: 580.0,
          paymentMethod: 'GCash',
          createdAt: now,
        ),
      );

      // Check All Transactions filter
      final allResult = await salesDataSource.getSalesRecords(channel: null);
      expect(allResult.isSuccess, isTrue);
      final allSales = allResult.dataOrNull!;
      expect(allSales.any((s) => s.id == 'sale_pos_walkin_combined'), isTrue);
      expect(allSales.any((s) => s.id == 'sale_mob_combined'), isTrue);

      // Combined Today Revenue = 420 + 580 = 1000
      final metrics = await adminRepository.getBusinessMetrics();
      expect(metrics.isSuccess, isTrue);
      expect(metrics.dataOrNull!.todaySales, 1000.0);
      expect(metrics.dataOrNull!.todayOrdersCount, 2);
    });

    test('5. Idempotency prevents duplicate sales entries or double-counted revenue on retry', () async {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'ord_idempotent_test',
        orderNumber: 'LMB-IDEM',
        customerId: 'cust_02',
        customerName: 'Repeat Buyer',
        customerPhone: '09170000002',
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: 'ASAP',
        paymentMethod: 'Pay at Counter',
        paymentStatus: 'PAID',
        items: const [
          OrderItemModel(
            id: 'it_idem',
            productId: 'sagada-geisha',
            productName: 'Sagada High Mountain Geisha',
            origin: 'Sagada',
            unitPrice: 580.0,
            quantity: 1,
            totalPrice: 580.0,
          ),
        ],
        subtotal: 580.0,
        totalAmount: 580.0,
        status: OrderStatus.completed,
        createdAt: now,
        completedAt: now,
      );

      // Attempt 1: completes and records sale
      final firstRecord = salesDataSource.recordCompletedOrderSale(order);
      expect(firstRecord, isTrue);

      // Attempt 2: duplicate call for already completed order
      final secondRecord = salesDataSource.recordCompletedOrderSale(order);
      expect(secondRecord, isTrue);

      // Check ledger count for this order
      final records = await salesDataSource.getSalesRecords(channel: SalesChannel.mobileApp);
      final matches = records.dataOrNull!.where((s) => s.orderId == 'ord_idempotent_test').toList();
      expect(matches.length, 1);

      // Verify Today's Sales is strictly ₱580, NOT ₱1,160
      final metrics = await adminRepository.getBusinessMetrics();
      expect(metrics.dataOrNull!.todaySales, 580.0);
      expect(metrics.dataOrNull!.todayOrdersCount, 1);
    });

    test('6. Historical sales strictly isolate from Today\'s Sales (Asia/Manila boundaries)', () async {
      final now = DateTime.now();
      final todayRange = BusinessTimeService.getTodayRange(now: now);

      // Sale timestamped 1 second before today began
      final yesterdaySale = SalesRecordModel(
        id: 'sale_yesterday_boundary',
        transactionNumber: 'TX-YEST-999',
        channel: SalesChannel.walkIn,
        items: const [
          SalesRecordItemModel(
            id: 'it_y',
            productId: 'p_y',
            productName: 'Past Coffee',
            snapshotUnitPrice: 300.0,
            quantity: 1,
            totalPrice: 300.0,
          ),
        ],
        subtotal: 300.0,
        totalAmount: 300.0,
        paymentMethod: 'Cash',
        createdAt: todayRange.startUtc.subtract(const Duration(seconds: 1)),
      );

      salesDataSource.recordDirectSale(yesterdaySale);

      final metrics = await adminRepository.getBusinessMetrics();
      expect(metrics.isSuccess, isTrue);
      // Yesterday's sale does NOT leak into Today's Sales
      expect(metrics.dataOrNull!.todaySales, 0.0);
      expect(metrics.dataOrNull!.todayOrdersCount, 0);
    });
  });
}
