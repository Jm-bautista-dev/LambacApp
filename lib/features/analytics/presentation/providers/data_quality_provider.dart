import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/data_quality_report_model.dart';
import '../../data/models/forecast_readiness_model.dart';
import '../../../forecasting/presentation/providers/forecasting_provider.dart';
import 'analytics_provider.dart';

/// FutureProvider for Data Quality Audit Report
final dataQualityReportProvider = FutureProvider<DataQualityReportModel>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final result = await repository.getDataQualityReport();

  return result.when(
    success: (report) => report,
    failure: (failure) => throw Exception(failure.message),
  );
});

/// FutureProvider for Forecast Readiness Assessment
final forecastReadinessProvider = FutureProvider<ForecastReadinessModel>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final period = ref.watch(forecastPeriodProvider);

  final result = await repository.getForecastReadiness(period: period);

  return result.when(
    success: (readiness) => readiness,
    failure: (failure) => throw Exception(failure.message),
  );
});
