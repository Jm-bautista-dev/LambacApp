import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/errors/async_operation_state.dart';
import 'package:lambac_app/core/monitoring/operational_monitoring_service.dart';
import 'package:lambac_app/core/network/realtime_stream_handler.dart';
import 'package:lambac_app/core/widgets/feedback/app_error_view.dart';
import 'package:lambac_app/core/widgets/inputs/app_form_field_error.dart';

void main() {
  group('Lambac UI States, Presentation & Lifecycle Safety Tests', () {
    group('1. AsyncOperationState Model & Transitions', () {
      test('Initial state properties', () {
        const state = AsyncOperationState<String>.initial();
        expect(state.isInitial, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.isFailure, isFalse);
        expect(state.dataOrNull, isNull);
        expect(state.failureOrNull, isNull);
      });

      test('Loading state preserves previous data during refresh', () {
        const state = AsyncOperationState<String>.loading(previousData: 'Cached Coffee Menu');
        expect(state.isLoading, isTrue);
        expect(state.dataOrNull, 'Cached Coffee Menu');
      });

      test('Success state holds authoritative payload', () {
        const state = AsyncOperationState<List<String>>.success(['Espresso', 'Pour Over']);
        expect(state.isSuccess, isTrue);
        expect(state.dataOrNull, ['Espresso', 'Pour Over']);
      });

      test('Failure state distinguishes recoverable vs non-recoverable', () {
        const recoverable = AsyncOperationState<String>.failure(NetworkFailure());
        expect(recoverable.isFailure, isTrue);
        expect(recoverable.isRecoverableFailure, isTrue);
        expect(recoverable.canRetry, isTrue);

        const unrecoverable = AsyncOperationState<String>.failure(ForbiddenFailure());
        expect(unrecoverable.isFailure, isTrue);
        expect(unrecoverable.isRecoverableFailure, isFalse);
        expect(unrecoverable.canRetry, isFalse);

        const valFailure = AsyncOperationState<String>.failure(
          ValidationFailure(message: 'Invalid phone', fieldErrors: {'phone': ['Required']}),
        );
        expect(valFailure.isValidationFailure, isTrue);
        expect(valFailure.canRetry, isFalse);
      });

      test('Pattern matching with when()', () {
        const state = AsyncOperationState<String>.success('Order #1042');
        final message = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          success: (data) => 'Order confirmed: $data',
          failure: (_) => 'failed',
          empty: () => 'empty',
        );

        expect(message, 'Order confirmed: Order #1042');
      });
    });

    group('2. AppErrorView Widget Presentation', () {
      testWidgets('Renders Network Unavailable title and Try Again button', (tester) async {
        bool retryTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppErrorView(
                failure: const NetworkFailure(),
                onRetry: () => retryTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Network Unavailable'), findsOneWidget);
        expect(find.text("You're offline. Check your connection and try again."), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);

        await tester.tap(find.text('Try Again'));
        await tester.pump();
        expect(retryTapped, isTrue);
      });

      testWidgets('Renders Access Denied for ForbiddenFailure without retry button', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppErrorView(
                failure: ForbiddenFailure(),
              ),
            ),
          ),
        );

        expect(find.text('Access Denied'), findsOneWidget);
        expect(find.text("You don't have permission to perform this action."), findsOneWidget);
        expect(find.text('Try Again'), findsNothing);
      });
    });

    group('3. AppFormFieldError Inline Presentation', () {
      testWidgets('Renders inline field error when field error exists', (tester) async {
        const failure = ValidationFailure(
          message: 'Validation failed',
          fieldErrors: {
            'email': ['Please enter a valid email address.'],
            'password': ['Password is too short.'],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppFormFieldError.forField(
                fieldKey: 'email',
                failure: failure,
              ),
            ),
          ),
        );

        expect(find.text('Please enter a valid email address.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });

      testWidgets('Renders nothing when no error for that field', (tester) async {
        const failure = ValidationFailure(
          message: 'Validation failed',
          fieldErrors: {'email': ['Invalid email']},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppFormFieldError.forField(
                fieldKey: 'phoneNumber',
                failure: failure,
              ),
            ),
          ),
        );

        expect(find.byType(AppFormFieldError), findsOneWidget);
        expect(find.text('Invalid email'), findsNothing);
        expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
      });
    });

    group('4. RealtimeStreamHandler Lifecycle & Session Isolation', () {
      test('Cancels subscription on session change to prevent user data bleeding', () {
        final controller1 = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();

        final handler = RealtimeStreamHandler<String>(
          streamTag: 'test_stream',
          domain: FailureDomain.firestoreAccess,
          streamBuilder: () => controller1.stream,
          itemMapper: (doc) => doc.id,
          onData: (items, isFromCache) {},
        );

        // Listen for user 1
        handler.listen(userId: 'user_1');
        expect(handler.isActive, isTrue);
        expect(handler.status, RealtimeSyncStatus.initialLoading);

        // Switch to user 2
        handler.listen(userId: 'user_2');
        expect(handler.isActive, isTrue);

        // Dispose cleanly
        handler.dispose();
        expect(handler.isActive, isFalse);
        expect(handler.status, RealtimeSyncStatus.closed);

        controller1.close();
      });
    });
  });
}
