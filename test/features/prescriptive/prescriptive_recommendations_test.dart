import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/prescriptive/data/datasources/mock_prescriptive_remote_datasource.dart';
import 'package:lambac_app/features/prescriptive/data/datasources/prescriptive_remote_datasource.dart';
import 'package:lambac_app/features/prescriptive/data/models/prescriptive_action_model.dart';
import 'package:lambac_app/features/prescriptive/data/models/prescriptive_recommendation_model.dart';
import 'package:lambac_app/features/prescriptive/data/repositories/prescriptive_repository_impl.dart';

void main() {
  group('Prescriptive Recommendations & Action Management Unit Tests', () {
    late MockPrescriptiveRemoteDataSource remoteDataSource;
    late PrescriptiveRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockPrescriptiveRemoteDataSource();
      remoteDataSource.reset();
      repository = PrescriptiveRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('getRecommendations returns actionable recommendations with data-driven explainability', () async {
      final result = await repository.getRecommendations();

      expect(result.isSuccess, isTrue);
      final recommendations = result.dataOrNull!;
      expect(recommendations.isNotEmpty, isTrue);

      final prepRec = recommendations.firstWhere((r) => r.category == RecommendationCategory.preparation);
      expect(prepRec.title, contains('Mount Apo Anaerobic'));
      expect(prepRec.explanation, contains('Forecasted daily demand'));
      expect(prepRec.supportingMetric, contains('27.4%'));
      expect(prepRec.priority, equals(RecommendationPriority.high));
      expect(prepRec.actionText, equals('Schedule Roast Batch'));
      expect(prepRec.actionType, equals(PrescriptiveActionType.roastBatch));
    });

    test('createAction creates persistent action record with unique ID and initial audit log', () async {
      final request = CreatePrescriptiveActionRequest(
        recommendationId: 'rec_test_01',
        actionType: PrescriptiveActionType.roastBatch,
        classification: ActionClassification.scheduled,
        priority: RecommendationPriority.high,
        title: 'Roast Batch: Mount Apo Anaerobic Micro-Lots',
        description: 'Prepare 12 bags batch',
        targetProductId: 'prod_mt_apo',
        targetProductName: 'Mount Apo Anaerobic Micro-Lot',
        targetQuantity: 12,
        targetUnit: 'bags',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Admin Lead',
        assignedTo: 'Hiro (Head Roaster)',
        notes: 'Agtron 58 Medium Roast profile',
        supportingMetric: 'Forecasted demand: 15.8 bags/day (+27.4%)',
        evidenceRationale: 'High 14-day velocity and customer reviews',
      );

      final result = await repository.createAction(request);

      expect(result.isSuccess, isTrue);
      final action = result.dataOrNull!;
      expect(action.id, startsWith('act_'));
      expect(action.status, equals(PrescriptiveActionStatus.scheduled));
      expect(action.targetQuantity, equals(12));
      expect(action.targetUnit, equals('bags'));
      expect(action.assignedTo, equals('Hiro (Head Roaster)'));
      expect(action.auditLogs.isNotEmpty, isTrue);
      expect(action.auditLogs.first.toStatus, equals(PrescriptiveActionStatus.scheduled));
      expect(action.auditLogs.first.changedBy, equals('Admin Lead'));
    });

    test('createAction enforces idempotency against duplicate submissions', () async {
      final request = CreatePrescriptiveActionRequest(
        recommendationId: 'rec_idempotent_01',
        actionType: PrescriptiveActionType.restockRawBeans,
        classification: ActionClassification.queue,
        priority: RecommendationPriority.medium,
        title: 'Restock Raw Beans',
        description: 'Restock beans',
        targetQuantity: 25,
        targetUnit: 'kg',
        supportingMetric: 'Depletion rate: 4.2 kg/day',
        evidenceRationale: 'Sales velocity spike',
      );

      final firstResult = await repository.createAction(request);
      final secondResult = await repository.createAction(request);

      expect(firstResult.isSuccess, isTrue);
      expect(secondResult.isSuccess, isTrue);
      expect(firstResult.dataOrNull!.id, equals(secondResult.dataOrNull!.id));
    });

    test('status lifecycle transition: SCHEDULED -> IN_PROGRESS -> COMPLETED with audit logs', () async {
      final createResult = await repository.createAction(
        CreatePrescriptiveActionRequest(
          recommendationId: 'rec_lifecycle_01',
          actionType: PrescriptiveActionType.roastBatch,
          classification: ActionClassification.scheduled,
          priority: RecommendationPriority.high,
          title: 'Roast Lifecycle Batch',
          description: 'Test batch lifecycle',
          targetQuantity: 15,
          targetUnit: 'bags',
          supportingMetric: '+25% demand',
          evidenceRationale: 'Forecast test',
        ),
      );

      final actionId = createResult.dataOrNull!.id;

      // 1. Transition to IN_PROGRESS
      final startResult = await repository.updateActionStatus(
        actionId,
        const UpdateActionStatusRequest(
          toStatus: PrescriptiveActionStatus.inProgress,
          changedBy: 'Hiro (Roaster)',
          note: 'Started Diedrich IR-12 preheat',
        ),
      );

      expect(startResult.isSuccess, isTrue);
      expect(startResult.dataOrNull!.status, equals(PrescriptiveActionStatus.inProgress));
      expect(startResult.dataOrNull!.auditLogs.length, equals(2));

      // 2. Transition to COMPLETED
      final completeResult = await repository.updateActionStatus(
        actionId,
        const UpdateActionStatusRequest(
          toStatus: PrescriptiveActionStatus.completed,
          changedBy: 'Hiro (Roaster)',
          note: 'Roast finished and packaged',
        ),
      );

      expect(completeResult.isSuccess, isTrue);
      final completed = completeResult.dataOrNull!;
      expect(completed.status, equals(PrescriptiveActionStatus.completed));
      expect(completed.completedAt, isNotNull);
      expect(completed.auditLogs.length, equals(3));
      expect(completed.auditLogs.last.toStatus, equals(PrescriptiveActionStatus.completed));
      expect(completed.auditLogs.last.note, contains('finished and packaged'));
    });

    test('rescheduleAction updates scheduled time and appends audit log', () async {
      final createResult = await repository.createAction(
        CreatePrescriptiveActionRequest(
          recommendationId: 'rec_resched_01',
          actionType: PrescriptiveActionType.menuPromotion,
          classification: ActionClassification.scheduled,
          priority: RecommendationPriority.low,
          title: 'Launch Decaf Promotion',
          description: 'Promote decaf',
          targetQuantity: 1,
          targetUnit: 'campaign',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
          supportingMetric: '8 units in 14 days',
          evidenceRationale: 'Promo test',
        ),
      );

      final actionId = createResult.dataOrNull!.id;
      final newDate = DateTime.now().add(const Duration(days: 5));

      final reschedResult = await repository.rescheduleAction(
        actionId,
        newDate,
        'Shifted for holiday launch',
        'Admin Lead',
      );

      expect(reschedResult.isSuccess, isTrue);
      final rescheduled = reschedResult.dataOrNull!;
      expect(rescheduled.scheduledAt, equals(newDate));
      expect(rescheduled.auditLogs.last.note, contains('Shifted for holiday launch'));
    });

    test('cancelAction updates status to cancelled with reason and timestamp', () async {
      final createResult = await repository.createAction(
        CreatePrescriptiveActionRequest(
          recommendationId: 'rec_cancel_01',
          actionType: PrescriptiveActionType.restockRawBeans,
          classification: ActionClassification.queue,
          priority: RecommendationPriority.medium,
          title: 'Restock Robusta',
          description: 'Restock test',
          targetQuantity: 50,
          targetUnit: 'kg',
          supportingMetric: 'Depletion rate',
          evidenceRationale: 'Cancel test',
        ),
      );

      final actionId = createResult.dataOrNull!.id;

      final cancelResult = await repository.cancelAction(
        actionId,
        'Supplier out of stock',
        'Inventory Admin',
      );

      expect(cancelResult.isSuccess, isTrue);
      final cancelled = cancelResult.dataOrNull!;
      expect(cancelled.status, equals(PrescriptiveActionStatus.cancelled));
      expect(cancelled.cancelledAt, isNotNull);
      expect(cancelled.auditLogs.last.toStatus, equals(PrescriptiveActionStatus.cancelled));
      expect(cancelled.auditLogs.last.note, contains('Supplier out of stock'));
    });
  });
}
