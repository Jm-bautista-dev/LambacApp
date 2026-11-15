import '../models/tutorial_state.dart';
import '../../data/models/tutorial_step_model.dart';

abstract class TutorialRepository {
  Future<TutorialState> getTutorialState();
  Future<void> completeTutorial({int version = 1});
  Future<void> resetTutorial();
  List<TutorialStepModel> getSteps();
}
