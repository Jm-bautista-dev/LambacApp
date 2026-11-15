import '../../domain/models/tutorial_state.dart';
import '../../domain/repositories/tutorial_repository.dart';
import '../datasources/customer_tutorial_data.dart';
import '../datasources/tutorial_local_datasource.dart';
import '../models/tutorial_step_model.dart';

class TutorialRepositoryImpl implements TutorialRepository {
  final TutorialLocalDataSource _localDataSource;

  TutorialRepositoryImpl({required TutorialLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<TutorialState> getTutorialState() async {
    final isCompleted = await _localDataSource.isTutorialCompleted();
    final version = await _localDataSource.getTutorialVersion() ?? 1;
    final lastCompletedAt = await _localDataSource.getLastCompletedAt();
    final steps = getSteps();

    return TutorialState(
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
    await _localDataSource.markTutorialCompleted(version: version);
  }

  @override
  Future<void> resetTutorial() async {
    await _localDataSource.resetTutorial();
  }

  @override
  List<TutorialStepModel> getSteps() {
    return CustomerTutorialData.steps;
  }
}
