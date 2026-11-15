import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/admin_spotlight_data.dart';
import 'package:lambac_app/features/onboarding/data/datasources/admin_tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/admin_tutorial_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/admin_spotlight_overlay.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/admin_spotlight_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_instructional_card.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_keys.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Admin Spotlight Coach-Mark Product Tour Unit & Widget Tests', () {
    late StorageService storageService;
    late AdminTutorialLocalDataSource localDataSource;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = AdminTutorialLocalDataSourceImpl(storageService: storageService);
    });

    test('1. AdminSpotlightData: Exactly 10 curated steps mapping real admin UI features', () {
      final steps = AdminSpotlightData.getSteps();

      expect(steps.length, equals(10));

      // Verify sequence of steps
      expect(steps[0].id, equals('admin_dashboard_header'));
      expect(steps[0].stepNumber, equals(1));
      expect(steps[0].title, equals('Executive Command Center'));
      expect(steps[0].targetKey, equals(SpotlightKeys.adminDashboardHeader));

      expect(steps[1].id, equals('admin_kpi_revenue'));
      expect(steps[1].stepNumber, equals(2));
      expect(steps[1].title, equals('Daily Revenue & Financial KPIs'));
      expect(steps[1].targetKey, equals(SpotlightKeys.adminRevenueCard));

      expect(steps[2].id, equals('admin_orders_queue'));
      expect(steps[2].stepNumber, equals(3));
      expect(steps[2].title, equals('Fulfillment & Status Queue'));
      expect(steps[2].targetKey, equals(SpotlightKeys.adminOrdersQueue));

      expect(steps[3].id, equals('admin_products_catalog'));
      expect(steps[3].stepNumber, equals(4));
      expect(steps[3].title, equals('Coffee Catalog & Availability'));
      expect(steps[3].targetKey, equals(SpotlightKeys.adminProductsCatalog));

      expect(steps[4].id, equals('admin_add_product'));
      expect(steps[4].stepNumber, equals(5));
      expect(steps[4].title, equals('New Roast Creation & Pricing'));
      expect(steps[4].targetKey, equals(SpotlightKeys.adminAddProductBtn));

      expect(steps[5].id, equals('admin_inbox_module'));
      expect(steps[5].stepNumber, equals(6));
      expect(steps[5].title, equals('Guest Concierge & Inquiries'));
      expect(steps[5].targetKey, equals(SpotlightKeys.adminInboxSummaryCard));

      expect(steps[6].id, equals('admin_bi_hub'));
      expect(steps[6].stepNumber, equals(7));
      expect(steps[6].title, equals('Business Intelligence Hub'));
      expect(steps[6].targetKey, equals(SpotlightKeys.adminBiTabs));

      expect(steps[7].id, equals('admin_forecasting'));
      expect(steps[7].stepNumber, equals(8));
      expect(steps[7].title, equals('Sales & Demand Forecasting'));
      expect(steps[7].targetKey, equals(SpotlightKeys.adminForecastingCard));

      expect(steps[8].id, equals('admin_prescriptive'));
      expect(steps[8].stepNumber, equals(9));
      expect(steps[8].title, equals('Prescriptive Decision Dispatch'));
      expect(steps[8].targetKey, equals(SpotlightKeys.adminPrescriptiveCard));

      expect(steps[9].id, equals('admin_control_rbac'));
      expect(steps[9].stepNumber, equals(10));
      expect(steps[9].title, equals('RBAC Governance & Shift Control'));
      expect(steps[9].targetKey, equals(SpotlightKeys.adminControlModules));
    });

    test('2. AdminSpotlightNotifier: Start tour, step progression, skip, and completion state', () async {
      final notifier = AdminSpotlightNotifier(localDataSource: localDataSource);

      // Initial State
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.isCompleted, isFalse);
      expect(notifier.state.currentStepIndex, equals(0));

      // Start Tour
      notifier.startTour();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.currentStepIndex, equals(0));
      expect(notifier.state.currentStep?.title, equals('Executive Command Center'));
      expect(notifier.state.isFirstStep, isTrue);
      expect(notifier.state.isLastStep, isFalse);

      // Advance Steps
      notifier.nextStep();
      expect(notifier.state.currentStepIndex, equals(1));
      expect(notifier.state.currentStep?.title, equals('Daily Revenue & Financial KPIs'));

      notifier.previousStep();
      expect(notifier.state.currentStepIndex, equals(0));

      // Jump to step 9 (Last Step - Step 10)
      notifier.jumpToStep(9);
      expect(notifier.state.currentStepIndex, equals(9));
      expect(notifier.state.isLastStep, isTrue);
      expect(notifier.state.currentStep?.title, equals('RBAC Governance & Shift Control'));

      // Finish Tour on final step
      await notifier.finishTour();
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.isCompleted, isTrue);
      expect(await localDataSource.isAdminTutorialCompleted(), isTrue);

      // Replay Tour
      notifier.replayTour();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.currentStepIndex, equals(0));

      // Skip Tour
      await notifier.skipTour();
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.hasSkipped, isTrue);
      expect(await localDataSource.isAdminTutorialCompleted(), isTrue);
    });

    testWidgets('3. AdminSpotlightOverlay: Renders spotlight card, step badge, Next, and Back actions', (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          adminTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AdminSpotlightOverlay(
                child: Center(
                  child: Container(
                    key: SpotlightKeys.adminDashboardHeader,
                    width: 200,
                    height: 50,
                    color: Colors.brown,
                    child: const Text('Admin Dashboard Header'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Initially inactive
      expect(find.byType(SpotlightInstructionalCard), findsNothing);

      // Activate Spotlight Tour
      container.read(adminSpotlightProvider.notifier).startTour();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Step 1 is rendered
      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.textContaining('STEP 1 OF 10'), findsOneWidget);
      expect(find.text('Executive Command Center'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip Tour'), findsOneWidget);
      expect(find.text('Back'), findsNothing); // No back button on first step

      // Tap Next -> Step 2
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('STEP 2 OF 10'), findsOneWidget);
      expect(find.text('Daily Revenue & Financial KPIs'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget); // Back button present on step 2

      // Tap Back -> Returns to Step 1
      await tester.tap(find.text('Back').first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 1 OF 10'), findsOneWidget);

      // Tap Skip Tour -> Closes overlay
      await tester.tap(find.text('Skip Tour'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SpotlightInstructionalCard), findsNothing);
      expect(container.read(adminSpotlightProvider).isActive, isFalse);
      expect(await localDataSource.isAdminTutorialCompleted(), isTrue);

      container.dispose();
    });

    testWidgets('4. SpotlightInstructionalCard: Final step shows "Finish Tour" and completes tour', (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          adminTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AdminSpotlightOverlay(
                child: Center(
                  child: Container(
                    key: SpotlightKeys.adminControlModules,
                    width: 200,
                    height: 50,
                    color: Colors.brown,
                    child: const Text('Admin Control Modules'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Start on final step (Step 10)
      container.read(adminSpotlightProvider.notifier).startTour(startStep: 9);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('STEP 10 OF 10'), findsOneWidget);
      expect(find.text('RBAC Governance & Shift Control'), findsOneWidget);
      expect(find.text('Finish Tour'), findsOneWidget);

      // Tap Finish Tour
      await tester.tap(find.text('Finish Tour'));
      await tester.pump(const Duration(milliseconds: 400));

      // Overlay dismissed and tour marked complete
      expect(find.byType(SpotlightInstructionalCard), findsNothing);
      expect(container.read(adminSpotlightProvider).isActive, isFalse);
      expect(container.read(adminSpotlightProvider).isCompleted, isTrue);

      container.dispose();
    });
  });
}
