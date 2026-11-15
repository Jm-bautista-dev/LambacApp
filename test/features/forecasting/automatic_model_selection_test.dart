import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/forecasting/data/datasources/mock_forecasting_remote_datasource.dart';
import 'package:lambac_app/features/forecasting/data/models/model_benchmark_result.dart';
import 'package:lambac_app/features/forecasting/domain/services/forecasting_model_selection_engine.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/model_benchmark_leaderboard_card.dart';

void main() {
  group('Automatic Forecasting Model Selection & Dynamic Switching Tests', () {
    const engine = ForecastingModelSelectionEngine();

    test('1. Engine evaluates candidate algorithms and ranks them by lowest composite score', () {
      final now = DateTime(2026, 10, 5);
      final dailyRevenues = <DateTime, double>{};

      // 30 days of synthetic sales data with weekly rhythm
      for (int i = 30; i >= 1; i--) {
        final date = now.subtract(Duration(days: i));
        final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
        final base = 1200.0 + (30 - i) * 35.0; // upward linear trend
        final weekendBoost = isWeekend ? 600.0 : 0.0;
        dailyRevenues[date] = base + weekendBoost;
      }

      final summary = engine.selectBestModelAndForecast(
        dailyActualRevenues: dailyRevenues,
        productSalesMap: const {},
        horizonDays: 14,
        periodLabel: 'Next 14 Days',
      );

      expect(summary.hasSufficientData, isTrue);
      expect(summary.benchmarkResults.isNotEmpty, isTrue);
      expect(summary.benchmarkResults.length, equals(7));

      // Verify leaderboards are ordered ascending by composite error score
      for (int i = 0; i < summary.benchmarkResults.length - 1; i++) {
        expect(
          summary.benchmarkResults[i].compositeScore,
          lessThanOrEqualTo(summary.benchmarkResults[i + 1].compositeScore),
        );
        expect(summary.benchmarkResults[i].rank, equals(i + 1));
      }

      // Rank 1 is marked as winner
      expect(summary.benchmarkResults.first.isWinner, isTrue);
      expect(summary.winningCandidateType, isNotNull);
      expect(summary.modelName, equals(summary.benchmarkResults.first.modelName));
      expect(summary.selectionReason, contains(summary.modelName));

      // Metrics exist and are non-negative
      expect(summary.mae, greaterThanOrEqualTo(0.0));
      expect(summary.rmse, greaterThanOrEqualTo(0.0));
      expect(summary.smape, greaterThanOrEqualTo(0.0));
      expect(summary.expectedLowerRange, lessThanOrEqualTo(summary.expectedSales));
      expect(summary.expectedUpperRange, greaterThanOrEqualTo(summary.expectedSales));
    });

    test('2. Dynamic Model Switching: Flat/Stable series favors Moving Average / SES over high-degree curves', () {
      final now = DateTime(2026, 10, 5);
      final stableRevenues = <DateTime, double>{};

      // 25 days of almost completely flat steady sales
      for (int i = 25; i >= 1; i--) {
        final date = now.subtract(Duration(days: i));
        stableRevenues[date] = 1000.0 + (i % 2 == 0 ? 10.0 : -10.0);
      }

      final summary = engine.selectBestModelAndForecast(
        dailyActualRevenues: stableRevenues,
        productSalesMap: const {},
        horizonDays: 7,
        periodLabel: 'Next 7 Days',
      );

      expect(summary.hasSufficientData, isTrue);
      final winner = summary.benchmarkResults.first;
      // Moving Average, Exponential Smoothing, or Linear Regression should have extremely low error
      expect(winner.smape, lessThan(10.0));
    });

    test('3. Data Sufficiency Check: Under 7 days returns Insufficient Data state', () {
      final now = DateTime(2026, 10, 5);
      final sparseRevenues = <DateTime, double>{
        now.subtract(const Duration(days: 3)): 500.0,
        now.subtract(const Duration(days: 2)): 600.0,
        now.subtract(const Duration(days: 1)): 700.0,
      };

      final summary = engine.selectBestModelAndForecast(
        dailyActualRevenues: sparseRevenues,
        productSalesMap: const {},
        horizonDays: 14,
        periodLabel: 'Next 14 Days',
      );

      expect(summary.hasSufficientData, isFalse);
      expect(summary.insufficientDataReason, contains('Insufficient historical sales data'));
      expect(summary.benchmarkResults.isEmpty, isTrue);
      expect(summary.expectedSales, equals(0.0));
    });

    test('4. Remote DataSource integrates Model Selection Engine on real historical sales ledger', () async {
      final dataSource = MockForecastingRemoteDataSource();
      final result = await dataSource.getForecastSummary(period: '14D');

      expect(result.isSuccess, isTrue);
      final summary = result.dataOrNull!;

      expect(summary.hasSufficientData, isTrue);
      expect(summary.benchmarkResults.length, equals(7));
      expect(summary.modelName.isNotEmpty, isTrue);
      expect(summary.expectedSales, greaterThan(0.0));
      expect(summary.expectedLowerRange, greaterThan(0.0));
      expect(summary.expectedUpperRange, greaterThan(summary.expectedLowerRange));
    });

    testWidgets('5. ModelBenchmarkLeaderboardCard renders winning model and candidate ranks', (tester) async {
      final summary = engine.selectBestModelAndForecast(
        dailyActualRevenues: {
          for (int i = 20; i >= 1; i--)
            DateTime(2026, 9, i): 800.0 + (i * 20.0) + (i % 7 == 0 ? 300.0 : 0.0),
        },
        productSalesMap: const {},
        horizonDays: 14,
        periodLabel: 'Next 14 Days',
      );

      bool rebenchmarked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModelBenchmarkLeaderboardCard(
                summary: summary,
                onRebenchmark: () => rebenchmarked = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Automatic Model Selection'), findsOneWidget);
      expect(find.text('RANK 1 WINNER'), findsOneWidget);
      expect(find.text(summary.modelName), findsAtLeastNWidgets(1));
      expect(find.textContaining('BENCHMARK CANDIDATE LEADERBOARD'), findsOneWidget);

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(rebenchmarked, isTrue);
    });
  });
}
