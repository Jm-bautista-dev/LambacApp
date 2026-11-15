import 'app_failure.dart';

/// Base Exception class for all application errors
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException({
    required this.message,
    this.statusCode,
    this.details,
  });

  /// Converts this technical exception into an AppFailure
  AppFailure toFailure() => UnknownFailure(message: message, statusCode: statusCode);

  @override
  String toString() => '$runtimeType(message: $message, statusCode: $statusCode)';
}

/// Network Connectivity Exception
class NetworkException extends AppException {
  const NetworkException({
    super.message = "You're offline. Check your connection and try again.",
    super.statusCode,
    super.details,
  });

  @override
  AppFailure toFailure() => NetworkFailure(message: message, statusCode: statusCode);
}

/// HTTP Server Error Exception (5xx)
class ServerException extends AppException {
  const ServerException({
    super.message = 'Roastery service is momentarily unavailable. Please try again soon.',
    super.statusCode = 500,
    super.details,
  });

  @override
  AppFailure toFailure() => ServerFailure(message: message, statusCode: statusCode);
}

/// Service Outage Exception (Firebase, Storage, Email relay)
class ServiceException extends AppException {
  final String? serviceName;

  const ServiceException({
    super.message = 'Service temporarily unavailable. Please try again.',
    super.statusCode = 503,
    this.serviceName,
    super.details,
  });

  @override
  AppFailure toFailure() => ServiceFailure(message: message, statusCode: statusCode, serviceName: serviceName);
}

/// Unauthorized / Session Expired Exception (401)
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Your session has expired. Please log in again.',
    super.statusCode = 401,
    super.details,
  });

  @override
  AppFailure toFailure() => UnauthorizedFailure(message: message, statusCode: statusCode);
}

/// Forbidden Access Exception (403)
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = "You don't have permission to perform this action.",
    super.statusCode = 403,
    super.details,
  });

  @override
  AppFailure toFailure() => ForbiddenFailure(message: message, statusCode: statusCode);
}

/// Resource Not Found Exception (404)
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
    super.details,
  });

  @override
  AppFailure toFailure() => NotFoundFailure(message: message, statusCode: statusCode);
}

/// Conflict / Stale Data Exception (409)
class ConflictException extends AppException {
  const ConflictException({
    super.message = 'A conflict occurred. Record already exists or data is stale.',
    super.statusCode = 409,
    super.details,
  });

  @override
  AppFailure toFailure() => ConflictFailure(message: message, statusCode: statusCode);
}

/// Failed Precondition Exception (412)
class PreconditionException extends AppException {
  const PreconditionException({
    super.message = 'Operation cannot proceed under current business rules.',
    super.statusCode = 412,
    super.details,
  });

  @override
  AppFailure toFailure() => PreconditionFailure(message: message, statusCode: statusCode);
}

/// Input Validation Exception (400, 422)
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    super.message = 'Invalid request data. Please check your inputs.',
    super.statusCode = 422,
    this.fieldErrors,
    super.details,
  });

  @override
  AppFailure toFailure() => ValidationFailure(
        message: message,
        statusCode: statusCode,
        fieldErrors: fieldErrors,
      );
}

/// Rate Limit Exceeded Exception (429)
class RateLimitException extends AppException {
  final Duration? retryAfter;

  const RateLimitException({
    super.message = 'Too many requests. Please wait a moment and try again.',
    super.statusCode = 429,
    this.retryAfter,
    super.details,
  });

  @override
  AppFailure toFailure() => RateLimitFailure(
        message: message,
        statusCode: statusCode,
        retryAfter: retryAfter,
      );
}

/// Request Timeout Exception (408)
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out. Please try again.',
    super.statusCode = 408,
    super.details,
  });

  @override
  AppFailure toFailure() => TimeoutFailure(message: message, statusCode: statusCode);
}

/// Local Cache / Storage Exception
class CacheException extends AppException {
  const CacheException({
    super.message = 'Failed to access local storage.',
    super.statusCode,
    super.details,
  });

  @override
  AppFailure toFailure() => CacheFailure(message: message, statusCode: statusCode);
}

/// Data Integrity Exception
class DataIntegrityException extends AppException {
  const DataIntegrityException({
    super.message = 'Data integrity issue detected.',
    super.statusCode,
    super.details,
  });

  @override
  AppFailure toFailure() => DataIntegrityFailure(message: message, statusCode: statusCode);
}

/// Cancelled Operation Exception
class CancelledException extends AppException {
  const CancelledException({
    super.message = 'Operation was cancelled.',
    super.statusCode,
    super.details,
  });

  @override
  AppFailure toFailure() => CancelledFailure(message: message, statusCode: statusCode);
}

/// Unknown / Unexpected Exception
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred. Please try again.',
    super.statusCode,
    super.details,
  });

  @override
  AppFailure toFailure() => UnknownFailure(message: message, statusCode: statusCode);
}
