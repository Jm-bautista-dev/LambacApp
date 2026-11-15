import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/customer_spotlight_data.dart';
import 'package:lambac_app/features/onboarding/data/datasources/tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/tutorial_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/customer_spotlight_overlay.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/customer_spotlight_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_instructional_card.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_keys.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Customer Spotlight Coach-Mark Product Tour Unit & Widget Tests', () {
    late StorageService storageService;
    late TutorialLocalDataSource localDataSource;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = TutorialLocalDataSourceImpl(storageService: storageService);
    });

    test('1. CustomerSpotlightData: Exactly 11 curated steps mapping real customer UI features', () {
      final steps = CustomerSpotlightData.steps;
      expect(steps.length, 11);

      // Verify all 11 steps in the required logical customer sequence
      expect(steps[0].id, 'spotlight_home_header');
      expect(steps[0].stepNumber, 1);
      expect(steps[0].categoryTitle, 'HOME & DASHBOARD');
      expect(steps[0].targetKey, SpotlightKeys.homeHeader);

      expect(steps[1].id, 'spotlight_notifications');
      expect(steps[1].stepNumber, 2);
      expect(steps[1].categoryTitle, 'NOTIFICATIONS');
      expect(steps[1].targetKey, SpotlightKeys.homeNotifications);

      expect(steps[2].id, 'spotlight_search');
      expect(steps[2].stepNumber, 3);
      expect(steps[2].categoryTitle, 'SEARCH & DISCOVERY');
      expect(steps[2].targetKey, SpotlightKeys.homeSearch);

      expect(steps[3].id, 'spotlight_categories');
      expect(steps[3].stepNumber, 4);
      expect(steps[3].categoryTitle, 'CATEGORY FILTERS');
      expect(steps[3].targetKey, SpotlightKeys.homeCategories);

      expect(steps[4].id, 'spotlight_hero_banner');
      expect(steps[4].stepNumber, 5);
      expect(steps[4].categoryTitle, 'ARTISAN ROASTERY');
      expect(steps[4].targetKey, SpotlightKeys.homeHeroBanner);

      expect(steps[5].id, 'spotlight_quick_pickup');
      expect(steps[5].stepNumber, 6);
      expect(steps[5].categoryTitle, 'PICKUP ORDERING');
      expect(steps[5].targetKey, SpotlightKeys.homeQuickPickup);

      expect(steps[6].id, 'spotlight_barista_chat');
      expect(steps[6].stepNumber, 7);
      expect(steps[6].categoryTitle, '1-ON-1 CONCIERGE');
      expect(steps[6].targetKey, SpotlightKeys.homeQuickChat);

      expect(steps[7].id, 'spotlight_order_tracking');
      expect(steps[7].stepNumber, 8);
      expect(steps[7].categoryTitle, '6-STAGE TRACKER');
      expect(steps[7].targetKey, SpotlightKeys.homeQuickTrack);

      expect(steps[8].id, 'spotlight_featured_harvests');
      expect(steps[8].stepNumber, 9);
      expect(steps[8].categoryTitle, 'SENSORY DETAILS');
      expect(steps[8].targetKey, SpotlightKeys.homeFirstProductCard);

      expect(steps[9].id, 'spotlight_cart');
      expect(steps[9].stepNumber, 10);
      expect(steps[9].categoryTitle, 'PICKUP CART');
      expect(steps[9].targetKey, SpotlightKeys.navCart);

      expect(steps[10].id, 'spotlight_profile');
      expect(steps[10].stepNumber, 11);
      expect(steps[10].categoryTitle, 'MEMBER ACCOUNT');
      expect(steps[10].targetKey, SpotlightKeys.navProfile);
    });

    test('2. CustomerSpotlightNotifier: Start tour, step progression, skip, restart, and completion state', () async {
      final containerRef = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          tutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      final notifier = containerRef.read(customerSpotlightProvider.notifier);
      expect(containerRef.read(customerSpotlightProvider).isActive, isFalse);
      expect(containerRef.read(customerSpotlightProvider).currentStepIndex, 0);

      // Start Tour
      notifier.startTour();
      expect(containerRef.read(customerSpotlightProvider).isActive, isTrue);
      expect(containerRef.read(customerSpotlightProvider).currentStepIndex, 0);
      expect(containerRef.read(customerSpotlightProvider).isFirstStep, isTrue);
      expect(containerRef.read(customerSpotlightProvider).isLastStep, isFalse);

      // Next Step -> Step 2
      await notifier.nextStep();
      expect(containerRef.read(customerSpotlightProvider).currentStepIndex, 1);
      expect(containerRef.read(customerSpotlightProvider).isFirstStep, isFalse);

      // Jump to last step (Step 11, index 10)
      notifier.goToStep(10);
      expect(containerRef.read(customerSpotlightProvider).currentStepIndex, 10);
      expect(containerRef.read(customerSpotlightProvider).isLastStep, isTrue);

      // Previous Step -> Step 10
      notifier.previousStep();
      expect(containerRef.read(customerSpotlightProvider).currentStepIndex, 9);

      // Restart tour
      notifier.restartTour();
      expect(containerRef.read(customerSpotlightProvider).currentStepIndex, 0);
      expect(containerRef.read(customerSpotlightProvider).isReplay, isTrue);

      // Complete Tour from last step
      notifier.goToStep(10);
      await notifier.nextStep();
      expect(containerRef.read(customerSpotlightProvider).isActive, isFalse);
      expect(containerRef.read(customerSpotlightProvider).isCompleted, isTrue);
      expect(await localDataSource.isTutorialCompleted(), isTrue);

      containerRef.dispose();
    });

    testWidgets('3. CustomerSpotlightOverlay: Renders spotlight card, step badge, Next, and Back actions', (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          tutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CustomerSpotlightOverlay(
                child: Center(
                  child: Container(
                    key: SpotlightKeys.homeHeader,
                    width: 200,
                    height: 50,
                    color: Colors.blue,
                    child: const Text('Target Header'),
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
      container.read(customerSpotlightProvider.notifier).startTour();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Step 1 is rendered
      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.textContaining('STEP 1 OF 11'), findsOneWidget);
      expect(find.text('Home & Daily Roastery Greeting'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip Tour'), findsOneWidget);
      expect(find.text('Back'), findsNothing); // No back button on first step

      // Tap Next -> Step 2
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('STEP 2 OF 11'), findsOneWidget);
      expect(find.text('Roastery Alerts & Readiness'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget); // Back button present on step 2

      // Tap Back -> Returns to Step 1
      await tester.tap(find.text('Back').first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 1 OF 11'), findsOneWidget);

      // Tap Skip Tour -> Closes overlay
      await tester.tap(find.text('Skip Tour').last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SpotlightInstructionalCard), findsNothing);
      expect(container.read(customerSpotlightProvider).isActive, isFalse);
      expect(await localDataSource.isTutorialCompleted(), isTrue);

      container.dispose();
    });

    testWidgets('4. SpotlightInstructionalCard: Final step shows "Start Exploring" and finishes tour', (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          tutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CustomerSpotlightOverlay(
                child: Center(
                  child: Container(
                    key: SpotlightKeys.navProfile,
                    width: 200,
                    height: 50,
                    color: Colors.brown,
                    child: const Text('Profile Tab'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Start on final step (Step 11, index 10)
      container.read(customerSpotlightProvider.notifier).startTour(startStep: 10);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('STEP 11 OF 11'), findsOneWidget);
      expect(find.text('Profile, Loyalty Beans & Reviews'), findsOneWidget);
      expect(find.text('Start Exploring'), findsOneWidget);

      // Tap Start Exploring
      await tester.tap(find.text('Start Exploring'));
      await tester.pump(const Duration(milliseconds: 400));

      // Overlay dismissed and tour marked complete
      expect(find.byType(SpotlightInstructionalCard), findsNothing);
      expect(container.read(customerSpotlightProvider).isActive, isFalse);
      expect(container.read(customerSpotlightProvider).isCompleted, isTrue);

      container.dispose();
    });
  });
}
