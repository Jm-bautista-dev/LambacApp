import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/customer_tutorial_data.dart';
import 'package:lambac_app/features/onboarding/data/datasources/tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/data/models/tutorial_category.dart';
import 'package:lambac_app/features/onboarding/data/repositories/tutorial_repository_impl.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/tutorial_provider.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Customer Interactive Tutorial & Guided Onboarding Unit Tests', () {
    late StorageService storageService;
    late TutorialLocalDataSource localDataSource;
    late TutorialRepositoryImpl repository;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = TutorialLocalDataSourceImpl(storageService: storageService);
      repository = TutorialRepositoryImpl(localDataSource: localDataSource);
    });

    test('1. Step Catalog completeness: All 20 customer features are defined with rich metadata', () {
      final steps = repository.getSteps();
      expect(steps.length, 20);

      // Verify categories covered
      final categories = steps.map((s) => s.category).toSet();
      expect(categories.contains(TutorialCategory.welcome), isTrue);
      expect(categories.contains(TutorialCategory.navigation), isTrue);
      expect(categories.contains(TutorialCategory.menu), isTrue);
      expect(categories.contains(TutorialCategory.ordering), isTrue);
      expect(categories.contains(TutorialCategory.pickup), isTrue);
      expect(categories.contains(TutorialCategory.tracking), isTrue);
      expect(categories.contains(TutorialCategory.concierge), isTrue);
      expect(categories.contains(TutorialCategory.account), isTrue);

      // Verify specific mandatory feature steps exist
      expect(steps.any((s) => s.id == 'welcome_identity'), isTrue);
      expect(steps.any((s) => s.id == 'guest_auth_model'), isTrue);
      expect(steps.any((s) => s.id == 'app_navigation'), isTrue);
      expect(steps.any((s) => s.id == 'home_experience'), isTrue);
      expect(steps.any((s) => s.id == 'menu_catalog'), isTrue);
      expect(steps.any((s) => s.id == 'product_details'), isTrue);
      expect(steps.any((s) => s.id == 'customizations_grind'), isTrue);
      expect(steps.any((s) => s.id == 'add_to_cart_flow'), isTrue);
      expect(steps.any((s) => s.id == 'cart_management'), isTrue);
      expect(steps.any((s) => s.id == 'pickup_only_model'), isTrue);
      expect(steps.any((s) => s.id == 'pickup_scheduling'), isTrue);
      expect(steps.any((s) => s.id == 'pay_at_counter'), isTrue);
      expect(steps.any((s) => s.id == 'order_lifecycle'), isTrue);
      expect(steps.any((s) => s.id == 'order_tracking_receipts'), isTrue);
      expect(steps.any((s) => s.id == 'notification_center'), isTrue);
      expect(steps.any((s) => s.id == 'barista_concierge_chat'), isTrue);
      expect(steps.any((s) => s.id == 'ai_customer_assistant'), isTrue);
      expect(steps.any((s) => s.id == 'reviews_and_ratings'), isTrue);
      expect(steps.any((s) => s.id == 'member_profile_rewards'), isTrue);
      expect(steps.any((s) => s.id == 'help_replay_access'), isTrue);
    });

    test('2. Persistence: LocalDataSource marks completion and stores version & timestamp', () async {
      expect(await localDataSource.isTutorialCompleted(), isFalse);
      expect(await localDataSource.getTutorialVersion(), isNull);
      expect(await localDataSource.getLastCompletedAt(), isNull);

      await localDataSource.markTutorialCompleted(version: 1);

      expect(await localDataSource.isTutorialCompleted(), isTrue);
      expect(await localDataSource.getTutorialVersion(), 1);
      expect(await localDataSource.getLastCompletedAt(), isNotNull);

      // Reset
      await localDataSource.resetTutorial();
      expect(await localDataSource.isTutorialCompleted(), isFalse);
    });

    test('3. State Notifier: Step navigation, skip, complete, and replay flow', () async {
      final notifier = TutorialNotifier(repository: repository);
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
      notifier.goToStep(10);
      expect(notifier.state.currentStepIndex, 10);

      // Previous Step
      notifier.previousStep();
      expect(notifier.state.currentStepIndex, 9);

      // Replay Mode
      notifier.startReplay(startStep: 5);
      expect(notifier.state.isReplayMode, isTrue);
      expect(notifier.state.currentStepIndex, 5);

      // Complete Tutorial
      await notifier.completeTutorial();
      expect(notifier.state.isCompleted, isTrue);
      expect(notifier.state.hasStartedTour, isFalse);
      expect(notifier.state.isReplayMode, isFalse);
      expect(await repository.getTutorialState().then((s) => s.isCompleted), isTrue);
    });

    test('4. Role Eligibility: Customer and Guests are eligible; Staff & Admin are strictly excluded', () {
      final notifier = TutorialNotifier(repository: repository);

      // Guest User (null or isGuest)
      expect(notifier.isRoleEligible(null), isTrue);
      expect(notifier.isRoleEligible(UserModel.guest()), isTrue);

      // Customer User
      const customer = UserModel(
        id: 'cust_01',
        email: 'customer@example.com',
        fullName: 'Jane Customer',
        role: UserRole.customer,
      );
      expect(notifier.isRoleEligible(customer), isTrue);

      // Staff User -> Forbidden
      const staff = UserModel(
        id: 'staff_01',
        email: 'staff@lambac.ph',
        fullName: 'Bob Barista',
        role: UserRole.employee,
      );
      expect(notifier.isRoleEligible(staff), isFalse);

      // Admin User -> Forbidden
      const admin = UserModel(
        id: 'admin_01',
        email: 'admin@lambac.ph',
        fullName: 'Alice Admin',
        role: UserRole.admin,
      );
      expect(notifier.isRoleEligible(admin), isFalse);
    });
  });
}
