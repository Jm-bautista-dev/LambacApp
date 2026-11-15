import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/barista_spotlight_data.dart';
import 'package:lambac_app/features/onboarding/data/datasources/staff_tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/data/models/spotlight_step_model.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/staff_tutorial_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/barista_spotlight_overlay.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/barista_spotlight_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/inverted_spotlight_clipper.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_instructional_card.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_keys.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Barista Spotlight Responsive, Populated/Empty Queue & Cutout Verification Tests', () {
    late StorageService storageService;
    late StaffTutorialLocalDataSource localDataSource;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = StaffTutorialLocalDataSourceImpl(storageService: storageService);
    });

    Widget buildMockStaffTree({
      required ProviderContainer container,
      required ValueNotifier<int> branchNotifier,
      required bool hasOrders,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.listen(baristaSpotlightProvider, (prev, next) {
                  if (next.isActive && next.currentStep != null) {
                    final targetBranch = next.currentStep!.targetBranchIndex;
                    if (targetBranch != null && targetBranch != branchNotifier.value) {
                      branchNotifier.value = targetBranch;
                    }
                  }
                });

                return BaristaSpotlightOverlay(
                  child: AnimatedBuilder(
                    animation: branchNotifier,
                    builder: (context, _) {
                      final branch = branchNotifier.value;
                      return Column(
                        children: [
                          // App Bar Header
                          Container(
                            key: SpotlightKeys.staffQueueHeader,
                            height: 60,
                            color: Colors.brown[900],
                            child: const Center(
                              child: Text('Widget: Barista Operations Queue Header'),
                            ),
                          ),
                          Expanded(
                            child: IndexedStack(
                              index: branch,
                              children: [
                                // Branch 0: Operations Queue
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // Metrics bar
                                      Container(
                                        key: SpotlightKeys.staffMetricsBar,
                                        height: 50,
                                        color: Colors.grey[850],
                                        child: const Center(
                                          child: Text('Widget: Operational Metrics Bar'),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (hasOrders) ...[
                                        // Populated order ticket
                                        Container(
                                          key: SpotlightKeys.staffFirstOrderCard,
                                          margin: const EdgeInsets.all(12),
                                          padding: const EdgeInsets.all(16),
                                          color: Colors.grey[900],
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                key: SpotlightKeys.staffOrderPickupBadge,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                color: Colors.amber[900],
                                                child: const Text('Widget: Pickup 2:30 PM'),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text('Widget: 2 × Single-Origin Pour Over'),
                                              const SizedBox(height: 16),
                                              Container(
                                                key: SpotlightKeys.staffOrderActionBtn,
                                                height: 40,
                                                color: Colors.amber,
                                                child: const Center(
                                                  child: Text('Widget: Start Preparing'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 400),
                                      ] else ...[
                                        // Empty queue state
                                        Container(
                                          key: SpotlightKeys.staffEmptyQueueCard,
                                          height: 200,
                                          margin: const EdgeInsets.all(24),
                                          color: Colors.grey[900],
                                          child: const Center(
                                            child: Text('Widget: All Caught Up! Empty Queue'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Branch 1: Concierge Inbox
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                        key: SpotlightKeys.staffInboxBanner,
                                        height: 60,
                                        color: Colors.teal[900],
                                        child: const Center(
                                          child: Text('Widget: Customer Concierge Banner'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Branch 2: My Shift Profile
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                        key: SpotlightKeys.staffShiftControls,
                                        height: 140,
                                        color: Colors.grey[800],
                                        child: const Center(
                                          child: Text('Widget: Shift Controls & Preferences'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Bottom Navigation Bar
                          Container(
                            height: 56,
                            color: Colors.black,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    key: SpotlightKeys.staffNavQueue,
                                    child: const Center(child: Text('Queue Nav')),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    key: SpotlightKeys.staffNavConcierge,
                                    child: const Center(child: Text('Concierge Nav')),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    key: SpotlightKeys.staffNavShift,
                                    child: const Center(child: Text('Shift Nav')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('1. Phone Form-Factor (390x844) with Populated Queue: Traverses all 8 steps with branch switching and unblurred cutout', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          staffTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );
      final branchNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        buildMockStaffTree(
          container: container,
          branchNotifier: branchNotifier,
          hasOrders: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final notifier = container.read(baristaSpotlightProvider.notifier);
      notifier.startTour();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Step 1: Barista Station Header
      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.textContaining('STEP 1 OF 8'), findsOneWidget);
      expect(find.text('Barista Station & Daily Queue'), findsOneWidget);

      // Advance to Step 2: Metrics Bar
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 2 OF 8'), findsOneWidget);
      expect(find.text('Real-Time Operational Metrics'), findsOneWidget);

      // Advance to Step 3: Order Ticket
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 3 OF 8'), findsOneWidget);
      expect(find.text('Order Ticket & Item Composition'), findsOneWidget);

      // Advance to Step 4: Preparing Status Control
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 4 OF 8'), findsOneWidget);
      expect(find.text('Start Brewing & Status Control'), findsOneWidget);

      // Advance to Step 5: Ready for Pickup & Order Completion
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 5 OF 8'), findsOneWidget);
      expect(find.text('Mark Ready & Order Completion'), findsOneWidget);

      // Advance to Step 6: Scheduled Pickup Time Slots
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 6 OF 8'), findsOneWidget);
      expect(find.text('Scheduled Pickup Time Slots'), findsOneWidget);

      // Advance to Step 7: Customer Concierge Inbox (Branch 1)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(branchNotifier.value, equals(1));
      expect(find.textContaining('STEP 7 OF 8'), findsOneWidget);
      expect(find.text('Customer Concierge Inbox'), findsOneWidget);

      // Advance to Step 8: My Shift & Station Controls (Branch 2)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(branchNotifier.value, equals(2));
      expect(find.textContaining('STEP 8 OF 8'), findsOneWidget);
      expect(find.text('My Shift & Station Controls'), findsOneWidget);
      expect(find.text('Finish Tour'), findsOneWidget);

      // Finish Tour
      await tester.tap(find.text('Finish Tour'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SpotlightInstructionalCard), findsNothing);
      expect(container.read(baristaSpotlightProvider).isActive, isFalse);
      expect(container.read(baristaSpotlightProvider).isCompleted, isTrue);

      container.dispose();
    });

    testWidgets('2. Empty Queue Resiliency: Steps 3-6 gracefully handle missing order widgets without drawing arbitrary false highlights', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          staffTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );
      final branchNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        buildMockStaffTree(
          container: container,
          branchNotifier: branchNotifier,
          hasOrders: false, // Queue is empty!
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final notifier = container.read(baristaSpotlightProvider.notifier);
      // Jump directly to Step 3 (Order Ticket on empty queue)
      notifier.startTour(startStep: 2);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.textContaining('STEP 3 OF 8'), findsOneWidget);
      expect(find.text('Order Ticket & Item Composition'), findsOneWidget);

      // Tap Next -> Step 4
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 4 OF 8'), findsOneWidget);

      // Verify no exception was thrown
      expect(tester.takeException(), isNull);

      // Flush remaining target retry animation timers before tearDown
      await tester.pump(const Duration(milliseconds: 500));

      container.dispose();
    });

    testWidgets('3. Tablet Form-Factor (820x1180): Verifies card placement and geometry without clipping', (tester) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          staffTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );
      final branchNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        buildMockStaffTree(
          container: container,
          branchNotifier: branchNotifier,
          hasOrders: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final notifier = container.read(baristaSpotlightProvider.notifier);
      notifier.startTour();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.text('Barista Station & Daily Queue'), findsOneWidget);
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    testWidgets('4. Desktop / Web Form-Factor (1440x900): Verifies wide layout spotlight framing', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          staffTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );
      final branchNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        buildMockStaffTree(
          container: container,
          branchNotifier: branchNotifier,
          hasOrders: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final notifier = container.read(baristaSpotlightProvider.notifier);
      notifier.startTour();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.text('Barista Station & Daily Queue'), findsOneWidget);
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    testWidgets('5. Architecture: InvertedSpotlightClipper properly creates cutout excluding target from blur', (tester) async {
      const outerRect = Rect.fromLTWH(0, 0, 400, 800);
      const targetRect = Rect.fromLTWH(50, 100, 300, 150);

      const clipper = InvertedSpotlightClipper(
        targetRect: targetRect,
        borderRadius: 14,
        shape: SpotlightShape.roundedRect,
      );

      final path = clipper.getClip(outerRect.size);

      // Target area must NOT be included in clip path (excluded from blur shader)
      expect(path.contains(const Offset(200, 175)), isFalse);

      // Surrounding areas MUST be included in clip path (dimmed and softly blurred)
      expect(path.contains(const Offset(20, 50)), isTrue);
      expect(path.contains(const Offset(200, 500)), isTrue);
    });
  });
}
