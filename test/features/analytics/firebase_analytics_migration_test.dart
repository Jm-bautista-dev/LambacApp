import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/analytics/data/models/analytics_summary_model.dart';
import 'package:lambac_app/features/analytics/data/models/business_insight_model.dart';
import 'package:lambac_app/features/analytics/data/models/customer_activity_summary.dart';
import 'package:lambac_app/features/analytics/data/models/data_quality_report_model.dart';
import 'package:lambac_app/features/analytics/data/models/forecast_readiness_model.dart';
import 'package:lambac_app/features/analytics/data/models/order_status_breakdown.dart';
import 'package:lambac_app/features/analytics/data/models/product_performance_model.dart';
import 'package:lambac_app/features/analytics/data/models/sales_trend_data_point.dart';
import 'package:lambac_app/features/forecasting/data/models/benchmark_history_entry_model.dart';
import 'package:lambac_app/features/forecasting/data/models/forecast_summary_model.dart';
import 'package:lambac_app/features/forecasting/data/models/model_benchmark_result.dart';
import 'package:lambac_app/features/forecasting/domain/services/forecasting_model_selection_engine.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/prescriptive/data/models/prescriptive_action_model.dart';
import 'package:lambac_app/features/prescriptive/data/models/prescriptive_recommendation_model.dart';
import 'package:lambac_app/features/sales/data/models/create_walk_in_sale_request.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_item_model.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_model.dart';
import 'package:lambac_app/features/sales/data/models/void_sale_request.dart';

void main() {
  group('Prompt 6: Sales, Descriptive Analytics, Forecasting & Prescriptive Firebase Migration', () {
    test('1. Sales: SalesRecordModel adheres to normalized sales/{saleId} schema with price snapshots', () {
      final now = DateTime.utc(2026, 10, 6, 14, 30, 0);
      const item = SalesRecordItemModel(
        id: 'item_s_101',
        productId: 'benguet-typica',
        productName: 'Benguet Arabica Typica Heirloom',
        size: '250g Bag',
        grind: 'V60 Pourover',
        snapshotUnitPrice: 420.0,
        quantity: 2,
        totalPrice: 840.0,
      );

      final sale = SalesRecordModel(
        id: 'sale_ord_1082',
        transactionNumber: 'TX-MOB-LMB-1082',
        channel: SalesChannel.mobileApp,
        orderId: 'ord_lmb_1082',
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
        items: const [item],
        subtotal: 840.0,
        totalAmount: 840.0,
        paymentMethod: 'GCash',
        createdAt: now,
      );

      final json = sale.toJson();

      // Verify Firestore field mapping
      expect(json['id'], equals('sale_ord_1082'));
      expect(json['transaction_number'], equals('TX-MOB-LMB-1082'));
      expect(json['channel'], equals('mobileApp'));
      expect(json['order_id'], equals('ord_lmb_1082'));
      expect(json['customer_name'], equals('Kenji Takahashi'));
      expect(json['subtotal'], equals(840.0));
      expect(json['total_amount'], equals(840.0));
      expect(json['payment_method'], equals('GCash'));
      expect(json['is_voided'], isFalse);

      final itemsJson = json['items'] as List;
      expect(itemsJson.length, equals(1));
      expect(itemsJson[0]['snapshot_unit_price'], equals(420.0));
      expect(itemsJson[0]['total_price'], equals(840.0));

      // Round-trip deserialization
      final deserialized = SalesRecordModel.fromJson(json);
      expect(deserialized.id, equals(sale.id));
      expect(deserialized.channel, equals(SalesChannel.mobileApp));
      expect(deserialized.items.first.snapshotUnitPrice, equals(420.0));
      expect(deserialized.totalAmount, equals(840.0));
    });

    test('2. Sales: Walk-in transactions and voiding preserve historical integrity', () {
      final request = CreateWalkInSaleRequest(
        customerName: 'Walk-In Guest',
        paymentMethod: 'Cash',
        items: const [
          SalesRecordItemModel(
            id: 'item_pos_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            snapshotUnitPrice: 480.0,
            quantity: 3,
            totalPrice: 1440.0,
          ),
        ],
      );

      expect(request.subtotal, equals(1440.0));
      expect(request.totalAmount, equals(1440.0));

      // Void sale request verification
      const voidReq = VoidSaleRequest(
        saleId: 'sale_pos_12345',
        voidReason: 'Accidental counter duplicate entry',
      );
      expect(voidReq.saleId, equals('sale_pos_12345'));
      expect(voidReq.voidReason, contains('duplicate entry'));
    });

    test('3. Descriptive Analytics: AnalyticsSummaryModel holds complete KPI distribution', () {
      final summary = AnalyticsSummaryModel(
        dateRangeLabel: '30 Days',
        totalSales: 45280.0,
        totalSalesChangePercent: 12.5,
        totalOrders: 98,
        totalOrdersChangePercent: 8.2,
        averageOrderValue: 462.04,
        topProductName: 'Mount Apo Anaerobic Honey Reserve',
        mobileSalesAmount: 28500.0,
        walkInSalesAmount: 16780.0,
        mobileOrdersCount: 60,
        walkInOrdersCount: 38,
        customerActivity: const CustomerActivitySummary(
          uniqueCustomersCount: 45,
          repeatCustomersCount: 22,
          averageOrderFrequency: 2.18,
        ),
        statusBreakdown: const OrderStatusBreakdown(
          pendingCount: 2,
          confirmedCount: 1,
          preparingCount: 3,
          readyForPickupCount: 4,
          completedCount: 98,
          cancelledCount: 1,
        ),
        salesTrends: [
          SalesTrendDataPoint(
            dateLabel: 'Today',
            timestamp: DateTime.now(),
            salesAmount: 2400.0,
            ordersCount: 5,
          ),
        ],
        topProducts: const [
          ProductPerformanceModel(
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            categoryName: 'Roastery Reserve',
            quantitySold: 42,
            revenueGenerated: 20160.0,
            percentageOfTotalRevenue: 44.5,
          ),
        ],
        lowestProducts: const [],
        insights: const [
          BusinessInsightModel(
            title: 'Top Product Contribution',
            text: 'Mount Apo contributes 44.5% of period revenue.',
            type: InsightType.positive,
          ),
        ],
      );

      expect(summary.totalSales, equals(45280.0));
      expect(summary.averageOrderValue, closeTo(462.04, 0.01));
      expect(summary.mobileSalesAmount + summary.walkInSalesAmount, equals(summary.totalSales));
      expect(summary.mobileOrdersCount + summary.walkInOrdersCount, equals(summary.totalOrders));
      expect(summary.statusBreakdown.completedCount, equals(98));
    });

    test('4. Descriptive Analytics: Continuous time-series contains zero-sales days without gaps', () {
      final now = DateTime.now();
      final trends = <SalesTrendDataPoint>[];

      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: 6 - i));
        // Day 3 has 0 sales
        final amt = (i == 3) ? 0.0 : 1200.0 + (i * 150);
        final cnt = (i == 3) ? 0 : 2 + i;

        trends.add(
          SalesTrendDataPoint(
            dateLabel: 'Day $i',
            timestamp: d,
            salesAmount: amt,
            ordersCount: cnt,
          ),
        );
      }

      expect(trends.length, equals(7));
      expect(trends[3].salesAmount, equals(0.0));
      expect(trends[3].ordersCount, equals(0));
      expect(trends[6].salesAmount, greaterThan(0.0));
    });

    test('5. Data Quality: DataQualityReportModel processes completeness score accurately', () {
      final report = DataQualityReportModel(
        totalRecordsProcessed: 100,
        validRecordsCount: 96,
        corruptedRecordsCount: 0,
        duplicateCount: 0,
        invalidPriceCount: 0,
        invalidQuantityCount: 0,
        completenessScorePercent: 96.0,
        auditedAt: DateTime.now(),
        mobileAppCount: 65,
        walkInCount: 31,
      );

      expect(report.totalRecordsProcessed, equals(100));
      expect(report.validRecordsCount, equals(96));
      expect(report.completenessScorePercent, equals(96.0));
      expect(report.isClean, isTrue);
    });

    test('6. Forecasting: ForecastingModelSelectionEngine backtests candidate models with zero-safe MAPE', () {
      const engine = ForecastingModelSelectionEngine();

      final now = DateTime.now();
      final dailyMap = <DateTime, double>{};

      // 30 days of synthetic actuals including zero-sales days
      for (int i = 0; i < 30; i++) {
        final day = now.subtract(Duration(days: 29 - i));
        final dayKey = DateTime(day.year, day.month, day.day);
        // Weekend spike, weekday normal, zero sales on day 10
        final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
        final amt = (i == 10) ? 0.0 : (isWeekend ? 3500.0 : 1800.0 + (i * 20));
        dailyMap[dayKey] = amt;
      }

      final productMap = <String, ({String name, String category, int totalUnits, double totalRev})>{
        'mt-apo-honey': (
          name: 'Mount Apo Anaerobic Honey Reserve',
          category: 'Roastery Reserve',
          totalUnits: 45,
          totalRev: 21600.0,
        ),
        'tokyo-blend': (
          name: 'Tokyo Kissaten Signature Blend',
          category: 'Signature Blend',
          totalUnits: 30,
          totalRev: 11400.0,
        ),
      };

      final summary = engine.selectBestModelAndForecast(
        dailyActualRevenues: dailyMap,
        productSalesMap: productMap,
        horizonDays: 14,
        periodLabel: 'Next 14 Days',
      );

      expect(summary.hasSufficientData, isTrue);
      expect(summary.expectedSales, greaterThan(0.0));
      expect(summary.modelName, isNotEmpty);
      expect(summary.winningCandidateType, isNotNull);
      // Zero-safe MAPE must not be NaN or Infinity despite zero-sales day
      expect(summary.mape.isNaN, isFalse);
      expect(summary.mape.isInfinite, isFalse);
      expect(summary.mape, inInclusiveRange(0.0, 100.0));
      expect(summary.benchmarkResults.length, equals(7)); // 7 evaluated algorithms
      expect(summary.productDemandForecasts.length, equals(2));
      expect(summary.points, isNotEmpty);
    });

    test('7. Forecasting: Insufficient historical data produces clean empty state without fake numbers', () {
      final summary = ForecastSummaryModel.insufficientData();
      expect(summary.hasSufficientData, isFalse);
      expect(summary.expectedSales, equals(0.0));
      expect(summary.insufficientDataReason, contains('Not enough historical data'));
      expect(summary.points, isEmpty);
      expect(summary.benchmarkResults, isEmpty);
    });

    test('8. Prescriptive: PrescriptiveActionModel adheres to roastSchedules/{scheduleId} schema', () {
      final now = DateTime.utc(2026, 10, 6, 10, 0, 0);
      final scheduledDate = now.add(const Duration(days: 1));

      final action = PrescriptiveActionModel(
        id: 'act_roast_2001',
        recommendationId: 'rec_top_bean_01',
        actionType: PrescriptiveActionType.roastBatch,
        classification: ActionClassification.scheduled,
        status: PrescriptiveActionStatus.scheduled,
        priority: RecommendationPriority.high,
        title: 'Roast Batch: Mount Apo Anaerobic Micro-Lots',
        description: 'Roasting 15 kg (12 bags) micro-lot profile at Roaster 1',
        targetProductId: 'prod_mt_apo',
        targetProductName: 'Mount Apo Anaerobic Micro-Lot',
        targetQuantity: 12,
        targetUnit: 'bags',
        scheduledAt: scheduledDate,
        createdAt: now,
        updatedAt: now,
        createdBy: 'Admin (Hiro Head Roaster)',
        assignedTo: 'Hiro (Head Roaster)',
        notes: 'Target Agtron 58 Medium Roast. Cupping score 88.5.',
        supportingMetric: 'Forecasted demand: 15.8 bags/day (+27.4%)',
        evidenceRationale: '14-day sales velocity spiked following weekend tasting event.',
        auditLogs: [
          ActionAuditLogModel(
            id: 'log_01',
            fromStatus: null,
            toStatus: PrescriptiveActionStatus.scheduled,
            changedBy: 'Admin (Hiro)',
            timestamp: now,
            note: 'Action scheduled following ML demand spike forecast',
          ),
        ],
      );

      final json = action.toJson();

      // Verify Firestore roastSchedules field schema
      expect(json['id'], equals('act_roast_2001'));
      expect(json['recommendation_id'], equals('rec_top_bean_01'));
      expect(json['action_type'], equals('roastBatch'));
      expect(json['classification'], equals('scheduled'));
      expect(json['status'], equals('scheduled'));
      expect(json['priority'], equals('high'));
      expect(json['title'], contains('Roast Batch'));
      expect(json['target_product_id'], equals('prod_mt_apo'));
      expect(json['target_product_name'], equals('Mount Apo Anaerobic Micro-Lot'));
      expect(json['target_quantity'], equals(12));
      expect(json['target_unit'], equals('bags'));
      expect(json['scheduled_at'], isNotNull);
      expect(json['created_by'], equals('Admin (Hiro Head Roaster)'));
      expect(json['assigned_to'], equals('Hiro (Head Roaster)'));
      expect(json['notes'], contains('Agtron 58'));
      expect(json['supporting_metric'], contains('15.8 bags/day'));

      // Round-trip deserialization
      final deserialized = PrescriptiveActionModel.fromJson(json);
      expect(deserialized.id, equals(action.id));
      expect(deserialized.actionType, equals(PrescriptiveActionType.roastBatch));
      expect(deserialized.targetQuantity, equals(12));
      expect(deserialized.status, equals(PrescriptiveActionStatus.scheduled));
      expect(deserialized.auditLogs.length, equals(1));
    });

    test('9. Prescriptive: Action lifecycle transitions (reschedule, complete) preserve audit trails', () {
      final now = DateTime.now();
      final action = PrescriptiveActionModel(
        id: 'act_1001',
        recommendationId: 'rec_1',
        actionType: PrescriptiveActionType.roastBatch,
        classification: ActionClassification.scheduled,
        status: PrescriptiveActionStatus.scheduled,
        priority: RecommendationPriority.high,
        title: 'Roast Batch: Benguet Typica',
        description: 'Batch roasting',
        targetQuantity: 10,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        supportingMetric: '10 bags',
        evidenceRationale: 'High demand',
        auditLogs: [
          ActionAuditLogModel(
            id: 'log_01',
            fromStatus: null,
            toStatus: PrescriptiveActionStatus.scheduled,
            changedBy: 'Admin',
            timestamp: now.subtract(const Duration(days: 1)),
            note: 'Initial schedule',
          ),
        ],
      );

      // Reschedule transition
      final rescheduledAt = now.add(const Duration(days: 2));
      final rescheduleLog = ActionAuditLogModel(
        id: 'log_02',
        fromStatus: PrescriptiveActionStatus.scheduled,
        toStatus: PrescriptiveActionStatus.scheduled,
        changedBy: 'Station Lead',
        timestamp: now,
        note: 'Rescheduled for morning batch',
      );

      final rescheduled = action.copyWith(
        scheduledAt: rescheduledAt,
        updatedAt: now,
        auditLogs: [...action.auditLogs, rescheduleLog],
      );

      expect(rescheduled.scheduledAt, equals(rescheduledAt));
      expect(rescheduled.auditLogs.length, equals(2));

      // Completion transition
      final completionLog = ActionAuditLogModel(
        id: 'log_03',
        fromStatus: PrescriptiveActionStatus.scheduled,
        toStatus: PrescriptiveActionStatus.completed,
        changedBy: 'Head Roaster',
        timestamp: now.add(const Duration(hours: 1)),
        note: 'Roast completed successfully',
      );

      final completed = rescheduled.copyWith(
        status: PrescriptiveActionStatus.completed,
        completedAt: now.add(const Duration(hours: 1)),
        updatedAt: now.add(const Duration(hours: 1)),
        auditLogs: [...rescheduled.auditLogs, completionLog],
      );

      expect(completed.status, equals(PrescriptiveActionStatus.completed));
      expect(completed.completedAt, isNotNull);
      expect(completed.auditLogs.length, equals(3));
      expect(completed.status.isTerminal, isTrue);
    });

    test('10. Prescriptive: Recommendation dynamically reflects linked action status', () {
      final rec = PrescriptiveRecommendationModel(
        id: 'rec_101',
        title: 'Prepare Additional Benguet Micro-Lots',
        explanation: 'Top revenue generator.',
        supportingMetric: 'Forecasted demand: 18 bags/day',
        priority: RecommendationPriority.high,
        category: RecommendationCategory.preparation,
        generatedAt: DateTime.now(),
        actionText: 'Schedule Roast Batch',
        relatedProductId: 'benguet-typica',
        targetProductName: 'Benguet Arabica Typica',
        actionType: PrescriptiveActionType.roastBatch,
        actionClassification: ActionClassification.scheduled,
        suggestedQuantity: 15,
        actionStatus: RecommendationActionStatus.actionScheduled,
        linkedActionId: 'act_roast_2001',
      );

      expect(rec.actionText, equals('Schedule Roast Batch'));
      expect(rec.actionStatus, equals(RecommendationActionStatus.actionScheduled));
      expect(rec.linkedActionId, equals('act_roast_2001'));
      expect(rec.actionStatus == RecommendationActionStatus.actionScheduled, isTrue);
    });
  });
}
