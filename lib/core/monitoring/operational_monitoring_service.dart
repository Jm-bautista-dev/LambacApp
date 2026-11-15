import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_failure.dart';
import '../security/audit_logger.dart';

/// Operational failure domains across Lambac architecture
enum FailureDomain {
  authentication,
  firestoreAccess,
  upload,
  orderCreation,
  checkout,
  chat,
  notificationDelivery,
  applicationStartup,
  networkConnectivity,
}

/// Severity classification for operational events
enum FailureSeverity {
  info,
  warning,
  error,
  critical,
}

/// Categorized failure types distinguishing expected validations from system failures
enum FailureType {
  validationError,
  unauthorizedAccess,
  serviceTimeout,
  quotaExceeded,
  serverError,
  networkOffline,
  unexpectedCrash,
}

/// Immutable record of an operational failure or system exception
class OperationalErrorRecord extends Equatable {
  final String id;
  final DateTime timestamp;
  final FailureDomain domain;
  final FailureType type;
  final FailureSeverity severity;
  final String message;
  final String? stackTraceSanitized;
  final Map<String, dynamic>? metadata;
  final int repeatCount;
  final bool isExpected;

  const OperationalErrorRecord({
    required this.id,
    required this.timestamp,
    required this.domain,
    required this.type,
    required this.severity,
    required this.message,
    this.stackTraceSanitized,
    this.metadata,
    this.repeatCount = 1,
    this.isExpected = false,
  });

  OperationalErrorRecord copyWith({
    int? repeatCount,
    DateTime? timestamp,
  }) {
    return OperationalErrorRecord(
      id: id,
      timestamp: timestamp ?? this.timestamp,
      domain: domain,
      type: type,
      severity: severity,
      message: message,
      stackTraceSanitized: stackTraceSanitized,
      metadata: metadata,
      repeatCount: repeatCount ?? this.repeatCount,
      isExpected: isExpected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'domain': domain.name,
      'type': type.name,
      'severity': severity.name,
      'message': message,
      if (stackTraceSanitized != null) 'stack_trace': stackTraceSanitized,
      if (metadata != null) 'metadata': metadata,
      'repeat_count': repeatCount,
      'is_expected': isExpected,
    };
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        domain,
        type,
        severity,
        message,
        metadata,
        repeatCount,
        isExpected,
      ];
}

/// Operational Monitoring and Structured Crash Reporting Service
class OperationalMonitoringService {
  static final OperationalMonitoringService _instance = OperationalMonitoringService._internal();
  factory OperationalMonitoringService() => _instance;
  OperationalMonitoringService._internal();

  final List<OperationalErrorRecord> _errorBuffer = [];
  final Map<String, DateTime> _recentFingerprints = {};

  /// Threshold for firing operational alerts (e.g. > 5 critical errors in 5 minutes)
  static const int alertThresholdCount = 5;
  static const Duration alertWindow = Duration(minutes: 5);

  /// Callback hook invoked when alert threshold is exceeded
  void Function(String alertMessage, int criticalCount)? onOperationalAlert;

  /// Sanitizes text and stack traces, removing passwords, bearer tokens, and secrets
  static String sanitizeText(String text) {
    var cleaned = text;
    // Redact Bearer tokens
    cleaned = cleaned.replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9_\-\.]+'), 'Bearer [REDACTED]');
    // Redact query parameter patterns
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(key|token|password|pwd|secret|auth|otp|pin|cvv)=([^&\s]+)', caseSensitive: false),
      (m) => '${m.group(1)}=[REDACTED]',
    );
    // Redact JSON patterns
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'"(password|pwd|secret|token|otp|pin|cvv|auth_token|refresh_token)":\s*"[^"]*"', caseSensitive: false),
      (m) => '"${m.group(1)}": "[REDACTED]"',
    );
    // Redact Authorization headers
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(Authorization:)\s+[^\n\r]+', caseSensitive: false),
      (m) => '${m.group(1)} [REDACTED]',
    );
    return cleaned;
  }

  /// Reports a failure with automatic classification, deduplication, and sanitization
  OperationalErrorRecord reportFailure({
    required FailureDomain domain,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    bool? isExpected,
    FailureSeverity? severity,
    FailureType? type,
  }) {
    final rawMessage = error is AppFailure ? error.message : error.toString();
    final sanitizedMessage = sanitizeText(rawMessage);
    final sanitizedTrace = stackTrace != null ? sanitizeText(stackTrace.toString()) : null;
    final sanitizedMetadata = AuditLogger.sanitizeState(metadata);

    // 1. Determine failure type and expectedness
    final resolvedType = type ?? _classifyFailureType(error);
    final resolvedIsExpected = isExpected ?? _isExpectedFailure(error, resolvedType);
    final resolvedSeverity = severity ?? _classifySeverity(resolvedType, resolvedIsExpected);

    // 2. Generate deduplication fingerprint (prevents repeated logging of transient loops)
    final fingerprint = '${domain.name}_${error.runtimeType}_$sanitizedMessage';
    final now = DateTime.now();

    final lastSeen = _recentFingerprints[fingerprint];
    if (lastSeen != null && now.difference(lastSeen) < const Duration(seconds: 60)) {
      // Find matching record in buffer and increment repeatCount
      final existingIndex = _errorBuffer.indexWhere((e) =>
          e.domain == domain &&
          e.message == sanitizedMessage &&
          now.difference(e.timestamp) < const Duration(seconds: 60));

      if (existingIndex != -1) {
        final updated = _errorBuffer[existingIndex].copyWith(
          repeatCount: _errorBuffer[existingIndex].repeatCount + 1,
          timestamp: now,
        );
        _errorBuffer[existingIndex] = updated;
        _recentFingerprints[fingerprint] = now;
        return updated;
      }
    }

    _recentFingerprints[fingerprint] = now;

    // 3. Create fresh operational error record
    final record = OperationalErrorRecord(
      id: 'err_${now.millisecondsSinceEpoch}_${_errorBuffer.length + 1}',
      timestamp: now,
      domain: domain,
      type: resolvedType,
      severity: resolvedSeverity,
      message: sanitizedMessage,
      stackTraceSanitized: sanitizedTrace,
      metadata: sanitizedMetadata,
      repeatCount: 1,
      isExpected: resolvedIsExpected,
    );

    _errorBuffer.insert(0, record);
    if (_errorBuffer.length > 500) {
      _errorBuffer.removeLast();
    }

    // 4. Check for Alert Threshold on Unexpected Critical Errors
    if (!resolvedIsExpected && (resolvedSeverity == FailureSeverity.error || resolvedSeverity == FailureSeverity.critical)) {
      _checkAlertThreshold(now, domain);
    }

    return record;
  }

  void _checkAlertThreshold(DateTime now, FailureDomain domain) {
    final recentCritical = _errorBuffer.where((e) =>
        !e.isExpected &&
        (e.severity == FailureSeverity.error || e.severity == FailureSeverity.critical) &&
        now.difference(e.timestamp) <= alertWindow);

    final totalCount = recentCritical.fold<int>(0, (acc, e) => acc + e.repeatCount);
    if (totalCount >= alertThresholdCount) {
      final msg = 'OPERATIONAL ALERT: $totalCount unexpected failures detected in domain "${domain.name}" within 5 minutes.';
      onOperationalAlert?.call(msg, totalCount);
    }
  }

  FailureType _classifyFailureType(Object error) {
    if (error is BadRequestFailure || error is UnprocessableFailure || error is FormatFailure) {
      return FailureType.validationError;
    }
    if (error is UnauthorizedFailure || error is ForbiddenFailure) {
      return FailureType.unauthorizedAccess;
    }
    if (error is TimeoutFailure) {
      return FailureType.serviceTimeout;
    }
    if (error is RateLimitFailure) {
      return FailureType.quotaExceeded;
    }
    if (error is NetworkFailure) {
      return FailureType.networkOffline;
    }
    if (error is ServerFailure) {
      return FailureType.serverError;
    }
    return FailureType.unexpectedCrash;
  }

  bool _isExpectedFailure(Object error, FailureType type) {
    return switch (type) {
      FailureType.validationError => true,
      FailureType.unauthorizedAccess => true,
      FailureType.networkOffline => true,
      FailureType.serviceTimeout => false,
      FailureType.quotaExceeded => false,
      FailureType.serverError => false,
      FailureType.unexpectedCrash => false,
    };
  }

  FailureSeverity _classifySeverity(FailureType type, bool isExpected) {
    if (isExpected) {
      return FailureSeverity.warning;
    }
    return switch (type) {
      FailureType.unexpectedCrash => FailureSeverity.critical,
      FailureType.serverError => FailureSeverity.error,
      FailureType.quotaExceeded => FailureSeverity.error,
      FailureType.serviceTimeout => FailureSeverity.warning,
      _ => FailureSeverity.info,
    };
  }

  /// Returns recent operational error logs with optional filtering
  List<OperationalErrorRecord> getRecentErrors({
    FailureDomain? domain,
    FailureSeverity? minSeverity,
    bool? expectedOnly,
    int limit = 50,
  }) {
    Iterable<OperationalErrorRecord> filtered = _errorBuffer;

    if (domain != null) {
      filtered = filtered.where((e) => e.domain == domain);
    }

    if (expectedOnly != null) {
      filtered = filtered.where((e) => e.isExpected == expectedOnly);
    }

    if (minSeverity != null) {
      filtered = filtered.where((e) => e.severity.index >= minSeverity.index);
    }

    return filtered.take(limit).toList();
  }

  void clearForTest() {
    _errorBuffer.clear();
    _recentFingerprints.clear();
  }
}

/// Riverpod Provider for OperationalMonitoringService
final operationalMonitoringServiceProvider = Provider<OperationalMonitoringService>((ref) {
  return OperationalMonitoringService();
});
