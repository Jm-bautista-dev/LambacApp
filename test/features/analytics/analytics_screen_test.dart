import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/analytics/data/datasources/mock_analytics_remote_datasource.dart';
import 'package:lambac_app/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:lambac_app/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:lambac_app/features/analytics/presentation/screens/analytics_screen.dart';

void main() {
  late MockAnalyticsRemoteDataSource remoteDataSource;
  late AnalyticsRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockAnalyticsRemoteDataSource();
    repository = AnalyticsRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('AnalyticsScreen Widget Tests', () {
    testWidgets('AnalyticsScreen renders KPI cards, trend chart, and insights card', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const AnalyticsScreen()));
      expect(find.text('Descriptive Analytics'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL REVENUE'), findsOneWidget);
      expect(find.text('TOTAL ORDERS'), findsOneWidget);
      expect(find.text('AVERAGE ORDER VALUE'), findsOneWidget);
      expect(find.text('Revenue & Order Volume'), findsOneWidget);
      expect(find.text('Roast Product Performance Breakdown'), findsOneWidget);
      expect(find.text('Data-Driven Business Insights'), findsOneWidget);
    });
  });
}
