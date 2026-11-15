import 'package:flutter/foundation.dart';
import '../errors/app_failure.dart';
import '../security/audit_logger.dart';
import 'operational_monitoring_service.dart';

/// Secure, PII-redacted Diagnostic Logger for Lambac Coffee Roastery
class SecureErrorLogger {
  SecureErrorLogger._();

  static final OperationalMonitoringService _monitoring = OperationalMonitoringService();
  static final AuditLogger _auditLogger = AuditLogger();

  /// Logs a structured operational failure with rigorous sanitization
  static void logFailure({
    required FailureDomain domain,
    required String operation,
    required AppFailure failure,
    Object? rawError,
    StackTrace? stackTrace,
    String? actorUid,
    String? recordId,
    Map<String, dynamic>? additionalMetadata,
  }) {
    final effectiveError = rawError ?? failure.originalException ?? failure;
    final effectiveTrace = stackTrace ?? failure.stackTrace;

    final metadata = <String, dynamic>{
      'operation': operation,
      'error_code': failure.errorCode ?? 'UNKNOWN',
      'status_code': failure.statusCode,
      'is_recoverable': failure.isRecoverable,
      'can_retry': failure.canRetry,
      if (actorUid != null) 'actor_uid': actorUid,
      if (recordId != null) 'record_id': recordId,
      if (additionalMetadata != null) ...additionalMetadata,
    };

    // Sanitize metadata to strip any accidental tokens, passwords, OTPs
    final sanitizedMeta = AuditLogger.sanitizeState(metadata);

    _monitoring.reportFailure(
      domain: domain,
      error: effectiveError,
      stackTrace: effectiveTrace,
      metadata: sanitizedMeta,
      isExpected: !failure.isRecoverable && failure is! ServerFailure && failure is! ServiceFailure,
      severity: _resolveSeverity(failure),
      type: _resolveFailureType(failure),
    );

    if (kDebugMode) {
      debugPrint(
        '⚠️ [LAMBAC_DIAGNOSTIC] [$domain::$operation] '
        'code=${failure.errorCode} recoverable=${failure.isRecoverable} '
        'canRetry=${failure.canRetry} msg="${failure.message}"',
      );
    }
  }

  /// Maps an AppFailure to appropriate FailureSeverity
  static FailureSeverity _resolveSeverity(AppFailure failure) {
    return switch (failure) {
      ServerFailure() || ServiceFailure() => FailureSeverity.error,
      DataIntegrityFailure() => FailureSeverity.error,
      UnknownFailure() => FailureSeverity.critical,
      RateLimitFailure() => FailureSeverity.warning,
      PreconditionFailure() || ConflictFailure() => FailureSeverity.warning,
      TimeoutFailure() || NetworkFailure() => FailureSeverity.warning,
      UnauthorizedFailure() || ForbiddenFailure() => FailureSeverity.warning,
      ValidationFailure() || CancelledFailure() => FailureSeverity.info,
      _ => FailureSeverity.warning,
    };
  }

  /// Maps an AppFailure to appropriate FailureType
  static FailureType _resolveFailureType(AppFailure failure) {
    return switch (failure) {
      ValidationFailure() || BadRequestFailure() || UnprocessableFailure() => FailureType.validationError,
      UnauthorizedFailure() || ForbiddenFailure() => FailureType.unauthorizedAccess,
      NetworkFailure() => FailureType.networkOffline,
      TimeoutFailure() => FailureType.serviceTimeout,
      RateLimitFailure() => FailureType.quotaExceeded,
      ServerFailure() || ServiceFailure() => FailureType.serverError,
      _ => FailureType.unexpectedCrash,
    };
  }
}
