import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/datasources/admin_tutorial_data.dart';
import 'package:lambac_app/features/onboarding/data/datasources/admin_tutorial_local_datasource.dart';
import 'package:lambac_app/features/onboarding/data/models/admin_tutorial_step_model.dart';
import 'package:lambac_app/features/onboarding/data/repositories/admin_tutorial_repository_impl.dart';
import 'package:lambac_app/features/onboarding/presentation/providers/admin_tutorial_provider.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Administrator & BI Interactive Tutorial Unit Tests', () {
    late StorageService storageService;
    late AdminTutorialLocalDataSource localDataSource;
    late AdminTutorialRepositoryImpl repository;

    setUp(() {
      storageService = InMemoryStorageService();
      localDataSource = AdminTutorialLocalDataSourceImpl(storageService: storageService);
      repository = AdminTutorialRepositoryImpl(localDataSource: localDataSource);
    });

    test('1. Admin Step Catalog completeness: All 22 executive steps are defined across 14 chapters', () {
      final steps = repository.getSteps();
      expect(steps.length, 22);

      // Verify all 14 chapters are covered
      final chapters = steps.map((s) => s.chapter).toSet();
      expect(chapters.contains(AdminTutorialChapter.welcome), isTrue);
      expect(chapters.contains(AdminTutorialChapter.dashboard), isTrue);
      expect(chapters.contains(AdminTutorialChapter.operations), isTrue);
      expect(chapters.contains(AdminTutorialChapter.products), isTrue);
      expect(chapters.contains(AdminTutorialChapter.employees), isTrue);
      expect(chapters.contains(AdminTutorialChapter.pipeline), isTrue);
      expect(chapters.contains(AdminTutorialChapter.descriptive), isTrue);
      expect(chapters.contains(AdminTutorialChapter.forecasting), isTrue);
      expect(chapters.contains(AdminTutorialChapter.prescriptive), isTrue);
      expect(chapters.contains(AdminTutorialChapter.execution), isTrue);
      expect(chapters.contains(AdminTutorialChapter.concierge), isTrue);
      expect(chapters.contains(AdminTutorialChapter.notifications), isTrue);
      expect(chapters.contains(AdminTutorialChapter.account), isTrue);
      expect(chapters.contains(AdminTutorialChapter.guide), isTrue);

      // Verify specific mandatory feature step IDs exist
      expect(steps.any((s) => s.id == 'admin_welcome'), isTrue);
      expect(steps.any((s) => s.id == 'admin_dashboard_kpis'), isTrue);
      expect(steps.any((s) => s.id == 'admin_dashboard_filters'), isTrue);
      expect(steps.any((s) => s.id == 'admin_operations_queue'), isTrue);
      expect(steps.any((s) => s.id == 'admin_product_catalog'), isTrue);
      expect(steps.any((s) => s.id == 'admin_employee_management'), isTrue);
      expect(steps.any((s) => s.id == 'admin_security_roles'), isTrue);
      expect(steps.any((s) => s.id == 'admin_bi_pipeline'), isTrue);
      expect(steps.any((s) => s.id == 'admin_descriptive_analytics'), isTrue);
      expect(steps.any((s) => s.id == 'admin_descriptive_date_ranges'), isTrue);
      expect(steps.any((s) => s.id == 'admin_forecasting_engine'), isTrue);
      expect(steps.any((s) => s.id == 'admin_forecasting_metrics'), isTrue);
      expect(steps.any((s) => s.id == 'admin_insufficient_data'), isTrue);
      expect(steps.any((s) => s.id == 'admin_prescriptive_recommendations'), isTrue);
      expect(steps.any((s) => s.id == 'admin_prescriptive_card_anatomy'), isTrue);
      expect(steps.any((s) => s.id == 'admin_decision_lifecycle'), isTrue);
      expect(steps.any((s) => s.id == 'admin_prescriptive_schedule'), isTrue);
      expect(steps.any((s) => s.id == 'admin_prescriptive_queue_history'), isTrue);
      expect(steps.any((s) => s.id == 'admin_customer_concierge'), isTrue);
      expect(steps.any((s) => s.id == 'admin_notifications_center'), isTrue);
      expect(steps.any((s) => s.id == 'admin_security_settings'), isTrue);
      expect(steps.any((s) => s.id == 'admin_guide_hub_replay'), isTrue);
    });

    test('2. Persistence: AdminTutorialLocalDataSource marks completion and persists version & timestamp', () async {
      expect(await localDataSource.isAdminTutorialCompleted(), isFalse);
      expect(await localDataSource.getAdminTutorialVersion(), isNull);
      expect(await localDataSource.getLastCompletedAt(), isNull);

      await localDataSource.markAdminTutorialCompleted(version: 1);

      expect(await localDataSource.isAdminTutorialCompleted(), isTrue);
      expect(await localDataSource.getAdminTutorialVersion(), 1);
      expect(await localDataSource.getLastCompletedAt(), isNotNull);

      // Reset
      await localDataSource.resetAdminTutorial();
      expect(await localDataSource.isAdminTutorialCompleted(), isFalse);
    });

    test('3. State Notifier: Executive tour navigation, chapter jumping, skip, complete, and replay flow', () async {
      final notifier = AdminTutorialNotifier(repository: repository);
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

      // Jump to Step (Step 8: BI Pipeline, 0-indexed = 7)
      notifier.goToStep(7);
      expect(notifier.state.currentStepIndex, 7);
      expect(notifier.state.currentStep?.id, 'admin_bi_pipeline');

      // Jump to Chapter
      notifier.goToChapter(AdminTutorialChapter.forecasting);
      expect(notifier.state.currentStep?.chapter, AdminTutorialChapter.forecasting);

      // Previous Step
      notifier.previousStep();
      expect(notifier.state.currentStepIndex, 9);
      expect(notifier.state.currentStep?.id, 'admin_descriptive_date_ranges');

      // Complete Tour
      await notifier.completeTutorial();
      expect(notifier.state.isCompleted, isTrue);
      expect(await localDataSource.isAdminTutorialCompleted(), isTrue);

      // Start Replay
      notifier.startReplay(startStep: 4);
      expect(notifier.state.hasStartedTour, isTrue);
      expect(notifier.state.currentStepIndex, 4);
    });

    test('4. Security & Role Isolation: Validates admin user eligibility', () {
      const adminUser = UserModel(
        id: 'adm_1',
        email: 'admin@lambac.com',
        fullName: 'Admin User',
        role: UserRole.admin,
      );

      const staffUser = UserModel(
        id: 'stf_1',
        email: 'staff@lambac.com',
        fullName: 'Staff User',
        role: UserRole.employee,
      );

      const customerUser = UserModel(
        id: 'cst_1',
        email: 'cust@lambac.com',
        fullName: 'Customer User',
        role: UserRole.customer,
      );

      final notifier = AdminTutorialNotifier(repository: repository);
      expect(notifier.isRoleEligible(adminUser), isTrue);
      expect(notifier.isRoleEligible(staffUser), isFalse);
      expect(notifier.isRoleEligible(customerUser), isFalse);
      expect(notifier.isRoleEligible(null), isFalse);
    });
  });
}
