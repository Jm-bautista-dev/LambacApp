import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/theme/app_theme.dart';
import 'package:lambac_app/features/forecasting/data/datasources/mock_forecasting_remote_datasource.dart';
import 'package:lambac_app/features/forecasting/data/models/model_benchmark_result.dart';
import 'package:lambac_app/features/forecasting/data/repositories/forecasting_repository_impl.dart';
import 'package:lambac_app/features/forecasting/domain/services/forecasting_model_selection_engine.dart';
import 'package:lambac_app/features/forecasting/presentation/providers/forecasting_benchmarking_provider.dart';
import 'package:lambac_app/features/forecasting/presentation/providers/forecasting_provider.dart';
import 'package:lambac_app/features/forecasting/presentation/screens/forecasting_benchmarking_screen.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/benchmarking_comparison_table.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/benchmarking_kpi_header.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/benchmarking_methodology_flow_card.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/export_benchmark_dialog.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/model_inspection_dialog.dart';

void main() {
  group('ForecastingModelSelectionEngine Dedicated Benchmarking Tests', () {
    const engine = ForecastingModelSelectionEngine();

    test('generates complete benchmark report across candidate algorithms', () {
      final now = DateTime.now();
      final dailyRevenues = <DateTime, double>{};

      // 30 days of synthetic coffee sales with weekend spikes
      for (int i = 0; i < 30; i++) {
        final d = now.subtract(Duration(days: 30 - i));
        final dayKey = DateTime(d.year, d.month, d.day);
        final isWeekend = d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
        dailyRevenues[dayKey] = 500.0 + (i * 15.0) + (isWeekend ? 350.0 : 0.0);
      }

      final start = now.subtract(const Duration(days: 30));
      final end = now.subtract(const Duration(days: 1));

      final report = engine.generateDedicatedBenchmarkReport(
        dailyActualRevenues: dailyRevenues,
        startDate: start,
        endDate: end,
        granularity: 'Daily',
      );

      expect(report.hasSufficientData, isTrue);
      expect(report.benchmarkResults.length, equals(7));
      expect(report.winningModel.rank, equals(1));
      expect(report.winningModel.isWinner, isTrue);
      expect(report.winningModel.mae, isPositive);
      expect(report.winningModel.rmse, isPositive);
      expect(report.winningModel.smape, isPositive);
      expect(report.backtestPoints.isNotEmpty, isTrue);
      expect(report.winnerExplanation, contains(report.winningModel.modelName));
      expect(report.trainingPoints, isPositive);
      expect(report.validationPoints, isPositive);
    });

    test('handles weekly granularity and short date spans gracefully', () {
      final now = DateTime.now();
      final dailyRevenues = <DateTime, double>{};

      for (int i = 0; i < 35; i++) {
        final d = now.subtract(Duration(days: 35 - i));
        final dayKey = DateTime(d.year, d.month, d.day);
        dailyRevenues[dayKey] = 600.0 + i * 10;
      }

      final report = engine.generateDedicatedBenchmarkReport(
        dailyActualRevenues: dailyRevenues,
        startDate: now.subtract(const Duration(days: 35)),
        endDate: now.subtract(const Duration(days: 1)),
        granularity: 'Weekly',
      );

      expect(report.hasSufficientData, isTrue);
      expect(report.granularity, equals('Weekly'));
    });

    test('returns insufficient data report when observation count is below threshold', () {
      final now = DateTime.now();
      final dailyRevenues = <DateTime, double>{
        now.subtract(const Duration(days: 2)): 100.0,
        now.subtract(const Duration(days: 1)): 200.0,
      };

      final report = engine.generateDedicatedBenchmarkReport(
        dailyActualRevenues: dailyRevenues,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.subtract(const Duration(days: 1)),
      );

      expect(report.hasSufficientData, isFalse);
      expect(report.status, equals('Insufficient data'));
    });
  });

  group('MockForecastingRemoteDataSource Benchmarking Integration Tests', () {
    test('getForecastingBenchmarkReport returns populated report with history', () async {
      final dataSource = MockForecastingRemoteDataSource();
      final result = await dataSource.getForecastingBenchmarkReport();

      expect(result.isSuccess, isTrue);
      final report = result.dataOrNull!;
      expect(report.hasSufficientData, isTrue);
      expect(report.benchmarkResults.isNotEmpty, isTrue);
      expect(report.history.isNotEmpty, isTrue);
    });

    test('re-benchmarking adds new audit log entry', () async {
      final dataSource = MockForecastingRemoteDataSource();
      final initialResult = await dataSource.getForecastingBenchmarkReport();
      final initialHistoryCount = initialResult.dataOrNull!.history.length;

      final rebenchResult = await dataSource.getForecastingBenchmarkReport(
        forceRebenchmark: true,
      );

      expect(rebenchResult.isSuccess, isTrue);
      expect(rebenchResult.dataOrNull!.history.length, greaterThan(initialHistoryCount));
      expect(rebenchResult.dataOrNull!.history.first.status, contains('BEST'));
    });
  });

  group('Forecasting Benchmarking UI Widgets Tests', () {
    testWidgets('renders BenchmarkingMethodologyFlowCard correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: BenchmarkingMethodologyFlowCard(),
            ),
          ),
        ),
      );

      expect(find.text('Automated Model Selection Methodology'), findsOneWidget);
      expect(find.text('Candidate Models'), findsOneWidget);
      expect(find.text('Walk-Forward Backtesting'), findsOneWidget);
      expect(find.text('Benchmark Ranking'), findsOneWidget);
      expect(find.text('Best Model Winner'), findsOneWidget);
    });

    testWidgets('renders BenchmarkingComparisonTable with candidate models', (tester) async {
      const results = [
        ModelBenchmarkResult(
          candidateType: ModelCandidateType.holtWintersSeasonal,
          modelName: 'Holt-Winters Seasonal (Triple ES)',
          mae: 290.40,
          rmse: 390.15,
          mape: 9.8,
          smape: 9.5,
          compositeScore: 10.8,
          rank: 1,
          isWinner: true,
          rationale: 'Best fit',
        ),
        ModelBenchmarkResult(
          candidateType: ModelCandidateType.linearRegression,
          modelName: 'Linear Regression (OLS)',
          mae: 420.50,
          rmse: 560.10,
          mape: 14.2,
          smape: 13.9,
          compositeScore: 18.4,
          rank: 2,
          isWinner: false,
          rationale: 'Evaluated linear',
        ),
      ];

      ModelBenchmarkResult? inspectedModel;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BenchmarkingComparisonTable(
                results: results,
                onInspectModel: (m) => inspectedModel = m,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Holt-Winters Seasonal (Triple ES)'), findsOneWidget);
      expect(find.text('Linear Regression (OLS)'), findsOneWidget);
      expect(find.text('BEST'), findsOneWidget);
      expect(find.text('Evaluated'), findsOneWidget);

      await tester.tap(find.text('Linear Regression (OLS)'));
      expect(inspectedModel?.modelName, equals('Linear Regression (OLS)'));
    });

    testWidgets('renders ForecastingBenchmarkingScreen successfully', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      const engine = ForecastingModelSelectionEngine();
      final dailyRevenues = <DateTime, double>{};
      for (int i = 0; i < 30; i++) {
        final d = now.subtract(Duration(days: 30 - i));
        dailyRevenues[DateTime(d.year, d.month, d.day)] = 500.0 + (i * 10);
      }

      final sampleReport = engine.generateDedicatedBenchmarkReport(
        dailyActualRevenues: dailyRevenues,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            forecastingBenchmarkReportProvider.overrideWith((ref) => sampleReport),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ForecastingBenchmarkingScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(ForecastingBenchmarkingScreen), findsOneWidget);
      expect(find.text('BENCHMARKING PERIOD'), findsOneWidget);
      expect(find.text('CURRENT BEST MODEL'), findsOneWidget);
      expect(find.text('Run Benchmark'), findsOneWidget);
      expect(find.text('Export Benchmark'), findsOneWidget);
    });
  });
}
