import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/barista_spotlight_data.dart';
import 'package:lambac_app/features/onboarding/data/datasources/staff_tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/staff_tutorial_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/barista_spotlight_overlay.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/barista_spotlight_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_instructional_card.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_keys.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Barista Spotlight Coach-Mark Product Tour Unit & Widget Tests', () {
    late StorageService storageService;
    late StaffTutorialLocalDataSource localDataSource;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = StaffTutorialLocalDataSourceImpl(storageService: storageService);
    });

    test('1. BaristaSpotlightData: Exactly 8 curated steps mapping real barista UI features', () {
      final steps = BaristaSpotlightData.getSteps();

      expect(steps.length, equals(8));

      // Verify sequence of steps
      expect(steps[0].id, equals('barista_dashboard_header'));
      expect(steps[0].stepNumber, equals(1));
      expect(steps[0].title, equals('Barista Station & Daily Queue'));
      expect(steps[0].targetKey, equals(SpotlightKeys.staffQueueHeader));

      expect(steps[1].id, equals('barista_metrics_pipeline'));
      expect(steps[1].stepNumber, equals(2));
      expect(steps[1].title, equals('Real-Time Operational Metrics'));
      expect(steps[1].targetKey, equals(SpotlightKeys.staffMetricsBar));

      expect(steps[2].id, equals('barista_order_ticket'));
      expect(steps[2].stepNumber, equals(3));
      expect(steps[2].title, equals('Order Ticket & Item Composition'));
      expect(steps[2].targetKey, equals(SpotlightKeys.staffFirstOrderCard));

      expect(steps[3].id, equals('barista_status_preparing'));
      expect(steps[3].stepNumber, equals(4));
      expect(steps[3].title, equals('Start Brewing & Status Control'));
      expect(steps[3].targetKey, equals(SpotlightKeys.staffOrderActionBtn));

      expect(steps[4].id, equals('barista_status_ready'));
      expect(steps[4].stepNumber, equals(5));
      expect(steps[4].title, equals('Mark Ready & Order Completion'));
      expect(steps[4].targetKey, equals(SpotlightKeys.staffOrderActionBtn));

      expect(steps[5].id, equals('barista_pickup_time_slot'));
      expect(steps[5].stepNumber, equals(6));
      expect(steps[5].title, equals('Scheduled Pickup Time Slots'));
      expect(steps[5].targetKey, equals(SpotlightKeys.staffOrderPickupBadge));

      expect(steps[6].id, equals('barista_nav_concierge'));
      expect(steps[6].stepNumber, equals(7));
      expect(steps[6].title, equals('Customer Concierge Inbox'));
      expect(steps[6].targetKey, equals(SpotlightKeys.staffInboxBanner));

      expect(steps[7].id, equals('barista_nav_shift'));
      expect(steps[7].stepNumber, equals(8));
      expect(steps[7].title, equals('My Shift & Station Controls'));
      expect(steps[7].targetKey, equals(SpotlightKeys.staffShiftControls));
    });

    test('2. BaristaSpotlightNotifier: Start tour, step progression, skip, and completion state', () async {
      final notifier = BaristaSpotlightNotifier(localDataSource: localDataSource);

      // Initial State
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.isCompleted, isFalse);
      expect(notifier.state.currentStepIndex, equals(0));

      // Start Tour
      notifier.startTour();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.currentStepIndex, equals(0));
      expect(notifier.state.currentStep?.title, equals('Barista Station & Daily Queue'));
      expect(notifier.state.isFirstStep, isTrue);
      expect(notifier.state.isLastStep, isFalse);

      // Advance Steps
      notifier.nextStep();
      expect(notifier.state.currentStepIndex, equals(1));
      expect(notifier.state.currentStep?.title, equals('Real-Time Operational Metrics'));

      notifier.previousStep();
      expect(notifier.state.currentStepIndex, equals(0));

      // Jump to step 7 (Last Step - Step 8)
      notifier.jumpToStep(7);
      expect(notifier.state.currentStepIndex, equals(7));
      expect(notifier.state.isLastStep, isTrue);
      expect(notifier.state.currentStep?.title, equals('My Shift & Station Controls'));

      // Finish Tour on final step
      await notifier.finishTour();
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.isCompleted, isTrue);
      expect(await localDataSource.isStaffTutorialCompleted(), isTrue);

      // Replay Tour
      notifier.replayTour();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.currentStepIndex, equals(0));

      // Skip Tour
      await notifier.skipTour();
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.hasSkipped, isTrue);
      expect(await localDataSource.isStaffTutorialCompleted(), isTrue);
    });

    testWidgets('3. BaristaSpotlightOverlay: Renders spotlight card, step badge, Next, and Back actions', (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          staffTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BaristaSpotlightOverlay(
                child: Center(
                  child: Container(
                    key: SpotlightKeys.staffQueueHeader,
                    width: 200,
                    height: 50,
                    color: Colors.green,
                    child: const Text('Barista Header'),
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
      container.read(baristaSpotlightProvider.notifier).startTour();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Step 1 is rendered
      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.textContaining('STEP 1 OF 8'), findsOneWidget);
      expect(find.text('Barista Station & Daily Queue'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip Tour'), findsOneWidget);
      expect(find.text('Back'), findsNothing); // No back button on first step

      // Tap Next -> Step 2
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('STEP 2 OF 8'), findsOneWidget);
      expect(find.text('Real-Time Operational Metrics'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget); // Back button present on step 2

      // Tap Back -> Returns to Step 1
      await tester.tap(find.text('Back').first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 1 OF 8'), findsOneWidget);

      // Tap Skip Tour -> Closes overlay
      await tester.tap(find.text('Skip Tour'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SpotlightInstructionalCard), findsNothing);
      expect(container.read(baristaSpotlightProvider).isActive, isFalse);
      expect(await localDataSource.isStaffTutorialCompleted(), isTrue);

      container.dispose();
    });

    testWidgets('4. SpotlightInstructionalCard: Final step shows "Finish Tour" and completes tour', (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          staffTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BaristaSpotlightOverlay(
                child: Center(
                  child: Container(
                    key: SpotlightKeys.staffShiftControls,
                    width: 200,
                    height: 50,
                    color: Colors.green,
                    child: const Text('Shift Tab'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Start on final step (Step 8)
      container.read(baristaSpotlightProvider.notifier).startTour(startStep: 7);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('STEP 8 OF 8'), findsOneWidget);
      expect(find.text('My Shift & Station Controls'), findsOneWidget);
      expect(find.text('Finish Tour'), findsOneWidget);

      // Tap Finish Tour
      await tester.tap(find.text('Finish Tour'));
      await tester.pump(const Duration(milliseconds: 400));

      // Overlay dismissed and tour marked complete
      expect(find.byType(SpotlightInstructionalCard), findsNothing);
      expect(container.read(baristaSpotlightProvider).isActive, isFalse);
      expect(container.read(baristaSpotlightProvider).isCompleted, isTrue);

      container.dispose();
    });
  });
}
