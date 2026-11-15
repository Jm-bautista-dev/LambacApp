import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../models/forecast_summary_model.dart';
import '../models/forecasting_benchmark_report_model.dart';

/// Contract for Remote ML Forecasting API
abstract class ForecastingRemoteDataSource {
  Future<Result<ForecastSummaryModel, AppFailure>> getForecastSummary({
    required String period, // "7D", "14D", "30D"
    String? productId,
  });

  Future<Result<ForecastingBenchmarkReportModel, AppFailure>> getForecastingBenchmarkReport({
    DateTime? startDate,
    DateTime? endDate,
    String granularity = 'Daily',
    bool forceRebenchmark = false,
  });
}

/// Concrete Dio-based implementation
class ForecastingRemoteDataSourceImpl implements ForecastingRemoteDataSource {
  final ApiClient _apiClient;

  ForecastingRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<ForecastSummaryModel, AppFailure>> getForecastSummary({
    required String period,
    String? productId,
  }) {
    final queryParams = <String, String>{
      'period': period,
      if (productId != null && productId.isNotEmpty) 'product_id': productId,
    };

    return _apiClient.get(
      '/admin/forecasting/summary',
      queryParameters: queryParams,
      requiresAuth: true,
      decoder: (data) => ForecastSummaryModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<ForecastingBenchmarkReportModel, AppFailure>> getForecastingBenchmarkReport({
    DateTime? startDate,
    DateTime? endDate,
    String granularity = 'Daily',
    bool forceRebenchmark = false,
  }) {
    final queryParams = <String, String>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      'granularity': granularity,
      'force_rebenchmark': forceRebenchmark.toString(),
    };

    return _apiClient.get(
      '/admin/forecasting/benchmark',
      queryParameters: queryParams,
      requiresAuth: true,
      decoder: (data) => data as ForecastingBenchmarkReportModel,
    );
  }
}

