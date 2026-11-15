import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/storage_service.dart';
import '../../data/datasources/staff_tutorial_local_datasource.dart';
import '../../data/repositories/staff_tutorial_repository_impl.dart';
import '../../domain/models/staff_tutorial_state.dart';
import '../../domain/repositories/staff_tutorial_repository.dart';

/// Provider for StaffTutorialLocalDataSource
final staffTutorialLocalDataSourceProvider = Provider<StaffTutorialLocalDataSource>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return StaffTutorialLocalDataSourceImpl(storageService: storage);
});

/// Provider for StaffTutorialRepository
final staffTutorialRepositoryProvider = Provider<StaffTutorialRepository>((ref) {
  final localDataSource = ref.watch(staffTutorialLocalDataSourceProvider);
  return StaffTutorialRepositoryImpl(localDataSource: localDataSource);
});

/// Provider for StaffTutorialNotifier
final staffTutorialNotifierProvider =
    StateNotifierProvider<StaffTutorialNotifier, StaffTutorialState>((ref) {
  final repository = ref.watch(staffTutorialRepositoryProvider);
  return StaffTutorialNotifier(repository: repository);
});

/// StateNotifier managing global Barista / Staff Operations Interactive Tutorial state
class StaffTutorialNotifier extends StateNotifier<StaffTutorialState> {
  final StaffTutorialRepository _repository;

  StaffTutorialNotifier({required StaffTutorialRepository repository})
      : _repository = repository,
        super(StaffTutorialState(steps: repository.getSteps())) {
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

  /// Check whether the staff operations tutorial has been completed
  Future<bool> isTutorialCompleted() async {
    final s = await _repository.getTutorialState();
    return s.isCompleted;
  }

  /// Begin the interactive operational tour
  void startTour() {
    state = state.copyWith(
      hasStartedTour: true,
      currentStepIndex: 0,
    );
  }

  /// Advance to the next operational step
  Future<void> nextStep() async {
    if (state.isLastStep) {
      await completeTutorial();
    } else {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex + 1,
      );
    }
  }

  /// Go back to the previous operational step
  void previousStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
      );
    }
  }

  /// Jump directly to an operational step by index
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

  /// Mark operational tutorial as completed
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

  /// Start manual replay from Staff Profile or Help Guide
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

  /// Strictly determines if the current user role is eligible for the Barista/Staff Operations tutorial
  bool isRoleEligible(UserModel? user) {
    if (user == null) return false;
    // Only authenticated employees (Staff/Barista) receive the Staff Operations Tutorial
    return user.isEmployee;
  }
}
