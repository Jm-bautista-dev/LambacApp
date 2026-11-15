import 'package:equatable/equatable.dart';
import '../../data/models/admin_tutorial_step_model.dart';

/// State of the Administrator Interactive Operations & BI Tutorial
class AdminTutorialState extends Equatable {
  final bool isLoading;
  final bool isCompleted;
  final int version;
  final DateTime? lastCompletedAt;
  final int currentStepIndex;
  final bool isReplayMode;
  final bool hasStartedTour;
  final AdminTutorialChapter? selectedChapterFilter;
  final List<AdminTutorialStepModel> steps;

  const AdminTutorialState({
    this.isLoading = false,
    this.isCompleted = false,
    this.version = 1,
    this.lastCompletedAt,
    this.currentStepIndex = 0,
    this.isReplayMode = false,
    this.hasStartedTour = false,
    this.selectedChapterFilter,
    this.steps = const [],
  });

  int get totalSteps => steps.length;
  AdminTutorialStepModel? get currentStep =>
      (currentStepIndex >= 0 && currentStepIndex < steps.length) ? steps[currentStepIndex] : null;

  AdminTutorialChapter? get currentChapter => currentStep?.chapter;
  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex == steps.length - 1;
  double get progressRatio => steps.isEmpty ? 0.0 : (currentStepIndex + 1) / steps.length;

  AdminTutorialState copyWith({
    bool? isLoading,
    bool? isCompleted,
    int? version,
    DateTime? lastCompletedAt,
    int? currentStepIndex,
    bool? isReplayMode,
    bool? hasStartedTour,
    AdminTutorialChapter? selectedChapterFilter,
    List<AdminTutorialStepModel>? steps,
  }) {
    return AdminTutorialState(
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      version: version ?? this.version,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isReplayMode: isReplayMode ?? this.isReplayMode,
      hasStartedTour: hasStartedTour ?? this.hasStartedTour,
      selectedChapterFilter: selectedChapterFilter ?? this.selectedChapterFilter,
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
        selectedChapterFilter,
        steps,
      ];
}
