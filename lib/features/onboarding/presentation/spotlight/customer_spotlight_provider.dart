import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/customer_spotlight_data.dart';
import '../../data/datasources/tutorial_local_datasource.dart';
import '../../data/models/spotlight_step_model.dart';
import '../providers/tutorial_provider.dart';

/// State of the Customer Spotlight Guided Tour
class CustomerSpotlightState extends Equatable {
  final bool isActive;
  final int currentStepIndex;
  final List<SpotlightStepModel> steps;
  final bool isReplay;
  final bool isCompleted;

  const CustomerSpotlightState({
    this.isActive = false,
    this.currentStepIndex = 0,
    this.steps = const [],
    this.isReplay = false,
    this.isCompleted = false,
  });

  int get totalSteps => steps.length;
  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => steps.isNotEmpty && currentStepIndex == steps.length - 1;
  double get progressRatio => steps.isEmpty ? 0.0 : (currentStepIndex + 1) / steps.length;

  SpotlightStepModel? get currentStep =>
      (currentStepIndex >= 0 && currentStepIndex < steps.length) ? steps[currentStepIndex] : null;

  CustomerSpotlightState copyWith({
    bool? isActive,
    int? currentStepIndex,
    List<SpotlightStepModel>? steps,
    bool? isReplay,
    bool? isCompleted,
  }) {
    return CustomerSpotlightState(
      isActive: isActive ?? this.isActive,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      isReplay: isReplay ?? this.isReplay,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        isActive,
        currentStepIndex,
        steps,
        isReplay,
        isCompleted,
      ];
}

/// Provider for CustomerSpotlightNotifier
final customerSpotlightProvider =
    StateNotifierProvider<CustomerSpotlightNotifier, CustomerSpotlightState>((ref) {
  final localDataSource = ref.watch(tutorialLocalDataSourceProvider);
  return CustomerSpotlightNotifier(localDataSource: localDataSource, ref: ref);
});

/// StateNotifier controlling the Spotlight Product Tour
class CustomerSpotlightNotifier extends StateNotifier<CustomerSpotlightState> {
  final TutorialLocalDataSource _localDataSource;
  final Ref _ref;

  CustomerSpotlightNotifier({
    required TutorialLocalDataSource localDataSource,
    required Ref ref,
  })  : _localDataSource = localDataSource,
        _ref = ref,
        super(CustomerSpotlightState(steps: CustomerSpotlightData.steps)) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final completed = await _localDataSource.isTutorialCompleted();
    if (mounted) {
      state = state.copyWith(isCompleted: completed);
    }
  }

  /// Start the spotlight tour on the live customer interface
  void startTour({bool isReplay = false, int startStep = 0}) {
    final clampedStep = startStep.clamp(0, state.steps.isEmpty ? 0 : state.steps.length - 1);
    state = state.copyWith(
      isActive: true,
      currentStepIndex: clampedStep,
      isReplay: isReplay,
    );
  }

  /// Restart the tour from the beginning
  void restartTour() {
    startTour(startStep: 0, isReplay: true);
  }

  /// Advance to the next spotlight step
  Future<void> nextStep() async {
    if (state.isLastStep) {
      await completeTour();
    } else {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex + 1,
      );
    }
  }

  /// Move to previous spotlight step
  void previousStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
      );
    }
  }

  /// Jump directly to a specific step
  void goToStep(int index) {
    if (index >= 0 && index < state.totalSteps) {
      state = state.copyWith(
        currentStepIndex: index,
      );
    }
  }

  /// Skip the tour and persist completion
  Future<void> skipTour() async {
    await _localDataSource.markTutorialCompleted();
    await _ref.read(tutorialNotifierProvider.notifier).skipTutorial();
    if (mounted) {
      state = state.copyWith(
        isActive: false,
        isCompleted: true,
        isReplay: false,
      );
    }
  }

  /// Mark the tour as completed and close overlay
  Future<void> completeTour() async {
    await _localDataSource.markTutorialCompleted();
    await _ref.read(tutorialNotifierProvider.notifier).completeTutorial();
    if (mounted) {
      state = state.copyWith(
        isActive: false,
        isCompleted: true,
        isReplay: false,
      );
    }
  }

  /// Dismiss the overlay without altering completion status
  void dismiss() {
    state = state.copyWith(
      isActive: false,
      isReplay: false,
    );
  }
}
