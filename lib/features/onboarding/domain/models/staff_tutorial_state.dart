import 'package:equatable/equatable.dart';
import '../../data/models/staff_tutorial_step_model.dart';

/// State of the Barista / Staff Interactive Operations Tutorial
class StaffTutorialState extends Equatable {
  final bool isLoading;
  final bool isCompleted;
  final int version;
  final DateTime? lastCompletedAt;
  final int currentStepIndex;
  final bool isReplayMode;
  final bool hasStartedTour;
  final List<StaffTutorialStepModel> steps;

  const StaffTutorialState({
    this.isLoading = false,
    this.isCompleted = false,
    this.version = 1,
    this.lastCompletedAt,
    this.currentStepIndex = 0,
    this.isReplayMode = false,
    this.hasStartedTour = false,
    this.steps = const [],
  });

  int get totalSteps => steps.length;
  StaffTutorialStepModel? get currentStep =>
      (currentStepIndex >= 0 && currentStepIndex < steps.length) ? steps[currentStepIndex] : null;

  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex == steps.length - 1;
  double get progressRatio => steps.isEmpty ? 0.0 : (currentStepIndex + 1) / steps.length;

  StaffTutorialState copyWith({
    bool? isLoading,
    bool? isCompleted,
    int? version,
    DateTime? lastCompletedAt,
    int? currentStepIndex,
    bool? isReplayMode,
    bool? hasStartedTour,
    List<StaffTutorialStepModel>? steps,
  }) {
    return StaffTutorialState(
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      version: version ?? this.version,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isReplayMode: isReplayMode ?? this.isReplayMode,
      hasStartedTour: hasStartedTour ?? this.hasStartedTour,
      steps: steps ?? this.steps,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isCompleted,
        version,
        lastCompletedAt,
        currentStepIndex,
        isReplayMode,
        hasStartedTour,
        steps,
      ];
}
