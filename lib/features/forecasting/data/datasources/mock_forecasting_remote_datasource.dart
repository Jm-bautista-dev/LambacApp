import 'dart:async';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../products/data/datasources/mock_product_remote_datasource.dart';
import '../../../sales/data/datasources/mock_sales_remote_datasource.dart';
import '../../domain/services/forecasting_model_selection_engine.dart';
import '../models/benchmark_history_entry_model.dart';
import '../models/forecast_summary_model.dart';
import '../models/forecasting_benchmark_report_model.dart';
import '../models/model_benchmark_result.dart';
import 'forecasting_remote_datasource.dart';

/// Dynamic Statistical Forecasting Data Source with Automated Model Selection
/// Continuously benchmarks candidate models (Linear, Polynomial, SES, Holt's, Holt-Winters, MA, Naive)
/// using rolling-origin backtesting against actual transaction history.
class MockForecastingRemoteDataSource implements ForecastingRemoteDataSource {
  static final MockForecastingRemoteDataSource _instance = MockForecastingRemoteDataSource._internal();
  factory MockForecastingRemoteDataSource() => _instance;

  final MockSalesRemoteDataSource _salesDataSource = MockSalesRemoteDataSource();
  final MockProductRemoteDataSource _productDataSource = MockProductRemoteDataSource();
  final ForecastingModelSelectionEngine _engine = const ForecastingModelSelectionEngine();

  final List<BenchmarkHistoryEntryModel> _historyLog = [];

  MockForecastingRemoteDataSource._internal() {
    _seedBenchmarkHistory();
  }

  void _seedBenchmarkHistory() {
    final now = DateTime.now();
    _historyLog.addAll([
      BenchmarkHistoryEntryModel(
        id: 'bench_audit_01',
        timestamp: now.subtract(const Duration(hours: 3)),
        evaluationPeriodLabel: 'Sep 1 – Sep 30, 2026',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
        granularity: 'Daily',
        winningModelName: 'Holt-Winters Seasonal (Triple ES)',
        winningCandidateType: ModelCandidateType.holtWintersSeasonal,
        mae: 290.40,
        rmse: 390.15,
        mape: 9.8,
        smape: 9.5,
        compositeScore: 10.8,
        modelsEvaluatedCount: 7,
        status: 'BEST (Selected)',
      ),
      BenchmarkHistoryEntryModel(
        id: 'bench_audit_02',
        timestamp: DateTime(2026, 9, 30, 18, 30),
        evaluationPeriodLabel: 'Aug 1 – Aug 31, 2026',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
        granularity: 'Daily',
        winningModelName: "Holt's Linear Trend (Double ES)",
        winningCandidateType: ModelCandidateType.holtsTrend,
        mae: 360.20,
        rmse: 470.80,
        mape: 11.9,
        smape: 11.4,
        compositeScore: 14.7,
        modelsEvaluatedCount: 7,
        status: 'Evaluated',
      ),
      BenchmarkHistoryEntryModel(
        id: 'bench_audit_03',
        timestamp: DateTime(2026, 8, 31, 19, 0),
        evaluationPeriodLabel: 'Jul 1 – Jul 31, 2026',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        granularity: 'Daily',
        winningModelName: 'Linear Regression (OLS)',
        winningCandidateType: ModelCandidateType.linearRegression,
        mae: 420.50,
        rmse: 560.10,
        mape: 14.2,
        smape: 13.9,
        compositeScore: 18.4,
        modelsEvaluatedCount: 7,
        status: 'Evaluated',
      ),
    ]);
  }

  @override
  Future<Result<ForecastSummaryModel, AppFailure>> getForecastSummary({
    required String period,
    String? productId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (period.toLowerCase() == 'insufficient') {
      return Result.success(ForecastSummaryModel.insufficientData());
    }

    final horizonDays = switch (period.toUpperCase()) {
      '7D' || '7 DAYS' => 7,
      '15D' || '15 DAYS' => 15,
      '30D' || '30 DAYS' => 30,
      '14D' || '14 DAYS' => 14,
      _ => 14,
    };

    final forecastPeriodLabel = 'Next $horizonDays Days';

    final allSales = _salesDataSource.getAllSales(includeVoided: false);
    if (allSales.length < 5) {
      return Result.success(
        ForecastSummaryModel.insufficientData(
          reason: 'Insufficient historical sales data for reliable forecasting. At least 7-14 days of store transaction history are required to project reliable demand.',
        ),
      );
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);

    const historyDays = 30;
    final historyStart = todayStart.subtract(const Duration(days: historyDays));

    final dailyActualMap = <DateTime, double>{};

    for (int i = 0; i < historyDays; i++) {
      final d = historyStart.add(Duration(days: i));
      final dayKey = DateTime(d.year, d.month, d.day);
      dailyActualMap[dayKey] = 0.0;
    }

    for (final sale in allSales) {
      final saleDate = DateTime(sale.createdAt.year, sale.createdAt.month, sale.createdAt.day);
      if (saleDate.isAfter(historyStart.subtract(const Duration(milliseconds: 1))) &&
          saleDate.isBefore(todayStart)) {
        if (productId == null || productId.isEmpty || sale.items.any((item) => item.productId == productId)) {
          final amt = productId != null && productId.isNotEmpty
              ? sale.items.where((i) => i.productId == productId).fold(0.0, (sum, i) => sum + i.totalPrice)
              : sale.totalAmount;
          dailyActualMap[saleDate] = (dailyActualMap[saleDate] ?? 0.0) + amt;
        }
      }
    }

    final productSalesCounts = <String, ({String name, String category, int totalUnits, double totalRev})>{};
    for (final sale in allSales) {
      if (sale.createdAt.isAfter(historyStart)) {
        for (final item in sale.items) {
          final prev = productSalesCounts[item.productId];
          if (prev != null) {
            productSalesCounts[item.productId] = (
              name: item.productName,
              category: prev.category,
              totalUnits: prev.totalUnits + item.quantity,
              totalRev: prev.totalRev + item.totalPrice,
            );
          } else {
            productSalesCounts[item.productId] = (
              name: item.productName,
              category: 'Roastery Reserve',
              totalUnits: item.quantity,
              totalRev: item.totalPrice,
            );
          }
        }
      }
    }

    final forecastSummary = _engine.selectBestModelAndForecast(
      dailyActualRevenues: dailyActualMap,
      productSalesMap: productSalesCounts,
      horizonDays: horizonDays,
      periodLabel: forecastPeriodLabel,
    );

    return Result.success(forecastSummary);
  }

  @override
  Future<Result<ForecastingBenchmarkReportModel, AppFailure>> getForecastingBenchmarkReport({
    DateTime? startDate,
    DateTime? endDate,
    String granularity = 'Daily',
    bool forceRebenchmark = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);

    final effectiveEnd = endDate ?? todayStart.subtract(const Duration(days: 1));
    final effectiveStart = startDate ?? effectiveEnd.subtract(const Duration(days: 29));

    final allSales = _salesDataSource.getAllSales(includeVoided: false);
    if (allSales.isEmpty) {
      return Result.success(
        ForecastingBenchmarkReportModel.insufficientData(
          startDate: effectiveStart,
          endDate: effectiveEnd,
          reason: 'No completed sales found in historical ledger.',
        ),
      );
    }

    // Build continuous map across the date span
    final dailyMap = <DateTime, double>{};
    final spanDays = effectiveEnd.difference(effectiveStart).inDays + 1;

    for (int i = 0; i < spanDays; i++) {
      final d = effectiveStart.add(Duration(days: i));
      final dayKey = DateTime(d.year, d.month, d.day);
      dailyMap[dayKey] = 0.0;
    }

    for (final sale in allSales) {
      final sDate = DateTime(sale.createdAt.year, sale.createdAt.month, sale.createdAt.day);
      if (!sDate.isBefore(effectiveStart) && !sDate.isAfter(effectiveEnd)) {
        dailyMap[sDate] = (dailyMap[sDate] ?? 0.0) + sale.totalAmount;
      }
    }

    final report = _engine.generateDedicatedBenchmarkReport(
      dailyActualRevenues: dailyMap,
      startDate: effectiveStart,
      endDate: effectiveEnd,
      granularity: granularity,
      history: List.unmodifiable(_historyLog),
    );

    // If rebenchmarking, record an audit entry
    if (forceRebenchmark && report.hasSufficientData) {
      final newEntry = BenchmarkHistoryEntryModel(
        id: 'bench_audit_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        evaluationPeriodLabel: report.evaluationPeriodLabel,
        startDate: report.startDate,
        endDate: report.endDate,
        granularity: report.granularity,
        winningModelName: report.winningModel.modelName,
        winningCandidateType: report.winningModel.candidateType,
        mae: report.winningModel.mae,
        rmse: report.winningModel.rmse,
        mape: report.winningModel.mape,
        smape: report.winningModel.smape,
        compositeScore: report.winningModel.compositeScore,
        modelsEvaluatedCount: report.benchmarkResults.length,
        status: 'BEST (Selected)',
      );
      _historyLog.insert(0, newEntry);
    }

    return Result.success(
      ForecastingBenchmarkReportModel(
        benchmarkTimestamp: report.benchmarkTimestamp,
        startDate: report.startDate,
        endDate: report.endDate,
        granularity: report.granularity,
        evaluationPeriodLabel: report.evaluationPeriodLabel,
        hasSufficientData: report.hasSufficientData,
        insufficientDataReason: report.insufficientDataReason,
        winningModel: report.winningModel,
        benchmarkResults: report.benchmarkResults,
        backtestPoints: report.backtestPoints,
        totalObservedPoints: report.totalObservedPoints,
        trainingPoints: report.trainingPoints,
        validationPoints: report.validationPoints,
        winnerExplanation: report.winnerExplanation,
        status: 'Up to date',
        history: List.unmodifiable(_historyLog),
      ),
    );
  }
}

