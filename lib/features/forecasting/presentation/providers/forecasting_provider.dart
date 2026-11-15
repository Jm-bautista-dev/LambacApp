import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_forecasting_remote_datasource.dart';
import '../../data/datasources/forecasting_remote_datasource.dart';
import '../../data/models/forecast_summary_model.dart';
import '../../data/repositories/forecasting_repository_impl.dart';
import '../../domain/repositories/forecasting_repository.dart';

/// Provider for Forecasting Remote Data Source
final forecastingRemoteDataSourceProvider = Provider<ForecastingRemoteDataSource>((ref) {
  return FirebaseForecastingRemoteDataSource();
});

/// Provider for Domain ForecastingRepository
final forecastingRepositoryProvider = Provider<ForecastingRepository>((ref) {
  final remoteDataSource = ref.watch(forecastingRemoteDataSourceProvider);
  return ForecastingRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Active Forecast Period State Provider ("7D", "14D", "15D", "30D")
final forecastPeriodProvider = StateProvider<String>((ref) => '14D');

/// Active Selected Product State Provider
final forecastSelectedProductProvider = StateProvider<String?>((ref) => null);

/// FutureProvider for Forecasting Analytics Summary
final forecastSummaryProvider = FutureProvider<ForecastSummaryModel>((ref) async {
  final repository = ref.watch(forecastingRepositoryProvider);
  final period = ref.watch(forecastPeriodProvider);
  final productId = ref.watch(forecastSelectedProductProvider);

  final result = await repository.getForecastSummary(
    period: period,
    productId: productId,
  );

  return result.when<ForecastSummaryModel>(
    success: (summary) => summary,
    failure: (failure) => throw Exception(failure.message),
  );
});
