import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../domain/repositories/prescriptive_repository.dart';
import '../datasources/prescriptive_remote_datasource.dart';
import '../models/prescriptive_action_model.dart';
import '../models/prescriptive_recommendation_model.dart';

/// Implementation of PrescriptiveRepository delegating to Remote DataSource
class PrescriptiveRepositoryImpl implements PrescriptiveRepository {
  final PrescriptiveRemoteDataSource _remoteDataSource;

  PrescriptiveRepositoryImpl({required PrescriptiveRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<List<PrescriptiveRecommendationModel>, AppFailure>> getRecommendations() {
    return _remoteDataSource.getRecommendations();
  }

  @override
  Future<Result<List<PrescriptiveActionModel>, AppFailure>> getActions({
    PrescriptiveActionStatus? status,
    ActionClassification? classification,
  }) {
    return _remoteDataSource.getActions(
      status: status,
      classification: classification,
    );
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> getActionById(String id) {
    return _remoteDataSource.getActionById(id);
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> createAction(
    CreatePrescriptiveActionRequest request,
  ) {
    return _remoteDataSource.createAction(request);
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> updateActionStatus(
    String actionId,
    UpdateActionStatusRequest request,
  ) {
    return _remoteDataSource.updateActionStatus(actionId, request);
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> rescheduleAction(
    String actionId,
    DateTime newScheduledAt,
    String? reason,
    String changedBy,
  ) {
    return _remoteDataSource.rescheduleAction(actionId, newScheduledAt, reason, changedBy);
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> cancelAction(
    String actionId,
    String? reason,
    String changedBy,
  ) {
    return _remoteDataSource.cancelAction(actionId, reason, changedBy);
  }
}
