import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/storage_service.dart';
import '../../data/datasources/tutorial_local_datasource.dart';
import '../../data/repositories/tutorial_repository_impl.dart';
import '../../domain/models/tutorial_state.dart';
import '../../domain/repositories/tutorial_repository.dart';

/// Provider for TutorialLocalDataSource
final tutorialLocalDataSourceProvider = Provider<TutorialLocalDataSource>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return TutorialLocalDataSourceImpl(storageService: storage);
});

/// Provider for TutorialRepository
final tutorialRepositoryProvider = Provider<TutorialRepository>((ref) {
  final localDataSource = ref.watch(tutorialLocalDataSourceProvider);
  return TutorialRepositoryImpl(localDataSource: localDataSource);
});

/// Provider for TutorialNotifier
final tutorialNotifierProvider = StateNotifierProvider<TutorialNotifier, TutorialState>((ref) {
  final repository = ref.watch(tutorialRepositoryProvider);
  return TutorialNotifier(repository: repository);
});

/// StateNotifier managing global Customer Interactive Tutorial state
class TutorialNotifier extends StateNotifier<TutorialState> {
  final TutorialRepository _repository;

  TutorialNotifier({required TutorialRepository repository})
      : _repository = repository,
        super(TutorialState(steps: repository.getSteps())) {
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

  /// Check whether the customer tutorial has been completed (for routing & startup guards)
  Future<bool> isTutorialCompleted() async {
    final s = await _repository.getTutorialState();
    return s.isCompleted;
  }

  /// Begin the interactive tour
  void startTour() {
    state = state.copyWith(
      hasStartedTour: true,
      currentStepIndex: 0,
    );
  }

  /// Advance to the next step
  Future<void> nextStep() async {
    if (state.isLastStep) {
      await completeTutorial();
    } else {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex + 1,
      );
    }
  }

  /// Go back to the previous step
  void previousStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
      );
    }
  }

  /// Jump directly to a step by index
  void goToStep(int index) {
    if (index >= 0 && index < state.totalSteps) {
      state = state.copyWith(
        hasStartedTour: true,
        currentStepIndex: index,
      );
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

  /// Mark tutorial as completed
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

  /// Start manual replay from Profile or Help Guide
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

  /// Strictly determines if the current role is allowed to see customer tutorial
  bool isRoleEligible(UserModel? user) {
    if (user == null) return true; // Guest is allowed
    if (user.isGuest) return true;
    if (user.isCustomer) return true;
    // Admins and Staff are strictly excluded from Customer Tutorial
    return false;
  }
}
