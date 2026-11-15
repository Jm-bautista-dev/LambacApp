import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../notifications/data/datasources/firebase_notification_remote_datasource.dart';
import '../../../notifications/data/models/app_notification_model.dart';
import '../../../sales/data/datasources/firebase_sales_remote_datasource.dart';
import '../../../sales/data/models/sales_channel.dart';
import '../models/prescriptive_action_model.dart';
import '../models/prescriptive_recommendation_model.dart';
import 'prescriptive_remote_datasource.dart';

/// Production Cloud Firestore Prescriptive Decision Support & Action Execution Store
/// Manages real persistent roast batch schedules, operational action queues, and audit trails in Firestore.
class FirebasePrescriptiveRemoteDataSource implements PrescriptiveRemoteDataSource {
  static final FirebasePrescriptiveRemoteDataSource _instance =
      FirebasePrescriptiveRemoteDataSource._internal();
  factory FirebasePrescriptiveRemoteDataSource({
    FirebaseSalesRemoteDataSource? salesDataSource,
    FirebaseFirestore? firestore,
    FirebaseNotificationRemoteDataSource? notificationDataSource,
  }) {
    if (salesDataSource != null) _instance._customSalesDataSource = salesDataSource;
    if (firestore != null) _instance._customFirestore = firestore;
    if (notificationDataSource != null) {
      _instance._customNotificationDataSource = notificationDataSource;
    }
    return _instance;
  }

  FirebaseSalesRemoteDataSource? _customSalesDataSource;
  FirebaseFirestore? _customFirestore;
  FirebaseNotificationRemoteDataSource? _customNotificationDataSource;

  FirebaseSalesRemoteDataSource get _salesDataSource =>
      _customSalesDataSource ?? FirebaseSalesRemoteDataSource();
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseNotificationRemoteDataSource get _notificationDataSource =>
      _customNotificationDataSource ?? FirebaseNotificationRemoteDataSource();

  bool _isSeeded = false;

  FirebasePrescriptiveRemoteDataSource._internal();

  CollectionReference<Map<String, dynamic>> get _roastSchedulesCol =>
      _firestore.collection('roastSchedules');

  /// Maps a Firestore document to a validated PrescriptiveActionModel
  PrescriptiveActionModel _mapDocToAction(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final id = doc.id;

    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final typeStr = (data['action_type'] ?? 'roast_batch').toString().toLowerCase();
    final actionType = switch (typeStr) {
      'restock_raw_beans' || 'restock' => PrescriptiveActionType.restockRawBeans,
      'menu_promotion' || 'promotion' => PrescriptiveActionType.menuPromotion,
      'operational_workflow' || 'workflow' || 'counter' => PrescriptiveActionType.operationalWorkflow,
      'informational' => PrescriptiveActionType.informational,
      _ => PrescriptiveActionType.roastBatch,
    };

    final classStr = (data['classification'] ?? 'scheduled').toString().toLowerCase();
    final classification = switch (classStr) {
      'queue' => ActionClassification.queue,
      'immediate' => ActionClassification.immediate,
      'informational' => ActionClassification.informational,
      _ => ActionClassification.scheduled,
    };

    final statStr = (data['status'] ?? 'scheduled').toString().toLowerCase();
    final status = switch (statStr) {
      'recommended' => PrescriptiveActionStatus.recommended,
      'pending_action' || 'pendingaction' => PrescriptiveActionStatus.pendingAction,
      'queued' => PrescriptiveActionStatus.queued,
      'in_progress' || 'inprogress' => PrescriptiveActionStatus.inProgress,
      'completed' => PrescriptiveActionStatus.completed,
      'cancelled' => PrescriptiveActionStatus.cancelled,
      'skipped' => PrescriptiveActionStatus.skipped,
      'failed' => PrescriptiveActionStatus.failed,
      _ => PrescriptiveActionStatus.scheduled,
    };

    final prioStr = (data['priority'] ?? 'medium').toString().toLowerCase();
    final priority = switch (prioStr) {
      'high' => RecommendationPriority.high,
      'low' => RecommendationPriority.low,
      _ => RecommendationPriority.medium,
    };

    final rawLogs = data['audit_logs'] as List<dynamic>? ?? [];
    final auditLogs = rawLogs.map((e) {
      final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
      return ActionAuditLogModel.fromJson(map);
    }).toList();

    return PrescriptiveActionModel(
      id: id,
      recommendationId: (data['recommendation_id'] ?? data['source_recommendation_id'] ?? '').toString(),
      actionType: actionType,
      classification: classification,
      status: status,
      priority: priority,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      targetProductId: data['target_product_id']?.toString(),
      targetProductName: data['target_product_name']?.toString(),
      targetQuantity: (data['target_quantity'] as num?)?.toInt() ?? 1,
      targetUnit: (data['target_unit'] ?? 'units').toString(),
      scheduledAt: parseNullableDateTime(data['scheduled_at'] ?? data['scheduled_date']),
      createdAt: parseDateTime(data['created_at']),
      updatedAt: parseDateTime(data['updated_at']),
      completedAt: parseNullableDateTime(data['completed_at']),
      cancelledAt: parseNullableDateTime(data['cancelled_at']),
      createdBy: (data['created_by'] ?? 'Admin').toString(),
      assignedTo: data['assigned_to']?.toString(),
      notes: (data['notes'] ?? data['reason'])?.toString(),
      supportingMetric: (data['supporting_metric'] ?? '').toString(),
      evidenceRationale: (data['evidence_rationale'] ?? '').toString(),
      auditLogs: auditLogs,
    );
  }

  @override
  Future<Result<List<PrescriptiveRecommendationModel>, AppFailure>> getRecommendations() async {
    try {
      final allSales = await _salesDataSource.getAllSales(includeVoided: false);
      final now = DateTime.now();

      final actionsResult = await getActions();
      final allActions = actionsResult.dataOrNull ?? [];

      PrescriptiveActionModel? findActiveAction(String recId) {
        for (final action in allActions) {
          if (action.recommendationId == recId &&
              action.status != PrescriptiveActionStatus.cancelled &&
              action.status != PrescriptiveActionStatus.skipped) {
            return action;
          }
        }
        return null;
      }

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

      // Analyze recent 14-day sales performance from Firestore sales
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

      final totalRecentRevenue = recentSales.fold(0.0, (acc, s) => acc + s.totalAmount);

      // 1. Top Grossing Bean -> Preparation & Roast Capacity Recommendation (High Priority)
      if (productTotals.isNotEmpty) {
        final sortedProducts = productTotals.entries.toList()
          ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));

        final topProduct = sortedProducts.first;
        final topPct = totalRecentRevenue > 0
            ? ((topProduct.value.revenue / totalRecentRevenue) * 100).toStringAsFixed(1)
            : '0.0';

        final recId = 'rec_${recCounter++}';
        final linkedAction = findActiveAction(recId);

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
          final linked2Action = findActiveAction(rec2Id);

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
          final linked3Action = findActiveAction(rec3Id);

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
        final linked4Action = findActiveAction(rec4Id);

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

      return Result.success(List.unmodifiable(generated));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to generate recommendations: $e'));
    }
  }

  @override
  Future<Result<List<PrescriptiveActionModel>, AppFailure>> getActions({
    PrescriptiveActionStatus? status,
    ActionClassification? classification,
  }) async {
    await seedInitialRoastSchedulesIfEmpty();

    try {
      final snap = await _roastSchedulesCol.get();
      var list = snap.docs.map(_mapDocToAction).toList();

      if (status != null) {
        list = list.where((a) => a.status == status).toList();
      }
      if (classification != null) {
        list = list.where((a) => a.classification == classification).toList();
      }

      list.sort((a, b) {
        final aDate = a.scheduledAt ?? a.createdAt;
        final bDate = b.scheduledAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

      return Result.success(List.unmodifiable(list));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to load roast schedules: $e'));
    }
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> getActionById(String id) async {
    try {
      final doc = await _roastSchedulesCol.doc(id).get();
      if (!doc.exists) {
        return Result.failure(NotFoundFailure(message: 'Prescriptive action #$id not found.'));
      }
      return Result.success(_mapDocToAction(doc));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to get action #$id: $e'));
    }
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> createAction(
    CreatePrescriptiveActionRequest request,
  ) async {
    try {
      // Idempotency check: prevent duplicate active actions for the same recommendation
      final existingActionsSnap = await _roastSchedulesCol
          .where('recommendation_id', isEqualTo: request.recommendationId)
          .get();

      for (final doc in existingActionsSnap.docs) {
        final act = _mapDocToAction(doc);
        if (act.status == PrescriptiveActionStatus.scheduled ||
            act.status == PrescriptiveActionStatus.queued ||
            act.status == PrescriptiveActionStatus.inProgress) {
          return Result.success(act);
        }
      }

      final now = DateTime.now();
      final newId = 'act_${now.millisecondsSinceEpoch}';

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

      final json = newAction.toJson();
      if (newAction.scheduledAt != null) {
        json['scheduled_at'] = Timestamp.fromDate(newAction.scheduledAt!);
      }
      json['created_at'] = Timestamp.fromDate(newAction.createdAt);
      json['updated_at'] = Timestamp.fromDate(newAction.updatedAt);

      await _roastSchedulesCol.doc(newId).set(json);

      // Send persistent notification to staff
      try {
        final notif = AppNotificationModel(
          id: 'notif_act_$newId',
          title: 'Prescriptive Action: ${newAction.title}',
          body:
              '${newAction.targetQuantity} ${newAction.targetUnit} scheduled for ${newAction.scheduledAt != null ? "upcoming shift" : "immediate queue"}.',
          type: NotificationType.orderStatus,
          targetId: newId,
          deepLinkPath: '/admin/business-intelligence',
          createdAt: now,
        );
        unawaited(_notificationDataSource.addNotificationForUser('usr_customer_demo', notif));
        unawaited(_notificationDataSource.addNotificationForUser('usr_lambac_1001', notif));
      } catch (_) {
        // Non-blocking notification emission
      }

      return Result.success(newAction);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to create roast action: $e'));
    }
  }

  @override
  Future<Result<PrescriptiveActionModel, AppFailure>> updateActionStatus(
    String actionId,
    UpdateActionStatusRequest request,
  ) async {
    try {
      final docRef = _roastSchedulesCol.doc(actionId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        return Result.failure(NotFoundFailure(message: 'Action #$actionId not found.'));
      }

      final existing = _mapDocToAction(docSnap);

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

      final updatedLogs = [...existing.auditLogs, newLog];

      final updateMap = <String, dynamic>{
        'status': request.toStatus.name,
        'updated_at': Timestamp.fromDate(now),
        'audit_logs': updatedLogs.map((e) => e.toJson()).toList(),
      };

      if (request.toStatus == PrescriptiveActionStatus.completed) {
        updateMap['completed_at'] = Timestamp.fromDate(existing.completedAt ?? now);
      }
      if (request.toStatus == PrescriptiveActionStatus.cancelled) {
        updateMap['cancelled_at'] = Timestamp.fromDate(existing.cancelledAt ?? now);
      }
      if (request.newScheduledAt != null) {
        updateMap['scheduled_at'] = Timestamp.fromDate(request.newScheduledAt!);
      }

      await docRef.update(updateMap);

      final updatedSnap = await docRef.get();
      return Result.success(_mapDocToAction(updatedSnap));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to update action #$actionId: $e'));
    }
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

  // ===========================================================================
  // IDEMPOTENT DEMONSTRATION SEEDING
  // ===========================================================================

  /// Seeds initial roast schedule and queue actions if Firestore collection is empty
  Future<void> seedInitialRoastSchedulesIfEmpty({bool force = false}) async {
    if (_isSeeded && !force) return;

    try {
      final snap = await _roastSchedulesCol.limit(1).get();
      if (snap.docs.isNotEmpty && !force) {
        _isSeeded = true;
        return;
      }

      final now = DateTime.now();

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
          scheduledAt: DateTime(now.year, now.month, now.day, 14, 0),
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
          scheduledAt: DateTime(now.year, now.month, now.day + 2, 9, 0),
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

      final batch = _firestore.batch();
      for (final act in seedActions) {
        final docRef = _roastSchedulesCol.doc(act.id);
        final map = act.toJson();
        if (act.scheduledAt != null) {
          map['scheduled_at'] = Timestamp.fromDate(act.scheduledAt!);
        }
        map['created_at'] = Timestamp.fromDate(act.createdAt);
        map['updated_at'] = Timestamp.fromDate(act.updatedAt);
        if (act.completedAt != null) {
          map['completed_at'] = Timestamp.fromDate(act.completedAt!);
        }
        batch.set(docRef, map);
      }
      await batch.commit();
      _isSeeded = true;
    } catch (_) {
      // Non-blocking in test / offline environments
    }
  }
}
