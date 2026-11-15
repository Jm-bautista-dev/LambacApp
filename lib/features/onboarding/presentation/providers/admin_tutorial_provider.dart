import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/storage_service.dart';
import '../../data/datasources/admin_tutorial_local_datasource.dart';
import '../../data/models/admin_tutorial_step_model.dart';
import '../../data/repositories/admin_tutorial_repository_impl.dart';
import '../../domain/models/admin_tutorial_state.dart';
import '../../domain/repositories/admin_tutorial_repository.dart';

/// Provider for AdminTutorialLocalDataSource
final adminTutorialLocalDataSourceProvider = Provider<AdminTutorialLocalDataSource>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AdminTutorialLocalDataSourceImpl(storageService: storage);
});

/// Provider for AdminTutorialRepository
final adminTutorialRepositoryProvider = Provider<AdminTutorialRepository>((ref) {
  final localDataSource = ref.watch(adminTutorialLocalDataSourceProvider);
  return AdminTutorialRepositoryImpl(localDataSource: localDataSource);
});

/// Provider for AdminTutorialNotifier
final adminTutorialNotifierProvider =
    StateNotifierProvider<AdminTutorialNotifier, AdminTutorialState>((ref) {
  final repository = ref.watch(adminTutorialRepositoryProvider);
  return AdminTutorialNotifier(repository: repository);
});

/// StateNotifier managing global Administrator Interactive Tutorial & BI Guide state
class AdminTutorialNotifier extends StateNotifier<AdminTutorialState> {
  final AdminTutorialRepository _repository;

  AdminTutorialNotifier({required AdminTutorialRepository repository})
      : _repository = repository,
        super(AdminTutorialState(steps: repository.getSteps())) {
    loadState();
  }

  /// Initial load from local persistence
  Future<void> loadState() async {
    state = state.copyWith(isLoading: true);
    final loaded = await _repository.getTutorialState();
    if (mounted) {
      state = loaded.copyWith(isLoading: false);
    }
  }

  /// Check whether the admin operations & BI tutorial has been completed
  Future<bool> isTutorialCompleted() async {
    final s = await _repository.getTutorialState();
    return s.isCompleted;
  }

  /// Begin the interactive executive tour
  void startTour() {
    state = state.copyWith(
      hasStartedTour: true,
      currentStepIndex: 0,
    );
  }

  /// Advance to the next administrative step
  Future<void> nextStep() async {
    if (state.isLastStep) {
      await completeTutorial();
    } else {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex + 1,
      );
    }
  }

  /// Go back to the previous administrative step
  void previousStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
      );
    }
  }

  /// Jump directly to an administrative step by index
  void goToStep(int index) {
    if (index >= 0 && index < state.totalSteps) {
      state = state.copyWith(
        hasStartedTour: true,
        currentStepIndex: index,
      );
    }
  }

  /// Jump to the first step of a specific chapter
  void goToChapter(AdminTutorialChapter chapter) {
    final index = state.steps.indexWhere((s) => s.chapter == chapter);
    if (index != -1) {
      goToStep(index);
    }
  }

  /// Skip the tutorial and mark as completed
  Future<void> skipTutorial() async {
    await _repository.completeTutorial(version: state.version);
    if (mounted) {
      state = state.copyWith(
        isCompleted: true,
        lastCompletedAt: DateTime.now(),
        hasStartedTour: false,
        isReplayMode: false,
      );
    }
  }

  /// Mark administrative tutorial as completed
  Future<void> completeTutorial() async {
    await _repository.completeTutorial(version: state.version);
    if (mounted) {
      state = state.copyWith(
        isCompleted: true,
        lastCompletedAt: DateTime.now(),
        hasStartedTour: false,
        isReplayMode: false,
      );
    }
  }

  /// Start manual replay from Admin Profile or Help Guide
  void startReplay({int startStep = 0}) {
    state = state.copyWith(
      isReplayMode: true,
      hasStartedTour: true,
      currentStepIndex: startStep.clamp(0, state.totalSteps - 1),
    );
  }

  /// Reset tutorial status (for testing or debugging)
  Future<void> resetTutorial() async {
    await _repository.resetTutorial();
    if (mounted) {
      state = state.copyWith(
        isCompleted: false,
        currentStepIndex: 0,
        hasStartedTour: false,
        isReplayMode: false,
        lastCompletedAt: null,
      );
    }
  }

  /// Strictly determines if the current user role is eligible for the Admin Tutorial
  bool isRoleEligible(UserModel? user) {
    if (user == null) return false;
    // Only authenticated Administrators receive the Admin Interactive System Tutorial
    return user.isAdmin;
  }
}
