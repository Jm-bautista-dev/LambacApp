import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/forecasting/data/datasources/mock_forecasting_remote_datasource.dart';
import 'package:lambac_app/features/forecasting/data/repositories/forecasting_repository_impl.dart';

void main() {
  group('ForecastingRepository Unit Tests', () {
    late MockForecastingRemoteDataSource remoteDataSource;
    late ForecastingRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockForecastingRemoteDataSource();
      repository = ForecastingRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('getForecastSummary returns predicted sales, order volume, and ML metrics', () async {
      final result = await repository.getForecastSummary(period: '14D');

      expect(result.isSuccess, isTrue);
      final summary = result.dataOrNull!;
      expect(summary.hasSufficientData, isTrue);
      expect(summary.expectedSales, greaterThan(0.0));
      expect(summary.expectedOrders, greaterThan(0));
      expect(summary.mape, greaterThan(0.0));
      expect(summary.points.isNotEmpty, isTrue);
      expect(summary.productDemandForecasts.isNotEmpty, isTrue);
    });

    test('getForecastSummary handles insufficient data state gracefully', () async {
      final result = await repository.getForecastSummary(period: 'insufficient');

      expect(result.isSuccess, isTrue);
      final summary = result.dataOrNull!;
      expect(summary.hasSufficientData, isFalse);
      expect(summary.insufficientDataReason, contains('Not enough historical data'));
    });
  });
}
