import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../data/models/forecast_summary_model.dart';
import '../../data/models/forecasting_benchmark_report_model.dart';

/// Clean Domain Repository Contract for Forecasting Analytics
abstract class ForecastingRepository {
  Future<Result<ForecastSummaryModel, AppFailure>> getForecastSummary({
    required String period,
    String? productId,
  });

  Future<Result<ForecastingBenchmarkReportModel, AppFailure>> getForecastingBenchmarkReport({
    DateTime? startDate,
    DateTime? endDate,
    String granularity = 'Daily',
    bool forceRebenchmark = false,
  });
}

