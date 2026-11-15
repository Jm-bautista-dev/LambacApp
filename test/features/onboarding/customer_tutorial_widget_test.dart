import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/data/repositories/tutorial_repository_impl.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/tutorial_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/screens/help_guide_screen.dart';
import 'package:lambac_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/tutorial_card.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/tutorial_completion_view.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/tutorial_progress_bar.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Customer Interactive Tutorial & Help Guide Widget Tests', () {
    late StorageService storageService;
    late TutorialLocalDataSource localDataSource;
    late TutorialRepositoryImpl repository;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = TutorialLocalDataSourceImpl(storageService: storageService);
      repository = TutorialRepositoryImpl(localDataSource: localDataSource);
    });

    Widget createWidgetUnderTest(Widget child) {
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          tutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
          tutorialRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('1. OnboardingScreen: Initial welcome screen renders luxury header, guest notice and buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Lambac Coffee Roastery'), findsOneWidget);
      expect(find.text('Start Interactive Tour'), findsOneWidget);
      expect(find.text('Explore Directly'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(
        find.textContaining('You can explore our menu without an account'),
        findsOneWidget,
      );
    });

    testWidgets('2. OnboardingScreen: Tapping Start Interactive Tour switches to Step 1 walkthrough', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Tap Start Tour
      await tester.tap(find.text('Start Interactive Tour'));
      await tester.pumpAndSettle();

      // Verify Step 1 is active
      expect(find.text('Step 1 of 20'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);
      expect(find.byType(TutorialProgressBar), findsOneWidget);
      expect(find.byType(TutorialCard), findsOneWidget);
      expect(find.text('Welcome to Lambac Coffee Roastery'), findsOneWidget);
    });

    testWidgets('3. OnboardingScreen: Next Step button advances through steps and updates progress', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const OnboardingScreen(initialStep: 0, isReplay: true)));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 20'), findsOneWidget);

      // Advance to step 2
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 20'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Guest Browsing & Member Accounts'), findsOneWidget);
    });

    testWidgets('4. TutorialCompletionView: Renders congratulations message, Start Exploring and View Again', (tester) async {
      bool startedExploring = false;
      bool viewedAgain = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialCompletionView(
              isDark: false,
              onStartExploring: () => startedExploring = true,
              onBrowseMenu: () {},
              onViewAgain: () => viewedAgain = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("You're all set."), findsOneWidget);
      expect(find.text('Start Exploring Lambac'), findsOneWidget);
      expect(find.text('Browse Roastery Menu'), findsOneWidget);
      expect(find.text('View Tutorial Again'), findsOneWidget);
      expect(find.textContaining('Profile → Help & Guide'), findsOneWidget);

      await tester.tap(find.text('Start Exploring Lambac'));
      expect(startedExploring, isTrue);

      await tester.tap(find.text('View Tutorial Again'));
      expect(viewedAgain, isTrue);
    });

    testWidgets('5. HelpGuideScreen: Renders Hero Replay card, Category filter chips, and FAQs', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const HelpGuideScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Help & Roastery Guide'), findsOneWidget);
      expect(find.text('Replay Interactive Tour (20 Steps)'), findsOneWidget);
      expect(find.text('Explore Feature Guides by Topic'), findsOneWidget);

      final faqFinder = find.text('Frequently Asked Questions');
      await tester.scrollUntilVisible(
        faqFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(faqFinder, findsOneWidget);

      final chatCtaFinder = find.text('Chat with Barista Team');
      await tester.scrollUntilVisible(
        chatCtaFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(chatCtaFinder, findsOneWidget);
    });
  });
}
