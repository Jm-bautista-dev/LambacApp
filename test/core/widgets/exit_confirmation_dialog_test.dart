import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lambac_app/core/widgets/dialogs/exit_confirmation_dialog.dart';

void main() {
  group('ExitConfirmationScope & ExitConfirmationDialog', () {
    testWidgets(
      'system back on secondary page pops normally and does NOT show exit dialog',
      (tester) async {
        bool exitCalled = false;

        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            ShellRoute(
              builder: (_, __, child) => ExitConfirmationScope(
                forceEnableForTesting: true,
                onExitConfirmed: () => exitCalled = true,
                child: child,
              ),
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, __) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () => context.push('/detail'),
                      child: const Text('Go Detail'),
                    ),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/detail',
              builder: (_, __) => const Scaffold(body: Text('Secondary Page')),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Go Detail'));
        await tester.pumpAndSettle();
        expect(find.text('Secondary Page'), findsOneWidget);

        // Simulate system back button on secondary page
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Go Detail'), findsOneWidget);
        expect(find.text('Exit Application?'), findsNothing);
        expect(exitCalled, isFalse);
      },
    );

    testWidgets(
      'system back on root page opens exit confirmation dialog; Cancel preserves state',
      (tester) async {
        bool exitCalled = false;
        int counter = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => ExitConfirmationScope(
                forceEnableForTesting: true,
                onExitConfirmed: () => exitCalled = true,
                child: Scaffold(
                  body: Column(
                    children: [
                      Text('Count: $counter'),
                      ElevatedButton(
                        onPressed: () => setState(() => counter++),
                        child: const Text('Increment'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Increment'));
        await tester.pump();
        expect(find.text('Count: 1'), findsOneWidget);

        // Simulate Android system back at root
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Exit Application?'), findsOneWidget);
        expect(
          find.text('Are you sure you want to leave Lambac Coffee Roastery?'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Exit'), findsOneWidget);

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Exit Application?'), findsNothing);
        expect(find.text('Count: 1'), findsOneWidget);
        expect(exitCalled, isFalse);
      },
    );

    testWidgets('tapping Exit confirms exit callback', (tester) async {
      bool exitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ExitConfirmationScope(
            forceEnableForTesting: true,
            onExitConfirmed: () => exitCalled = true,
            child: const Scaffold(body: Text('Root Page')),
          ),
        ),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();

      expect(exitCalled, isTrue);
    });

    testWidgets(
      'repeated back presses do not stack duplicate dialogs; barrier tap dismisses cleanly',
      (tester) async {
        bool exitCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: ExitConfirmationScope(
              forceEnableForTesting: true,
              onExitConfirmed: () => exitCalled = true,
              child: const Scaffold(body: Text('Root Page')),
            ),
          ),
        );

        // First back press opens exit dialog
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Exit Application?'), findsOneWidget);

        // Second back press while dialog is open dismisses the dialog cleanly without exiting
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Exit Application?'), findsNothing);
        expect(exitCalled, isFalse);

        // Third back press re-opens dialog; barrier tap dismisses cleanly
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Exit Application?'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.text('Exit Application?'), findsNothing);
        expect(exitCalled, isFalse);
      },
    );

    testWidgets(
      'works across StatefulShellRoute bottom nav destinations and 320x568 / 1920x1080 in dark mode',
      (tester) async {
        for (final size in const [Size(320, 568), Size(1920, 1080)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          final router = GoRouter(
            initialLocation: '/tab1',
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (_, __, navigationShell) => ExitConfirmationScope(
                  forceEnableForTesting: true,
                  child: Scaffold(
                    body: navigationShell,
                    bottomNavigationBar: BottomNavigationBar(
                      currentIndex: navigationShell.currentIndex,
                      onTap: (i) => navigationShell.goBranch(i),
                      items: const [
                        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                        BottomNavigationBarItem(icon: Icon(Icons.coffee), label: 'Menu'),
                      ],
                    ),
                  ),
                ),
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: '/tab1',
                        builder: (_, __) => const Center(child: Text('Tab 1')),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: '/tab2',
                        builder: (_, __) => const Center(child: Text('Tab 2')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp.router(
              theme: ThemeData.dark(),
              routerConfig: router,
            ),
          );
          await tester.pumpAndSettle();

          // Switch to second root tab
          await tester.tap(find.text('Menu'));
          await tester.pumpAndSettle();
          expect(find.text('Tab 2'), findsOneWidget);

          // Press system back at root tab 2
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Exit Application?'), findsOneWidget);

          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(find.text('Tab 2'), findsOneWidget);

          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      },
    );

    testWidgets('non-Android platforms (e.g. iOS/Desktop) do not intercept with exit dialog',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExitConfirmationScope(
            child: Scaffold(body: Text('iOS/Desktop Root')),
          ),
        ),
      );

      expect(find.byType(PopScope), findsNothing);
    });
  });
}
