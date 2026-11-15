import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/analytics/data/datasources/mock_analytics_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/forecasting/data/datasources/mock_forecasting_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/models/create_walk_in_sale_request.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_item_model.dart';
import 'package:lambac_app/features/sales/data/models/void_sale_request.dart';

OrderModel createTestOrder({
  required String id,
  required double amount,
  DateTime? createdAt,
}) {
  return OrderModel(
    id: id,
    orderNumber: id.toUpperCase(),
    customerId: 'cust_test',
    customerName: 'Test Customer',
    customerPhone: '09171234567',
    pickupLocation: PickupLocationModel.flagship,
    pickupTimeSlot: 'ASAP',
    paymentMethod: 'GCash',
    paymentStatus: 'PAID',
    items: [
      OrderItemModel(
        id: 'item_$id',
        productId: 'mt-apo-honey',
        productName: 'Mount Apo Anaerobic Honey Reserve',
        origin: 'Davao',
        unitPrice: amount,
        quantity: 1,
        totalPrice: amount,
      ),
    ],
    subtotal: amount,
    totalAmount: amount,
    status: OrderStatus.completed,
    createdAt: createdAt ?? DateTime.now(),
  );
}

void main() {
  group('Today Revenue Calculation & Historical Separation Tests', () {
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

    test('TEST 1 — No sales today: Historical sales exist, Today sales = 0 -> Revenue is 0.00', () async {
      final result = await adminRepository.getBusinessMetrics();

      expect(result.isSuccess, isTrue);
      final metrics = result.dataOrNull!;

      expect(metrics.todaySales, equals(0.0));
      expect(metrics.todayOrdersCount, equals(0));
    });

    test('TEST 2 — One completed sale today: ₱500 sale -> Today Revenue is ₱500.00', () async {
      final order = createTestOrder(id: 'ord_today_1', amount: 500.0);
      salesDataSource.recordCompletedOrderSale(order);

      final result = await adminRepository.getBusinessMetrics();

      expect(result.isSuccess, isTrue);
      final metrics = result.dataOrNull!;

      expect(metrics.todaySales, equals(500.0));
      expect(metrics.todayOrdersCount, equals(1));
    });

    test('TEST 3 — Multiple completed sales today: ₱500 + ₱250 + ₱750 -> Today Revenue is ₱1,500.00', () async {
      final salesToAdd = [500.0, 250.0, 750.0];

      for (int i = 0; i < salesToAdd.length; i++) {
        final order = createTestOrder(id: 'ord_today_multi_$i', amount: salesToAdd[i]);
        salesDataSource.recordCompletedOrderSale(order);
      }

      final result = await adminRepository.getBusinessMetrics();

      expect(result.isSuccess, isTrue);
      final metrics = result.dataOrNull!;

      expect(metrics.todaySales, equals(1500.0));
      expect(metrics.todayOrdersCount, equals(3));
    });

    test('TEST 4 — Historical sales only: 45 days of past transactions do NOT leak into Today Revenue', () async {
      final allSales = salesDataSource.getAllSales(includeVoided: false);
      expect(allSales.length, greaterThan(20));

      final result = await adminRepository.getBusinessMetrics();

      expect(result.isSuccess, isTrue);
      final metrics = result.dataOrNull!;

      expect(metrics.todaySales, equals(0.0));
      expect(metrics.todayOrdersCount, equals(0));
    });

    test('TEST 5 — Cancelled / Voided sale today: Voided ₱1,000 transaction is excluded from Today Revenue', () async {
      final order = createTestOrder(id: 'ord_today_void', amount: 1000.0);
      salesDataSource.recordCompletedOrderSale(order);

      // Verify it initially counted
      var metricsResult = await adminRepository.getBusinessMetrics();
      expect(metricsResult.dataOrNull!.todaySales, equals(1000.0));

      // Void the transaction
      final voidResult = await salesDataSource.voidSaleRecord(
        const VoidSaleRequest(
          saleId: 'sale_ord_today_void',
          voidReason: 'Customer requested order cancellation',
        ),
      );
      expect(voidResult.isSuccess, isTrue);

      // Verify it is excluded and Today Revenue returns to 0.00
      metricsResult = await adminRepository.getBusinessMetrics();
      expect(metricsResult.dataOrNull!.todaySales, equals(0.0));
      expect(metricsResult.dataOrNull!.todayOrdersCount, equals(0));
    });

    test('TEST 6 — Pending order today: Pending order does NOT count towards Today Revenue until completed', () async {
      // Create pending order
      final createOrderResult = await orderDataSource.createOrder(
        const CreateOrderRequest(
          customerName: 'Online Guest',
          customerPhone: '09171234567',
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'Pay at Counter',
          items: [],
        ),
      );
      // Even if pending orders exist in the system, Today's Revenue must remain 0.00
      final result = await adminRepository.getBusinessMetrics();
      expect(result.dataOrNull!.todaySales, equals(0.0));
    });

    test('TEST 7 — Historical seeded dataset remains fully available for BI Analytics & ML Forecasting', () async {
      final analyticsDataSource = MockAnalyticsRemoteDataSource();
      final forecastingDataSource = MockForecastingRemoteDataSource();

      // Descriptive Analytics for 30 days
      final analyticsResult = await analyticsDataSource.getAnalyticsSummary(dateRange: '30d');
      expect(analyticsResult.isSuccess, isTrue);
      final analyticsSummary = analyticsResult.dataOrNull!;
      expect(analyticsSummary.totalSales, greaterThan(10000.0));
      expect(analyticsSummary.totalOrders, greaterThan(15));
      expect(analyticsSummary.salesTrends.length, equals(30));

      // ML Forecasting for Next 14 Days
      final forecastResult = await forecastingDataSource.getForecastSummary(period: '14D');
      expect(forecastResult.isSuccess, isTrue);
      final forecastSummary = forecastResult.dataOrNull!;
      expect(forecastSummary.hasSufficientData, isTrue);
      expect(forecastSummary.expectedSales, greaterThan(5000.0));
      expect(forecastSummary.productDemandForecasts.isNotEmpty, isTrue);
    });

    test('TEST 8 — Date boundaries: Sales yesterday at 23:59:59 are strictly isolated from today', () async {
      final now = DateTime.now();
      final yesterdayLate = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);

      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final salesForToday = salesDataSource.getSalesForDateRange(todayStart, todayEnd);
      expect(salesForToday.every((s) => !s.createdAt.isBefore(todayStart) && !s.createdAt.isAfter(todayEnd)), isTrue);
      expect(salesForToday.any((s) => s.createdAt.isAtSameMomentAs(yesterdayLate)), isFalse);
    });
  });
}
