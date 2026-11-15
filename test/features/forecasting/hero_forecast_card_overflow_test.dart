import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/forecasting/data/datasources/mock_forecasting_remote_datasource.dart';
import 'package:lambac_app/features/forecasting/data/models/forecast_summary_model.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/hero_forecast_card.dart';

void main() {
  late ForecastSummaryModel summary;

  setUpAll(() async {
    final ds = MockForecastingRemoteDataSource();
    final res = await ds.getForecastSummary(period: '14D');
    summary = res.dataOrNull!;
  });

  Widget buildTestWidget({required double width}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: HeroForecastCard(
                summary: summary,
                onOpenBenchmark: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('HeroForecastCard Horizontal Overflow Regression Tests', () {
    testWidgets('Renders without overflow on standard mobile (390px)', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 390));
      await tester.pumpAndSettle();

      expect(find.text('SALES FORECAST'), findsOneWidget);
      expect(find.text('Why was this model selected?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on narrow mobile (360px)', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 360));
      await tester.pumpAndSettle();

      expect(find.text('SALES FORECAST'), findsOneWidget);
      expect(find.text('Why was this model selected?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on ultra-compact mobile (320px)', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 320));
      await tester.pumpAndSettle();

      expect(find.text('SALES FORECAST'), findsOneWidget);
      expect(find.text('Why was this model selected?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
