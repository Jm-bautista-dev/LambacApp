import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/forecasting_benchmark_report_model.dart';
import 'forecasting_provider.dart';

/// Active Benchmarking Date Range Filter State Provider
final benchmarkDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
  final thirtyDaysAgo = yesterday.subtract(const Duration(days: 29));
  return DateTimeRange(start: thirtyDaysAgo, end: yesterday);
});

/// Active Time Granularity State Provider ("Daily", "Weekly")
final benchmarkGranularityProvider = StateProvider<String>((ref) => 'Daily');

/// Manual Re-Benchmarking Trigger Nonce (increments on user action)
final rebenchmarkNonceProvider = StateProvider<int>((ref) => 0);

/// Re-benchmarking in-progress animation state
final isRebenchmarkingActiveProvider = StateProvider<bool>((ref) => false);

/// Dedicated Async FutureProvider for the Forecasting Benchmarking Report
final forecastingBenchmarkReportProvider = FutureProvider<ForecastingBenchmarkReportModel>((ref) async {
  final repository = ref.watch(forecastingRepositoryProvider);
  final dateRange = ref.watch(benchmarkDateRangeProvider);
  final granularity = ref.watch(benchmarkGranularityProvider);
  final nonce = ref.watch(rebenchmarkNonceProvider);

  final result = await repository.getForecastingBenchmarkReport(
    startDate: dateRange.start,
    endDate: dateRange.end,
    granularity: granularity,
    forceRebenchmark: nonce > 0,
  );

  return result.when<ForecastingBenchmarkReportModel>(
    success: (report) => report,
    failure: (failure) => throw Exception(failure.message),
  );
});
