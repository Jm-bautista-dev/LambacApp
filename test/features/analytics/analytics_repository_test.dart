import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/analytics/data/datasources/mock_analytics_remote_datasource.dart';
import 'package:lambac_app/features/analytics/data/repositories/analytics_repository_impl.dart';

void main() {
  group('AnalyticsRepository Unit Tests', () {
    late MockAnalyticsRemoteDataSource remoteDataSource;
    late AnalyticsRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockAnalyticsRemoteDataSource();
      repository = AnalyticsRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('getAnalyticsSummary returns aggregated KPIs and sales trend points for 30D', () async {
      final result = await repository.getAnalyticsSummary(dateRange: '30D');

      expect(result.isSuccess, isTrue);
      final summary = result.dataOrNull!;
      expect(summary.totalSales, greaterThan(0.0));
      expect(summary.totalOrders, greaterThan(0));
      expect(summary.salesTrends.isNotEmpty, isTrue);
      expect(summary.topProducts.isNotEmpty, isTrue);
      expect(summary.insights.isNotEmpty, isTrue);
    });

    test('getAnalyticsSummary adapts data points when filtering by 7D date range', () async {
      final result = await repository.getAnalyticsSummary(dateRange: '7D');

      expect(result.isSuccess, isTrue);
      final summary = result.dataOrNull!;
      expect(summary.dateRangeLabel, equals('7D'));
      expect(summary.salesTrends.length, equals(7));
    });
  });
}
