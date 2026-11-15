import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/onboarding/data/datasources/admin_tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/data/repositories/admin_tutorial_repository_impl.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/admin_tutorial_provider.dart';
import 'package:lambac_app/features/onboarding/presentation/screens/admin_help_guide_screen.dart';
import 'package:lambac_app/features/onboarding/presentation/screens/admin_tutorial_screen.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/admin_tutorial_card.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/admin_tutorial_completion_view.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/admin_tutorial_progress_bar.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Administrator Interactive Tutorial & Help Guide Widget Tests', () {
    late StorageService storageService;
    late AdminTutorialLocalDataSource localDataSource;
    late AdminTutorialRepositoryImpl repository;

    const mockAdminUser = UserModel(
      id: 'admin_101',
      email: 'jmbautista0228@gmail.com',
      fullName: 'Master Roaster Admin',
      role: UserRole.admin,
      status: UserStatus.active,
    );

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = AdminTutorialLocalDataSourceImpl(storageService: storageService);
      repository = AdminTutorialRepositoryImpl(localDataSource: localDataSource);
    });

    Widget createWidgetUnderTest(Widget child) {
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockAdminUser),
          storageServiceProvider.overrideWithValue(storageService),
          adminTutorialLocalDataSourceProvider.overrideWithValue(localDataSource),
          adminTutorialRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('1. AdminTutorialScreen: Initial welcome screen renders BI hub title, start tour, and replay reminder', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AdminTutorialScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to the Lambac Business Intelligence Hub'), findsOneWidget);
      expect(find.text('Start Tour'), findsOneWidget);
      expect(find.text('Skip'), findsWidgets);
      expect(
        find.textContaining('Admin Profile → Help & Guide'),
        findsOneWidget,
      );
    });

    testWidgets('2. AdminTutorialScreen: Tapping Start Tour switches to Step 1 executive walkthrough', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AdminTutorialScreen()));
      await tester.pumpAndSettle();

      // Tap Start Tour
      await tester.tap(find.text('Start Tour'));
      await tester.pumpAndSettle();

      // Verify Step 1 is active
      expect(find.text('Step 1 of 22'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);
      expect(find.byType(AdminTutorialProgressBar), findsOneWidget);
      expect(find.byType(AdminTutorialCard), findsOneWidget);
      expect(find.text('Welcome to Lambac BI Hub'), findsWidgets);
    });

    testWidgets('3. AdminTutorialScreen: Next Step button advances through steps and updates progress', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AdminTutorialScreen(initialStep: 0, isReplay: true)));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 22'), findsOneWidget);

      // Advance to step 2
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 22'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Executive Governance Dashboard'), findsOneWidget);
    });

    testWidgets('4. AdminTutorialCompletionView: Renders ready to manage celebration, Open Dashboard and Replay', (tester) async {
      bool openedDashboard = false;
      bool replayed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTutorialCompletionView(
              isDark: false,
              onOpenDashboard: () => openedDashboard = true,
              onReplayTutorial: () => replayed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("You're ready to manage Lambac."), findsOneWidget);
      expect(find.text('Open Dashboard'), findsOneWidget);
      expect(find.text('Replay Tutorial'), findsOneWidget);
      expect(find.textContaining('Admin Profile → Help & Guide'), findsOneWidget);

      await tester.tap(find.text('Open Dashboard'));
      expect(openedDashboard, isTrue);

      await tester.tap(find.text('Replay Tutorial'));
      expect(replayed, isTrue);
    });

    testWidgets('5. AdminHelpGuideScreen: Renders executive guide hero, search bar, and chapter directory', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AdminHelpGuideScreen()));
      await tester.pumpAndSettle();

      expect(find.text('BI & Executive System Guide'), findsOneWidget);
      expect(find.text('Executive System & BI Walkthrough'), findsOneWidget);
      expect(find.text('EXECUTIVE BI HUB'), findsOneWidget);

      final mainListScrollable = find.byType(Scrollable).first;
      final sopFinder = find.text('EXECUTIVE SOPS & BI METHODOLOGY FAQS');
      await tester.scrollUntilVisible(
        sopFinder,
        200,
        scrollable: mainListScrollable,
      );
      expect(sopFinder, findsOneWidget);
    });
  });
}
