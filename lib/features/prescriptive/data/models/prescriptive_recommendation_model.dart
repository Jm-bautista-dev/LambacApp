import 'package:equatable/equatable.dart';
import 'prescriptive_action_model.dart';

enum RecommendationPriority { high, medium, low }

enum RecommendationCategory { preparation, inventory, promotion, productPerformance }

enum RecommendationActionStatus {
  pending,
  actionScheduled,
  actionQueued,
  inProgress,
  actionCompleted,
  dismissed;

  String get displayName => switch (this) {
        RecommendationActionStatus.pending => 'Pending Action',
        RecommendationActionStatus.actionScheduled => 'Action Scheduled',
        RecommendationActionStatus.actionQueued => 'Action Queued',
        RecommendationActionStatus.inProgress => 'Action In Progress',
        RecommendationActionStatus.actionCompleted => 'Action Completed',
        RecommendationActionStatus.dismissed => 'Dismissed',
      };
}

/// Data-Driven Prescriptive Recommendation Entity with Decision Traceability & Action Status
class PrescriptiveRecommendationModel extends Equatable {
  final String id;
  final String title;
  final String explanation; // Data-driven "WHY" explanation
  final String supportingMetric; // e.g. "Forecasted demand: +27% daily velocity"
  final RecommendationPriority priority;
  final RecommendationCategory category;
  final DateTime generatedAt;
  final String? actionText; // e.g. "Schedule Roast Batch", "Replenish Raw Beans"
  final String? relatedProductId;
  final String? targetProductName;
  final PrescriptiveActionType actionType;
  final ActionClassification actionClassification;
  final int suggestedQuantity;
  final String suggestedUnit;
  final RecommendationActionStatus actionStatus;
  final String? linkedActionId;
  final DateTime? linkedActionScheduledAt;

  const PrescriptiveRecommendationModel({
    required this.id,
    required this.title,
    required this.explanation,
    required this.supportingMetric,
    required this.priority,
    required this.category,
    required this.generatedAt,
    this.actionText,
    this.relatedProductId,
    this.targetProductName,
    this.actionType = PrescriptiveActionType.roastBatch,
    this.actionClassification = ActionClassification.scheduled,
    this.suggestedQuantity = 12,
    this.suggestedUnit = 'bags',
    this.actionStatus = RecommendationActionStatus.pending,
    this.linkedActionId,
    this.linkedActionScheduledAt,
  });

  PrescriptiveRecommendationModel copyWith({
    String? id,
    String? title,
    String? explanation,
    String? supportingMetric,
    RecommendationPriority? priority,
    RecommendationCategory? category,
    DateTime? generatedAt,
    String? actionText,
    String? relatedProductId,
    String? targetProductName,
    PrescriptiveActionType? actionType,
    ActionClassification? actionClassification,
    int? suggestedQuantity,
    String? suggestedUnit,
    RecommendationActionStatus? actionStatus,
    String? linkedActionId,
    DateTime? linkedActionScheduledAt,
  }) {
    return PrescriptiveRecommendationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      explanation: explanation ?? this.explanation,
      supportingMetric: supportingMetric ?? this.supportingMetric,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      generatedAt: generatedAt ?? this.generatedAt,
      actionText: actionText ?? this.actionText,
      relatedProductId: relatedProductId ?? this.relatedProductId,
      targetProductName: targetProductName ?? this.targetProductName,
      actionType: actionType ?? this.actionType,
      actionClassification: actionClassification ?? this.actionClassification,
      suggestedQuantity: suggestedQuantity ?? this.suggestedQuantity,
      suggestedUnit: suggestedUnit ?? this.suggestedUnit,
      actionStatus: actionStatus ?? this.actionStatus,
      linkedActionId: linkedActionId ?? this.linkedActionId,
      linkedActionScheduledAt: linkedActionScheduledAt ?? this.linkedActionScheduledAt,
    );
  }

  factory PrescriptiveRecommendationModel.fromJson(Map<String, dynamic> json) {
    final prioStr = (json['priority'] ?? 'medium').toString().toLowerCase();
    final priority = switch (prioStr) {
      'high' => RecommendationPriority.high,
      'low' => RecommendationPriority.low,
      _ => RecommendationPriority.medium,
    };

    final catStr = (json['category'] ?? 'preparation').toString().toLowerCase();
    final category = switch (catStr) {
      'inventory' => RecommendationCategory.inventory,
      'promotion' => RecommendationCategory.promotion,
      'productperformance' || 'product_performance' => RecommendationCategory.productPerformance,
      _ => RecommendationCategory.preparation,
    };

    final typeStr = (json['action_type'] ?? 'roast_batch').toString().toLowerCase();
    final actionType = switch (typeStr) {
      'restock_raw_beans' || 'restock' => PrescriptiveActionType.restockRawBeans,
      'menu_promotion' || 'promotion' => PrescriptiveActionType.menuPromotion,
      'operational_workflow' || 'workflow' || 'counter' => PrescriptiveActionType.operationalWorkflow,
      'informational' => PrescriptiveActionType.informational,
      _ => PrescriptiveActionType.roastBatch,
    };

    final classStr = (json['action_classification'] ?? 'scheduled').toString().toLowerCase();
    final actionClassification = switch (classStr) {
      'queue' => ActionClassification.queue,
      'immediate' => ActionClassification.immediate,
      'informational' => ActionClassification.informational,
      _ => ActionClassification.scheduled,
    };

    final statusStr = (json['action_status'] ?? 'pending').toString().toLowerCase();
    final actionStatus = switch (statusStr) {
      'action_scheduled' || 'actionscheduled' => RecommendationActionStatus.actionScheduled,
      'action_queued' || 'actionqueued' => RecommendationActionStatus.actionQueued,
      'in_progress' || 'inprogress' => RecommendationActionStatus.inProgress,
      'action_completed' || 'actioncompleted' => RecommendationActionStatus.actionCompleted,
      'dismissed' => RecommendationActionStatus.dismissed,
      _ => RecommendationActionStatus.pending,
    };

    return PrescriptiveRecommendationModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      supportingMetric: (json['supporting_metric'] ?? '').toString(),
      priority: priority,
      category: category,
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actionText: json['action_text']?.toString(),
      relatedProductId: json['related_product_id']?.toString(),
      targetProductName: json['target_product_name']?.toString(),
      actionType: actionType,
      actionClassification: actionClassification,
      suggestedQuantity: (json['suggested_quantity'] as num?)?.toInt() ?? 12,
      suggestedUnit: (json['suggested_unit'] ?? 'bags').toString(),
      actionStatus: actionStatus,
      linkedActionId: json['linked_action_id']?.toString(),
      linkedActionScheduledAt: json['linked_action_scheduled_at'] != null
          ? DateTime.tryParse(json['linked_action_scheduled_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'explanation': explanation,
      'supporting_metric': supportingMetric,
      'priority': priority.name,
      'category': category.name,
      'generated_at': generatedAt.toIso8601String(),
      if (actionText != null) 'action_text': actionText,
      if (relatedProductId != null) 'related_product_id': relatedProductId,
      if (targetProductName != null) 'target_product_name': targetProductName,
      'action_type': actionType.name,
      'action_classification': actionClassification.name,
      'suggested_quantity': suggestedQuantity,
      'suggested_unit': suggestedUnit,
      'action_status': actionStatus.name,
      if (linkedActionId != null) 'linked_action_id': linkedActionId,
      if (linkedActionScheduledAt != null)
        'linked_action_scheduled_at': linkedActionScheduledAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        explanation,
        supportingMetric,
        priority,
        category,
        generatedAt,
        actionText,
        relatedProductId,
        targetProductName,
        actionType,
        actionClassification,
        suggestedQuantity,
        suggestedUnit,
        actionStatus,
        linkedActionId,
        linkedActionScheduledAt,
      ];
}
