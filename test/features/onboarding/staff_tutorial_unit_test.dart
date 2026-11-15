import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/staff_tutorial_data.dart';
import 'package:lambac_app/features/onboarding/data/datasources/staff_tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/data/models/staff_tutorial_step_model.dart';
import 'package:lambac_app/features/onboarding/data/repositories/staff_tutorial_repository_impl.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/staff_tutorial_provider.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Barista / Staff Interactive Operations Tutorial Unit Tests', () {
    late StorageService storageService;
    late StaffTutorialLocalDataSource localDataSource;
    late StaffTutorialRepositoryImpl repository;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = StaffTutorialLocalDataSourceImpl(storageService: storageService);
      repository = StaffTutorialRepositoryImpl(localDataSource: localDataSource);
    });

    test('1. Staff Step Catalog completeness: All 20 operational steps are defined with rich SOP metadata', () {
      final steps = repository.getSteps();
      expect(steps.length, 20);

      // Verify categories covered
      final categories = steps.map((s) => s.category).toSet();
      expect(categories.contains(StaffTutorialCategory.welcome), isTrue);
      expect(categories.contains(StaffTutorialCategory.navigation), isTrue);
      expect(categories.contains(StaffTutorialCategory.queue), isTrue);
      expect(categories.contains(StaffTutorialCategory.preparation), isTrue);
      expect(categories.contains(StaffTutorialCategory.pickup), isTrue);
      expect(categories.contains(StaffTutorialCategory.pos), isTrue);
      expect(categories.contains(StaffTutorialCategory.concierge), isTrue);
      expect(categories.contains(StaffTutorialCategory.shift), isTrue);

      // Verify specific mandatory operational feature steps exist
      expect(steps.any((s) => s.id == 'staff_welcome'), isTrue);
      expect(steps.any((s) => s.id == 'staff_navigation'), isTrue);
      expect(steps.any((s) => s.id == 'staff_kpi_metrics'), isTrue);
      expect(steps.any((s) => s.id == 'staff_queue_filtering'), isTrue);
      expect(steps.any((s) => s.id == 'staff_order_card_anatomy'), isTrue);
      expect(steps.any((s) => s.id == 'staff_stage_accept'), isTrue);
      expect(steps.any((s) => s.id == 'staff_stage_preparing'), isTrue);
      expect(steps.any((s) => s.id == 'staff_stage_prepared'), isTrue);
      expect(steps.any((s) => s.id == 'staff_stage_ready'), isTrue);
      expect(steps.any((s) => s.id == 'staff_stage_completed'), isTrue);
      expect(steps.any((s) => s.id == 'staff_realtime_sync'), isTrue);
      expect(steps.any((s) => s.id == 'staff_pay_at_counter'), isTrue);
      expect(steps.any((s) => s.id == 'staff_walk_in_pos'), isTrue);
      expect(steps.any((s) => s.id == 'staff_concierge_inbox'), isTrue);
      expect(steps.any((s) => s.id == 'staff_ai_handoff'), isTrue);
      expect(steps.any((s) => s.id == 'staff_notifications'), isTrue);
      expect(steps.any((s) => s.id == 'staff_profile_shift'), isTrue);
      expect(steps.any((s) => s.id == 'staff_help_replay'), isTrue);
      expect(steps.any((s) => s.id == 'staff_safety_rules'), isTrue);
      expect(steps.any((s) => s.id == 'staff_completion'), isTrue);
    });

    test('2. Persistence: StaffTutorialLocalDataSource marks completion and persists version & timestamp', () async {
      expect(await localDataSource.isStaffTutorialCompleted(), isFalse);
      expect(await localDataSource.getStaffTutorialVersion(), isNull);
      expect(await localDataSource.getLastCompletedAt(), isNull);

      await localDataSource.markStaffTutorialCompleted(version: 1);

      expect(await localDataSource.isStaffTutorialCompleted(), isTrue);
      expect(await localDataSource.getStaffTutorialVersion(), 1);
      expect(await localDataSource.getLastCompletedAt(), isNotNull);

      // Reset
      await localDataSource.resetStaffTutorial();
      expect(await localDataSource.isStaffTutorialCompleted(), isFalse);
    });

    test('3. State Notifier: Operational tour navigation, skip, complete, and replay flow', () async {
      final notifier = StaffTutorialNotifier(repository: repository);
      await notifier.loadState();

      expect(notifier.state.hasStartedTour, isFalse);
      expect(notifier.state.isCompleted, isFalse);
      expect(notifier.state.currentStepIndex, 0);

      // Start Tour
      notifier.startTour();
      expect(notifier.state.hasStartedTour, isTrue);
      expect(notifier.state.currentStepIndex, 0);
      expect(notifier.state.isFirstStep, isTrue);

      // Next Step
      await notifier.nextStep();
      expect(notifier.state.currentStepIndex, 1);
      expect(notifier.state.isFirstStep, isFalse);

      // Jump to Step
      notifier.goToStep(11); // Step 12: Pay-at-Counter
      expect(notifier.state.currentStepIndex, 11);

      // Previous Step
      notifier.previousStep();
      expect(notifier.state.currentStepIndex, 10);

      // Replay Mode
      notifier.startReplay(startStep: 4);
      expect(notifier.state.isReplayMode, isTrue);
      expect(notifier.state.currentStepIndex, 4);

      // Complete Tutorial
      await notifier.completeTutorial();
      expect(notifier.state.isCompleted, isTrue);
      expect(notifier.state.hasStartedTour, isFalse);
      expect(notifier.state.isReplayMode, isFalse);
      expect(await repository.getTutorialState().then((s) => s.isCompleted), isTrue);
    });

    test('4. Role Eligibility: Only authenticated Staff/Baristas are eligible; Customers, Admins & Guests are forbidden', () {
      final notifier = StaffTutorialNotifier(repository: repository);

      // Guest User -> Forbidden
      expect(notifier.isRoleEligible(null), isFalse);
      expect(notifier.isRoleEligible(UserModel.guest()), isFalse);

      // Customer User -> Forbidden
      const customer = UserModel(
        id: 'cust_01',
        email: 'customer@example.com',
        fullName: 'Jane Customer',
        role: UserRole.customer,
      );
      expect(notifier.isRoleEligible(customer), isFalse);

      // Admin User -> Forbidden from Staff Onboarding
      const admin = UserModel(
        id: 'admin_01',
        email: 'admin@lambac.ph',
        fullName: 'Alice Admin',
        role: UserRole.admin,
      );
      expect(notifier.isRoleEligible(admin), isFalse);

      // Staff / Employee User -> Strictly Eligible
      const staff = UserModel(
        id: 'staff_01',
        email: 'barista.staff@lambac.com',
        fullName: 'Jordan Barista',
        role: UserRole.employee,
      );
      expect(notifier.isRoleEligible(staff), isTrue);
    });
  });
}
