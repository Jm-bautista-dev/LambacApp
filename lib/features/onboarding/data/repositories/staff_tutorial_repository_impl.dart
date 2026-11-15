import '../../domain/models/staff_tutorial_state.dart';
import '../../domain/repositories/staff_tutorial_repository.dart';
import '../datasources/staff_tutorial_data.dart';
import '../datasources/staff_tutorial_local_datasource.dart';
import '../models/staff_tutorial_step_model.dart';

class StaffTutorialRepositoryImpl implements StaffTutorialRepository {
  final StaffTutorialLocalDataSource _localDataSource;

  StaffTutorialRepositoryImpl({required StaffTutorialLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<StaffTutorialState> getTutorialState() async {
    final isCompleted = await _localDataSource.isStaffTutorialCompleted();
    final version = await _localDataSource.getStaffTutorialVersion() ?? 1;
    final lastCompletedAt = await _localDataSource.getLastCompletedAt();
    final steps = getSteps();

    return StaffTutorialState(
      isLoading: false,
      isCompleted: isCompleted,
      version: version,
      lastCompletedAt: lastCompletedAt,
      currentStepIndex: 0,
      steps: steps,
    );
  }

  @override
  Future<void> completeTutorial({int version = 1}) async {
    await _localDataSource.markStaffTutorialCompleted(version: version);
  }

  @override
  Future<void> resetTutorial() async {
    await _localDataSource.resetStaffTutorial();
  }

  @override
  List<StaffTutorialStepModel> getSteps() {
    return StaffTutorialData.steps;
  }
}
