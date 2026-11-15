import 'dart:async';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../notifications/data/datasources/mock_notification_remote_datasource.dart';
import '../../../notifications/data/models/app_notification_model.dart';
import '../../../products/data/datasources/mock_product_remote_datasource.dart';
import '../../../sales/data/datasources/mock_sales_remote_datasource.dart';
import '../../../sales/data/models/sales_channel.dart';
import '../models/prescriptive_action_model.dart';
import '../models/prescriptive_recommendation_model.dart';
import 'prescriptive_remote_datasource.dart';

/// Dynamic, Evidence-Backed Prescriptive Decision Support & Action Execution Store
/// Manages realistic state transitions, persistent action schedules, queue, history, and audit trails.
class MockPrescriptiveRemoteDataSource implements PrescriptiveRemoteDataSource {
  static final MockPrescriptiveRemoteDataSource _instance =
      MockPrescriptiveRemoteDataSource._internal();
  factory MockPrescriptiveRemoteDataSource() => _instance;

  final MockSalesRemoteDataSource _salesDataSource = MockSalesRemoteDataSource();
  final MockProductRemoteDataSource _productDataSource = MockProductRemoteDataSource();

  final List<PrescriptiveRecommendationModel> _recommendations = [];
  final Map<String, PrescriptiveActionModel> _actions = {};
  int _actionCounter = 1000;

  MockPrescriptiveRemoteDataSource._internal() {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();

    // 1. Seed historical and active action records for an authentic operational roastery workflow
    final seedActions = [
      PrescriptiveActionModel(
        id: 'act_1001',
        recommendationId: 'rec_seed_history_01',
        actionType: PrescriptiveActionType.roastBatch,
        classification: ActionClassification.scheduled,
        status: PrescriptiveActionStatus.completed,
        priority: RecommendationPriority.high,
        title: 'Roast Batch: Mount Apo Anaerobic Micro-Lots',
        description: 'Roasting 15 kg (12 bags) micro-lot profile at Roaster 1',
        targetProductId: 'prod_mt_apo',
        targetProductName: 'Mount Apo Anaerobic Micro-Lot',
        targetQuantity: 12,
        targetUnit: 'bags',
        scheduledAt: now.subtract(const Duration(days: 2, hours: 4)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2, hours: 2)),
        completedAt: now.subtract(const Duration(days: 2, hours: 2)),
        createdBy: 'Admin (Hiro Roastery Lead)',
        assignedTo: 'Barista Hiro (Head Roaster)',
        notes: 'Target Agtron 58 Medium Roast. Cupping score 88.5 verified.',
        supportingMetric: 'Forecasted demand: 15.8 bags/day (+27.4%)',
        evidenceRationale: '14-day sales velocity spiked following weekend tasting event.',
        auditLogs: [
          ActionAuditLogModel(
            id: 'log_seed_01',
            fromStatus: null,
            toStatus: PrescriptiveActionStatus.scheduled,
            changedBy: 'Admin (Hiro)',
            timestamp: now.subtract(const Duration(days: 3)),
            note: 'Action scheduled following ML demand spike forecast',
          ),
          ActionAuditLogModel(
            id: 'log_seed_02',
            fromStatus: PrescriptiveActionStatus.scheduled,
            toStatus: PrescriptiveActionStatus.inProgress,
            changedBy: 'Hiro (Roaster)',
            timestamp: now.subtract(const Duration(days: 2, hours: 4)),
            note: 'Preheating Diedrich IR-12 drum to 200°C',
          ),
          ActionAuditLogModel(
            id: 'log_seed_03',
            fromStatus: PrescriptiveActionStatus.inProgress,
            toStatus: PrescriptiveActionStatus.completed,
            changedBy: 'Hiro (Roaster)',
            timestamp: now.subtract(const Duration(days: 2, hours: 2)),
            note: 'Roast profile executed perfectly in 11m 42s. Packaged and sealed.',
          ),
        ],
      ),
      PrescriptiveActionModel(
        id: 'act_1002',
        recommendationId: 'rec_seed_history_02',
        actionType: PrescriptiveActionType.restockRawBeans,
        classification: ActionClassification.queue,
        status: PrescriptiveActionStatus.completed,
        priority: RecommendationPriority.medium,
        title: 'Restock Raw Green Beans: Benguet Typica',
        description: 'PO issued to Benguet Highland Farmers Cooperative for 60 kg green beans',
        targetProductId: 'prod_benguet_typica',
        targetProductName: 'Benguet Highland Typica',
        targetQuantity: 60,
        targetUnit: 'kg',
        scheduledAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 14)),
        completedAt: now.subtract(const Duration(hours: 14)),
        createdBy: 'Admin (Inventory Manager)',
        assignedTo: 'Station Lead Marco',
        notes: 'Received moisture level 10.8%. Grade 1 Arabica.',
        supportingMetric: 'Depletion rate: 4.2 kg/day (~5 days inventory remaining)',
        evidenceRationale: 'High depletion velocity across walk-in espresso orders.',
        auditLogs: [
          ActionAuditLogModel(
            id: 'log_seed_04',
            fromStatus: null,
            toStatus: PrescriptiveActionStatus.queued,
            changedBy: 'Admin',
            timestamp: now.subtract(const Duration(days: 2)),
            note: 'Queued automated restocking PO',
          ),
          ActionAuditLogModel(
            id: 'log_seed_05',
            fromStatus: PrescriptiveActionStatus.queued,
            toStatus: PrescriptiveActionStatus.completed,
            changedBy: 'Marco (Station Lead)',
            timestamp: now.subtract(const Duration(hours: 14)),
            note: '60 kg delivered to roastery warehouse and inspected.',
          ),
        ],
      ),
      PrescriptiveActionModel(
        id: 'act_1003',
        recommendationId: 'rec_seed_sched_01',
        actionType: PrescriptiveActionType.roastBatch,
        classification: ActionClassification.scheduled,
        status: PrescriptiveActionStatus.scheduled,
        priority: RecommendationPriority.high,
        title: 'Roast Batch: Tokyo Kissaten Dark Roast Blend',
        description: 'Batch roasting 20 bags for weekend espresso bar staging',
        targetProductId: 'prod_tokyo_kissaten',
        targetProductName: 'Tokyo Kissaten Signature Blend',
        targetQuantity: 20,
        targetUnit: 'bags',
        scheduledAt: DateTime(now.year, now.month, now.day, 14, 0), // Today 2:00 PM
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        createdBy: 'Admin',
        assignedTo: 'Hiro (Head Roaster)',
        notes: 'Japanese Slow-Drip Dark Roast profile with heavy crema oil development.',
        supportingMetric: 'Projected demand: 18.2 bags/day (+31.5%)',
        evidenceRationale: 'Peak afternoon walk-in espresso demand spike.',
        auditLogs: [
          ActionAuditLogModel(
            id: 'log_seed_06',
            fromStatus: null,
            toStatus: PrescriptiveActionStatus.scheduled,
            changedBy: 'Admin',
            timestamp: now.subtract(const Duration(hours: 4)),
            note: 'Scheduled batch for today 2:00 PM shift',
          ),
        ],
      ),
      PrescriptiveActionModel(
        id: 'act_1004',
        recommendationId: 'rec_seed_sched_02',
        actionType: PrescriptiveActionType.menuPromotion,
        classification: ActionClassification.scheduled,
        status: PrescriptiveActionStatus.scheduled,
        priority: RecommendationPriority.low,
        title: 'Launch Menu Promotion: Swiss Water Decaf Feature',
        description: 'Digital feature discount (15% off) on mobile app pour-over menu',
        targetProductId: 'prod_swiss_decaf',
        targetProductName: 'Swiss Water Process Decaf',
        targetQuantity: 1,
        targetUnit: 'campaign',
        scheduledAt: DateTime(now.year, now.month, now.day + 2, 9, 0), // 2 days from now 9:00 AM
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        createdBy: 'Admin (Marketing)',
        assignedTo: 'App Content Team',
        notes: 'Target evening / decaf coffee lovers on Lambac mobile app.',
        supportingMetric: '14-Day Sales: 8 units (Underutilized inventory)',
        evidenceRationale: 'Increasing turnaround speed on decaf micro-lots.',
        auditLogs: [
          ActionAuditLogModel(
            id: 'log_seed_07',
            fromStatus: null,
            toStatus: PrescriptiveActionStatus.scheduled,
            changedBy: 'Admin (Marketing)',
            timestamp: now.subtract(const Duration(hours: 6)),
            note: 'Scheduled campaign launch for upcoming Tuesday',
          ),
        ],
      ),
    ];

    for (final action in seedActions) {
      _actions[action.id] = action;
    }
  }

  /// Reset in-memory database (useful for integration testing)
  void reset() {
    _recommendations.clear();
    _actions.clear();
    _actionCounter = 1000;
    _seedInitialData();
  }

  @override
  Future<Result<List<PrescriptiveRecommendationModel>, AppFailure>> getRecommendations() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));

    final allSales = _salesDataSource.getAllSales(includeVoided: false);
    final now = DateTime.now();

    final generated = <PrescriptiveRecommendationModel>[];
    int recCounter = 1;

    if (allSales.isEmpty) {
      final rec = PrescriptiveRecommendationModel(
        id: 'rec_baseline_01',
        title: 'Initialize Store Sales Data Pipeline',
        explanation:
            'No completed sales have been recorded in the centralized ledger. Fulfill customer mobile pickup orders to unlock automated prescriptive intelligence.',
        supportingMetric: '0 transactions in sales ledger',
        priority: RecommendationPriority.high,
        category: RecommendationCategory.productPerformance,
        generatedAt: now,
        actionText: 'View Order Queue',
        actionType: PrescriptiveActionType.operationalWorkflow,
        actionClassification: ActionClassification.immediate,
      );
      return Result.success([rec]);
    }

    // Analyze recent 14-day sales performance
    final recentStart = now.subtract(const Duration(days: 14));
    final recentSales = allSales.where((s) => s.createdAt.isAfter(recentStart)).toList();

    final productTotals = <String, ({String name, int qty, double revenue})>{};
    for (final sale in recentSales) {
      for (final item in sale.items) {
        final existing = productTotals[item.productId];
        if (existing != null) {
          productTotals[item.productId] = (
            name: item.productName,
            qty: existing.qty + item.quantity,
            revenue: existing.revenue + item.totalPrice,
          );
        } else {
          productTotals[item.productId] = (
            name: item.productName,
            qty: item.quantity,
            revenue: item.totalPrice,
          );
        }
      }
    }

    final totalRecentRevenue = recentSales.fold(0.0, (sum, s) => sum + s.totalAmount);

    // 1. Top Grossing Bean -> Preparation & Roast Capacity Recommendation (High Priority)
    if (productTotals.isNotEmpty) {
      final sortedProducts = productTotals.entries.toList()
        ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));

      final topProduct = sortedProducts.first;
      final topPct = totalRecentRevenue > 0
          ? ((topProduct.value.revenue / totalRecentRevenue) * 100).toStringAsFixed(1)
          : '0.0';

      final recId = 'rec_${recCounter++}';
      final linkedAction = _findActiveActionForRecommendation(recId);

      generated.add(
        PrescriptiveRecommendationModel(
          id: recId,
          title: 'Prepare Additional ${topProduct.value.name} Micro-Lots',
          explanation:
              'Forecasted daily demand indicates ${topProduct.value.name} is the top revenue generator, contributing ₱${topProduct.value.revenue.toStringAsFixed(2)} across ${topProduct.value.qty} units sold ($topPct% of 14-day sales). Increasing batch roasting capacity will prevent stock depletion.',
          supportingMetric: 'Forecasted demand: ${topProduct.value.qty} bags (+27.4%)',
          priority: RecommendationPriority.high,
          category: RecommendationCategory.preparation,
          generatedAt: now.subtract(const Duration(hours: 1)),
          actionText: 'Schedule Roast Batch',
          relatedProductId: topProduct.key,
          targetProductName: topProduct.value.name,
          actionType: PrescriptiveActionType.roastBatch,
          actionClassification: ActionClassification.scheduled,
          suggestedQuantity: 12,
          suggestedUnit: 'bags',
          actionStatus: linkedAction != null
              ? (linkedAction.status == PrescriptiveActionStatus.completed
                  ? RecommendationActionStatus.actionCompleted
                  : RecommendationActionStatus.actionScheduled)
              : RecommendationActionStatus.pending,
          linkedActionId: linkedAction?.id,
          linkedActionScheduledAt: linkedAction?.scheduledAt,
        ),
      );

      // 2. High Velocity -> Inventory Restocking Recommendation (Medium/High Priority)
      if (sortedProducts.length > 1) {
        final secondProduct = sortedProducts[1];
        final dailyVelocity = secondProduct.value.qty / 14.0;
        final estimatedDaysLeft = (25 / (dailyVelocity > 0 ? dailyVelocity : 1.0)).round();

        final rec2Id = 'rec_${recCounter++}';
        final linked2Action = _findActiveActionForRecommendation(rec2Id);

        generated.add(
          PrescriptiveRecommendationModel(
            id: rec2Id,
            title: 'Replenish Raw Beans for ${secondProduct.value.name}',
            explanation:
                'Sales velocity for ${secondProduct.value.name} is ${dailyVelocity.toStringAsFixed(1)} bags/day (${secondProduct.value.qty} bags in 14 days). Projected stockout in ~$estimatedDaysLeft days without reordering.',
            supportingMetric:
                'Depletion rate: ${dailyVelocity.toStringAsFixed(1)} bags/day (~$estimatedDaysLeft days left)',
            priority: estimatedDaysLeft <= 10
                ? RecommendationPriority.high
                : RecommendationPriority.medium,
            category: RecommendationCategory.inventory,
            generatedAt: now.subtract(const Duration(hours: 3)),
            actionText: 'Order Raw Beans',
            relatedProductId: secondProduct.key,
            targetProductName: secondProduct.value.name,
            actionType: PrescriptiveActionType.restockRawBeans,
            actionClassification: ActionClassification.queue,
            suggestedQuantity: 25,
            suggestedUnit: 'kg',
            actionStatus: linked2Action != null
                ? (linked2Action.status == PrescriptiveActionStatus.completed
                    ? RecommendationActionStatus.actionCompleted
                    : RecommendationActionStatus.actionQueued)
                : RecommendationActionStatus.pending,
            linkedActionId: linked2Action?.id,
            linkedActionScheduledAt: linked2Action?.scheduledAt,
          ),
        );
      }

      // 3. Lowest Volume Product -> Menu & Promotion Recommendation (Low Priority)
      final lowestProduct = sortedProducts.last;
      if (lowestProduct.key != topProduct.key) {
        final rec3Id = 'rec_${recCounter++}';
        final linked3Action = _findActiveActionForRecommendation(rec3Id);

        generated.add(
          PrescriptiveRecommendationModel(
            id: rec3Id,
            title: 'Feature ${lowestProduct.value.name} in Digital Promos',
            explanation:
                '${lowestProduct.value.name} recorded only ${lowestProduct.value.qty} units sold (₱${lowestProduct.value.revenue.toStringAsFixed(2)}) over the past 14 days. Introducing barista pour-over recommendations or bundle pairings will improve stock turnaround.',
            supportingMetric: '14-Day Sales: ${lowestProduct.value.qty} units sold',
            priority: RecommendationPriority.low,
            category: RecommendationCategory.promotion,
            generatedAt: now.subtract(const Duration(hours: 6)),
            actionText: 'Launch Promotion',
            relatedProductId: lowestProduct.key,
            targetProductName: lowestProduct.value.name,
            actionType: PrescriptiveActionType.menuPromotion,
            actionClassification: ActionClassification.scheduled,
            suggestedQuantity: 1,
            suggestedUnit: 'campaign',
            actionStatus: linked3Action != null
                ? (linked3Action.status == PrescriptiveActionStatus.completed
                    ? RecommendationActionStatus.actionCompleted
                    : RecommendationActionStatus.actionScheduled)
                : RecommendationActionStatus.pending,
            linkedActionId: linked3Action?.id,
            linkedActionScheduledAt: linked3Action?.scheduledAt,
          ),
        );
      }
    }

    // 4. Mobile Pickup Staging Optimization
    final mobileSales = recentSales.where((s) => s.channel == SalesChannel.mobileApp);
    final mobileRevenue = mobileSales.fold(0.0, (acc, s) => acc + s.totalAmount);

    if (totalRecentRevenue > 0) {
      final mobilePct = (mobileRevenue / totalRecentRevenue) * 100;

      final rec4Id = 'rec_${recCounter++}';
      final linked4Action = _findActiveActionForRecommendation(rec4Id);

      generated.add(
        PrescriptiveRecommendationModel(
          id: rec4Id,
          title: 'Streamline Mobile Pickup Staging Shelves',
          explanation:
              'Mobile in-app pickup orders account for ${mobilePct.toStringAsFixed(1)}% of revenue (₱${mobileRevenue.toStringAsFixed(2)}). Keep order pickup bags clearly tagged with customer names for rapid handover.',
          supportingMetric: 'Mobile Pickup: ${mobilePct.toStringAsFixed(1)}% of total revenue',
          priority: RecommendationPriority.medium,
          category: RecommendationCategory.productPerformance,
          generatedAt: now.subtract(const Duration(hours: 8)),
          actionText: 'Audit Pickup Shelf',
          actionType: PrescriptiveActionType.operationalWorkflow,
          actionClassification: ActionClassification.immediate,
          suggestedQuantity: 1,
          suggestedUnit: 'audit session',
          actionStatus: linked4Action != null
              ? (linked4Action.status == PrescriptiveActionStatus.completed
                  ? RecommendationActionStatus.actionCompleted
                  : RecommendationActionStatus.actionScheduled)
              : RecommendationActionStatus.pending,
          linkedActionId: linked4Action?.id,
          linkedActionScheduledAt: linked4Action?.scheduledAt,
        ),
      );
    }

    _recommendations.clear();
    _recommendations.addAll(generated);

    return Result.success(List.unmodifiable(_recommendations));
  }

  PrescriptiveActionModel? _findActiveActionForRecommendation(String recId) {
    for (final action in _actions.values) {
      if (action.recommendationId == recId &&
          action.status != PrescriptiveActionStatus.cancelled &&
          action.status != PrescriptiveActionStatus.skipped) {
        return action;
      }
    }
    return null;
  }

  @override
  Future<Result<List<PrescriptiveActionModel>, AppFailure>> getActions({
    PrescriptiveActionStatus? status,
    ActionClassification? classification,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));

    var list = _actions.values.toList();

    if (status != null) {
      list = list.where((a) => a.status == status).toList();
    }
    if (classification != null) {
      list = list.where((a) => a.classification == classification).toList();
    }

    // Sort by scheduledAt / createdAt descending
    list.sort((a, b) {
      final aDate = a.scheduledAt ?? a.createdAt;
      final bDate = b.scheduledAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return Result.success(List.unmodifiable(list));
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> getActionById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final action = _actions[id];
    if (action == null) {
      return Result.failure(NotFoundFailure(message: 'Prescriptive action #$id not found.'));
    }
    return Result.success(action);
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> createAction(
    CreatePrescriptiveActionRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Idempotency check: prevent duplicate active actions for the same recommendation
    final existing = _findActiveActionForRecommendation(request.recommendationId);
    if (existing != null &&
        (existing.status == PrescriptiveActionStatus.scheduled ||
            existing.status == PrescriptiveActionStatus.queued ||
            existing.status == PrescriptiveActionStatus.inProgress)) {
      return Result.success(existing);
    }

    final now = DateTime.now();
    final newId = 'act_${++_actionCounter}';

    final initialStatus = request.classification == ActionClassification.queue
        ? PrescriptiveActionStatus.queued
        : (request.classification == ActionClassification.immediate
            ? PrescriptiveActionStatus.inProgress
            : PrescriptiveActionStatus.scheduled);

    final initialLog = ActionAuditLogModel(
      id: 'log_${newId}_01',
      fromStatus: null,
      toStatus: initialStatus,
      changedBy: request.createdBy,
      timestamp: now,
      note: request.notes ?? 'Action initiated from Prescriptive Recommendation',
    );

    final newAction = PrescriptiveActionModel(
      id: newId,
      recommendationId: request.recommendationId,
      actionType: request.actionType,
      classification: request.classification,
      status: initialStatus,
      priority: request.priority,
      title: request.title,
      description: request.description,
      targetProductId: request.targetProductId,
      targetProductName: request.targetProductName,
      targetQuantity: request.targetQuantity,
      targetUnit: request.targetUnit,
      scheduledAt: request.scheduledAt ?? now,
      createdAt: now,
      updatedAt: now,
      createdBy: request.createdBy,
      assignedTo: request.assignedTo,
      notes: request.notes,
      supportingMetric: request.supportingMetric,
      evidenceRationale: request.evidenceRationale,
      auditLogs: [initialLog],
    );

    _actions[newId] = newAction;

    // Send push notification to station staff
    try {
      final notifDs = MockNotificationRemoteDataSource();
      final notif = AppNotificationModel(
        id: 'notif_act_${newId}',
        title: 'Prescriptive Action: ${newAction.title}',
        body:
            '${newAction.targetQuantity} ${newAction.targetUnit} scheduled for ${newAction.scheduledAt != null ? "upcoming shift" : "immediate queue"}.',
        type: NotificationType.orderStatus,
        targetId: newId,
        deepLinkPath: '/admin/business-intelligence',
        createdAt: now,
      );
      notifDs.addNotificationForUser('usr_customer_demo', notif);
      notifDs.addNotificationForUser('usr_lambac_1001', notif);
    } catch (_) {
      // Non-blocking notification emission
    }

    return Result.success(newAction);
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> updateActionStatus(
    String actionId,
    UpdateActionStatusRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final existing = _actions[actionId];
    if (existing == null) {
      return Result.failure(NotFoundFailure(message: 'Action #$actionId not found.'));
    }

    // Status transition validation
    if (existing.status == PrescriptiveActionStatus.completed &&
        request.toStatus != PrescriptiveActionStatus.completed &&
        request.newScheduledAt == null) {
      return const Result.failure(
        BadRequestFailure(
          message: 'Completed action cannot be reverted without a reschedule date.',
        ),
      );
    }

    final now = DateTime.now();
    final logId = 'log_${actionId}_${existing.auditLogs.length + 1}';

    final newLog = ActionAuditLogModel(
      id: logId,
      fromStatus: existing.status,
      toStatus: request.toStatus,
      changedBy: request.changedBy,
      timestamp: now,
      note: request.note,
    );

    final updated = existing.copyWith(
      status: request.toStatus,
      updatedAt: now,
      completedAt: request.toStatus == PrescriptiveActionStatus.completed
          ? (existing.completedAt ?? now)
          : null,
      cancelledAt: request.toStatus == PrescriptiveActionStatus.cancelled
          ? (existing.cancelledAt ?? now)
          : null,
      scheduledAt: request.newScheduledAt ?? existing.scheduledAt,
      auditLogs: [...existing.auditLogs, newLog],
    );

    _actions[actionId] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> rescheduleAction(
    String actionId,
    DateTime newScheduledAt,
    String? reason,
    String changedBy,
  ) async {
    return updateActionStatus(
      actionId,
      UpdateActionStatusRequest(
        toStatus: PrescriptiveActionStatus.scheduled,
        changedBy: changedBy,
        note: reason != null ? 'Rescheduled: $reason' : 'Rescheduled to new date/time',
        newScheduledAt: newScheduledAt,
      ),
    );
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> cancelAction(
    String actionId,
    String? reason,
    String changedBy,
  ) async {
    return updateActionStatus(
      actionId,
      UpdateActionStatusRequest(
        toStatus: PrescriptiveActionStatus.cancelled,
        changedBy: changedBy,
        note: reason != null ? 'Cancelled: $reason' : 'Action cancelled by user',
      ),
    );
  }
}
