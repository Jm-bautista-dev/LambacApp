import 'package:equatable/equatable.dart';
import 'prescriptive_recommendation_model.dart';

/// Operational action types generated from Prescriptive recommendations
enum PrescriptiveActionType {
  roastBatch,
  restockRawBeans,
  menuPromotion,
  operationalWorkflow,
  informational;

  String get displayName => switch (this) {
        PrescriptiveActionType.roastBatch => 'Roast Batch',
        PrescriptiveActionType.restockRawBeans => 'Restock Raw Beans',
        PrescriptiveActionType.menuPromotion => 'Menu Promotion',
        PrescriptiveActionType.operationalWorkflow => 'Operational Workflow',
        PrescriptiveActionType.informational => 'Informational Notice',
      };
}

/// Execution classification dictating the scheduling or queue behavior
enum ActionClassification {
  scheduled,
  queue,
  immediate,
  informational;

  String get displayName => switch (this) {
        ActionClassification.scheduled => 'Scheduled Event',
        ActionClassification.queue => 'Action Queue',
        ActionClassification.immediate => 'Immediate Execution',
        ActionClassification.informational => 'Informational',
      };
}

/// Full operational lifecycle of a prescriptive business action
enum PrescriptiveActionStatus {
  recommended,
  pendingAction,
  scheduled,
  queued,
  inProgress,
  completed,
  cancelled,
  skipped,
  failed;

  String get displayName => switch (this) {
        PrescriptiveActionStatus.recommended => 'Recommended',
        PrescriptiveActionStatus.pendingAction => 'Pending Action',
        PrescriptiveActionStatus.scheduled => 'Scheduled',
        PrescriptiveActionStatus.queued => 'Queued',
        PrescriptiveActionStatus.inProgress => 'In Progress',
        PrescriptiveActionStatus.completed => 'Completed',
        PrescriptiveActionStatus.cancelled => 'Cancelled',
        PrescriptiveActionStatus.skipped => 'Skipped',
        PrescriptiveActionStatus.failed => 'Failed',
      };

  bool get isTerminal =>
      this == PrescriptiveActionStatus.completed ||
      this == PrescriptiveActionStatus.cancelled ||
      this == PrescriptiveActionStatus.skipped ||
      this == PrescriptiveActionStatus.failed;

  bool get isActive =>
      this == PrescriptiveActionStatus.scheduled ||
      this == PrescriptiveActionStatus.queued ||
      this == PrescriptiveActionStatus.inProgress;
}

/// Immutable audit record tracking operational status transitions
class ActionAuditLogModel extends Equatable {
  final String id;
  final PrescriptiveActionStatus? fromStatus;
  final PrescriptiveActionStatus toStatus;
  final String changedBy;
  final DateTime timestamp;
  final String? note;

  const ActionAuditLogModel({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    required this.changedBy,
    required this.timestamp,
    this.note,
  });

  factory ActionAuditLogModel.fromJson(Map<String, dynamic> json) {
    PrescriptiveActionStatus? parseStatus(dynamic val) {
      if (val == null) return null;
      final str = val.toString().toLowerCase();
      return PrescriptiveActionStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == str,
        orElse: () => PrescriptiveActionStatus.scheduled,
      );
    }

    return ActionAuditLogModel(
      id: json['id']?.toString() ?? '',
      fromStatus: parseStatus(json['from_status']),
      toStatus: parseStatus(json['to_status']) ?? PrescriptiveActionStatus.scheduled,
      changedBy: json['changed_by']?.toString() ?? 'System',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (fromStatus != null) 'from_status': fromStatus!.name,
        'to_status': toStatus.name,
        'changed_by': changedBy,
        'timestamp': timestamp.toIso8601String(),
        if (note != null) 'note': note,
      };

  @override
  List<Object?> get props => [id, fromStatus, toStatus, changedBy, timestamp, note];
}

/// Persistent, Enterprise Prescriptive Action Record
class PrescriptiveActionModel extends Equatable {
  final String id;
  final String recommendationId;
  final PrescriptiveActionType actionType;
  final ActionClassification classification;
  final PrescriptiveActionStatus status;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String? targetProductId;
  final String? targetProductName;
  final int targetQuantity;
  final String targetUnit;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String createdBy;
  final String? assignedTo;
  final String? notes;
  final String supportingMetric;
  final String evidenceRationale;
  final List<ActionAuditLogModel> auditLogs;

  const PrescriptiveActionModel({
    required this.id,
    required this.recommendationId,
    required this.actionType,
    required this.classification,
    required this.status,
    required this.priority,
    required this.title,
    required this.description,
    this.targetProductId,
    this.targetProductName,
    required this.targetQuantity,
    this.targetUnit = 'units',
    this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.createdBy = 'Admin',
    this.assignedTo,
    this.notes,
    required this.supportingMetric,
    required this.evidenceRationale,
    this.auditLogs = const [],
  });

  PrescriptiveActionModel copyWith({
    String? id,
    String? recommendationId,
    PrescriptiveActionType? actionType,
    ActionClassification? classification,
    PrescriptiveActionStatus? status,
    RecommendationPriority? priority,
    String? title,
    String? description,
    String? targetProductId,
    String? targetProductName,
    int? targetQuantity,
    String? targetUnit,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? createdBy,
    String? assignedTo,
    String? notes,
    String? supportingMetric,
    String? evidenceRationale,
    List<ActionAuditLogModel>? auditLogs,
  }) {
    return PrescriptiveActionModel(
      id: id ?? this.id,
      recommendationId: recommendationId ?? this.recommendationId,
      actionType: actionType ?? this.actionType,
      classification: classification ?? this.classification,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      targetProductId: targetProductId ?? this.targetProductId,
      targetProductName: targetProductName ?? this.targetProductName,
      targetQuantity: targetQuantity ?? this.targetQuantity,
      targetUnit: targetUnit ?? this.targetUnit,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      notes: notes ?? this.notes,
      supportingMetric: supportingMetric ?? this.supportingMetric,
      evidenceRationale: evidenceRationale ?? this.evidenceRationale,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }

  factory PrescriptiveActionModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['action_type'] ?? 'roast_batch').toString().toLowerCase();
    final actionType = switch (typeStr) {
      'restock_raw_beans' || 'restock' => PrescriptiveActionType.restockRawBeans,
      'menu_promotion' || 'promotion' => PrescriptiveActionType.menuPromotion,
      'operational_workflow' || 'workflow' || 'counter' => PrescriptiveActionType.operationalWorkflow,
      'informational' => PrescriptiveActionType.informational,
      _ => PrescriptiveActionType.roastBatch,
    };

    final classStr = (json['classification'] ?? 'scheduled').toString().toLowerCase();
    final classification = switch (classStr) {
      'queue' => ActionClassification.queue,
      'immediate' => ActionClassification.immediate,
      'informational' => ActionClassification.informational,
      _ => ActionClassification.scheduled,
    };

    final statStr = (json['status'] ?? 'scheduled').toString().toLowerCase();
    final status = switch (statStr) {
      'recommended' => PrescriptiveActionStatus.recommended,
      'pending_action' || 'pendingaction' => PrescriptiveActionStatus.pendingAction,
      'queued' => PrescriptiveActionStatus.queued,
      'in_progress' || 'inprogress' => PrescriptiveActionStatus.inProgress,
      'completed' => PrescriptiveActionStatus.completed,
      'cancelled' => PrescriptiveActionStatus.cancelled,
      'skipped' => PrescriptiveActionStatus.skipped,
      'failed' => PrescriptiveActionStatus.failed,
      _ => PrescriptiveActionStatus.scheduled,
    };

    final prioStr = (json['priority'] ?? 'medium').toString().toLowerCase();
    final priority = switch (prioStr) {
      'high' => RecommendationPriority.high,
      'low' => RecommendationPriority.low,
      _ => RecommendationPriority.medium,
    };

    final logsList = (json['audit_logs'] as List?)
            ?.map((e) => ActionAuditLogModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return PrescriptiveActionModel(
      id: (json['id'] ?? '').toString(),
      recommendationId: (json['recommendation_id'] ?? '').toString(),
      actionType: actionType,
      classification: classification,
      status: status,
      priority: priority,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      targetProductId: json['target_product_id']?.toString(),
      targetProductName: json['target_product_name']?.toString(),
      targetQuantity: (json['target_quantity'] as num?)?.toInt() ?? 1,
      targetUnit: (json['target_unit'] ?? 'units').toString(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'].toString())
          : null,
      createdBy: (json['created_by'] ?? 'Admin').toString(),
      assignedTo: json['assigned_to']?.toString(),
      notes: json['notes']?.toString(),
      supportingMetric: (json['supporting_metric'] ?? '').toString(),
      evidenceRationale: (json['evidence_rationale'] ?? '').toString(),
      auditLogs: logsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recommendation_id': recommendationId,
        'action_type': actionType.name,
        'classification': classification.name,
        'status': status.name,
        'priority': priority.name,
        'title': title,
        'description': description,
        if (targetProductId != null) 'target_product_id': targetProductId,
        if (targetProductName != null) 'target_product_name': targetProductName,
        'target_quantity': targetQuantity,
        'target_unit': targetUnit,
        if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        if (cancelledAt != null) 'cancelled_at': cancelledAt!.toIso8601String(),
        'created_by': createdBy,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (notes != null) 'notes': notes,
        'supporting_metric': supportingMetric,
        'evidence_rationale': evidenceRationale,
        'audit_logs': auditLogs.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        recommendationId,
        actionType,
        classification,
        status,
        priority,
        title,
        description,
        targetProductId,
        targetProductName,
        targetQuantity,
        targetUnit,
        scheduledAt,
        createdAt,
        updatedAt,
        completedAt,
        cancelledAt,
        createdBy,
        assignedTo,
        notes,
        supportingMetric,
        evidenceRationale,
        auditLogs,
      ];
}
