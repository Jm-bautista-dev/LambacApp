import 'dart:async' as async;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/errors/async_operation_state.dart';
import 'package:lambac_app/core/errors/error_handler.dart';
import 'package:lambac_app/core/monitoring/operational_monitoring_service.dart';
import 'package:lambac_app/core/monitoring/secure_error_logger.dart';
import 'package:lambac_app/core/network/result.dart';
import 'package:lambac_app/core/network/retry_policy.dart';

void main() {
  group('Lambac Application-Wide Error Handling Foundation Tests', () {
    setUp(() {
      OperationalMonitoringService().clearForTest();
    });

    group('1. Error Classification & Typed Model Contracts', () {
      test('All 13 error categories instantiate with correct defaults', () {
        const vFail = ValidationFailure(
          message: 'Invalid input',
          fieldErrors: {'email': ['Email required']},
        );
        expect(vFail.errorCode, 'VALIDATION_ERROR');
        expect(vFail.isRecoverable, isTrue);
        expect(vFail.canRetry, isFalse);
        expect(vFail.firstErrorFor('email'), 'Email required');

        const authFail = UnauthorizedFailure();
        expect(authFail.errorCode, 'UNAUTHORIZED');
        expect(authFail.isRecoverable, isTrue);
        expect(authFail.canRetry, isFalse);

        const forbidFail = ForbiddenFailure();
        expect(forbidFail.errorCode, 'FORBIDDEN');
        expect(forbidFail.isRecoverable, isFalse);
        expect(forbidFail.canRetry, isFalse);

        const notFoundFail = NotFoundFailure();
        expect(notFoundFail.errorCode, 'NOT_FOUND');
        expect(notFoundFail.isRecoverable, isFalse);

        const conflictFail = ConflictFailure();
        expect(conflictFail.errorCode, 'CONFLICT');
        expect(conflictFail.isRecoverable, isTrue);
        expect(conflictFail.canRetry, isFalse);

        const precondFail = PreconditionFailure();
        expect(precondFail.errorCode, 'PRECONDITION_FAILED');
        expect(precondFail.canRetry, isFalse);

        const rateLimitFail = RateLimitFailure();
        expect(rateLimitFail.errorCode, 'RATE_LIMIT_EXCEEDED');
        expect(rateLimitFail.canRetry, isFalse);

        const netFail = NetworkFailure();
        expect(netFail.errorCode, 'NETWORK_ERROR');
        expect(netFail.isRecoverable, isTrue);
        expect(netFail.canRetry, isTrue);

        const timeFail = TimeoutFailure();
        expect(timeFail.errorCode, 'TIMEOUT');
        expect(timeFail.isRecoverable, isTrue);
        expect(timeFail.canRetry, isTrue);

        const servFail = ServiceFailure();
        expect(servFail.errorCode, 'SERVICE_ERROR');
        expect(servFail.isRecoverable, isTrue);
        expect(servFail.canRetry, isTrue);

        const dataFail = DataIntegrityFailure();
        expect(dataFail.errorCode, 'DATA_INTEGRITY_ERROR');
        expect(dataFail.canRetry, isFalse);

        const cancelFail = CancelledFailure();
        expect(cancelFail.errorCode, 'CANCELLED');
        expect(cancelFail.canRetry, isFalse);

        const unkFail = UnknownFailure();
        expect(unkFail.errorCode, 'UNKNOWN_ERROR');
        expect(unkFail.canRetry, isFalse);
      });

      test('Original exception and stack traces are excluded from user toString', () {
        final failure = NetworkFailure(
          message: "You're offline. Check your connection and try again.",
          originalException: const SocketException('Failed host lookup: firestore.googleapis.com'),
          stackTrace: StackTrace.current,
        );

        final display = failure.toString();
        expect(display, contains("You're offline"));
        expect(display, isNot(contains('Failed host lookup')));
        expect(display, isNot(contains('firestore.googleapis.com')));
      });
    });

    group('2. Firebase Auth Exception Mapping', () {
      test('Maps invalid-email to ValidationFailure with fieldErrors', () {
        final ex = FirebaseAuthException(code: 'invalid-email', message: 'Bad email');
        final failure = ErrorHandler.handle(ex);

        expect(failure, isA<ValidationFailure>());
        final vf = failure as ValidationFailure;
        expect(vf.firstErrorFor('email'), contains('valid email'));
      });

      test('Maps wrong-password and invalid-credential to safe UnauthorizedFailure', () {
        final ex1 = FirebaseAuthException(code: 'wrong-password');
        final f1 = ErrorHandler.handle(ex1);
        expect(f1, isA<UnauthorizedFailure>());
        expect(f1.message, 'Email or password is incorrect.');

        final ex2 = FirebaseAuthException(code: 'invalid-credential');
        final f2 = ErrorHandler.handle(ex2);
        expect(f2, isA<UnauthorizedFailure>());
        expect(f2.message, 'Email or password is incorrect.');
      });

      test('Maps user-disabled to system administrator notice', () {
        final ex = FirebaseAuthException(code: 'user-disabled');
        final f = ErrorHandler.handle(ex);
        expect(f, isA<UnauthorizedFailure>());
        expect(f.message, contains('disabled'));
      });

      test('Maps expired-action-code to verification code expired message', () {
        final ex = FirebaseAuthException(code: 'expired-action-code');
        final f = ErrorHandler.handle(ex);
        expect(f, isA<ValidationFailure>());
        expect(f.message, 'Your verification code has expired. Request a new code.');
      });

      test('Maps user-token-expired to session expired message', () {
        final ex = FirebaseAuthException(code: 'user-token-expired');
        final f = ErrorHandler.handle(ex);
        expect(f, isA<UnauthorizedFailure>());
        expect(f.message, 'Your session has expired. Please log in again.');
      });
    });

    group('3. Cloud Firestore & Storage Exception Mapping', () {
      test('Maps permission-denied to ForbiddenFailure', () {
        final ex = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
        final f = ErrorHandler.handle(ex);
        expect(f, isA<ForbiddenFailure>());
        expect(f.message, "You don't have permission to perform this action.");
      });

      test('Maps unavailable to NetworkFailure', () {
        final ex = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
        final f = ErrorHandler.handle(ex);
        expect(f, isA<NetworkFailure>());
        expect(f.message, "You're offline. Check your connection and try again.");
      });

      test('Maps not-found with product operation context to product unavailable message', () {
        final ex = FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
        final f = ErrorHandler.handle(ex, operation: 'product');
        expect(f, isA<NotFoundFailure>());
        expect(f.message, 'This product is no longer available.');
      });

      test('Maps retry-limit-exceeded with upload operation context to upload message', () {
        final ex = FirebaseException(plugin: 'firebase_storage', code: 'retry-limit-exceeded');
        final f = ErrorHandler.handle(ex, operation: 'upload');
        expect(f, isA<ServiceFailure>());
        expect(f.message, "We couldn't upload this image. Please try again.");
      });

      test('Maps deadline-exceeded with order operation to contextual order message', () {
        final ex = FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded');
        final f = ErrorHandler.handle(ex, operation: 'order');
        expect(f, isA<TimeoutFailure>());
        expect(f.message, "We couldn't confirm your order. Please check its status before trying again.");
      });
    });

    group('4. Dio & System Exception Mapping', () {
      test('Maps Dio connectionError to NetworkFailure', () {
        final dioEx = DioException(
          requestOptions: RequestOptions(path: '/api/v1/orders'),
          type: DioExceptionType.connectionError,
        );
        final f = ErrorHandler.handle(dioEx);
        expect(f, isA<NetworkFailure>());
      });

      test('Maps Dio badResponse 403 to ForbiddenFailure', () {
        final dioEx = DioException(
          requestOptions: RequestOptions(path: '/api/v1/admin'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/admin'),
            statusCode: 403,
          ),
        );
        final f = ErrorHandler.handle(dioEx);
        expect(f, isA<ForbiddenFailure>());
      });

      test('Maps SocketException to NetworkFailure', () {
        const sockEx = SocketException('Failed host lookup');
        final f = ErrorHandler.handle(sockEx);
        expect(f, isA<NetworkFailure>());
        expect(f.message, contains('offline'));
      });

      test('Maps FormatException to FormatFailure', () {
        const fmtEx = FormatException('Invalid JSON');
        final f = ErrorHandler.handle(fmtEx);
        expect(f, isA<FormatFailure>());
      });

      test('Maps TypeError to DataIntegrityFailure without crashing', () {
        try {
          dynamic val = 'not an int';
          int num = val as int;
          expect(num, isNotNull);
        } catch (e) {
          final f = ErrorHandler.handle(e);
          expect(f, isA<DataIntegrityFailure>());
        }
      });

      test('Maps unknown exception safely without leaking stack or raw internal strings', () {
        final rawError = Exception('CRITICAL_DATABASE_INTERNAL_CORRUPTION: Table users failed integrity check');
        final f = ErrorHandler.handle(rawError);
        expect(f, isA<UnknownFailure>());
        expect(f.message, 'Something went wrong. Please try again.');
        expect(f.message, isNot(contains('CRITICAL_DATABASE')));
      });
    });

    group('5. Retry and Timeout Policy Framework', () {
      test('Idempotent read retries transient network errors with bounded backoff', () async {
        int callCount = 0;

        final result = await executeWithRetry<String>(
          policy: const RetryPolicy(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 10),
            maxDelay: Duration(milliseconds: 50),
            isIdempotent: true,
          ),
          operation: () async {
            callCount++;
            if (callCount < 3) {
              return const Result.failure(NetworkFailure());
            }
            return const Result.success('Coffee beans fetched');
          },
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, 'Coffee beans fetched');
        expect(callCount, 3);
      });

      test('Never retries non-idempotent operations', () async {
        int callCount = 0;

        final result = await executeWithRetry<String>(
          policy: RetryPolicy.nonIdempotent,
          operation: () async {
            callCount++;
            return const Result.failure(NetworkFailure());
          },
        );

        expect(result.isFailure, isTrue);
        expect(callCount, 1);
      });

      test('Never retries validation failures or bad credentials even if policy is idempotent', () async {
        int callCount = 0;

        final result = await executeWithRetry<String>(
          policy: RetryPolicy.idempotentRead,
          operation: () async {
            callCount++;
            return const Result.failure(ValidationFailure(message: 'Invalid input'));
          },
        );

        expect(result.isFailure, isTrue);
        expect(callCount, 1);
      });

      test('Times out long operations and returns TimeoutFailure', () async {
        final result = await executeWithRetry<String>(
          policy: const RetryPolicy(maxAttempts: 1, isIdempotent: true),
          timeout: const Duration(milliseconds: 50),
          operation: () async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            return const Result.success('Finished');
          },
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<TimeoutFailure>());
      });
    });

    group('6. Concurrency & Duplicate Submission Prevention', () {
      test('OperationGate blocks concurrent overlapping submissions', () async {
        final gate = OperationGate();
        final completer = async.Completer<String>();

        // Launch first in-flight task
        final firstFuture = gate.run(() => completer.future);

        // Attempt second concurrent task while first is in-flight
        final secondResult = await gate.run(() async => 'concurrent call');

        expect(secondResult, isNull, reason: 'Duplicate simultaneous submission should be blocked');

        // Complete first task
        completer.complete('first call complete');
        final firstResult = await firstFuture;
        expect(firstResult, 'first call complete');

        // Subsequent call succeeds after previous completion
        final thirdResult = await gate.run(() async => 'third call');
        expect(thirdResult, 'third call');
      });
    });

    group('7. Secure Diagnostic Logging & PII Sanitization', () {
      test('Redacts bearer tokens, query passwords, and JSON secrets', () {
        const rawLog = 'Bearer ya29.a0AfH6SM... password=SecretPassword123 otp=987654 token=abc123xyz';
        final sanitized = OperationalMonitoringService.sanitizeText(rawLog);

        expect(sanitized, isNot(contains('ya29.a0AfH6SM')));
        expect(sanitized, isNot(contains('SecretPassword123')));
        expect(sanitized, isNot(contains('987654')));
        expect(sanitized, isNot(contains('abc123xyz')));
        expect(sanitized, contains('Bearer [REDACTED]'));
        expect(sanitized, contains('password=[REDACTED]'));
        expect(sanitized, contains('otp=[REDACTED]'));

        const authHeader = 'Authorization: Bearer mySecretToken';
        expect(OperationalMonitoringService.sanitizeText(authHeader), contains('Authorization: [REDACTED]'));
      });

      test('Redacts JSON credential fields', () {
        const jsonString = '{"user": "mateo", "password": "supersecretpassword", "otp": "123456"}';
        final sanitized = OperationalMonitoringService.sanitizeText(jsonString);

        expect(sanitized, isNot(contains('supersecretpassword')));
        expect(sanitized, isNot(contains('123456')));
        expect(sanitized, contains('"password": "[REDACTED]"'));
        expect(sanitized, contains('"otp": "[REDACTED]"'));
      });

      test('SecureErrorLogger records diagnostic failure without leaking to user', () {
        SecureErrorLogger.logFailure(
          domain: FailureDomain.checkout,
          operation: 'place_order',
          failure: const ServerFailure(message: 'Roastery service unavailable'),
          actorUid: 'usr_test_123',
          additionalMetadata: {'password': 'leaked_pwd', 'cart_count': 3},
        );

        final errors = OperationalMonitoringService().getRecentErrors(domain: FailureDomain.checkout);
        expect(errors, isNotEmpty);
        final record = errors.first;
        expect(record.metadata?['password'], '[REDACTED]');
        expect(record.metadata?['cart_count'], 3);
        expect(record.metadata?['operation'], 'place_order');
      });
    });
  });
}
