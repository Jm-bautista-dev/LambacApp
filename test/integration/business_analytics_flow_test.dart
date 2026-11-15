import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/analytics/data/datasources/mock_analytics_remote_datasource.dart';
import 'package:lambac_app/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:lambac_app/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:lambac_app/features/forecasting/data/datasources/mock_forecasting_remote_datasource.dart';
import 'package:lambac_app/features/forecasting/data/repositories/forecasting_repository_impl.dart';
import 'package:lambac_app/features/forecasting/presentation/providers/forecasting_provider.dart';
import 'package:lambac_app/features/prescriptive/data/datasources/mock_prescriptive_remote_datasource.dart';
import 'package:lambac_app/features/prescriptive/data/repositories/prescriptive_repository_impl.dart';
import 'package:lambac_app/features/prescriptive/presentation/providers/prescriptive_provider.dart';
import 'package:lambac_app/features/prescriptive/presentation/screens/business_intelligence_screen.dart';

void main() {
  group('Integration Test: Business Intelligence Hub (Descriptive + Forecasting + Prescriptive)', () {
    late MockAnalyticsRemoteDataSource analyticsRemoteDataSource;
    late AnalyticsRepositoryImpl analyticsRepository;
    late MockForecastingRemoteDataSource forecastingRemoteDataSource;
    late ForecastingRepositoryImpl forecastingRepository;
    late MockPrescriptiveRemoteDataSource prescriptiveRemoteDataSource;
    late PrescriptiveRepositoryImpl prescriptiveRepository;

    setUp(() {
      analyticsRemoteDataSource = MockAnalyticsRemoteDataSource();
      analyticsRepository = AnalyticsRepositoryImpl(remoteDataSource: analyticsRemoteDataSource);

      forecastingRemoteDataSource = MockForecastingRemoteDataSource();
      forecastingRepository = ForecastingRepositoryImpl(remoteDataSource: forecastingRemoteDataSource);

      prescriptiveRemoteDataSource = MockPrescriptiveRemoteDataSource();
      prescriptiveRepository = PrescriptiveRepositoryImpl(remoteDataSource: prescriptiveRemoteDataSource);
    });

    testWidgets('Unified BI Hub loads Descriptive, Forecasting, and Prescriptive tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(analyticsRepository),
            forecastingRepositoryProvider.overrideWithValue(forecastingRepository),
            prescriptiveRepositoryProvider.overrideWithValue(prescriptiveRepository),
          ],
          child: const MaterialApp(
            home: BusinessIntelligenceScreen(initialTabIndex: 3),
          ),
        ),
      );

      expect(find.text('Business Intelligence Hub'), findsOneWidget);
      expect(find.text('3. Prescriptive'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('High Priority'), findsOneWidget);
    });
  });
}
