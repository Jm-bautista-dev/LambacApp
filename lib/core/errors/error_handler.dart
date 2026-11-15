import 'dart:async' as async;
import 'dart:io' show SocketException, HttpException;
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../monitoring/operational_monitoring_service.dart';
import '../monitoring/secure_error_logger.dart';
import 'app_exception.dart';
import 'app_failure.dart';

/// Centralized Production Error Handler for Lambac Coffee Roastery
/// Authoritatively converts technical exceptions (Firebase, Dio, I/O, System) into typed AppFailures
class ErrorHandler {
  ErrorHandler._();

  /// Primary entry point: Handles and converts any error into a typed AppFailure
  static AppFailure handle(
    Object error, {
    StackTrace? stackTrace,
    String? operation,
    FailureDomain? domain,
    String? actorUid,
    String? recordId,
  }) {
    final failure = handleException(error, stackTrace: stackTrace, operation: operation);

    if (domain != null && operation != null) {
      SecureErrorLogger.logFailure(
        domain: domain,
        operation: operation,
        failure: failure,
        rawError: error,
        stackTrace: stackTrace,
        actorUid: actorUid,
        recordId: recordId,
      );
    }

    return failure;
  }

  /// Converts any technical exception or error into a typed AppFailure
  static AppFailure handleException(
    Object error, {
    StackTrace? stackTrace,
    String? operation,
  }) {
    if (error is AppFailure) {
      return _applyContext(error, operation);
    }

    if (error is AppException) {
      final baseFailure = error.toFailure();
      return _applyContext(
        _withDiagnostic(baseFailure, error, stackTrace),
        operation,
      );
    }

    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthException(error, stackTrace, operation);
    }

    if (error is FirebaseException) {
      return _handleFirebaseException(error, stackTrace, operation);
    }

    if (error is DioException) {
      return _handleDioException(error, stackTrace, operation);
    }

    if (error is SocketException) {
      return NetworkFailure(
        message: "You're offline. Check your connection and try again.",
        originalException: error,
        stackTrace: stackTrace,
      );
    }

    if (error is HttpException) {
      return NetworkFailure(
        message: 'Network protocol error occurred. Please check your connection.',
        originalException: error,
        stackTrace: stackTrace,
      );
    }

    if (error is async.TimeoutException) {
      return TimeoutFailure(
        message: operation == 'checkout' || operation == 'order'
            ? "We couldn't confirm your order in time. Please check its status before trying again."
            : 'Request timed out. Please try again.',
        originalException: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return FormatFailure(
        message: 'Invalid data format received. Please try again.',
        originalException: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PlatformException) {
      return _handlePlatformException(error, stackTrace, operation);
    }

    if (error is TypeError) {
      return DataIntegrityFailure(
        message: 'Data inconsistency detected. Please refresh the page.',
        originalException: error,
        stackTrace: stackTrace,
      );
    }

    // Default safe unexpected error without leaking technical internal strings
    return UnknownFailure(
      message: 'Something went wrong. Please try again.',
      originalException: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps Firebase Auth Exception codes into typed failures with contextual messages
  static AppFailure _handleFirebaseAuthException(
    FirebaseAuthException e,
    StackTrace? stackTrace,
    String? operation,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return ValidationFailure(
          message: 'The email address is improperly formatted.',
          fieldErrors: const {'email': ['Please enter a valid email address.']},
          originalException: e,
          stackTrace: stackTrace,
          isRecoverable: true,
          canRetry: false,
        );

      case 'user-disabled':
        return UnauthorizedFailure(
          message: 'This account has been disabled. Please contact your system administrator.',
          originalException: e,
          stackTrace: stackTrace,
          isRecoverable: false, // User cannot recover disabled account by retrying
          canRetry: false,
        );

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        // Generic response protects against email enumeration while guiding manual correction
        return UnauthorizedFailure(
          message: 'Email or password is incorrect.',
          originalException: e,
          stackTrace: stackTrace,
          isRecoverable: true, // User can manually correct credentials and resubmit
          canRetry: false,     // Automatic resubmission of rejected credentials is prohibited
        );

      case 'email-already-in-use':
        return ValidationFailure(
          message: 'An account with this email already exists. Please sign in instead.',
          fieldErrors: const {'email': ['An account with this email already exists.']},
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'weak-password':
        return ValidationFailure(
          message: 'Password is too weak. Please use at least 8 characters with letters and numbers.',
          fieldErrors: const {'password': ['Password is too weak.']},
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'network-request-failed':
        return NetworkFailure(
          message: "You're offline. Check your connection and try again.",
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'too-many-requests':
        return RateLimitFailure(
          message: 'Too many login attempts. Please wait a moment before trying again.',
          retryAfter: const Duration(seconds: 45),
          originalException: e,
          stackTrace: stackTrace,
          isRecoverable: true,
          canRetry: false,
        );

      case 'requires-recent-login':
        return UnauthorizedFailure(
          message: 'For your security, please sign in again before performing this action.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'expired-action-code':
        return ValidationFailure(
          message: 'Your verification code has expired. Request a new code.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'invalid-action-code':
      case 'invalid-verification-code':
        return ValidationFailure(
          message: 'Invalid verification code. Please check your code and try again.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'operation-not-allowed':
        return ServerFailure(
          message: 'Email/password sign-in is currently unavailable. Please contact support.',
          originalException: e,
          stackTrace: stackTrace,
          isRecoverable: false,
          canRetry: false,
        );

      case 'missing-email':
      case 'missing-password':
      case 'channel-error':
        return ValidationFailure(
          message: 'Please enter both your email address and password.',
          originalException: e,
          stackTrace: stackTrace,
          isRecoverable: true,
          canRetry: false,
        );

      case 'user-token-expired':
      case 'id-token-expired':
      case 'id-token-revoked':
        return UnauthorizedFailure(
          message: 'Your session has expired. Please log in again.',
          originalException: e,
          stackTrace: stackTrace,
        );

      default:
        return UnauthorizedFailure(
          message: 'Authentication failed. Please verify your credentials.',
          originalException: e,
          stackTrace: stackTrace,
        );
    }
  }

  /// Maps Cloud Firestore & Firebase Core Exception codes
  static AppFailure _handleFirebaseException(
    FirebaseException e,
    StackTrace? stackTrace,
    String? operation,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return ForbiddenFailure(
          message: "You don't have permission to perform this action.",
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'unavailable':
      case 'network-request-failed':
        return NetworkFailure(
          message: "You're offline. Check your connection and try again.",
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'deadline-exceeded':
        return TimeoutFailure(
          message: operation == 'checkout' || operation == 'order'
              ? "We couldn't confirm your order. Please check its status before trying again."
              : 'Request timed out. Please try again.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'not-found':
      case 'object-not-found':
      case 'bucket-not-found':
        if (operation == 'product') {
          return NotFoundFailure(
            message: 'This product is no longer available.',
            originalException: e,
            stackTrace: stackTrace,
          );
        }
        return NotFoundFailure(
          message: 'The requested resource was not found.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'already-exists':
        return ConflictFailure(
          message: 'A conflict occurred. Record already exists.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'failed-precondition':
        if (operation == 'order' || operation == 'checkout') {
          return PreconditionFailure(
            message: 'Order cannot proceed under current inventory or store rules.',
            originalException: e,
            stackTrace: stackTrace,
          );
        }
        return PreconditionFailure(
          message: 'Operation cannot proceed under current system state.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'aborted':
        return ConflictFailure(
          message: 'The operation was interrupted by concurrent updates. Please try again.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'resource-exhausted':
      case 'quota-exceeded':
        return RateLimitFailure(
          message: 'Too many requests. Please wait a moment and try again.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'unauthenticated':
        return UnauthorizedFailure(
          message: 'Your session has expired. Please log in again.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'cancelled':
      case 'canceled':
        return CancelledFailure(
          message: 'The operation was cancelled.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'data-loss':
        return DataIntegrityFailure(
          message: 'Data corruption detected. Please refresh to load fresh data.',
          originalException: e,
          stackTrace: stackTrace,
        );

      case 'retry-limit-exceeded':
        return ServiceFailure(
          message: operation == 'upload'
              ? "We couldn't upload this image. Please try again."
              : 'Service temporarily unavailable. Please try again.',
          originalException: e,
          stackTrace: stackTrace,
        );

      default:
        return ServiceFailure(
          message: 'Roastery cloud services are momentarily unavailable. Please try again.',
          originalException: e,
          stackTrace: stackTrace,
        );
    }
  }

  /// Maps Dio HTTP Client Exceptions
  static AppFailure _handleDioException(
    DioException dioError,
    StackTrace? stackTrace,
    String? operation,
  ) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(
          message: operation == 'order' || operation == 'checkout'
              ? "We couldn't confirm your order. Please check its status before trying again."
              : 'Connection timed out. Please check your internet connection.',
          originalException: dioError,
          stackTrace: stackTrace,
        );

      case DioExceptionType.badResponse:
        final statusCode = dioError.response?.statusCode ?? 500;
        final data = dioError.response?.data;
        final rawMsg = _extractMessage(data);

        return switch (statusCode) {
          400 => BadRequestFailure(
              message: rawMsg ?? 'Bad request. Please verify your inputs.',
              originalException: dioError,
              stackTrace: stackTrace,
            ),
          401 => UnauthorizedFailure(
              message: rawMsg ?? 'Your session has expired. Please log in again.',
              originalException: dioError,
              stackTrace: stackTrace,
            ),
          403 => ForbiddenFailure(
              message: rawMsg ?? "You don't have permission to perform this action.",
              originalException: dioError,
              stackTrace: stackTrace,
            ),
          404 => NotFoundFailure(
              message: rawMsg ?? 'The requested item or resource could not be found.',
              originalException: dioError,
              stackTrace: stackTrace,
            ),
          409 => ConflictFailure(
              message: rawMsg ?? 'A conflict occurred. Record already exists.',
              originalException: dioError,
              stackTrace: stackTrace,
            ),
          412 => PreconditionFailure(
              message: rawMsg ?? 'Operation cannot proceed under current conditions.',
              originalException: dioError,
              stackTrace: stackTrace,
            ),
          422 => UnprocessableFailure(
              message: rawMsg ?? 'Unable to process request due to business rules.',
              originalException: dioError,
              stackTrace: stackTrace,
            ),
          429 => RateLimitFailure(
              message: rawMsg ?? 'Too many requests. Please wait a moment and try again.',
              originalException: dioError,
              stackTrace: stackTrace,
            ),
          _ => ServerFailure(
              message: rawMsg ?? 'Roastery service is momentarily unavailable. Please try again soon.',
              statusCode: statusCode,
              originalException: dioError,
              stackTrace: stackTrace,
            ),
        };

      case DioExceptionType.cancel:
        return CancelledFailure(
          message: 'The request was cancelled.',
          originalException: dioError,
          stackTrace: stackTrace,
        );

      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: "You're offline. Check your connection and try again.",
          originalException: dioError,
          stackTrace: stackTrace,
        );

      case DioExceptionType.badCertificate:
        return NetworkFailure(
          message: 'Secure connection certificate failed. Please check your network security.',
          originalException: dioError,
          stackTrace: stackTrace,
        );

      case DioExceptionType.unknown:
      default:
        return UnknownFailure(
          message: 'Something went wrong. Please try again.',
          originalException: dioError,
          stackTrace: stackTrace,
        );
    }
  }

  /// Maps PlatformException from native plugins
  static AppFailure _handlePlatformException(
    PlatformException e,
    StackTrace? stackTrace,
    String? operation,
  ) {
    if (e.code == 'network_error') {
      return NetworkFailure(
        message: "You're offline. Check your connection and try again.",
        originalException: e,
        stackTrace: stackTrace,
      );
    }
    return ServiceFailure(
      message: 'A device or service error occurred. Please try again.',
      originalException: e,
      stackTrace: stackTrace,
    );
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
      if (data['error'] != null && data['error'].toString().isNotEmpty) {
        return data['error'].toString();
      }
    }
    return null;
  }

  static AppFailure _withDiagnostic(AppFailure failure, Object error, StackTrace? stackTrace) {
    if (failure.originalException != null) return failure;
    return switch (failure) {
      NetworkFailure() => NetworkFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      ServerFailure() => ServerFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      ServiceFailure() => ServiceFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          serviceName: failure.serviceName,
          originalException: error,
          stackTrace: stackTrace,
        ),
      UnauthorizedFailure() => UnauthorizedFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      ForbiddenFailure() => ForbiddenFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      ValidationFailure() => ValidationFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          fieldErrors: failure.fieldErrors,
          originalException: error,
          stackTrace: stackTrace,
        ),
      NotFoundFailure() => NotFoundFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      ConflictFailure() => ConflictFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      PreconditionFailure() => PreconditionFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      RateLimitFailure() => RateLimitFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          retryAfter: failure.retryAfter,
          originalException: error,
          stackTrace: stackTrace,
        ),
      TimeoutFailure() => TimeoutFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      CacheFailure() => CacheFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      DataIntegrityFailure() => DataIntegrityFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      CancelledFailure() => CancelledFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
      _ => UnknownFailure(
          message: failure.message,
          statusCode: failure.statusCode,
          originalException: error,
          stackTrace: stackTrace,
        ),
    };
  }

  static AppFailure _applyContext(AppFailure failure, String? operation) {
    if (operation == null) return failure;
    return failure;
  }
}
