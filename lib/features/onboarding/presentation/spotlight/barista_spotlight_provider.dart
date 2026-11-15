import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/barista_spotlight_data.dart';
import '../../data/datasources/staff_tutorial_local_datasource.dart';
import '../../data/models/spotlight_step_model.dart';
import '../providers/staff_tutorial_provider.dart';

/// State of the Barista Interactive Spotlight Coach-Mark Tour
class BaristaSpotlightState {
  final List<SpotlightStepModel> steps;
  final int currentStepIndex;
  final bool isActive;
  final bool isCompleted;
  final bool hasSkipped;

  const BaristaSpotlightState({
    required this.steps,
    this.currentStepIndex = 0,
    this.isActive = false,
    this.isCompleted = false,
    this.hasSkipped = false,
  });

  SpotlightStepModel? get currentStep {
    if (!isActive || steps.isEmpty || currentStepIndex < 0 || currentStepIndex >= steps.length) {
      return null;
    }
    return steps[currentStepIndex];
  }

  int get totalSteps => steps.length;
  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex >= steps.length - 1;

  BaristaSpotlightState copyWith({
    List<SpotlightStepModel>? steps,
    int? currentStepIndex,
    bool? isActive,
    bool? isCompleted,
    bool? hasSkipped,
  }) {
    return BaristaSpotlightState(
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      hasSkipped: hasSkipped ?? this.hasSkipped,
    );
  }
}

/// StateNotifier controlling the Barista Spotlight Coach-Mark Tour
class BaristaSpotlightNotifier extends StateNotifier<BaristaSpotlightState> {
  final StaffTutorialLocalDataSource _localDataSource;

  BaristaSpotlightNotifier({
    required StaffTutorialLocalDataSource localDataSource,
  })  : _localDataSource = localDataSource,
        super(BaristaSpotlightState(steps: BaristaSpotlightData.getSteps())) {
    _init();
  }

  Future<void> _init() async {
    final completed = await _localDataSource.isStaffTutorialCompleted();
    if (!state.isCompleted && mounted) {
      state = state.copyWith(isCompleted: completed);
    }
  }

  /// Launch the spotlight tour from a specific step (defaults to Step 1)
  void startTour({int startStep = 0, bool isReplay = false}) {
    state = state.copyWith(
      isActive: true,
      currentStepIndex: startStep.clamp(0, state.steps.length - 1),
    );
  }

  /// Move to next spotlight step or finish if on the last step
  void nextStep() {
    if (state.isLastStep) {
      finishTour();
    } else {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex + 1,
      );
    }
  }

  /// Move to previous spotlight step
  void previousStep() {
    if (!state.isFirstStep) {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
      );
    }
  }

  /// Jump to a specific step
  void jumpToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < state.steps.length) {
      state = state.copyWith(
        currentStepIndex: stepIndex,
        isActive: true,
      );
    }
  }

  /// Skip the tour and save completed status locally
  Future<void> skipTour() async {
    state = state.copyWith(
      isActive: false,
      hasSkipped: true,
      isCompleted: true,
    );
    await _localDataSource.markStaffTutorialCompleted();
  }

  /// Finish the tour on the final step and save completed status locally
  Future<void> finishTour() async {
    state = state.copyWith(
      isActive: false,
      isCompleted: true,
    );
    await _localDataSource.markStaffTutorialCompleted();
  }

  /// Replay the tour from the beginning
  void replayTour() {
    startTour(startStep: 0);
  }
}

/// Riverpod provider for BaristaSpotlightNotifier
final baristaSpotlightProvider =
    StateNotifierProvider<BaristaSpotlightNotifier, BaristaSpotlightState>((ref) {
  final localDataSource = ref.watch(staffTutorialLocalDataSourceProvider);
  return BaristaSpotlightNotifier(localDataSource: localDataSource);
});
