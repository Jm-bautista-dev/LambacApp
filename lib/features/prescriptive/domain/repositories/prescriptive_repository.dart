import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../data/datasources/prescriptive_remote_datasource.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../../data/models/prescriptive_recommendation_model.dart';

/// Prescriptive Repository Interface for recommendations & operational actions
abstract class PrescriptiveRepository {
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
