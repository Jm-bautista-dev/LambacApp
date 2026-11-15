import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/firebase_prescriptive_remote_datasource.dart';
import '../../data/datasources/prescriptive_remote_datasource.dart';
import '../../data/models/prescriptive_action_model.dart';
import '../../data/models/prescriptive_recommendation_model.dart';
import '../../data/repositories/prescriptive_repository_impl.dart';
import '../../domain/repositories/prescriptive_repository.dart';

/// Provider for Prescriptive Remote Data Source
final prescriptiveRemoteDataSourceProvider = Provider<PrescriptiveRemoteDataSource>((ref) {
  return FirebasePrescriptiveRemoteDataSource();
});

/// Provider for Domain PrescriptiveRepository
final prescriptiveRepositoryProvider = Provider<PrescriptiveRepository>((ref) {
  final remoteDataSource = ref.watch(prescriptiveRemoteDataSourceProvider);
  return PrescriptiveRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Priority Filter Provider for Recommendations (null = All, high, medium, low)
final prescriptivePriorityFilterProvider = StateProvider<RecommendationPriority?>((ref) => null);

/// FutureProvider for Prescriptive Business Recommendations
final prescriptiveRecommendationsProvider =
    FutureProvider<List<PrescriptiveRecommendationModel>>((ref) async {
  final repository = ref.watch(prescriptiveRepositoryProvider);
  final priorityFilter = ref.watch(prescriptivePriorityFilterProvider);

  final result = await repository.getRecommendations();

  return result.when(
    success: (list) {
      if (priorityFilter == null) return list;
      return list.where((rec) => rec.priority == priorityFilter).toList();
    },
    failure: (failure) => throw Exception(failure.message),
  );
});

/// Prescriptive Action State Notifier managing all persistent action records
class PrescriptiveActionsNotifier extends StateNotifier<AsyncValue<List<PrescriptiveActionModel>>> {
  final PrescriptiveRepository _repository;
  final Ref _ref;

  PrescriptiveActionsNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadActions();
  }

  Future<void> loadActions() async {
    state = const AsyncValue.loading();
    final result = await _repository.getActions();
    result.when(
      success: (actions) {
        state = AsyncValue.data(actions);
      },
      failure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
    );
  }

  /// Create a new operational prescriptive action record
  Future<Result<PrescriptiveActionModel, AppFailure>> createAction(
    CreatePrescriptiveActionRequest request,
  ) async {
    final result = await _repository.createAction(request);
    return result.when(
      success: (createdAction) {
        // Refresh local actions state and recommendations list
        loadActions();
        _ref.invalidate(prescriptiveRecommendationsProvider);
        return Result<PrescriptiveActionModel, AppFailure>.success(createdAction);
      },
      failure: (failure) => Result<PrescriptiveActionModel, AppFailure>.failure(failure),
    );
  }

  /// Transition action to a new status (e.g. IN_PROGRESS, COMPLETED)
  Future<Result<PrescriptiveActionModel, AppFailure>> updateStatus({
    required String actionId,
    required PrescriptiveActionStatus toStatus,
    String? note,
    DateTime? newScheduledAt,
  }) async {
    final currentUser = _ref.read(currentUserProvider);
    final actorName = currentUser != null
        ? '${currentUser.role.name.toUpperCase()} (${currentUser.fullName})'
        : 'Admin';

    final result = await _repository.updateActionStatus(
      actionId,
      UpdateActionStatusRequest(
        toStatus: toStatus,
        changedBy: actorName,
        note: note,
        newScheduledAt: newScheduledAt,
      ),
    );

    return result.when(
      success: (updated) {
        loadActions();
        _ref.invalidate(prescriptiveRecommendationsProvider);
        return Result<PrescriptiveActionModel, AppFailure>.success(updated);
      },
      failure: (failure) => Result<PrescriptiveActionModel, AppFailure>.failure(failure),
    );
  }

  /// Reschedule an existing scheduled action
  Future<Result<PrescriptiveActionModel, AppFailure>> reschedule({
    required String actionId,
    required DateTime newScheduledAt,
    String? reason,
  }) async {
    final currentUser = _ref.read(currentUserProvider);
    final actorName = currentUser != null
        ? '${currentUser.role.name.toUpperCase()} (${currentUser.fullName})'
        : 'Admin';

    final result = await _repository.rescheduleAction(
      actionId,
      newScheduledAt,
      reason,
      actorName,
    );

    return result.when(
      success: (updated) {
        loadActions();
        _ref.invalidate(prescriptiveRecommendationsProvider);
        return Result<PrescriptiveActionModel, AppFailure>.success(updated);
      },
      failure: (failure) => Result<PrescriptiveActionModel, AppFailure>.failure(failure),
    );
  }

  /// Cancel an action with audit rationale
  Future<Result<PrescriptiveActionModel, AppFailure>> cancel({
    required String actionId,
    String? reason,
  }) async {
    final currentUser = _ref.read(currentUserProvider);
    final actorName = currentUser != null
        ? '${currentUser.role.name.toUpperCase()} (${currentUser.fullName})'
        : 'Admin';

    final result = await _repository.cancelAction(
      actionId,
      reason,
      actorName,
    );

    return result.when(
      success: (cancelled) {
        loadActions();
        _ref.invalidate(prescriptiveRecommendationsProvider);
        return Result<PrescriptiveActionModel, AppFailure>.success(cancelled);
      },
      failure: (failure) => Result<PrescriptiveActionModel, AppFailure>.failure(failure),
    );
  }
}

/// Global StateNotifierProvider for Prescriptive Actions
final prescriptiveActionsNotifierProvider =
    StateNotifierProvider<PrescriptiveActionsNotifier, AsyncValue<List<PrescriptiveActionModel>>>(
        (ref) {
  final repository = ref.watch(prescriptiveRepositoryProvider);
  return PrescriptiveActionsNotifier(repository, ref);
});

/// Filtered Provider for Prescriptive Schedule (Upcoming Scheduled Actions)
final prescriptiveScheduleProvider = Provider<List<PrescriptiveActionModel>>((ref) {
  final actionsAsync = ref.watch(prescriptiveActionsNotifierProvider);
  return actionsAsync.maybeWhen(
    data: (actions) {
      final scheduled = actions
          .where((a) =>
              a.status == PrescriptiveActionStatus.scheduled ||
              (a.status == PrescriptiveActionStatus.inProgress && a.scheduledAt != null))
          .toList();

      // Sort chronologically (earliest upcoming first)
      scheduled.sort((a, b) {
        final aDate = a.scheduledAt ?? a.createdAt;
        final bDate = b.scheduledAt ?? b.createdAt;
        return aDate.compareTo(bDate);
      });
      return scheduled;
    },
    orElse: () => [],
  );
});

/// Filtered Provider for Operational Action Queue (Active tasks needing attention)
final prescriptiveQueueProvider = Provider<List<PrescriptiveActionModel>>((ref) {
  final actionsAsync = ref.watch(prescriptiveActionsNotifierProvider);
  return actionsAsync.maybeWhen(
    data: (actions) {
      final active = actions.where((a) => a.status.isActive).toList();

      // Priority sort: high -> medium -> low
      active.sort((a, b) {
        final pCompare = a.priority.index.compareTo(b.priority.index);
        if (pCompare != 0) return pCompare;
        final aDate = a.scheduledAt ?? a.createdAt;
        final bDate = b.scheduledAt ?? b.createdAt;
        return aDate.compareTo(bDate);
      });
      return active;
    },
    orElse: () => [],
  );
});

/// Filtered Provider for Prescriptive Action History (Completed & Cancelled)
final prescriptiveHistoryProvider = Provider<List<PrescriptiveActionModel>>((ref) {
  final actionsAsync = ref.watch(prescriptiveActionsNotifierProvider);
  return actionsAsync.maybeWhen(
    data: (actions) {
      final history = actions.where((a) => a.status.isTerminal).toList();

      // Sort most recently completed / updated first
      history.sort((a, b) {
        final aDate = a.completedAt ?? a.cancelledAt ?? a.updatedAt;
        final bDate = b.completedAt ?? b.cancelledAt ?? b.updatedAt;
        return bDate.compareTo(aDate);
      });
      return history;
    },
    orElse: () => [],
  );
});

/// Single Action Family Provider
final prescriptiveActionByIdProvider =
    FutureProvider.family<PrescriptiveActionModel, String>((ref, id) async {
  final repository = ref.watch(prescriptiveRepositoryProvider);
  final result = await repository.getActionById(id);
  return result.when(
    success: (action) => action,
    failure: (fail) => throw Exception(fail.message),
  );
});
