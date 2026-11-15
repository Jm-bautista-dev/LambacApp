import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/analytics/data/datasources/mock_analytics_remote_datasource.dart';
import 'package:lambac_app/features/analytics/data/models/forecast_readiness_model.dart';
import 'package:lambac_app/features/analytics/data/repositories/analytics_repository_impl.dart';

void main() {
  group('Forecast Readiness Assessment Unit Tests', () {
    late MockAnalyticsRemoteDataSource remoteDataSource;
    late AnalyticsRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockAnalyticsRemoteDataSource();
      repository = AnalyticsRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('getForecastReadiness returns READY status when dataset satisfies 14-day threshold', () async {
      final result = await repository.getForecastReadiness(period: '14D');

      expect(result.isSuccess, isTrue);
      final readiness = result.dataOrNull!;
      expect(readiness.status, equals(ReadinessStatus.ready));
      expect(readiness.isReady, isTrue);
      expect(readiness.historicalRecordCount, greaterThan(0));
      expect(readiness.historicalDaySpan, greaterThan(0));
    });

    test('getForecastReadiness returns INSUFFICIENT status with missing requirements when dataset < 14 days', () async {
      final result = await repository.getForecastReadiness(period: 'insufficient');

      expect(result.isSuccess, isTrue);
      final readiness = result.dataOrNull!;
      expect(readiness.status, equals(ReadinessStatus.insufficient));
      expect(readiness.isReady, isFalse);
      expect(readiness.missingRequirements.isNotEmpty, isTrue);
      expect(readiness.missingRequirements.first, contains('Requires at least 14 days'));
    });
  });
}
