import '../models/staff_tutorial_state.dart';
import '../../data/models/staff_tutorial_step_model.dart';

abstract class StaffTutorialRepository {
  Future<StaffTutorialState> getTutorialState();
  Future<void> completeTutorial({int version = 1});
  Future<void> resetTutorial();
  List<StaffTutorialStepModel> getSteps();
}
