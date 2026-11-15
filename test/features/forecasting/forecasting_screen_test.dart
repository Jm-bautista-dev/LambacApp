import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/forecasting/data/datasources/mock_forecasting_remote_datasource.dart';
import 'package:lambac_app/features/forecasting/data/repositories/forecasting_repository_impl.dart';
import 'package:lambac_app/features/forecasting/presentation/providers/forecasting_provider.dart';
import 'package:lambac_app/features/forecasting/presentation/screens/forecasting_screen.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/hero_forecast_card.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/how_forecasting_works_card.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/model_benchmark_preview_card.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/model_reliability_card.dart';

void main() {
  late MockForecastingRemoteDataSource remoteDataSource;
  late ForecastingRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockForecastingRemoteDataSource();
    repository = ForecastingRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  Widget buildTestableWidget(Widget child, {String period = '14D'}) {
    return ProviderScope(
      overrides: [
        forecastingRepositoryProvider.overrideWithValue(repository),
        forecastPeriodProvider.overrideWith((ref) => period),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('ForecastingScreen Widget Tests', () {
    testWidgets('ForecastingScreen renders hero card, benchmark preview, chart, reliability & how it works', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const ForecastingScreen()));

      expect(find.text('Sales & Demand Forecasting'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.byType(HeroForecastCard), findsOneWidget);
      expect(find.text('SALES FORECAST'), findsOneWidget);
      expect(find.text('Why was this model selected?'), findsOneWidget);
      expect(find.byType(ModelBenchmarkPreviewCard), findsOneWidget);
      expect(find.text('Model Benchmark'), findsOneWidget);
      expect(find.text('Historical Sales vs. Forecast Projection'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byType(ModelReliabilityCard),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(ModelReliabilityCard), findsOneWidget);
      expect(find.text('Model Reliability & Validation Metrics'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byType(HowForecastingWorksCard),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(HowForecastingWorksCard), findsOneWidget);
      expect(find.text('How Forecasting Works'), findsOneWidget);
    });

    testWidgets('ForecastingScreen renders insufficient historical data alert state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const ForecastingScreen(), period: 'insufficient'));

      expect(find.text('Sales & Demand Forecasting'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Not Enough Historical Data'), findsOneWidget);
      expect(find.textContaining('Not enough historical data'), findsOneWidget);
    });
  });
}
