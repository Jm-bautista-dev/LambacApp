import 'package:equatable/equatable.dart';

/// Sealed Base Failure Class for standardizing all user-facing domain errors
sealed class AppFailure extends Equatable {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Object? originalException;
  final StackTrace? stackTrace;
  final bool? _isRecoverable;
  final bool? _canRetry;

  const AppFailure({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.originalException,
    this.stackTrace,
    bool? isRecoverable,
    bool? canRetry,
  })  : _isRecoverable = isRecoverable,
        _canRetry = canRetry;

  const factory AppFailure.unexpected({
    required String message,
    Object? originalException,
    StackTrace? stackTrace,
  }) = UnknownFailure;

  /// User-friendly message suitable for presentation in toasts, dialogs, and banners
  String get userFriendlyMessage => message;

  /// Indicates whether this failure is recoverable (e.g. user action or reconnecting can resolve it)
  bool get isRecoverable => _isRecoverable ?? defaultIsRecoverable;

  /// Indicates whether an automatic or manual retry of the operation is appropriate
  bool get canRetry => _canRetry ?? defaultCanRetry;

  /// Default recovery classification based on failure category
  bool get defaultIsRecoverable => switch (this) {
        NetworkFailure() => true,
        TimeoutFailure() => true,
        RateLimitFailure() => true,
        ValidationFailure() => true,
        UnauthorizedFailure() => true,
        ConflictFailure() => true,
        PreconditionFailure() => true,
        ServerFailure() => true,
        ServiceFailure() => true,
        CacheFailure() => true,
        NotFoundFailure() => false,
        ForbiddenFailure() => false,
        DataIntegrityFailure() => false,
        FormatFailure() => false,
        CancelledFailure() => false,
        UnknownFailure() => false,
        _ => false,
      };

  /// Default retry classification — ONLY safe transient errors can be retried automatically
  bool get defaultCanRetry => switch (this) {
        NetworkFailure() => true,
        TimeoutFailure() => true,
        ServerFailure() => true,
        ServiceFailure() => true,
        RateLimitFailure() => false, // Requires waiting cooldown
        ValidationFailure() => false, // Resending same invalid input will fail
        UnauthorizedFailure() => false, // Requires user credentials
        ForbiddenFailure() => false, // Lacks authorization
        ConflictFailure() => false, // Requires state refresh
        PreconditionFailure() => false,
        NotFoundFailure() => false,
        DataIntegrityFailure() => false,
        FormatFailure() => false,
        CacheFailure() => true,
        CancelledFailure() => false,
        UnknownFailure() => false,
        _ => false,
      };

  @override
  List<Object?> get props => [message, statusCode, errorCode];

  @override
  String toString() => '$runtimeType(message: $message, code: $errorCode, status: $statusCode)';
}

/// 1. Network Failure (Offline / Connection Reset / No Route to Host)
final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = "You're offline. Check your connection and try again.",
    super.statusCode,
    super.errorCode = 'NETWORK_ERROR',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 2. Server Failure (500, 502, 503, 504 / Roastery Backend Outage)
final class ServerFailure extends AppFailure {
  const ServerFailure({
    super.message = 'Roastery service is momentarily unavailable. Please try again soon.',
    super.statusCode = 500,
    super.errorCode = 'SERVER_ERROR',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 3. Service Failure (Firebase, Email Relay, Storage, or Third-Party Integration Outage)
final class ServiceFailure extends AppFailure {
  final String? serviceName;

  const ServiceFailure({
    super.message = 'Service temporarily unavailable. Please try again.',
    super.statusCode = 503,
    super.errorCode = 'SERVICE_ERROR',
    this.serviceName,
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });

  @override
  List<Object?> get props => [message, statusCode, errorCode, serviceName];
}

/// 4. Unauthorized Failure / Authentication Error (401 / Bad Credentials / Session Expired)
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({
    super.message = 'Your session has expired. Please log in again.',
    super.statusCode = 401,
    super.errorCode = 'UNAUTHORIZED',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 5. Forbidden Access Failure / Authorization Error (403 / Insufficient Permissions)
final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({
    super.message = "You don't have permission to perform this action.",
    super.statusCode = 403,
    super.errorCode = 'FORBIDDEN',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 6. Bad Request Failure (400)
final class BadRequestFailure extends AppFailure {
  const BadRequestFailure({
    super.message = 'Bad request. Please check input parameters.',
    super.statusCode = 400,
    super.errorCode = 'BAD_REQUEST',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 7. Conflict Failure (409 / Duplicate Record / Stale Data / Invalid State Transition)
final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    super.message = 'A conflict occurred. Record already exists or data is stale.',
    super.statusCode = 409,
    super.errorCode = 'CONFLICT',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 8. Failed Precondition (412 / Operation cannot proceed under current business rules)
final class PreconditionFailure extends AppFailure {
  const PreconditionFailure({
    super.message = 'Operation cannot proceed under current business rules.',
    super.statusCode = 412,
    super.errorCode = 'PRECONDITION_FAILED',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 9. Unprocessable Entity Failure (422 / Business Validation Rules)
final class UnprocessableFailure extends AppFailure {
  const UnprocessableFailure({
    super.message = 'Unable to process request due to business rule validation.',
    super.statusCode = 422,
    super.errorCode = 'UNPROCESSABLE',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 10. Rate Limit Exceeded Failure (429 / Too Many Attempts)
final class RateLimitFailure extends AppFailure {
  final Duration? retryAfter;

  const RateLimitFailure({
    super.message = 'Too many requests. Please wait a moment and try again.',
    super.statusCode = 429,
    super.errorCode = 'RATE_LIMIT_EXCEEDED',
    this.retryAfter,
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });

  @override
  List<Object?> get props => [message, statusCode, errorCode, retryAfter];
}

/// 11. Format Failure (Invalid data format received from server)
final class FormatFailure extends AppFailure {
  const FormatFailure({
    super.message = 'Invalid data format received from server.',
    super.statusCode,
    super.errorCode = 'FORMAT_ERROR',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 12. Data Integrity Failure (Malformed, Incomplete, or Inconsistent Records)
final class DataIntegrityFailure extends AppFailure {
  const DataIntegrityFailure({
    super.message = 'Data integrity issue detected. The record is incomplete or corrupted.',
    super.statusCode,
    super.errorCode = 'DATA_INTEGRITY_ERROR',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 13. Not Found Failure (404)
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.message = 'The requested item or page could not be found.',
    super.statusCode = 404,
    super.errorCode = 'NOT_FOUND',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 14. Input Validation Failure (400, 422 with Field-Level Errors)
final class ValidationFailure extends AppFailure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    super.message = 'Please check the information provided and try again.',
    super.statusCode = 422,
    super.errorCode = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });

  /// Extracts the first error message for a given field key
  String? firstErrorFor(String fieldKey) {
    if (fieldErrors == null) return null;
    final errors = fieldErrors![fieldKey];
    if (errors != null && errors.isNotEmpty) {
      return errors.first;
    }
    return null;
  }

  @override
  List<Object?> get props => [message, statusCode, errorCode, fieldErrors];
}

/// 15. Timeout Failure (408)
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({
    super.message = 'Request timed out. Please try again.',
    super.statusCode = 408,
    super.errorCode = 'TIMEOUT',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 16. Cache / Local Storage Failure
final class CacheFailure extends AppFailure {
  const CacheFailure({
    super.message = 'Could not access local storage or cached data.',
    super.statusCode,
    super.errorCode = 'CACHE_ERROR',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 17. Cancelled Operation Failure
final class CancelledFailure extends AppFailure {
  const CancelledFailure({
    super.message = 'The operation was cancelled.',
    super.statusCode,
    super.errorCode = 'CANCELLED',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}

/// 18. Unknown / Unexpected Failure
final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'Something went wrong. Please try again.',
    super.statusCode,
    super.errorCode = 'UNKNOWN_ERROR',
    super.originalException,
    super.stackTrace,
    super.isRecoverable,
    super.canRetry,
  });
}
