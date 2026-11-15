import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../models/analytics_summary_model.dart';
import '../models/data_quality_report_model.dart';
import '../models/forecast_readiness_model.dart';

/// Contract for Remote Analytics & Data Quality API
abstract class AnalyticsRemoteDataSource {
  Future<Result<AnalyticsSummaryModel, AppFailure>> getAnalyticsSummary({
    required String dateRange,
    String? categoryId,
    String? productId,
  });

  Future<Result<DataQualityReportModel, AppFailure>> getDataQualityReport();

  Future<Result<ForecastReadinessModel, AppFailure>> getForecastReadiness({
    required String period,
  });
}

/// Concrete Dio-based implementation
class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final ApiClient _apiClient;

  AnalyticsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<AnalyticsSummaryModel, AppFailure>> getAnalyticsSummary({
    required String dateRange,
    String? categoryId,
    String? productId,
  }) {
    final queryParams = <String, String>{
      'date_range': dateRange,
      if (categoryId != null) 'category_id': categoryId,
      if (productId != null) 'product_id': productId,
    };

    return _apiClient.get(
      '/admin/analytics/summary',
      queryParameters: queryParams,
      requiresAuth: true,
      decoder: (data) => AnalyticsSummaryModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<DataQualityReportModel, AppFailure>> getDataQualityReport() {
    return _apiClient.get(
      '/admin/analytics/data-quality',
      requiresAuth: true,
      decoder: (data) => DataQualityReportModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<ForecastReadinessModel, AppFailure>> getForecastReadiness({
    required String period,
  }) {
    return _apiClient.get(
      '/admin/analytics/forecast-readiness',
      queryParameters: {'period': period},
      requiresAuth: true,
      decoder: (data) => ForecastReadinessModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
