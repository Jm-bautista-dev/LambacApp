import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/services/feedback_service.dart';
import 'package:lambac_app/core/widgets/dialogs/app_dialog.dart';
import 'package:lambac_app/core/widgets/feedback/app_toast.dart';

void main() {
  group('Professional Toast & Modal Feedback System Tests', () {
    testWidgets('AppToast.cartItemAdded renders item name, quantity, and View Cart action', (tester) async {
      bool viewCartTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppToast.cartItemAdded(
                  context,
                  productName: 'Iced Spanish Latte',
                  quantity: 2,
                  variantDescription: '500g, Whole Bean',
                  onViewCart: () {
                    viewCartTapped = true;
                  },
                ),
                child: const Text('Add Item'),
              ),
            ),
          ),
        ),
      );

      // Tap to trigger toast
      await tester.tap(find.text('Add Item'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 400)); // Finish entry animation

      expect(find.text('Added to Cart'), findsOneWidget);
      expect(find.text('2 × Iced Spanish Latte (500g, Whole Bean)'), findsOneWidget);
      expect(find.text('View Cart →'), findsOneWidget);

      // Tap View Cart action
      await tester.tap(find.text('View Cart →'));
      await tester.pump();
      expect(viewCartTapped, isTrue);
    });

    testWidgets('AppToast.error sanitizes raw technical exceptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppToast.error(
                  context,
                  'SocketException: OS Error: Connection refused, errno = 111, address = 127.0.0.1',
                ),
                child: const Text('Trigger Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Must NOT show raw SocketException
      expect(find.textContaining('SocketException'), findsNothing);
      expect(find.text('Unable to connect. Please check your internet connection and try again.'), findsOneWidget);
    });

    testWidgets('AppToast.show clears existing snackbar immediately to prevent stacking', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppToast.info(context, 'First message'),
                    child: const Text('First'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppToast.success(context, 'Second message'),
                    child: const Text('Second'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap First
      await tester.tap(find.text('First'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('First message'), findsOneWidget);

      // Tap Second immediately
      await tester.tap(find.text('Second'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // First should be replaced by Second
      expect(find.text('Second message'), findsOneWidget);
    });

    testWidgets('AppDialog.destructive renders title, message, destructive button, and returns decision', (tester) async {
      bool? userDecision;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  userDecision = await AppDialog.destructive(
                    context,
                    title: 'Sign Out?',
                    message: 'Are you sure you want to sign out?',
                    confirmText: 'Sign Out',
                    cancelText: 'Cancel',
                    icon: Icons.logout_rounded,
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out?'), findsOneWidget);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(userDecision, isTrue);
    });

    testWidgets('AppDialog.confirm returns false when Cancel is tapped', (tester) async {
      bool? userDecision;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  userDecision = await AppDialog.confirm(
                    context,
                    title: 'Discard Changes?',
                    message: 'Any unsaved changes will be lost.',
                    confirmText: 'Discard',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Discard Changes?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(userDecision, isFalse);
    });

    testWidgets('AppFeedback.handleFailure displays mapped polite error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppFeedback.handleFailure(
                  context,
                  const ServerFailure(),
                ),
                child: const Text('Trigger Failure'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Failure'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Something went wrong on our end. Please try again.'), findsOneWidget);
    });
  });
}
