import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/customer_spotlight_data.dart';
import 'package:lambac_app/features/onboarding/data/datasources/tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/data/models/spotlight_step_model.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/tutorial_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/customer_spotlight_overlay.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/customer_spotlight_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/inverted_spotlight_clipper.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_instructional_card.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_keys.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Customer Spotlight Responsive, Empty/Populated State & Cutout Verification Tests', () {
    late StorageService storageService;
    late TutorialLocalDataSource localDataSource;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = TutorialLocalDataSourceImpl(storageService: storageService);
    });

    Widget buildMockCustomerTree({
      required ProviderContainer container,
      required bool hasProducts,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: CustomerSpotlightOverlay(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 1. Header greeting
                    Container(
                      key: SpotlightKeys.homeHeader,
                      height: 70,
                      color: Colors.brown[900],
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text('Lambac Roastery Header'),
                          const Spacer(),
                          Container(
                            key: SpotlightKeys.homeNotifications,
                            width: 38,
                            height: 38,
                            color: Colors.amber,
                            child: const Icon(Icons.notifications),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Search Box
                    Container(
                      key: SpotlightKeys.homeSearch,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey[800],
                      child: const Center(child: Text('Search origins...')),
                    ),
                    const SizedBox(height: 12),

                    // 3. Category Chips
                    Container(
                      key: SpotlightKeys.homeCategories,
                      height: 42,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey[850],
                      child: const Center(child: Text('Category Chips: Single Origin, Espresso')),
                    ),
                    const SizedBox(height: 12),

                    // 4. Hero Banner
                    Container(
                      key: SpotlightKeys.homeHeroBanner,
                      height: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.brown[800],
                      child: const Center(child: Text('Artisan Roasting Hero Banner')),
                    ),
                    const SizedBox(height: 12),

                    // 5. Quick Actions Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              key: SpotlightKeys.homeQuickPickup,
                              height: 60,
                              color: Colors.amber[800],
                              child: const Center(child: Text('Pickup')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              key: SpotlightKeys.homeQuickChat,
                              height: 60,
                              color: Colors.amber[800],
                              child: const Center(child: Text('Chat')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              key: SpotlightKeys.homeQuickTrack,
                              height: 60,
                              color: Colors.amber[800],
                              child: const Center(child: Text('Track')),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Featured Section & Product Cards
                    Container(
                      key: SpotlightKeys.homeFeaturedList,
                      height: 310,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.black26,
                      child: hasProducts
                          ? ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Container(
                                  key: SpotlightKeys.homeFirstProductCard,
                                  width: 200,
                                  color: Colors.brown[700],
                                  child: const Center(child: Text('First Product: Mount Apo Micro-lot')),
                                ),
                              ],
                            )
                          : const Center(child: Text('Loading Fresh Roasts...')),
                    ),
                    const SizedBox(height: 300),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Container(
              height: 64,
              color: Colors.grey[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(key: SpotlightKeys.navHome, width: 40, height: 40, color: Colors.amber),
                  Container(key: SpotlightKeys.navRoastery, width: 40, height: 40, color: Colors.grey),
                  Container(key: SpotlightKeys.navCart, width: 40, height: 40, color: Colors.grey),
                  Container(key: SpotlightKeys.navOrders, width: 40, height: 40, color: Colors.grey),
                  Container(key: SpotlightKeys.navProfile, width: 40, height: 40, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('1. Responsive Layout: Phone viewport (390 x 844) renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          tutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        buildMockCustomerTree(
          container: container,
          hasProducts: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      container.read(customerSpotlightProvider.notifier).startTour();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.text('Home & Daily Roastery Greeting'), findsOneWidget);

      // Verify that every step can advance cleanly without overflow on mobile phone
      final notifier = container.read(customerSpotlightProvider.notifier);
      for (int i = 0; i < CustomerSpotlightData.steps.length; i++) {
        expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
        if (i < CustomerSpotlightData.steps.length - 1) {
          await notifier.nextStep();
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pump(const Duration(milliseconds: 300));
        }
      }

      container.dispose();
    });

    testWidgets('2. Responsive Layout: Tablet viewport (820 x 1180) renders with spacious elegance', (tester) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          tutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        buildMockCustomerTree(
          container: container,
          hasProducts: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      container.read(customerSpotlightProvider.notifier).startTour();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.text('Home & Daily Roastery Greeting'), findsOneWidget);

      // Verify step 9 (Featured Harvests)
      container.read(customerSpotlightProvider.notifier).goToStep(8);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sensory Profiles & Custom Grind'), findsOneWidget);

      container.dispose();
    });

    testWidgets('3. Responsive Layout: Desktop/Web viewport (1440 x 900) positions card safely', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          tutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        buildMockCustomerTree(
          container: container,
          hasProducts: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      container.read(customerSpotlightProvider.notifier).startTour();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);

      // Verify step 10 (Cart) positioned above bottom bar
      container.read(customerSpotlightProvider.notifier).goToStep(9);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Your Pickup Cart & Checkout'), findsOneWidget);

      container.dispose();
    });

    testWidgets('4. Empty Catalog Fallback: Gracefully highlights section when product card is absent', (tester) async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          tutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );

      await tester.pumpWidget(
        buildMockCustomerTree(
          container: container,
          hasProducts: false, // Catalog has not loaded products yet
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Jump to step 9 (which targets homeFirstProductCard)
      container.read(customerSpotlightProvider.notifier).startTour(startStep: 8);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      // Card is displayed safely and gracefully without throwing errors
      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.text('Sensory Profiles & Custom Grind'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      container.dispose();
    });

    test('5. InvertedSpotlightClipper: Path math physically carves target out of background scrim', () {
      const canvasSize = Size(400, 800);
      const target = Rect.fromLTWH(50, 100, 200, 80);

      // Rounded rect clipper
      const clipper = InvertedSpotlightClipper(
        targetRect: target,
        borderRadius: 16.0,
        shape: SpotlightShape.roundedRect,
      );

      final clipPath = clipper.getClip(canvasSize);

      // Outer canvas bounds must be covered
      expect(clipPath.contains(const Offset(10, 10)), isTrue);
      expect(clipPath.contains(const Offset(350, 750)), isTrue);

      // Target area center MUST NOT be covered by the clip path (it is inverted/carved out)
      expect(clipPath.contains(target.center), isFalse);

      // Circle shape clipper
      const circleClipper = InvertedSpotlightClipper(
        targetRect: target,
        borderRadius: 16.0,
        shape: SpotlightShape.circle,
      );
      final circlePath = circleClipper.getClip(canvasSize);
      expect(circlePath.contains(const Offset(10, 10)), isTrue);
      expect(circlePath.contains(target.center), isFalse);
    });
  });
}
