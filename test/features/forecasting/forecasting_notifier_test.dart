import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/forecasting/data/datasources/mock_forecasting_remote_datasource.dart';
import 'package:lambac_app/features/forecasting/data/repositories/forecasting_repository_impl.dart';
import 'package:lambac_app/features/forecasting/presentation/providers/forecasting_provider.dart';

void main() {
  group('Forecasting State & Provider Unit Tests', () {
    late MockForecastingRemoteDataSource remoteDataSource;
    late ForecastingRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockForecastingRemoteDataSource();
      repository = ForecastingRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('forecastPeriodProvider defaults to 14D and updates forecast summary', () async {
      final container = ProviderContainer(
        overrides: [
          forecastingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(forecastPeriodProvider), equals('14D'));

      final summary = await container.read(forecastSummaryProvider.future);
      expect(summary.forecastPeriod, equals('Next 14 Days'));
      expect(summary.hasSufficientData, isTrue);

      // Switch period to 30D
      container.read(forecastPeriodProvider.notifier).state = '30D';
      expect(container.read(forecastPeriodProvider), equals('30D'));
    });
  });
}
