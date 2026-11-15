import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../models/prescriptive_action_model.dart';
import '../models/prescriptive_recommendation_model.dart';

/// Request payload for creating a new operational prescriptive action
class CreatePrescriptiveActionRequest {
  final String recommendationId;
  final PrescriptiveActionType actionType;
  final ActionClassification classification;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String? targetProductId;
  final String? targetProductName;
  final int targetQuantity;
  final String targetUnit;
  final DateTime? scheduledAt;
  final String createdBy;
  final String? assignedTo;
  final String? notes;
  final String supportingMetric;
  final String evidenceRationale;

  const CreatePrescriptiveActionRequest({
    required this.recommendationId,
    required this.actionType,
    required this.classification,
    required this.priority,
    required this.title,
    required this.description,
    this.targetProductId,
    this.targetProductName,
    required this.targetQuantity,
    this.targetUnit = 'units',
    this.scheduledAt,
    this.createdBy = 'Admin',
    this.assignedTo,
    this.notes,
    required this.supportingMetric,
    required this.evidenceRationale,
  });

  Map<String, dynamic> toJson() => {
        'recommendation_id': recommendationId,
        'action_type': actionType.name,
        'classification': classification.name,
        'priority': priority.name,
        'title': title,
        'description': description,
        if (targetProductId != null) 'target_product_id': targetProductId,
        if (targetProductName != null) 'target_product_name': targetProductName,
        'target_quantity': targetQuantity,
        'target_unit': targetUnit,
        if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
        'created_by': createdBy,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (notes != null) 'notes': notes,
        'supporting_metric': supportingMetric,
        'evidence_rationale': evidenceRationale,
      };
}

/// Request payload for changing status or adding an audit note
class UpdateActionStatusRequest {
  final PrescriptiveActionStatus toStatus;
  final String changedBy;
  final String? note;
  final DateTime? newScheduledAt;

  const UpdateActionStatusRequest({
    required this.toStatus,
    required this.changedBy,
    this.note,
    this.newScheduledAt,
  });

  Map<String, dynamic> toJson() => {
        'to_status': toStatus.name,
        'changed_by': changedBy,
        if (note != null) 'note': note,
        if (newScheduledAt != null) 'new_scheduled_at': newScheduledAt!.toIso8601String(),
      };
}

/// Contract for Remote Prescriptive Decision-Support and Action Execution API
abstract class PrescriptiveRemoteDataSource {
  Future<Result<List<PrescriptiveRecommendationModel>, AppFailure>> getRecommendations();

  Future<Result<List<PrescriptiveActionModel>, AppFailure>> getActions({
    PrescriptiveActionStatus? status,
    ActionClassification? classification,
  });

  Future<Result<PrescriptiveActionModel, AppFailure>> getActionById(String id);

  Future<Result<PrescriptiveActionModel, AppFailure>> createAction(
    CreatePrescriptiveActionRequest request,
  );

  Future<Result<PrescriptiveActionModel, AppFailure>> updateActionStatus(
    String actionId,
    UpdateActionStatusRequest request,
  );

  Future<Result<PrescriptiveActionModel, AppFailure>> rescheduleAction(
    String actionId,
    DateTime newScheduledAt,
    String? reason,
    String changedBy,
  );

  Future<Result<PrescriptiveActionModel, AppFailure>> cancelAction(
    String actionId,
    String? reason,
    String changedBy,
  );
}

/// Concrete Dio-based implementation for production API endpoints
class PrescriptiveRemoteDataSourceImpl implements PrescriptiveRemoteDataSource {
  final ApiClient _apiClient;

  PrescriptiveRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<List<PrescriptiveRecommendationModel>, AppFailure>> getRecommendations() {
    return _apiClient.get(
      '/admin/prescriptive/recommendations',
      requiresAuth: true,
      decoder: (data) {
        final list = data is List ? data : (data['recommendations'] ?? data['data']) as List;
        return list
            .map((item) => PrescriptiveRecommendationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<Result<List<PrescriptiveActionModel>, AppFailure>> getActions({
    PrescriptiveActionStatus? status,
    ActionClassification? classification,
  }) {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status.name;
    if (classification != null) queryParams['classification'] = classification.name;

    return _apiClient.get(
      '/admin/prescriptive/actions',
      queryParameters: queryParams,
      requiresAuth: true,
      decoder: (data) {
        final list = data is List ? data : (data['actions'] ?? data['data']) as List;
        return list
            .map((item) => PrescriptiveActionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> getActionById(String id) {
    return _apiClient.get(
      '/admin/prescriptive/actions/$id',
      requiresAuth: true,
      decoder: (data) =>
          PrescriptiveActionModel.fromJson((data['action'] ?? data['data'] ?? data) as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> createAction(
    CreatePrescriptiveActionRequest request,
  ) {
    return _apiClient.post(
      '/admin/prescriptive/actions',
      data: request.toJson(),
      requiresAuth: true,
      decoder: (data) =>
          PrescriptiveActionModel.fromJson((data['action'] ?? data['data'] ?? data) as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> updateActionStatus(
    String actionId,
    UpdateActionStatusRequest request,
  ) {
    return _apiClient.patch(
      '/admin/prescriptive/actions/$actionId/status',
      data: request.toJson(),
      requiresAuth: true,
      decoder: (data) =>
          PrescriptiveActionModel.fromJson((data['action'] ?? data['data'] ?? data) as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> rescheduleAction(
    String actionId,
    DateTime newScheduledAt,
    String? reason,
    String changedBy,
  ) {
    return _apiClient.post(
      '/admin/prescriptive/actions/$actionId/reschedule',
      data: {
        'new_scheduled_at': newScheduledAt.toIso8601String(),
        'reason': reason,
        'changed_by': changedBy,
      },
      requiresAuth: true,
      decoder: (data) =>
          PrescriptiveActionModel.fromJson((data['action'] ?? data['data'] ?? data) as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> cancelAction(
    String actionId,
    String? reason,
    String changedBy,
  ) {
    return _apiClient.post(
      '/admin/prescriptive/actions/$actionId/cancel',
      data: {
        'reason': reason,
        'changed_by': changedBy,
      },
      requiresAuth: true,
      decoder: (data) =>
          PrescriptiveActionModel.fromJson((data['action'] ?? data['data'] ?? data) as Map<String, dynamic>),
    );
  }
}
