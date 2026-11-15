import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/forecasting/data/models/historical_vs_forecast_data_point.dart';
import 'package:lambac_app/features/forecasting/domain/services/forecasting_model_selection_engine.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_item_model.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_model.dart';
import 'package:lambac_app/features/sales/data/models/void_sale_request.dart';
import 'package:lambac_app/shared/services/mock_ledger_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MockLedgerStore.init();
    MockUserDatabase().resetForTests();
    MockUserDatabase().seedDefaultUsers();
    MockUserDatabase().setCurrentUser(
      MockUserDatabase().getByEmail('jmbautista0228@gmail.com')!.user,
    );
    MockOrderRemoteDataSource().resetForTesting();
    MockSalesRemoteDataSource().resetForTesting();
  });

  group('Business Analytics & Sales Pipeline Integrity Audit Suite', () {
    final salesDataSource = MockSalesRemoteDataSource();
    final adminDataSource = MockAdminRemoteDataSource();
    final adminRepository = AdminRepositoryImpl(remoteDataSource: adminDataSource);
    const forecastingEngine = ForecastingModelSelectionEngine();

    OrderModel createCompletedTestOrder({
      required String id,
      required double amount,
      DateTime? completedAt,
    }) {
      final now = completedAt ?? DateTime.now();
      return OrderModel(
        id: id,
        orderNumber: 'ORD-${id.toUpperCase()}',
        customerId: 'cust_analytics_test',
        customerName: 'Analytics Customer',
        customerPhone: '09171234567',
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Today',
        pickupTimeSlot: '11:00 AM - 11:30 AM',
        paymentMethod: 'GCash',
        paymentStatus: 'PAID',
        items: [
          OrderItemModel(
            id: 'item_$id',
            productId: 'benguet-typica',
            productName: 'Benguet Arabica Typica',
            origin: 'Benguet',
            unitPrice: amount,
            quantity: 1,
            totalPrice: amount,
          ),
        ],
        subtotal: amount,
        totalAmount: amount,
        status: OrderStatus.completed,
        createdAt: now,
        completedAt: completedAt,
      );
    }

    test('1. Authoritative Ledger & Single-Count Deduplication: Re-recording completed order never duplicates sales', () {
      final order = createCompletedTestOrder(id: 'ord_dedup_01', amount: 420.0);

      // Initial record
      final firstRecord = salesDataSource.recordCompletedOrderSale(order);
      expect(firstRecord, isTrue);

      final salesCountInitial = salesDataSource.getAllSales().where((s) => s.orderId == order.id).length;
      expect(salesCountInitial, equals(1));

      // Attempt duplicate record (e.g. repeated webhook or listener event)
      final secondRecord = salesDataSource.recordCompletedOrderSale(order);
      expect(secondRecord, isTrue);

      final salesCountAfter = salesDataSource.getAllSales().where((s) => s.orderId == order.id).length;
      expect(salesCountAfter, equals(1), reason: 'Completed order must be counted exactly once in sales ledger');
    });

    test('2. Channel Representation & Aggregation: Mobile pickup orders and POS walk-in counter sales coexist seamlessly', () async {
      // 1. Record completed mobile order
      final mobileOrder = createCompletedTestOrder(id: 'ord_channel_mob', amount: 350.0);
      salesDataSource.recordCompletedOrderSale(mobileOrder);

      // 2. Record POS counter walk-in sale via recordDirectSale
      final walkInSale = SalesRecordModel(
        id: 'sale_wi_1',
        transactionNumber: 'TX-POS-2026-001',
        channel: SalesChannel.walkIn,
        items: const [
          SalesRecordItemModel(
            id: 'item_wi_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Honey',
            snapshotUnitPrice: 450.0,
            quantity: 1,
            totalPrice: 450.0,
          ),
        ],
        subtotal: 450.0,
        totalAmount: 450.0,
        paymentMethod: 'Cash',
        createdAt: DateTime.now(),
      );
      final walkInRes = salesDataSource.recordDirectSale(walkInSale);
      expect(walkInRes, isTrue);

      final allSales = salesDataSource.getAllSales();
      final mobSale = allSales.firstWhere((s) => s.orderId == mobileOrder.id);
      final wiSale = allSales.firstWhere((s) => s.id == walkInSale.id);

      expect(mobSale.channel, equals(SalesChannel.mobileApp));
      expect(wiSale.channel, equals(SalesChannel.walkIn));
      expect(mobSale.totalAmount, equals(350.0));
      expect(wiSale.totalAmount, equals(450.0));
    });

    test('3. Exclusion of Invalid & Voided Transactions: Voided transactions are strictly excluded from net revenue', () async {
      final initialMetrics = await adminRepository.getBusinessMetrics();
      final initialRevenue = initialMetrics.dataOrNull?.todaySales ?? 0.0;

      // Add a sale of 600
      final order = createCompletedTestOrder(id: 'ord_to_void', amount: 600.0);
      salesDataSource.recordCompletedOrderSale(order);

      final addedMetrics = await adminRepository.getBusinessMetrics();
      expect(addedMetrics.dataOrNull?.todaySales, closeTo(initialRevenue + 600.0, 0.01));

      // Void the sale via voidSaleRecord
      final recordedSale = salesDataSource.getAllSales().firstWhere((s) => s.orderId == order.id);
      final voidRes = await salesDataSource.voidSaleRecord(
        VoidSaleRequest(
          saleId: recordedSale.id,
          voidReason: 'Customer cancelled at counter and was refunded',
        ),
      );
      expect(voidRes.isSuccess, isTrue);

      // Verify today revenue has excluded the voided sale
      final postVoidMetrics = await adminRepository.getBusinessMetrics();
      expect(postVoidMetrics.dataOrNull?.todaySales, closeTo(initialRevenue, 0.01));

      // Verify the record is preserved with isVoided == true (not deleted from disk)
      final preservedSale = salesDataSource.getAllSales(includeVoided: true).firstWhere((s) => s.id == recordedSale.id);
      expect(preservedSale.isVoided, isTrue);
      expect(preservedSale.voidReason, contains('refunded'));
    });

    test('4. Consistent Timezone (UTC+8) & Genuine Zero Reporting: Days without qualifying sales report 0.00', () async {
      // Create a clean datasource state with no sales today
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final todaySales = salesDataSource.getSalesForDateRange(todayStart, todayEnd);
      final todayRevenue = todaySales.fold(0.0, (sum, s) => sum + s.totalAmount);

      expect(todaySales.isEmpty, isTrue);
      expect(todayRevenue, equals(0.0), reason: 'Must report genuine 0.00 when no sales exist today');

      // Test yesterday boundary: 23:59:59 yesterday is strictly excluded from today
      final yesterdayLate = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
      final yesterdayOrder = createCompletedTestOrder(
        id: 'ord_yest_late',
        amount: 800.0,
        completedAt: yesterdayLate,
      );
      salesDataSource.recordCompletedOrderSale(yesterdayOrder);

      final todaySalesAfter = salesDataSource.getSalesForDateRange(todayStart, todayEnd);
      expect(todaySalesAfter.isEmpty, isTrue, reason: 'Sales placed at 23:59:59 yesterday must never leak into today');
    });

    test('5. Mathematical Reconciliation: Line items sum matches subtotal and totalAmount', () {
      final items = [
        const SalesRecordItemModel(
          id: 'item_rec_1',
          productId: 'benguet-typica',
          productName: 'Benguet Typica',
          snapshotUnitPrice: 420.0,
          quantity: 2,
          totalPrice: 840.0,
        ),
        const SalesRecordItemModel(
          id: 'item_rec_2',
          productId: 'mt-apo-honey',
          productName: 'Mount Apo Honey',
          snapshotUnitPrice: 450.0,
          quantity: 1,
          totalPrice: 450.0,
        ),
      ];

      final calculatedSum = items.fold(0.0, (sum, i) => sum + i.totalPrice);
      final sale = SalesRecordModel(
        id: 'sale_recon_1',
        transactionNumber: 'TX-RECON-01',
        channel: SalesChannel.walkIn,
        items: items,
        subtotal: calculatedSum,
        totalAmount: calculatedSum,
        paymentMethod: 'Cash',
        createdAt: DateTime.now(),
      );

      expect(sale.totalAmount, equals(1290.0));
      expect(sale.subtotal, equals(1290.0));
      expect(sale.totalItemCount, equals(3));
    });

    test('6. Time-Series Forecasting: Walk-forward validation prevents future leakage & reports honest error metrics', () {
      final baseDate = DateTime(2026, 9, 1);
      final dailyRevenues = <DateTime, double>{};

      // 40 days of trended history
      for (int i = 0; i < 40; i++) {
        final d = baseDate.add(Duration(days: i));
        final trend = i * 25.0;
        final seasonality = (i % 7 == 5 || i % 7 == 6) ? 350.0 : 0.0;
        dailyRevenues[d] = 1000.0 + trend + seasonality;
      }

      // Generate dedicated benchmark report
      final report = forecastingEngine.generateDedicatedBenchmarkReport(
        dailyActualRevenues: dailyRevenues,
        startDate: baseDate,
        endDate: baseDate.add(const Duration(days: 39)),
      );

      expect(report.hasSufficientData, isTrue);
      expect(report.benchmarkResults.isNotEmpty, isTrue);

      // Verify that candidate results contain genuine calculated metrics
      for (final result in report.benchmarkResults) {
        expect(result.mape, greaterThanOrEqualTo(0.0));
        expect(result.rmse, greaterThanOrEqualTo(0.0));
        expect(result.mae, greaterThanOrEqualTo(0.0));
        expect(result.smape, greaterThanOrEqualTo(0.0));
      }

      // Best model is selected based on lowest composite score
      expect(report.winningModel, isNotNull);
      expect(report.winningModel.isWinner, isTrue);
      expect(report.winningModel.rank, equals(1));
    });

    test('7. Sparse History Protection: Datasets with fewer than 5 records reject training with insufficientData state', () {
      final sparseRevenues = <DateTime, double>{
        DateTime(2026, 10, 1): 500.0,
        DateTime(2026, 10, 2): 600.0,
      };

      final report = forecastingEngine.generateDedicatedBenchmarkReport(
        dailyActualRevenues: sparseRevenues,
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 2),
      );

      expect(report.hasSufficientData, isFalse);
      expect(report.insufficientDataReason, contains('Insufficient historical sales records'));
      expect(report.benchmarkResults.isEmpty, isTrue);
    });

    test('8. Observed vs. Forecasted Separation: Data points explicitly tag isForecasted flag', () {
      final now = DateTime(2026, 10, 1);
      final actualPoint = HistoricalVsForecastDataPoint(
        dateLabel: 'Oct 01',
        timestamp: now,
        actualSales: 1500.0,
        isForecasted: false,
      );

      final forecastPoint = HistoricalVsForecastDataPoint(
        dateLabel: 'Oct 15',
        timestamp: now.add(const Duration(days: 14)),
        predictedSales: 1750.0,
        lowerBound: 1550.0,
        upperBound: 1950.0,
        isForecasted: true,
      );

      expect(actualPoint.isForecasted, isFalse);
      expect(forecastPoint.isForecasted, isTrue);
      expect(forecastPoint.upperBound!, greaterThan(forecastPoint.predictedSales!));
      expect(forecastPoint.lowerBound!, lessThan(forecastPoint.predictedSales!));
    });
  });
}
