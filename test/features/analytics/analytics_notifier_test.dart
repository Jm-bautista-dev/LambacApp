import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/analytics/data/datasources/mock_analytics_remote_datasource.dart';
import 'package:lambac_app/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:lambac_app/features/analytics/presentation/providers/analytics_provider.dart';

void main() {
  group('Analytics State & Provider Unit Tests', () {
    late MockAnalyticsRemoteDataSource remoteDataSource;
    late AnalyticsRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockAnalyticsRemoteDataSource();
      repository = AnalyticsRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('analyticsDateRangeProvider defaults to 30D and triggers provider update', () async {
      final container = ProviderContainer(
        overrides: [
          analyticsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(analyticsDateRangeProvider), equals('30D'));

      final summary = await container.read(analyticsSummaryProvider.future);
      expect(summary.totalSales, greaterThan(0.0));

      // Switch date range to 7D
      container.read(analyticsDateRangeProvider.notifier).state = '7D';
      expect(container.read(analyticsDateRangeProvider), equals('7D'));
    });
  });
}
