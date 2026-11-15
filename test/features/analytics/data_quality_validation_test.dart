import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/analytics/data/datasources/mock_analytics_remote_datasource.dart';
import 'package:lambac_app/features/analytics/data/repositories/analytics_repository_impl.dart';

void main() {
  group('Analytics Data Quality Pipeline Unit Tests', () {
    late MockAnalyticsRemoteDataSource remoteDataSource;
    late AnalyticsRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockAnalyticsRemoteDataSource();
      repository = AnalyticsRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('getDataQualityReport audits store sales dataset and calculates completeness score', () async {
      final result = await repository.getDataQualityReport();

      expect(result.isSuccess, isTrue);
      final report = result.dataOrNull!;
      expect(report.totalRecordsProcessed, greaterThan(0));
      expect(report.validRecordsCount, greaterThan(0));
      expect(report.corruptedRecordsCount, equals(0));
      expect(report.completenessScorePercent, greaterThanOrEqualTo(90.0));
      expect(report.mobileAppCount, greaterThan(0));
      expect(report.walkInCount, equals(0));
      expect(report.isClean, isTrue);
    });
  });
}
