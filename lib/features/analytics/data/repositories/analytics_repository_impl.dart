import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';
import '../models/analytics_summary_model.dart';
import '../models/data_quality_report_model.dart';
import '../models/forecast_readiness_model.dart';

/// Concrete AnalyticsRepository implementation
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource _remoteDataSource;

  AnalyticsRepositoryImpl({required AnalyticsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<AnalyticsSummaryModel, AppFailure>> getAnalyticsSummary({
    required String dateRange,
    String? categoryId,
    String? productId,
  }) {
    return _remoteDataSource.getAnalyticsSummary(
      dateRange: dateRange,
      categoryId: categoryId,
      productId: productId,
    );
  }

  @override
  Future<Result<DataQualityReportModel, AppFailure>> getDataQualityReport() {
    return _remoteDataSource.getDataQualityReport();
  }

  @override
  Future<Result<ForecastReadinessModel, AppFailure>> getForecastReadiness({
    required String period,
  }) {
    return _remoteDataSource.getForecastReadiness(period: period);
  }
}
