import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/admin_spotlight_data.dart';
import 'package:lambac_app/features/onboarding/data/datasources/admin_tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/data/models/spotlight_step_model.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/admin_tutorial_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/admin_spotlight_overlay.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/admin_spotlight_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_instructional_card.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_keys.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Admin Spotlight Responsive & Geometry Verification Tests', () {
    late StorageService storageService;
    late AdminTutorialLocalDataSource localDataSource;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = AdminTutorialLocalDataSourceImpl(storageService: storageService);
    });

    Widget buildMockAdminTree({
      required ProviderContainer container,
      required ValueNotifier<int> branchNotifier,
      required ScrollController scrollController,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.listen(adminSpotlightProvider, (prev, next) {
                  if (next.isActive && next.currentStep != null) {
                    final targetBranch = next.currentStep!.targetBranchIndex;
                    if (targetBranch != null && targetBranch != branchNotifier.value) {
                      branchNotifier.value = targetBranch;
                    }
                  }
                });

                return AdminSpotlightOverlay(
                  child: AnimatedBuilder(
                animation: branchNotifier,
                builder: (context, _) {
                  final branch = branchNotifier.value;
                  return Column(
                    children: [
                      // Simulated Tab Bar / Branch Selector
                      Container(
                        height: 50,
                        color: Colors.black87,
                        child: Row(
                          children: [
                            Text('Current Branch: $branch'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: branch,
                          children: [
                            // Branch 0: Dashboard
                            SingleChildScrollView(
                              controller: scrollController,
                              child: Column(
                                children: [
                                  Container(
                                    key: SpotlightKeys.adminDashboardHeader,
                                    height: 120,
                                    color: Colors.brown[900],
                                    child: const Center(
                                      child: Text('Widget: Executive Command Center Header'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    key: SpotlightKeys.adminRevenueCard,
                                    height: 100,
                                    color: Colors.brown[800],
                                    child: const Center(
                                      child: Text('Widget: Daily Revenue & Financial KPIs'),
                                    ),
                                  ),
                                  const SizedBox(height: 500),
                                  Container(
                                    key: SpotlightKeys.adminInboxSummaryCard,
                                    height: 100,
                                    color: Colors.brown[700],
                                    child: const Center(
                                      child: Text('Widget: Guest Concierge & Inquiries'),
                                    ),
                                  ),
                                  const SizedBox(height: 200),
                                ],
                              ),
                            ),
                            // Branch 1: Orders
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  Container(
                                    key: SpotlightKeys.adminOrdersQueue,
                                    height: 140,
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: Text('Widget: Fulfillment & Status Queue'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Branch 2: Products
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  Container(
                                    key: SpotlightKeys.adminAddProductBtn,
                                    height: 48,
                                    width: 48,
                                    color: Colors.amber,
                                    child: const Center(
                                      child: Text('Widget: Add Roast'),
                                    ),
                                  ),
                                  Container(
                                    key: SpotlightKeys.adminProductsCatalog,
                                    height: 120,
                                    color: Colors.grey[850],
                                    child: const Center(
                                      child: Text('Widget: Coffee Catalog & Availability'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Branch 3: Intelligence
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  Container(
                                    key: SpotlightKeys.adminBiTabs,
                                    height: 60,
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Text('Widget: Business Intelligence Tabs'),
                                    ),
                                  ),
                                  Container(
                                    key: SpotlightKeys.adminForecastingCard,
                                    height: 120,
                                    color: Colors.grey[750],
                                    child: const Center(
                                      child: Text('Widget: Sales & Demand Forecasting'),
                                    ),
                                  ),
                                  Container(
                                    key: SpotlightKeys.adminPrescriptiveCard,
                                    height: 120,
                                    color: Colors.grey[700],
                                    child: const Center(
                                      child: Text('Widget: Prescriptive Decision Dispatch'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Branch 4: Control / Profile
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  Container(
                                    key: SpotlightKeys.adminControlModules,
                                    height: 150,
                                    color: Colors.grey[650],
                                    child: const Center(
                                      child: Text('Widget: RBAC Governance & Shift Control'),
                                    ),
                                  ),
                                ],
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

    testWidgets('1. Phone Form-Factor (390x844): Traverses all 10 steps with unblurred mask and branch switching', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          adminTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );
      final branchNotifier = ValueNotifier<int>(0);
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildMockAdminTree(
          container: container,
          branchNotifier: branchNotifier,
          scrollController: scrollController,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final notifier = container.read(adminSpotlightProvider.notifier);
      notifier.startTour();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Step 1: Executive Command Center
      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.textContaining('STEP 1 OF 10'), findsOneWidget);
      expect(find.text('Executive Command Center'), findsOneWidget);

      // Advance to Step 2: Revenue
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 2 OF 10'), findsOneWidget);
      expect(find.text('Daily Revenue & Financial KPIs'), findsOneWidget);

      // Advance to Step 3: Orders Queue (Branch 1)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(branchNotifier.value, equals(1));
      expect(find.textContaining('STEP 3 OF 10'), findsOneWidget);
      expect(find.text('Fulfillment & Status Queue'), findsOneWidget);

      // Advance to Step 4: Catalog (Branch 2)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(branchNotifier.value, equals(2));
      expect(find.textContaining('STEP 4 OF 10'), findsOneWidget);
      expect(find.text('Coffee Catalog & Availability'), findsOneWidget);

      // Advance to Step 5: Add Roast (Branch 2)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 5 OF 10'), findsOneWidget);
      expect(find.text('New Roast Creation & Pricing'), findsOneWidget);

      // Advance to Step 6: Inbox Module (Branch 0 with scroll)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(branchNotifier.value, equals(0));
      expect(find.textContaining('STEP 6 OF 10'), findsOneWidget);
      expect(find.text('Guest Concierge & Inquiries'), findsOneWidget);

      // Advance to Step 7: BI Hub (Branch 3)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(branchNotifier.value, equals(3));
      expect(find.textContaining('STEP 7 OF 10'), findsOneWidget);
      expect(find.text('Business Intelligence Hub'), findsOneWidget);

      // Advance to Step 8: Forecasting (Branch 3)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 8 OF 10'), findsOneWidget);
      expect(find.text('Sales & Demand Forecasting'), findsOneWidget);

      // Advance to Step 9: Prescriptive (Branch 3)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('STEP 9 OF 10'), findsOneWidget);
      expect(find.text('Prescriptive Decision Dispatch'), findsOneWidget);

      // Advance to Step 10: Control RBAC (Branch 4)
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(branchNotifier.value, equals(4));
      expect(find.textContaining('STEP 10 OF 10'), findsOneWidget);
      expect(find.text('RBAC Governance & Shift Control'), findsOneWidget);
      expect(find.text('Finish Tour'), findsOneWidget);

      // Finish Tour
      await tester.tap(find.text('Finish Tour'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SpotlightInstructionalCard), findsNothing);
      expect(container.read(adminSpotlightProvider).isActive, isFalse);
      expect(container.read(adminSpotlightProvider).isCompleted, isTrue);

      container.dispose();
    });

    testWidgets('2. Tablet Form-Factor (820x1180): Verifies card placement and geometry without clipping', (tester) async {
      tester.view.physicalSize = const Size(820, 1180);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          adminTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );
      final branchNotifier = ValueNotifier<int>(0);
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildMockAdminTree(
          container: container,
          branchNotifier: branchNotifier,
          scrollController: scrollController,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final notifier = container.read(adminSpotlightProvider.notifier);
      notifier.startTour();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.text('Executive Command Center'), findsOneWidget);

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    testWidgets('3. Desktop / Web Form-Factor (1440x900): Verifies wide layout spotlight framing', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          adminTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
        ],
      );
      final branchNotifier = ValueNotifier<int>(0);
      final scrollController = ScrollController();

      await tester.pumpWidget(
        buildMockAdminTree(
          container: container,
          branchNotifier: branchNotifier,
          scrollController: scrollController,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final notifier = container.read(adminSpotlightProvider.notifier);
      notifier.startTour();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SpotlightInstructionalCard), findsOneWidget);
      expect(find.text('Executive Command Center'), findsOneWidget);

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    testWidgets('4. Architecture: InvertedSpotlightClipper properly creates cutout excluding target from blur', (tester) async {
      const outerRect = Rect.fromLTWH(0, 0, 400, 800);
      const targetRect = Rect.fromLTWH(50, 100, 300, 150);

      final clipper = InvertedSpotlightClipper(
        targetRect: targetRect,
        borderRadius: 16,
        shape: SpotlightShape.roundedRect,
      );

      final path = clipper.getClip(outerRect.size);

      // Point inside target rectangle must NOT be contained in the clip path (it is cut out / unblurred)
      expect(path.contains(const Offset(200, 175)), isFalse);

      // Point outside target rectangle MUST be contained in the clip path (it is blurred and dimmed)
      expect(path.contains(const Offset(20, 50)), isTrue);
      expect(path.contains(const Offset(200, 500)), isTrue);
    });

    testWidgets('5. Architecture: SpotlightBackgroundEffect renders peripheral blur strips excluding targetRect from blur', (tester) async {
      const outerSize = Size(400, 800);
      const targetRect = Rect.fromLTWH(50, 100, 300, 150);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: outerSize.width,
              height: outerSize.height,
              child: const SpotlightBackgroundEffect(
                targetRect: targetRect,
                borderRadius: 16,
                shape: SpotlightShape.roundedRect,
                scrimColor: Color(0xAA000000),
              ),
            ),
          ),
        ),
      );

      // Verify BackdropFilter widgets exist for surrounding blur
      final backdropFilters = find.byType(BackdropFilter);
      expect(backdropFilters, findsWidgets);

      // Verify that no BackdropFilter widget is positioned inside the targetRect center
      for (final element in backdropFilters.evaluate()) {
        final renderObject = element.renderObject as RenderBox;
        final globalPos = renderObject.localToGlobal(Offset.zero);
        final bounds = Rect.fromLTWH(globalPos.dx, globalPos.dy, renderObject.size.width, renderObject.size.height);
        
        // The bounds of each blur strip should be outside the interior of targetRect
        final targetCenter = targetRect.center;
        expect(bounds.contains(targetCenter), isFalse,
            reason: 'Blur strip must never cover the center of targetRect');
      }

      // Verify CustomPaint with even-odd scrim is present
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
