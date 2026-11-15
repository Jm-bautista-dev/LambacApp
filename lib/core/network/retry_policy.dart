import 'dart:async';
import 'dart:math';
import '../errors/app_failure.dart';
import '../errors/error_handler.dart';
import 'result.dart';

/// Configuration for Bounded Exponential Backoff with Jitter
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final double jitterFactor;
  final bool isIdempotent;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 4),
    this.backoffMultiplier = 2.0,
    this.jitterFactor = 0.2,
    this.isIdempotent = true,
  });

  /// Read-only idempotent query policy (up to 3 attempts with exponential backoff)
  static const RetryPolicy idempotentRead = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 400),
    maxDelay: Duration(seconds: 3),
    isIdempotent: true,
  );

  /// Safe mutation policy with explicit idempotency guarantee
  static const RetryPolicy idempotentMutation = RetryPolicy(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 1000),
    maxDelay: Duration(seconds: 4),
    isIdempotent: true,
  );

  /// Non-idempotent policy: NEVER retries automatically
  static const RetryPolicy nonIdempotent = RetryPolicy(
    maxAttempts: 1,
    isIdempotent: false,
  );

  /// Computes backoff duration with random jitter
  Duration computeDelay(int attempt) {
    if (attempt <= 0) return Duration.zero;

    final exponentialMillis = initialDelay.inMilliseconds * pow(backoffMultiplier, attempt - 1);
    final boundedMillis = min(exponentialMillis.toDouble(), maxDelay.inMilliseconds.toDouble());

    // Apply jitter: +/- (jitterFactor * boundedMillis)
    final random = Random();
    final jitterDelta = boundedMillis * jitterFactor * (random.nextDouble() * 2 - 1);
    final finalMillis = max(100.0, boundedMillis + jitterDelta).toInt();

    return Duration(milliseconds: finalMillis);
  }

  /// Evaluates whether an AppFailure may be safely retried under this policy
  bool shouldRetry(AppFailure failure, int attempt) {
    if (attempt >= maxAttempts) return false;
    if (!isIdempotent) return false;

    // Strict guardrails: NEVER auto-retry these categories under any circumstances
    if (failure is ValidationFailure) return false;
    if (failure is UnauthorizedFailure) return false;
    if (failure is ForbiddenFailure) return false;
    if (failure is CancelledFailure) return false;
    if (failure is PreconditionFailure) return false;

    return failure.canRetry;
  }
}

/// Executes an asynchronous operation wrapped with timeout and bounded exponential backoff
Future<Result<T, AppFailure>> executeWithRetry<T>({
  required Future<Result<T, AppFailure>> Function() operation,
  RetryPolicy policy = RetryPolicy.idempotentRead,
  Duration timeout = const Duration(seconds: 15),
  String? operationName,
  void Function(int attempt, Duration delay, AppFailure failure)? onRetry,
}) async {
  int attempt = 1;

  while (true) {
    try {
      final result = await operation().timeout(
        timeout,
        onTimeout: () => Result.failure(
          TimeoutFailure(
            message: operationName != null
                ? "The operation '$operationName' timed out. Please try again."
                : 'The request took too long to complete. Please try again.',
          ),
        ),
      );

      if (result.isSuccess) {
        return result;
      }

      final failure = result.failureOrNull!;
      if (!policy.shouldRetry(failure, attempt)) {
        return result;
      }

      final delay = policy.computeDelay(attempt);
      onRetry?.call(attempt, delay, failure);
      await Future<void>.delayed(delay);
      attempt++;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        operation: operationName,
      );

      if (!policy.shouldRetry(failure, attempt)) {
        return Result.failure(failure);
      }

      final delay = policy.computeDelay(attempt);
      onRetry?.call(attempt, delay, failure);
      await Future<void>.delayed(delay);
      attempt++;
    }
  }
}
