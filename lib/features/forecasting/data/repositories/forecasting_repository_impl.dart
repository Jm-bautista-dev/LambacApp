import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../domain/repositories/forecasting_repository.dart';
import '../datasources/forecasting_remote_datasource.dart';
import '../models/forecast_summary_model.dart';
import '../models/forecasting_benchmark_report_model.dart';

/// Concrete ForecastingRepository implementation
class ForecastingRepositoryImpl implements ForecastingRepository {
  final ForecastingRemoteDataSource _remoteDataSource;

  ForecastingRepositoryImpl({required ForecastingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<ForecastSummaryModel, AppFailure>> getForecastSummary({
    required String period,
    String? productId,
  }) {
    return _remoteDataSource.getForecastSummary(
      period: period,
      productId: productId,
    );
  }

  @override
  Future<Result<ForecastingBenchmarkReportModel, AppFailure>> getForecastingBenchmarkReport({
    DateTime? startDate,
    DateTime? endDate,
    String granularity = 'Daily',
    bool forceRebenchmark = false,
  }) {
    return _remoteDataSource.getForecastingBenchmarkReport(
      startDate: startDate,
      endDate: endDate,
      granularity: granularity,
      forceRebenchmark: forceRebenchmark,
    );
  }
}

