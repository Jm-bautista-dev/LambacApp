import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/theme/app_theme.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/benchmarking_date_filter_bar.dart';
import 'package:lambac_app/features/forecasting/presentation/widgets/forecast_control_bar.dart';

void main() {
  group('BenchmarkingDateFilterBar and ForecastControlBar Overflow Tests', () {
    const testViewports = [
      Size(320, 600), // Narrow mobile (e.g. small Android / iPhone SE)
      Size(360, 800), // Standard Android phone (previously triggered 216px and 87px overflows)
      Size(390, 844), // iPhone 12/13/14
      Size(412, 915), // Pixel 7 / Galaxy S21
      Size(800, 1000), // Tablet / Web small pane
      Size(1200, 900), // Desktop Web
    ];

    for (final size in testViewports) {
      testWidgets('BenchmarkingDateFilterBar renders with zero RenderFlex overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final oldOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint('FLUTTER_ERROR_DETAILS:\n${details.toString()}');
          oldOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldOnError);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BenchmarkingDateFilterBar(
                      onExport: () {},
                      onRunBenchmark: () {},
                      isRebenchmarking: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Must find the interactive action buttons and preset chips without any layout errors
        expect(find.text('BENCHMARKING PERIOD'), findsOneWidget);
        expect(find.text('Change Date'), findsOneWidget);
        expect(find.text('Export Benchmark'), findsOneWidget);
        expect(find.text('Run Benchmark'), findsOneWidget);
        expect(find.text('Presets: '), findsOneWidget);
        expect(find.text('Last 7D'), findsOneWidget);
        expect(find.text('Last 14D'), findsOneWidget);
        expect(find.text('Last 30D'), findsOneWidget);
        expect(find.text('Granularity: '), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ForecastControlBar renders with zero RenderFlex overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ForecastControlBar(
                      onRefreshForecast: () {},
                      onRebenchmark: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('7 Days'), findsOneWidget);
        expect(find.text('14 Days'), findsOneWidget);
        expect(find.text('30 Days'), findsOneWidget);
        expect(find.text('Refresh Forecast'), findsOneWidget);
        expect(find.text('Re-Benchmark'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
