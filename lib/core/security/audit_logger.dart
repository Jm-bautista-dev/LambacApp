import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Type of security and operational events audited
enum AuditActionType {
  adminCreated,
  employeeCreated,
  accountDisabled,
  accountEnabled,
  passwordResetRequested,
  roleChanged,
  permissionsChanged,
  securityConfigChanged,
  productCreated,
  productUpdated,
  productPriceChanged,
  productAvailabilityChanged,
  orderStatusChanged,
  posSaleCompleted,
  posSaleVoided,
  inventoryAdjusted,
  systemFailure,
  loginSuccess,
  loginFailure,
  logout,
  firstLoginPasswordChanged;

  String toFormattedString() {
    return switch (this) {
      AuditActionType.adminCreated => 'Admin Created',
      AuditActionType.employeeCreated => 'Employee Created',
      AuditActionType.accountDisabled => 'Account Disabled',
      AuditActionType.accountEnabled => 'Account Enabled',
      AuditActionType.passwordResetRequested => 'Password Reset Requested',
      AuditActionType.roleChanged => 'Role Changed',
      AuditActionType.permissionsChanged => 'Permissions Changed',
      AuditActionType.securityConfigChanged => 'Security Config Changed',
      AuditActionType.productCreated => 'Product Created',
      AuditActionType.productUpdated => 'Product Updated',
      AuditActionType.productPriceChanged => 'Price Changed',
      AuditActionType.productAvailabilityChanged => 'Availability Changed',
      AuditActionType.orderStatusChanged => 'Order Status Changed',
      AuditActionType.posSaleCompleted => 'POS Sale Completed',
      AuditActionType.posSaleVoided => 'POS Sale Voided / Corrected',
      AuditActionType.inventoryAdjusted => 'Inventory Adjusted',
      AuditActionType.systemFailure => 'System Failure / Operational Error',
      AuditActionType.loginSuccess => 'Login Success',
      AuditActionType.loginFailure => 'Login Failure',
      AuditActionType.logout => 'Logout',
      AuditActionType.firstLoginPasswordChanged => 'First Login Password Set',
    };
  }
}

/// Immutable record of an audited security action
class AuditLogEntry extends Equatable {
  final String id;
  final DateTime timestamp;
  final AuditActionType action;
  final String actorEmail;
  final String actorRole;
  final String? actorUid;
  final String? entityId;
  final String? targetEmail;
  final String? targetRole;
  final bool isSuccess;
  final String? details;
  final Map<String, dynamic>? beforeState;
  final Map<String, dynamic>? afterState;

  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.actorEmail,
    required this.actorRole,
    this.actorUid,
    this.entityId,
    this.targetEmail,
    this.targetRole,
    this.isSuccess = true,
    this.details,
    this.beforeState,
    this.afterState,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action': action.name,
      'actor_email': actorEmail,
      'actor_role': actorRole,
      if (actorUid != null) 'actor_uid': actorUid,
      if (entityId != null) 'entity_id': entityId,
      if (targetEmail != null) 'target_email': targetEmail,
      if (targetRole != null) 'target_role': targetRole,
      'is_success': isSuccess,
      if (details != null) 'details': details,
      if (beforeState != null) 'before_state': beforeState,
      if (afterState != null) 'after_state': afterState,
    };
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: AuditActionType.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => AuditActionType.loginSuccess,
      ),
      actorEmail: json['actor_email'] as String,
      actorRole: json['actor_role'] as String,
      actorUid: json['actor_uid'] as String?,
      entityId: json['entity_id'] as String?,
      targetEmail: json['target_email'] as String?,
      targetRole: json['target_role'] as String?,
      isSuccess: json['is_success'] as bool? ?? true,
      details: json['details'] as String?,
      beforeState: json['before_state'] as Map<String, dynamic>?,
      afterState: json['after_state'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        action,
        actorEmail,
        actorRole,
        actorUid,
        entityId,
        targetEmail,
        targetRole,
        isSuccess,
        details,
        beforeState,
        afterState,
      ];
}

/// In-memory & Persistent Security Audit Logger
class AuditLogger {
  static final AuditLogger _instance = AuditLogger._internal();
  factory AuditLogger() => _instance;
  AuditLogger._internal();

  final List<AuditLogEntry> _logs = [];

  static const _sensitiveKeywords = [
    'password',
    'pwd',
    'token',
    'otp',
    'secret',
    'credential',
    'private_key',
    'privatekey',
    'cvv',
    'auth_token',
    'pin',
  ];

  /// Sanitizes state maps by stripping or redacting sensitive keys and values
  static Map<String, dynamic>? sanitizeState(Map<String, dynamic>? state) {
    if (state == null) return null;

    final sanitized = <String, dynamic>{};
    for (final entry in state.entries) {
      final keyLower = entry.key.toLowerCase();
      final isMetadataKey = keyLower.endsWith('_policy') ||
          keyLower.endsWith('_rules') ||
          keyLower.endsWith('_format') ||
          keyLower.endsWith('_version');

      final isSensitiveKey = !isMetadataKey &&
          _sensitiveKeywords.any((kw) =>
              keyLower == kw ||
              keyLower.endsWith('_$kw') ||
              keyLower.startsWith('${kw}_') ||
              (keyLower.contains(kw) && !keyLower.contains('policy')));

      if (isSensitiveKey) {
        sanitized[entry.key] = '[REDACTED]';
      } else if (entry.value is Map<String, dynamic>) {
        sanitized[entry.key] = sanitizeState(entry.value as Map<String, dynamic>);
      } else if (entry.value is String) {
        sanitized[entry.key] = sanitizeString(entry.value as String);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  /// Sanitizes detail strings from accidental credential leakage
  static String? sanitizeString(String? val) {
    if (val == null) return null;
    var result = val;
    // Redact Bearer tokens
    result = result.replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9_\-\.]+'), 'Bearer [REDACTED]');
    // Redact OTP patterns (e.g. "otp: 123456" or "OTP=123456")
    result = result.replaceAllMapped(
      RegExp(r'(otp|pin)[:=\s]+[0-9]{4,8}', caseSensitive: false),
      (m) => 'otp=[REDACTED]',
    );
    // Redact password patterns
    result = result.replaceAllMapped(
      RegExp(r'(password|pwd)[:=\s]+[^\s,]+', caseSensitive: false),
      (m) => 'password=[REDACTED]',
    );
    // Redact token parameters
    result = result.replaceAllMapped(
      RegExp(r'(token|secret|key)=([^\s,]+)', caseSensitive: false),
      (m) => '${m.group(1)}=[REDACTED]',
    );
    return result;
  }

  /// Records a new audit log entry. Strictly sanitizes state and detail fields.
  void log({
    required AuditActionType action,
    required String actorEmail,
    required String actorRole,
    String? actorUid,
    String? entityId,
    String? targetEmail,
    String? targetRole,
    bool isSuccess = true,
    String? details,
    Map<String, dynamic>? beforeState,
    Map<String, dynamic>? afterState,
  }) {
    final entry = AuditLogEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}_${_logs.length + 1}',
      timestamp: DateTime.now(),
      action: action,
      actorEmail: actorEmail,
      actorRole: actorRole,
      actorUid: actorUid,
      entityId: entityId,
      targetEmail: targetEmail,
      targetRole: targetRole,
      isSuccess: isSuccess,
      details: sanitizeString(details),
      beforeState: sanitizeState(beforeState),
      afterState: sanitizeState(afterState),
    );

    _logs.insert(0, entry); // Most recent first
    if (_logs.length > 500) {
      _logs.removeLast(); // Keep up to 500 entries in active memory buffer
    }
  }

  /// Returns filtered audit logs
  List<AuditLogEntry> getLogs({
    String? targetEmail,
    AuditActionType? action,
    String? entityId,
    int limit = 50,
  }) {
    Iterable<AuditLogEntry> filtered = _logs;

    if (targetEmail != null && targetEmail.isNotEmpty) {
      final normalized = targetEmail.toLowerCase();
      filtered = filtered.where(
        (entry) =>
            entry.targetEmail?.toLowerCase() == normalized ||
            entry.actorEmail.toLowerCase() == normalized,
      );
    }

    if (action != null) {
      filtered = filtered.where((entry) => entry.action == action);
    }

    if (entityId != null && entityId.isNotEmpty) {
      filtered = filtered.where((entry) => entry.entityId == entityId);
    }

    return filtered.take(limit).toList();
  }

  void clearForTest() {
    _logs.clear();
  }
}

/// Riverpod provider for AuditLogger
final auditLoggerProvider = Provider<AuditLogger>((ref) {
  return AuditLogger();
});
