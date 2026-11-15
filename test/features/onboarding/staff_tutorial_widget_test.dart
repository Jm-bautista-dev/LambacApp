import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/onboarding/data/datasources/staff_tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/data/repositories/staff_tutorial_repository_impl.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/staff_tutorial_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/screens/staff_help_guide_screen.dart';
import 'package:lambac_app/features/onboarding/presentation/screens/staff_tutorial_screen.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/staff_tutorial_card.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/staff_tutorial_completion_view.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/staff_tutorial_progress_bar.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Barista / Staff Interactive Operations Tutorial & Help Guide Widget Tests', () {
    late StorageService storageService;
    late StaffTutorialLocalDataSource localDataSource;
    late StaffTutorialRepositoryImpl repository;

    const mockStaffUser = UserModel(
      id: 'staff_101',
      email: 'barista.staff@lambac.com',
      fullName: 'Jordan Barista',
      role: UserRole.employee,
      status: UserStatus.active,
    );

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = StaffTutorialLocalDataSourceImpl(storageService: storageService);
      repository = StaffTutorialRepositoryImpl(localDataSource: localDataSource);
    });

    Widget createWidgetUnderTest(Widget child) {
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockStaffUser),
          storageServiceProvider.overrideWithValue(storageService),
          staffTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
          staffTutorialRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('1. StaffTutorialScreen: Initial welcome screen renders operations title, start tour, and replay reminder', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const StaffTutorialScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Lambac Operations'), findsOneWidget);
      expect(find.text('Start Tour'), findsOneWidget);
      expect(find.text('Skip'), findsWidgets);
      expect(
        find.textContaining('You can replay this guide anytime from My Shift'),
        findsOneWidget,
      );
    });

    testWidgets('2. StaffTutorialScreen: Tapping Start Tour switches to Step 1 operational walkthrough', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const StaffTutorialScreen()));
      await tester.pumpAndSettle();

      // Tap Start Tour
      await tester.tap(find.text('Start Tour'));
      await tester.pumpAndSettle();

      // Verify Step 1 is active
      expect(find.text('Step 1 of 20'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);
      expect(find.byType(StaffTutorialProgressBar), findsOneWidget);
      expect(find.byType(StaffTutorialCard), findsOneWidget);
      expect(find.text('Welcome to Lambac Operations'), findsWidgets);
    });

    testWidgets('3. StaffTutorialScreen: Next Step button advances through steps and updates progress', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const StaffTutorialScreen(initialStep: 0, isReplay: true)));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 20'), findsOneWidget);

      // Advance to step 2
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 20'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Station Navigation Structure'), findsOneWidget);
    });

    testWidgets('4. StaffTutorialCompletionView: Renders service ready celebration, Start Working and Replay', (tester) async {
      bool startedWorking = false;
      bool replayed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffTutorialCompletionView(
              isDark: false,
              onStartWorking: () => startedWorking = true,
              onReplayTutorial: () => replayed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("You're ready for service."), findsOneWidget);
      expect(find.text('Start Working'), findsOneWidget);
      expect(find.text('Replay Tutorial'), findsOneWidget);
      expect(find.textContaining('My Shift → Help & Guide'), findsOneWidget);

      await tester.tap(find.text('Start Working'));
      expect(startedWorking, isTrue);

      await tester.tap(find.text('Replay Tutorial'));
      expect(replayed, isTrue);
    });

    testWidgets('5. StaffHelpGuideScreen: Renders Operations Hub, Search, Category filter chips, and SOPs', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const StaffHelpGuideScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Help & Operations Guide'), findsOneWidget);
      expect(find.text('Barista & Staff Operations Walkthrough'), findsOneWidget);
      expect(find.text('STAFF OPERATIONS SOP'), findsOneWidget);

      final mainListScrollable = find.byType(Scrollable).first;
      final sopFinder = find.text('STANDARD OPERATING PROCEDURES (SOP)');
      await tester.scrollUntilVisible(
        sopFinder,
        200,
        scrollable: mainListScrollable,
      );
      expect(sopFinder, findsOneWidget);
    });
  });
}
