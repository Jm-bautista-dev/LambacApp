import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/errors/error_handler.dart';
import 'package:lambac_app/core/network/result.dart';
import 'package:lambac_app/features/auth/data/models/auth_response_model.dart';
import 'package:lambac_app/features/auth/data/models/login_request.dart';
import 'package:lambac_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepositoryImpl implements AuthRepository {
  int loginCallCount = 0;
  Completer<Result<AuthResponseModel, AppFailure>>? loginCompleter;

  @override
  Future<Result<AuthResponseModel, AppFailure>> login(LoginRequest request) async {
    loginCallCount++;
    if (loginCompleter != null) {
      return loginCompleter!.future;
    }
    return const Result.failure(
      UnauthorizedFailure(message: 'Email or password is incorrect.'),
    );
  }

  @override
  Future<Result<AuthResponseModel?, AppFailure>> restoreSession() async {
    return const Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PRODUCTION FIX 01 — FirebaseAuthException Error Classification & Recovery', () {
    test('invalid-credential maps to UnauthorizedFailure with non-enumerating message and canRetry=false', () {
      final exception = FirebaseAuthException(code: 'invalid-credential');
      final failure = ErrorHandler.handle(exception);

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, 'Email or password is incorrect.');
      expect(failure.isRecoverable, isTrue, reason: 'User can manually correct credentials');
      expect(failure.canRetry, isFalse, reason: 'Automatic retry of invalid credentials is prohibited');
    });

    test('invalid-login-credentials maps to UnauthorizedFailure with non-enumerating message', () {
      final exception = FirebaseAuthException(code: 'invalid-login-credentials');
      final failure = ErrorHandler.handle(exception);

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, 'Email or password is incorrect.');
      expect(failure.isRecoverable, isTrue);
      expect(failure.canRetry, isFalse);
    });

    test('wrong-password maps to UnauthorizedFailure with identical non-enumerating message', () {
      final exception = FirebaseAuthException(code: 'wrong-password');
      final failure = ErrorHandler.handle(exception);

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, 'Email or password is incorrect.');
      expect(failure.isRecoverable, isTrue);
      expect(failure.canRetry, isFalse);
    });

    test('user-not-found maps to UnauthorizedFailure without leaking email non-existence', () {
      final exception = FirebaseAuthException(code: 'user-not-found');
      final failure = ErrorHandler.handle(exception);

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, 'Email or password is incorrect.');
      expect(failure.isRecoverable, isTrue);
      expect(failure.canRetry, isFalse);
    });

    test('invalid-email maps to ValidationFailure with recoverable=true and canRetry=false', () {
      final exception = FirebaseAuthException(code: 'invalid-email');
      final failure = ErrorHandler.handle(exception);

      expect(failure, isA<ValidationFailure>());
      expect(failure.isRecoverable, isTrue, reason: 'User can correct formatting');
      expect(failure.canRetry, isFalse, reason: 'Resubmitting malformed email will fail');
    });

    test('user-disabled maps to UnauthorizedFailure with isRecoverable=false and canRetry=false', () {
      final exception = FirebaseAuthException(code: 'user-disabled');
      final failure = ErrorHandler.handle(exception);

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, contains('disabled'));
      expect(failure.isRecoverable, isFalse, reason: 'User cannot resolve a disabled account on their own');
      expect(failure.canRetry, isFalse, reason: 'Retrying credentials against a disabled account is futile');
    });

    test('too-many-requests maps to RateLimitFailure with isRecoverable=true and canRetry=false', () {
      final exception = FirebaseAuthException(code: 'too-many-requests');
      final failure = ErrorHandler.handle(exception);

      expect(failure, isA<RateLimitFailure>());
      expect(failure.isRecoverable, isTrue, reason: 'Can be resolved after waiting cooldown');
      expect(failure.canRetry, isFalse, reason: 'Immediate retry is blocked by rate limiting');
      expect((failure as RateLimitFailure).retryAfter, isNotNull);
    });

    test('network-request-failed maps to NetworkFailure with isRecoverable=true and canRetry=true', () {
      final exception = FirebaseAuthException(code: 'network-request-failed');
      final failure = ErrorHandler.handle(exception);

      expect(failure, isA<NetworkFailure>());
      expect(failure.isRecoverable, isTrue);
      expect(failure.canRetry, isTrue, reason: 'Network errors can be safely retried once connection resumes');
    });
  });

  group('PRODUCTION FIX 01 — Concurrency Lock & Duplicate Request Prevention', () {
    test('AuthNotifier deduplicates concurrent login calls and avoids duplicate requests', () async {
      final mockRepo = MockAuthRepositoryImpl();
      mockRepo.loginCompleter = Completer<Result<AuthResponseModel, AppFailure>>();

      final notifier = AuthNotifier(repository: mockRepo);

      // Fire two concurrent login attempts simultaneously
      final future1 = notifier.login(email: 'test@example.com', password: 'password123');
      final future2 = notifier.login(email: 'test@example.com', password: 'password123');

      // Verify repository was only called ONCE
      expect(mockRepo.loginCallCount, 1);

      // Complete the pending request
      mockRepo.loginCompleter!.complete(
        const Result.failure(UnauthorizedFailure(message: 'Email or password is incorrect.')),
      );

      final res1 = await future1;
      final res2 = await future2;

      expect(res1.isFailure, isTrue);
      expect(res2.isFailure, isTrue);
      expect(mockRepo.loginCallCount, 1, reason: 'Duplicate concurrent request was prevented');
    });
  });
}
