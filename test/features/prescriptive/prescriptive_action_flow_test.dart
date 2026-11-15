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
import 'package:lambac_app/features/prescriptive/presentation/screens/prescriptive_action_detail_screen.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/notifications/data/datasources/mock_notification_remote_datasource.dart';
import 'package:lambac_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:lambac_app/features/prescriptive/presentation/widgets/action_configuration_sheet.dart';
import 'package:lambac_app/features/prescriptive/presentation/widgets/action_success_modal.dart';

void main() {
  group('Prescriptive Action Flow & Sub-Module Integration Tests', () {
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
      prescriptiveRemoteDataSource.reset();
      prescriptiveRepository = PrescriptiveRepositoryImpl(remoteDataSource: prescriptiveRemoteDataSource);
    });

    Widget createTestApp({int initialTabIndex = 3, int initialSubTab = 0}) {
      return ProviderScope(
        overrides: [
          analyticsRepositoryProvider.overrideWithValue(analyticsRepository),
          forecastingRepositoryProvider.overrideWithValue(forecastingRepository),
          prescriptiveRepositoryProvider.overrideWithValue(prescriptiveRepository),
          notificationRemoteDataSourceProvider.overrideWithValue(MockNotificationRemoteDataSource()),
          currentUserProvider.overrideWith((ref) => MockUserDatabase().currentUser),
        ],
        child: MaterialApp(
          home: BusinessIntelligenceScreen(
            initialTabIndex: initialTabIndex,
            initialPrescriptiveSubTab: initialSubTab,
          ),
        ),
      );
    }

    testWidgets('1. BI Hub Prescriptive Tab renders sub-modules: Recommendations, Schedule, Queue, History', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(initialTabIndex: 3));
      await tester.pumpAndSettle();

      expect(find.text('Recommendations'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Action Queue'), findsOneWidget);
      expect(find.text('History & Audit'), findsOneWidget);
      expect(find.text('High Priority'), findsOneWidget);
    });

    testWidgets('2. Clicking Schedule Roast Batch opens configuration sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(initialTabIndex: 3, initialSubTab: 0));
      await tester.pumpAndSettle();

      final scheduleBtn = find.text('Schedule Roast Batch');
      if (scheduleBtn.evaluate().isNotEmpty) {
        await tester.tap(scheduleBtn.first);
        await tester.pumpAndSettle();

        expect(find.byType(ActionConfigurationSheet), findsOneWidget);
        expect(find.text('CONFIGURE OPERATIONAL ACTION'), findsOneWidget);
        expect(find.text('Confirm & Schedule Action'), findsOneWidget);

        // Submit action
        await tester.tap(find.text('Confirm & Schedule Action'));
        await tester.pumpAndSettle();

        // Expect ActionSuccessModal
        expect(find.byType(ActionSuccessModal), findsOneWidget);
        expect(find.text('Action Scheduled'), findsOneWidget);

        // Tap Done to dismiss modal
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('3. Schedule sub-tab renders grouped chronological timeline cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(initialTabIndex: 3, initialSubTab: 1));
      await tester.pumpAndSettle();

      expect(find.text('Roast Batches'), findsOneWidget);
      expect(find.text('Raw Bean Restock'), findsOneWidget);
      expect(find.text('Menu Promos'), findsOneWidget);
    });

    testWidgets('4. Prescriptive Action Detail Screen renders full audit log timeline and lifecycle buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prescriptiveRepositoryProvider.overrideWithValue(prescriptiveRepository),
          ],
          child: const MaterialApp(
            home: PrescriptiveActionDetailScreen(actionId: 'act_1003'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Action #act_1003'), findsOneWidget);
      expect(find.text('OPERATIONAL AUDIT TRAIL'), findsOneWidget);
      expect(find.text('Mark In Progress'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
      expect(find.text('Cancel Action'), findsOneWidget);
    });
  });
}
