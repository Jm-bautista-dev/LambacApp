import '../models/admin_tutorial_state.dart';
import '../../data/models/admin_tutorial_step_model.dart';

abstract class AdminTutorialRepository {
  Future<AdminTutorialState> getTutorialState();
  Future<void> completeTutorial({int version = 1});
  Future<void> resetTutorial();
  List<AdminTutorialStepModel> getSteps();
}
