import '../../domain/models/admin_tutorial_state.dart';
import '../../domain/repositories/admin_tutorial_repository.dart';
import '../datasources/admin_tutorial_data.dart';
import '../datasources/admin_tutorial_local_datasource.dart';
import '../models/admin_tutorial_step_model.dart';

class AdminTutorialRepositoryImpl implements AdminTutorialRepository {
  final AdminTutorialLocalDataSource _localDataSource;

  AdminTutorialRepositoryImpl({required AdminTutorialLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<AdminTutorialState> getTutorialState() async {
    final isCompleted = await _localDataSource.isAdminTutorialCompleted();
    final version = await _localDataSource.getAdminTutorialVersion() ?? 1;
    final lastCompletedAt = await _localDataSource.getLastCompletedAt();
    final steps = getSteps();

    return AdminTutorialState(
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
    await _localDataSource.markAdminTutorialCompleted(version: version);
  }

  @override
  Future<void> resetTutorial() async {
    await _localDataSource.resetAdminTutorial();
  }

  @override
  List<AdminTutorialStepModel> getSteps() {
    return AdminTutorialData.steps;
  }
}
