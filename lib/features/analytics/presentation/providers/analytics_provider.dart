import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/analytics_remote_datasource.dart';
import '../../data/datasources/firebase_analytics_remote_datasource.dart';
import '../../data/datasources/mock_analytics_remote_datasource.dart';
import '../../data/models/analytics_summary_model.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/repositories/analytics_repository.dart';

/// Provider for Analytics Remote Data Source
final analyticsRemoteDataSourceProvider = Provider<AnalyticsRemoteDataSource>((ref) {
  try {
    if (Firebase.apps.isEmpty) {
      return MockAnalyticsRemoteDataSource();
    }
  } catch (_) {
    return MockAnalyticsRemoteDataSource();
  }
  return FirebaseAnalyticsRemoteDataSource();
});

/// Provider for Domain AnalyticsRepository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final remoteDataSource = ref.watch(analyticsRemoteDataSourceProvider);
  return AnalyticsRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Active Date Range Filter State Provider ("Today", "7D", "30D", "3M")
final analyticsDateRangeProvider = StateProvider<String>((ref) => '30D');

/// Active Category Filter State Provider
final analyticsCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// FutureProvider for Aggregated Analytics Summary
final analyticsSummaryProvider = FutureProvider<AnalyticsSummaryModel>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  final categoryId = ref.watch(analyticsCategoryFilterProvider);

  final result = await repository.getAnalyticsSummary(
    dateRange: dateRange,
    categoryId: categoryId,
  );

  return result.when<AnalyticsSummaryModel>(
    success: (summary) => summary,
    failure: (failure) => throw Exception(failure.message),
  );
});
