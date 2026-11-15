import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../data/models/analytics_summary_model.dart';
import '../../data/models/data_quality_report_model.dart';
import '../../data/models/forecast_readiness_model.dart';

/// Clean Domain Repository Contract for Business Analytics & Data Quality
abstract class AnalyticsRepository {
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
