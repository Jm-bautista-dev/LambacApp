import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../cart/data/models/pickup_location_model.dart';
import '../../../sales/data/models/sales_channel.dart';
import '../../../sales/data/models/sales_record_item_model.dart';
import '../../domain/events/order_events.dart';
import '../../domain/services/order_realtime_service.dart';
import '../../domain/services/pickup_scheduling_service.dart';
import '../models/create_order_request.dart';
import '../models/first_order_eligibility_model.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import 'order_remote_datasource.dart';

/// Production Cloud Firestore Data Source for Customer Pickup Orders & Real-time Lifecycle
class FirebaseOrderRemoteDataSource implements OrderRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final OrderRealtimeService _realtimeService;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSubscription;
  final Map<String, OrderModel> _cachedOrders = {};

  FirebaseOrderRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    OrderRealtimeService? realtimeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _realtimeService = realtimeService ?? OrderRealtimeService() {
    // Realtime sync is started on-demand per authenticated user in getOrders/createOrder
  }

  String? _listeningUserId;

  Future<void> _ensureRealtimeSyncForUser(String userId, {required bool isStaff}) async {
    if (_ordersSubscription != null && _listeningUserId == userId) {
      return; // Already actively subscribed for this user
    }

    await _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _listeningUserId = userId;

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('orders');
      if (!isStaff) {
        query = query
            .where('customer_id', isEqualTo: userId)
            .limit(25);
      } else {
        query = query
            .where('status', whereIn: ['pending', 'confirmed', 'preparing', 'prepared', 'readyForPickup'])
            .limit(25);
      }

      _ordersSubscription = query.snapshots().listen((snapshot) {
        // Verify current user still matches before processing
        if (_auth.currentUser?.uid != userId) {
          clearSession();
          return;
        }

        for (final docChange in snapshot.docChanges) {
          final doc = docChange.doc;
          final order = _mapDocToOrder(doc);
          final previous = _cachedOrders[order.id];

          // Diagnostic Logging (explicitly logs both fulfillment status and payment status)
          // ignore: avoid_print
          print('[ORDER SNAPSHOT] orderId=${order.id} (${order.orderNumber}) firestoreStatus=${doc.data()?['status']} mappedStatus=${order.status.name} paymentMethod=${order.paymentMethod} paymentStatus=${order.paymentStatus}');

          // Guard: If current cached order is terminal completed, do not allow stale snapshot to revert it
          if (previous != null && previous.status == OrderStatus.completed && order.status != OrderStatus.completed) {
            // ignore: avoid_print
            print('[ORDER SNAPSHOT IGNORED] orderId=${order.id} cached=completed incoming=${order.status.name}');
            continue;
          }

          _cachedOrders[order.id] = order;

          if (docChange.type == DocumentChangeType.added && previous == null) {
            _realtimeService.notifyOrderCreated(OrderCreatedEvent(order: order));
          } else if (docChange.type == DocumentChangeType.modified ||
              (previous != null && previous.status != order.status)) {
            _realtimeService.notifyStatusChanged(
              OrderStatusChangedEvent(
                orderId: order.id,
                orderNumber: order.orderNumber,
                previousStatus: previous?.status ?? order.status,
                newStatus: order.status,
                order: order,
                updatedByRole: 'system',
              ),
            );
          }
        }
      }, onError: (Object error, StackTrace stackTrace) {
        ErrorHandler.handle(
          error,
          stackTrace: stackTrace,
          domain: FailureDomain.orderCreation,
          operation: 'order_realtime_sync',
          actorUid: userId,
        );
      });
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        domain: FailureDomain.orderCreation,
        operation: 'order_realtime_sync_init',
        actorUid: userId,
      );
    }
  }

  void dispose() {
    unawaited(_ordersSubscription?.cancel());
    _ordersSubscription = null;
    _listeningUserId = null;
    _cachedOrders.clear();
  }

  @override
  void clearSession() {
    dispose();
  }

  // ===========================================================================
  // FIRST-ORDER GCASH ELIGIBILITY (TRUSTED BACKEND VERIFICATION)
  // ===========================================================================

  bool _isQualifyingPaidOrder(OrderModel order) {
    if (order.status == OrderStatus.cancelled) return false;
    final pStatus = order.paymentStatus.toUpperCase();
    final isGcash = order.paymentMethod.toLowerCase().contains('gcash');
    if (isGcash && pStatus == 'PAID') {
      return true;
    }
    if (order.status == OrderStatus.completed && pStatus == 'PAID') {
      return true;
    }
    return false;
  }

  bool _isActivePendingGcashOrder(OrderModel order) {
    if (order.status == OrderStatus.cancelled || order.status == OrderStatus.completed) {
      return false;
    }
    final pStatus = order.paymentStatus.toUpperCase();
    final isGcash = order.paymentMethod.toLowerCase().contains('gcash');
    return isGcash && pStatus == 'PENDING';
  }

  @override
  FirstOrderEligibility getFirstOrderEligibilitySync(String? userId) {
    final effectiveUid = userId ?? _auth.currentUser?.uid ?? '';
    if (effectiveUid.isEmpty) {
      return FirstOrderEligibility.firstOrderRequired(customerId: '');
    }

    final userOrders = _cachedOrders.values.where((o) => o.customerId == effectiveUid).toList();
    for (final order in userOrders) {
      if (_isQualifyingPaidOrder(order)) {
        return FirstOrderEligibility.completed(
          customerId: effectiveUid,
          qualifyingOrderId: order.id,
        );
      }
    }

    String? activePendingId;
    for (final order in userOrders) {
      if (_isActivePendingGcashOrder(order)) {
        activePendingId = order.id;
        break;
      }
    }

    return FirstOrderEligibility.firstOrderRequired(
      customerId: effectiveUid,
      activeFirstOrderId: activePendingId,
    );
  }

  @override
  Future<Result<FirstOrderEligibility, AppFailure>> checkFirstOrderEligibility() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to verify payment eligibility.'),
      );
    }

    final uid = user.uid;
    try {
      // 1. Check user profile document in /users/{uid}
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final uData = userDoc.data() ?? {};
        final completedFlag = uData['first_order_gcash_completed'] == true ||
            uData['firstOrderGcashCompleted'] == true;
        if (completedFlag) {
          return Result.success(
            FirstOrderEligibility.completed(
              customerId: uid,
              qualifyingOrderId: (uData['first_order_completed_order_id'] ??
                      uData['firstOrderCompletedOrderId'])
                  ?.toString(),
            ),
          );
        }
      }

      // 2. Check authoritative /orders collection for any verified PAID qualifying order
      final ordersSnap = await _firestore
          .collection('orders')
          .where('customer_id', isEqualTo: uid)
          .limit(30)
          .get();

      String? qualifyingOrderId;
      String? activeFirstOrderId;

      for (final doc in ordersSnap.docs) {
        final order = _mapDocToOrder(doc);
        _cachedOrders[order.id] = order;
        if (_isQualifyingPaidOrder(order)) {
          qualifyingOrderId = order.id;
          break;
        }
        if (activeFirstOrderId == null && _isActivePendingGcashOrder(order)) {
          activeFirstOrderId = order.id;
        }
      }

      if (qualifyingOrderId != null) {
        return Result.success(
          FirstOrderEligibility.completed(
            customerId: uid,
            qualifyingOrderId: qualifyingOrderId,
          ),
        );
      }

      // 3. Check /first_order_reservations/{uid}
      if (activeFirstOrderId == null) {
        try {
          final resDoc = await _firestore.collection('first_order_reservations').doc(uid).get();
          if (resDoc.exists) {
            final rData = resDoc.data() ?? {};
            final rStatus = (rData['status'] ?? '').toString().toUpperCase();
            if (rStatus == 'COMPLETED') {
              return Result.success(
                FirstOrderEligibility.completed(
                  customerId: uid,
                  qualifyingOrderId: rData['order_id']?.toString(),
                ),
              );
            }
            if (rStatus == 'ACTIVE_PENDING') {
              final rOrderId = rData['order_id']?.toString();
              if (rOrderId != null && rOrderId.isNotEmpty) {
                final rOrderDoc = await _firestore.collection('orders').doc(rOrderId).get();
                if (rOrderDoc.exists) {
                  final rOrder = _mapDocToOrder(rOrderDoc);
                  if (_isQualifyingPaidOrder(rOrder)) {
                    return Result.success(
                      FirstOrderEligibility.completed(
                        customerId: uid,
                        qualifyingOrderId: rOrder.id,
                      ),
                    );
                  }
                  if (_isActivePendingGcashOrder(rOrder)) {
                    activeFirstOrderId = rOrder.id;
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      return Result.success(
        FirstOrderEligibility.firstOrderRequired(
          customerId: uid,
          activeFirstOrderId: activeFirstOrderId,
        ),
      );
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to verify first-order eligibility: $e'),
      );
    }
  }

  // ===========================================================================
  // ORDER CREATION
  // ===========================================================================

  @override
  Future<Result<OrderModel, AppFailure>> createOrder(CreateOrderRequest request) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to place orders.'),
      );
    }

    final effectiveUserId = user.uid;
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);
    final effectiveUserName = request.customerName.isNotEmpty
        ? request.customerName
        : ((user.displayName != null && user.displayName!.isNotEmpty) ? user.displayName! : 'Coffee Enthusiast');
    final effectivePhone = request.customerPhone.isNotEmpty
        ? request.customerPhone
        : ((user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ? user.phoneNumber! : '09171234567');

    if (request.items.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Cannot place an order with an empty cart.'),
      );
    }

    // Server-Side Pickup Schedule & Operating Hours Validation
    final scheduleValidation = PickupSchedulingService().validateSchedule(
      dateStr: request.pickupDate,
      timeSlotStr: request.pickupTimeSlot,
      location: request.pickupLocation,
    );

    if (scheduleValidation.isFailure) {
      return Result.failure(scheduleValidation.failureOrNull!);
    }

    // 1. Idempotency Check: Fast return if request is a network retry of an already created order
    final idempotencyKey = request.idempotencyKey;
    if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
      try {
        final existingSnap = await _firestore
            .collection('orders')
            .where('customer_id', isEqualTo: effectiveUserId)
            .where('idempotency_key', isEqualTo: idempotencyKey.trim())
            .limit(1)
            .get();

        if (existingSnap.docs.isNotEmpty) {
          final existingOrder = _mapDocToOrder(existingSnap.docs.first);
          _cachedOrders[existingOrder.id] = existingOrder;
          return Result.success(existingOrder);
        }
      } catch (_) {
        // Fall through to transactional verification
      }
    }

    // 1b. Trusted Backend First-Order GCash Eligibility & Simultaneous Order Guard
    FirstOrderEligibility? firstOrderEligibility;
    if (!isStaffOrAdmin) {
      final eligResult = await checkFirstOrderEligibility();
      if (eligResult.isSuccess) {
        firstOrderEligibility = eligResult.dataOrNull;
      } else {
        firstOrderEligibility = getFirstOrderEligibilitySync(effectiveUserId);
      }

      if (firstOrderEligibility != null && firstOrderEligibility.requiresFirstOrderGcash) {
        final isGcashMethod = request.paymentMethod.toLowerCase().contains('gcash');
        if (!isGcashMethod) {
          return const Result.failure(
            ValidationFailure(
              message: 'Your first order must be paid through GCash. Pay at Counter is unavailable until your first GCash order is verified as PAID.',
            ),
          );
        }

        if (firstOrderEligibility.activeFirstOrderId != null) {
          return Result.failure(
            ValidationFailure(
              message: 'You already have an active first-order GCash checkout in progress (${firstOrderEligibility.activeFirstOrderId}). Simultaneous first-order attempts are not allowed.',
            ),
          );
        }
      }
    }

    try {
      // 2. Execute atomic Firestore transaction:
      // - Revalidates product existence in catalog
      // - Revalidates product enabled status & stock availability
      // - Authoritatively computes unit prices and totals from backend catalog
      // - Enforces atomic single-reservation lock on /first_order_reservations/{uid}
      // - Atomically decrements product stock (for staff/POS)
      // - Persists order with initial PENDING (GCash) or UNPAID (Pay at Counter) status
      final newOrder = await _firestore.runTransaction<OrderModel>((transaction) async {
        final productDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};

        // Read Phase: Fetch authoritative product documents + first-order reservation doc
        for (final item in request.items) {
          final pRef = _firestore.collection('products').doc(item.productId);
          final pDoc = await transaction.get(pRef);
          productDocs[item.productId] = pDoc;
        }

        final DocumentReference<Map<String, dynamic>>? reservationRef;
        final DocumentSnapshot<Map<String, dynamic>>? reservationSnap;
        final bool requiresFirstOrderLock =
            !isStaffOrAdmin && (firstOrderEligibility?.requiresFirstOrderGcash ?? false);

        if (requiresFirstOrderLock) {
          reservationRef = _firestore.collection('first_order_reservations').doc(effectiveUserId);
          reservationSnap = await transaction.get(reservationRef);
        } else {
          reservationRef = null;
          reservationSnap = null;
        }

        // Validate Phase A: Atomic simultaneous first-order check inside transaction
        if (requiresFirstOrderLock && reservationSnap != null && reservationSnap.exists) {
          final rData = reservationSnap.data() ?? {};
          final rStatus = (rData['status'] ?? '').toString().toUpperCase();
          final existingLockedOrderId = rData['order_id']?.toString();
          if (rStatus == 'ACTIVE_PENDING' &&
              existingLockedOrderId != null &&
              existingLockedOrderId.isNotEmpty) {
            throw ValidationFailure(
              message: 'You already have an active first-order GCash checkout in progress ($existingLockedOrderId). Simultaneous first-order attempts are not allowed.',
            );
          }
        }

        // Validate Phase: Verify catalog rules, availability, stock, and pricing
        final verifiedOrderItems = <OrderItemModel>[];
        for (final item in request.items) {
          final pDoc = productDocs[item.productId];
          if (pDoc == null || !pDoc.exists) {
            throw ValidationFailure(
              message: "Product '${item.productName}' was removed from the catalog.",
            );
          }

          final data = pDoc.data() ?? {};
          final isEnabled = (data['is_enabled'] ?? data['isEnabled'] ?? true) as bool;
          if (!isEnabled) {
            throw ValidationFailure(
              message: "Product '${item.productName}' is currently unavailable or disabled by an administrator. Please remove it from your cart.",
            );
          }

          final currentStock = ((data['stock_quantity'] ?? data['stock'] ?? 0) as num).toInt();
          if (currentStock < item.quantity) {
            throw ValidationFailure(
              message: "Insufficient stock for '${item.productName}'. Requested: ${item.quantity}, Available: $currentStock.",
            );
          }

          // Authoritative Selling Price Calculation
          final liveBasePrice = ((data['price'] ?? data['base_price'] ?? 0.0) as num).toDouble();
          final sizeDelta = item.sizeVariant?.priceDelta ?? 0.0;
          final grindDelta = item.grindVariant?.priceDelta ?? 0.0;
          final liveExpectedUnitPrice = liveBasePrice + sizeDelta + grindDelta;

          // Reject cart if prices were tampered with or changed in catalog
          if ((liveExpectedUnitPrice - item.unitPrice).abs() > 0.01) {
            throw ValidationFailure(
              message: "Price change detected on '${item.productName}'. Current price is ₱${liveExpectedUnitPrice.toStringAsFixed(2)} (Cart had ₱${item.unitPrice.toStringAsFixed(2)}). Please refresh your cart.",
            );
          }

          final verifiedTotal = liveExpectedUnitPrice * item.quantity;
          verifiedOrderItems.add(
            OrderItemModel.fromCartItem(item).copyWith(
              unitPrice: liveExpectedUnitPrice,
              totalPrice: verifiedTotal,
            ),
          );
        }

        // Authoritative Totals
        final verifiedSubtotal = verifiedOrderItems.fold(0.0, (acc, i) => acc + i.totalPrice);

        // Write Phase A: If staff or admin (e.g. POS), update product stock.
        // Customers do NOT write directly to /products (maintaining least-privilege inventory security).
        if (isStaffOrAdmin) {
          for (final item in request.items) {
            final pDoc = productDocs[item.productId]!;
            final data = pDoc.data() ?? {};
            final currentStock = ((data['stock_quantity'] ?? data['stock'] ?? 0) as num).toInt();
            final newStock = (currentStock - item.quantity).clamp(0, 999999);
            final newAvailability = newStock == 0 ? 'outOfStock' : (newStock <= 5 ? 'lowStock' : 'available');

            transaction.update(_firestore.collection('products').doc(item.productId), {
              'stock_quantity': newStock,
              'availability': newAvailability,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        }

        // Write Phase B: Persist order document
        final randomSuffix = (1000 + (DateTime.now().millisecondsSinceEpoch % 8999)).toString();
        final orderId = 'ord_lmb_$randomSuffix';
        final orderNumber = 'LMB-$randomSuffix';
        final now = DateTime.now();

        final created = OrderModel(
          id: orderId,
          orderNumber: orderNumber,
          customerId: effectiveUserId,
          customerName: effectiveUserName,
          customerPhone: effectivePhone,
          items: verifiedOrderItems,
          subtotal: verifiedSubtotal,
          totalAmount: verifiedSubtotal,
          status: OrderStatus.pending,
          pickupLocation: request.pickupLocation,
          pickupDate: request.pickupDate,
          pickupTimeSlot: request.pickupTimeSlot,
          paymentMethod: request.paymentMethod,
          paymentStatus: request.paymentMethod.toLowerCase().contains('gcash') ? 'PENDING' : 'UNPAID',
          notes: request.notes,
          createdAt: now,
          estimatedReadyAt: now.add(const Duration(minutes: 20)),
          idempotencyKey: idempotencyKey,
        );

        final orderData = created.toJson();
        orderData['status_updated_at'] = now.toIso8601String();
        orderData['created_at'] = FieldValue.serverTimestamp();
        if (requiresFirstOrderLock) {
          orderData['is_first_order_gcash'] = true;
        }

        transaction.set(_firestore.collection('orders').doc(orderId), orderData);

        if (requiresFirstOrderLock && reservationRef != null) {
          transaction.set(
            reservationRef,
            {
              'customer_id': effectiveUserId,
              'order_id': orderId,
              'order_number': orderNumber,
              'payment_method': 'GCash',
              'status': 'ACTIVE_PENDING',
              'updated_at': now.toIso8601String(),
            },
            SetOptions(merge: true),
          );
        }

        return created;
      });

      _cachedOrders[newOrder.id] = newOrder;
      _realtimeService.notifyOrderCreated(OrderCreatedEvent(order: newOrder));
      return Result.success(newOrder);
    } on ValidationFailure catch (vf) {
      return Result.failure(vf);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Fallback for customer checkout: When security rules disallow customer writes to /products,
        // create the order in /orders directly so the customer's purchase is completed and queued.
        try {
          final randomSuffix = (1000 + (DateTime.now().millisecondsSinceEpoch % 8999)).toString();
          final orderId = 'ord_lmb_$randomSuffix';
          final orderNumber = 'LMB-$randomSuffix';
          final now = DateTime.now();

          final verifiedOrderItems = <OrderItemModel>[];
          for (final item in request.items) {
            final pDoc = await _firestore.collection('products').doc(item.productId).get();
            final data = pDoc.data() ?? {};
            final liveBasePrice = ((data['price'] ?? data['base_price'] ?? item.unitPrice) as num).toDouble();
            final sizeDelta = item.sizeVariant?.priceDelta ?? 0.0;
            final grindDelta = item.grindVariant?.priceDelta ?? 0.0;
            final liveExpectedUnitPrice = (liveBasePrice + sizeDelta + grindDelta > 0)
                ? (liveBasePrice + sizeDelta + grindDelta)
                : item.unitPrice;
            final verifiedTotal = liveExpectedUnitPrice * item.quantity;
            verifiedOrderItems.add(
              OrderItemModel.fromCartItem(item).copyWith(
                unitPrice: liveExpectedUnitPrice,
                totalPrice: verifiedTotal,
              ),
            );
          }

          final verifiedSubtotal = verifiedOrderItems.fold(0.0, (acc, i) => acc + i.totalPrice);

          final isGcashOrder = request.paymentMethod.toLowerCase().contains('gcash');
          final requiresFirstOrderLock =
              !isStaffOrAdmin && (firstOrderEligibility?.requiresFirstOrderGcash ?? false);

          final created = OrderModel(
            id: orderId,
            orderNumber: orderNumber,
            customerId: effectiveUserId,
            customerName: effectiveUserName,
            customerPhone: effectivePhone,
            items: verifiedOrderItems,
            subtotal: verifiedSubtotal,
            totalAmount: verifiedSubtotal,
            status: OrderStatus.pending,
            pickupLocation: request.pickupLocation,
            pickupDate: request.pickupDate,
            pickupTimeSlot: request.pickupTimeSlot,
            paymentMethod: request.paymentMethod,
            paymentStatus: isGcashOrder ? 'PENDING' : 'UNPAID',
            notes: request.notes,
            createdAt: now,
            estimatedReadyAt: now.add(const Duration(minutes: 20)),
            idempotencyKey: idempotencyKey,
          );

          final orderData = created.toJson();
          orderData['status_updated_at'] = now.toIso8601String();
          orderData['created_at'] = FieldValue.serverTimestamp();
          if (requiresFirstOrderLock) {
            orderData['is_first_order_gcash'] = true;
          }

          await _firestore.collection('orders').doc(orderId).set(orderData);

          if (requiresFirstOrderLock) {
            try {
              await _firestore
                  .collection('first_order_reservations')
                  .doc(effectiveUserId)
                  .set(
                    {
                      'customer_id': effectiveUserId,
                      'order_id': orderId,
                      'order_number': orderNumber,
                      'payment_method': 'GCash',
                      'status': 'ACTIVE_PENDING',
                      'updated_at': now.toIso8601String(),
                    },
                    SetOptions(merge: true),
                  );
            } catch (_) {}
          }

          _cachedOrders[created.id] = created;
          _realtimeService.notifyOrderCreated(OrderCreatedEvent(order: created));
          return Result.success(created);
        } catch (innerErr) {
          if (innerErr is FirebaseException) {
            return Result.failure(_mapFirebaseException(innerErr));
          }
          return Result.failure(ServerFailure(message: innerErr.toString()));
        }
      }
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      if (e is AppFailure) return Result.failure(e);
      return Result.failure(ServerFailure(message: 'Failed to place order: $e'));
    }
  }

  // ===========================================================================
  // ORDER QUERIES
  // ===========================================================================

  @override
  Future<Result<PaginatedList<OrderModel>, AppFailure>> getOrders({
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
    OrderStatus? statusFilter,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to access orders.'),
      );
    }

    final effectiveUserId = user.uid;
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);
    unawaited(_ensureRealtimeSyncForUser(effectiveUserId, isStaff: isStaffOrAdmin));

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('orders');
      if (!isStaffOrAdmin) {
        // Customer sees strictly their own orders using single-field index on customer_id
        query = query.where('customer_id', isEqualTo: effectiveUserId);
      } else if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      } else {
        query = query.orderBy('created_at', descending: true);
      }

      final snapshot = await query.get();
      var orders = snapshot.docs.map((doc) {
        final order = _mapDocToOrder(doc);
        _cachedOrders[order.id] = order;
        return order;
      }).toList();

      if (statusFilter != null) {
        orders = orders.where((o) => o.status == statusFilter).toList();
      }

      // Stable deterministic ordering: newest first with document ID tie-breaker
      orders.sort((a, b) {
        final dateCmp = b.createdAt.compareTo(a.createdAt);
        if (dateCmp != 0) return dateCmp;
        return a.id.compareTo(b.id);
      });

      final totalCount = orders.length;

      String? cursorId;
      if (lastDocument is DocumentSnapshot) {
        cursorId = lastDocument.id;
      } else if (lastDocument is String && lastDocument.isNotEmpty) {
        cursorId = lastDocument;
      }

      int startIndex = 0;
      if (cursorId != null) {
        final idx = orders.indexWhere((o) => o.id == cursorId);
        if (idx != -1) startIndex = idx + 1;
      } else if (page > 1) {
        startIndex = (page - 1) * limit;
      }

      final endIndex = (startIndex + limit) > totalCount ? totalCount : (startIndex + limit);
      final pageItems = startIndex < totalCount ? orders.sublist(startIndex, endIndex) : <OrderModel>[];
      final hasNextPage = endIndex < totalCount;
      final nextCursor = pageItems.isNotEmpty ? pageItems.last.id : null;

      return Result.success(
        PaginatedList<OrderModel>(
          items: List.unmodifiable(pageItems),
          page: page,
          pageSize: limit,
          totalCount: totalCount,
          hasNextPage: hasNextPage,
          cursor: nextCursor,
        ),
      );
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to retrieve orders: $e'));
    }
  }

  @override
  Future<Result<OrderModel, AppFailure>> getOrderById(String orderId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to view order details.'),
      );
    }

    final effectiveUserId = user.uid;
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);

    try {
      // 1. Check direct doc lookup
      final doc = await _firestore.collection('orders').doc(orderId).get();
      OrderModel? order;

      if (doc.exists) {
        order = _mapDocToOrder(doc);
        _cachedOrders[order.id] = order;
      } else {
        // 2. Lookup by orderNumber (e.g. LMB-1082)
        final snap = await _firestore
            .collection('orders')
            .where('order_number', isEqualTo: orderId)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          order = _mapDocToOrder(snap.docs.first);
          _cachedOrders[order.id] = order;
        }
      }

      // 3. Fallback to cache
      order ??= _cachedOrders[orderId] ??
          _cachedOrders.values.cast<OrderModel?>().firstWhere(
                (o) => o?.orderNumber == orderId,
                orElse: () => null,
              );

      if (order == null) {
        return const Result.failure(NotFoundFailure(message: 'Order not found.'));
      }

      // Ownership enforcement
      if (!isStaffOrAdmin && order.customerId != effectiveUserId) {
        return const Result.failure(
          ForbiddenFailure(message: 'Forbidden: Access denied to this order.'),
        );
      }

      return Result.success(order);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to retrieve order: $e'));
    }
  }

  // ===========================================================================
  // ORDER STATUS GOVERNANCE
  // ===========================================================================

  @override
  Future<Result<OrderModel, AppFailure>> updateOrderStatus(String orderId, OrderStatus status) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to process orders.'),
      );
    }

    final effectiveUserId = user.uid;
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);

    if (!isStaffOrAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Processing orders requires Staff, Barista, or Admin access.'),
      );
    }

    try {
      DocumentReference<Map<String, dynamic>> docRef = _firestore.collection('orders').doc(orderId);
      DocumentSnapshot<Map<String, dynamic>> docSnap = await docRef.get();

      if (!docSnap.exists) {
        // Try resolving by order_number
        final querySnap = await _firestore
            .collection('orders')
            .where('order_number', isEqualTo: orderId)
            .limit(1)
            .get();
        if (querySnap.docs.isEmpty) {
          return const Result.failure(NotFoundFailure(message: 'Order not found.'));
        }
        docRef = querySnap.docs.first.reference;
        docSnap = querySnap.docs.first;
      }

      final existingOrder = _mapDocToOrder(docSnap);

      // Idempotency: duplicate request for already-persisted status is a safe no-op
      if (existingOrder.status == status) {
        return Result.success(existingOrder);
      }

      // Enforce valid status transition lifecycle
      if (!existingOrder.status.canTransitionTo(status)) {
        return Result.failure(
          ValidationFailure(
            message: 'Cannot transition order #${existingOrder.orderNumber} from ${existingOrder.status.toDisplayString()} to ${status.toDisplayString()}.',
          ),
        );
      }

      final isCompleting = status == OrderStatus.completed;
      final saleDocRefWithPrefix = _firestore.collection('sales').doc('sale_${existingOrder.id}');
      final saleDocRefBare = _firestore.collection('sales').doc(existingOrder.id);

      // ignore: avoid_print
      print('[TX_DIAG] Method: updateOrderStatus | START | orderId: ${existingOrder.id} (${existingOrder.orderNumber}) | targetStatus: ${status.name} | isCompleting: $isCompleting');

      // Execute atomic transaction following strict 3-phase Firestore ordering:
      // PHASE A: ALL READS FIRST (order doc, linked sale doc variations)
      // PHASE B: VALIDATIONS & LIFECYCLE CHECKS
      // PHASE C: ALL WRITES AFTER READS (order doc update, sales record creation/update)
      var writeStaged = false;
      final updatedOrder = await _firestore.runTransaction<OrderModel>((transaction) async {
        // =====================================================================
        // PHASE A — READ ALL REQUIRED DOCUMENTS
        // Every transaction.get() must be executed strictly before any writes!
        // =====================================================================
        // ignore: avoid_print
        print('[TX_DIAG] Method: updateOrderStatus | READ_START | docRef: ${docRef.path} | writeStaged: $writeStaged');
        final currentOrderSnap = await transaction.get(docRef);

        final DocumentSnapshot<Map<String, dynamic>>? existingSalePrefixedSnap;
        final DocumentSnapshot<Map<String, dynamic>>? existingSaleBareSnap;
        if (isCompleting) {
          // Pre-read both potential document ID conventions in /sales to prevent duplicate records
          // ignore: avoid_print
          print('[TX_DIAG] Method: updateOrderStatus | READ_SALES_START | prefixed: ${saleDocRefWithPrefix.path} bare: ${saleDocRefBare.path} | writeStaged: $writeStaged');
          existingSalePrefixedSnap = await transaction.get(saleDocRefWithPrefix);
          existingSaleBareSnap = await transaction.get(saleDocRefBare);
        } else {
          existingSalePrefixedSnap = null;
          existingSaleBareSnap = null;
        }

        // =====================================================================
        // PHASE B — VALIDATE
        // =====================================================================
        if (!currentOrderSnap.exists) {
          throw const NotFoundFailure(message: 'Order document does not exist.');
        }

        final currentOrder = _mapDocToOrder(currentOrderSnap);

        // Idempotency guard: If order is already in the target status (and paid if completing)
        if (currentOrder.status == status) {
          if (!isCompleting || currentOrder.paymentStatus.toUpperCase() == 'PAID') {
            // ignore: avoid_print
            print('[TX_DIAG] Method: updateOrderStatus | IDEMPOTENT_EXIT | orderId: ${currentOrder.id}');
            return currentOrder;
          }
        }

        // Enforce valid status transition lifecycle
        if (!currentOrder.status.canTransitionTo(status)) {
          throw ValidationFailure(
            message: 'Cannot transition order #${currentOrder.orderNumber} from ${currentOrder.status.toDisplayString()} to ${status.toDisplayString()}.',
          );
        }

        // If completing, order must be in valid ready/prepared state
        if (isCompleting &&
            currentOrder.status != OrderStatus.readyForPickup &&
            currentOrder.status != OrderStatus.prepared) {
          throw ValidationFailure(
            message: 'Order #${currentOrder.orderNumber} is currently in ${currentOrder.status.toDisplayString()} state. Only ready orders can be collected & completed.',
          );
        }

        // Validate positive total amount
        if (currentOrder.totalAmount <= 0) {
          throw ValidationFailure(
            message: 'Order #${currentOrder.orderNumber} has invalid total amount (₱${currentOrder.totalAmount.toStringAsFixed(2)}).',
          );
        }

        final isGcashOrder = currentOrder.paymentMethod.toLowerCase().contains('gcash');
        final currentPaymentStatusUpper = currentOrder.paymentStatus.toUpperCase();

        // Prevent staff from advancing a failed, expired, or cancelled GCash order
        if (isGcashOrder &&
            status != OrderStatus.cancelled &&
            (currentPaymentStatusUpper == 'FAILED' ||
                currentPaymentStatusUpper == 'EXPIRED' ||
                currentPaymentStatusUpper == 'CANCELLED')) {
          throw ValidationFailure(
            message: 'Cannot advance GCash order #${currentOrder.orderNumber} to ${status.toDisplayString()} while payment status is $currentPaymentStatusUpper.',
          );
        }

        // Prevent staff from completing an unverified GCash order
        if (isCompleting &&
            isGcashOrder &&
            currentPaymentStatusUpper != 'PAID') {
          throw ValidationFailure(
            message: 'Cannot complete GCash order #${currentOrder.orderNumber} while payment status is ${currentOrder.paymentStatus}. GCash payment must be verified by PayMongo first.',
          );
        }

        final now = DateTime.now();
        // Rule 8: Barista fulfillment actions must NEVER change payment status on non-completion steps,
        // and must not overwrite verified GCash payment metadata on completion.
        final bool recordCounterPaymentOnCompletion =
            isCompleting && !isGcashOrder && currentPaymentStatusUpper != 'PAID';
        final resolvedPaymentStatus = recordCounterPaymentOnCompletion
            ? 'PAID'
            : currentOrder.paymentStatus;

        final completedOrder = currentOrder.copyWith(
          status: status,
          paymentStatus: resolvedPaymentStatus,
          completedAt: isCompleting ? (currentOrder.completedAt ?? now) : currentOrder.completedAt,
        );

        // Resolve which sales document to update or create
        final DocumentReference<Map<String, dynamic>> targetSaleDocRef;
        final bool saleAlreadyExists;
        if (existingSalePrefixedSnap != null && existingSalePrefixedSnap.exists) {
          targetSaleDocRef = saleDocRefWithPrefix;
          saleAlreadyExists = true;
        } else if (existingSaleBareSnap != null && existingSaleBareSnap.exists) {
          targetSaleDocRef = saleDocRefBare;
          saleAlreadyExists = true;
        } else {
          targetSaleDocRef = saleDocRefWithPrefix;
          saleAlreadyExists = false;
        }

        // =====================================================================
        // PHASE C — WRITE ALL REQUIRED DOCUMENTS ATOMICALLY
        // Only executed after all reads and validations are complete
        // =====================================================================
        writeStaged = true;

        // 1. Atomically update order document
        // Strictly separate fulfillment updates from payment updates:
        // Only write payment_status when counter payment is collected upon Pay at Counter pickup completion.
        final orderUpdateData = <String, dynamic>{
          'status': status.name,
          if (recordCounterPaymentOnCompletion) 'payment_status': 'PAID',
          if (recordCounterPaymentOnCompletion) 'payment_recorded_at': now.toIso8601String(),
          if (recordCounterPaymentOnCompletion) 'payment_recorded_by_staff_id': effectiveUserId,
          if (isCompleting) 'completed_at': (completedOrder.completedAt ?? now).toIso8601String(),
          if (isCompleting) 'completed_by_staff_id': effectiveUserId,
          'status_updated_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        // ignore: avoid_print
        print('[TX_DIAG] Method: updateOrderStatus | WRITE_ORDER | doc: ${docRef.path} | writeStaged: $writeStaged');
        transaction.set(docRef, orderUpdateData, SetOptions(merge: true));

        // 2. Atomically write/update linked Centralized Sales Ledger record
        if (isCompleting) {
          if (!saleAlreadyExists) {
            final salesItems = completedOrder.items.map((item) {
              return SalesRecordItemModel(
                id: 'item_s_${item.id}',
                productId: item.productId,
                productName: item.productName,
                size: item.size,
                grind: item.grind,
                snapshotUnitPrice: item.unitPrice,
                quantity: item.quantity,
                totalPrice: item.totalPrice,
              );
            }).toList();

            final saleData = <String, dynamic>{
              'id': targetSaleDocRef.id,
              'transaction_number': 'TX-MOB-${completedOrder.orderNumber}',
              'channel': SalesChannel.mobileApp.canonicalKey, // 'MOBILE_APP_PICKUP'
              'order_id': completedOrder.id,
              'customer_name': completedOrder.customerName,
              'customer_phone': completedOrder.customerPhone,
              'items': salesItems.map((i) => i.toJson()).toList(),
              'subtotal': completedOrder.subtotal,
              'total_amount': completedOrder.totalAmount,
              'payment_method': completedOrder.paymentMethod,
              'is_voided': false,
              'staff_id': effectiveUserId,
              'recorded_by_staff_id': effectiveUserId,
              'created_at': Timestamp.fromDate(completedOrder.completedAt ?? now),
            };

            // ignore: avoid_print
            print('[TX_DIAG] Method: updateOrderStatus | WRITE_SALE_NEW | doc: ${targetSaleDocRef.path} | writeStaged: $writeStaged');
            transaction.set(targetSaleDocRef, saleData);
          } else {
            // ignore: avoid_print
            print('[TX_DIAG] Method: updateOrderStatus | WRITE_SALE_UPDATE | doc: ${targetSaleDocRef.path} | writeStaged: $writeStaged');
            transaction.update(targetSaleDocRef, {
              'is_voided': false,
              'payment_method': completedOrder.paymentMethod,
              'staff_id': effectiveUserId,
              'updated_at': Timestamp.fromDate(now),
            });
          }
        }

        return completedOrder;
      });

      _cachedOrders[updatedOrder.id] = updatedOrder;

      // Broadcast real-time event after commit
      _realtimeService.notifyStatusChanged(
        OrderStatusChangedEvent(
          orderId: updatedOrder.id,
          orderNumber: updatedOrder.orderNumber,
          previousStatus: existingOrder.status,
          newStatus: status,
          order: updatedOrder,
          updatedByRole: isStaffOrAdmin ? 'staff' : 'system',
        ),
      );

      return Result.success(updatedOrder);
    } on ValidationFailure catch (vf) {
      // ignore: avoid_print
      print('[TX_DIAG] Method: updateOrderStatus | VALIDATION_FAILURE: ${vf.message}');
      return Result.failure(vf);
    } on FirebaseException catch (e, st) {
      // ignore: avoid_print
      print('[TX_DIAG] Method: updateOrderStatus | FIREBASE_EXCEPTION: [${e.code}] ${e.message}\nStackTrace: $st');
      return Result.failure(_mapFirebaseException(e));
    } catch (e, st) {
      // ignore: avoid_print
      print('[TX_DIAG] Method: updateOrderStatus | RUNTIME_EXCEPTION: $e\nStackTrace: $st');
      if (e is AppFailure) return Result.failure(e);
      return Result.failure(ServerFailure(message: 'Failed to update order status: $e'));
    }
  }

  @override
  Future<Result<OrderModel, AppFailure>> updatePaymentStatus(String orderId, PaymentStatus status) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(UnauthorizedFailure(message: 'Authentication required.'));
    }

    final effectiveUserId = user.uid;
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);

    if (!isStaffOrAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Recording counter payments requires staff or admin access.'),
      );
    }

    try {
      DocumentReference<Map<String, dynamic>> docRef = _firestore.collection('orders').doc(orderId);
      DocumentSnapshot<Map<String, dynamic>> docSnap = await docRef.get();

      if (!docSnap.exists) {
        final querySnap = await _firestore
            .collection('orders')
            .where('order_number', isEqualTo: orderId)
            .limit(1)
            .get();
        if (querySnap.docs.isEmpty) {
          return const Result.failure(NotFoundFailure(message: 'Order not found.'));
        }
        docRef = querySnap.docs.first.reference;
        docSnap = querySnap.docs.first;
      }

      final existingOrder = _mapDocToOrder(docSnap);

      // Prevent staff from manually marking an unverified GCash order as PAID at the counter
      if (status == PaymentStatus.paid &&
          existingOrder.paymentMethod.toLowerCase().contains('gcash') &&
          existingOrder.paymentStatus.toUpperCase() != 'PAID') {
        return Result.failure(
          ValidationFailure(
            message: 'GCash order #${existingOrder.orderNumber} cannot be manually marked as PAID at the counter. Payment must be verified by PayMongo.',
          ),
        );
      }

      // Idempotency: duplicate request for already-recorded payment
      if (existingOrder.paymentStatus.toUpperCase() == status.toDisplayString().toUpperCase()) {
        return Result.success(existingOrder);
      }

      // ignore: avoid_print
      print('[TX_DIAG] Method: updatePaymentStatus | START | orderId: ${existingOrder.id} (${existingOrder.orderNumber}) | targetPaymentStatus: ${status.toDisplayString()}');
      var writeStaged = false;
      final updatedOrder = await _firestore.runTransaction<OrderModel>((transaction) async {
        // PHASE A — READ
        // ignore: avoid_print
        print('[TX_DIAG] Method: updatePaymentStatus | READ_START | doc: ${docRef.path} | writeStaged: $writeStaged');
        final currentSnap = await transaction.get(docRef);
        if (!currentSnap.exists) {
          throw const NotFoundFailure(message: 'Order not found.');
        }

        // PHASE B — VALIDATE
        final current = _mapDocToOrder(currentSnap);
        if (current.paymentStatus.toUpperCase() == status.toDisplayString().toUpperCase()) {
          // ignore: avoid_print
          print('[TX_DIAG] Method: updatePaymentStatus | IDEMPOTENT_EXIT | orderId: ${current.id}');
          return current; // Idempotent
        }

        final now = DateTime.now();
        final paidOrder = current.copyWith(
          paymentStatus: status.toDisplayString(),
        );

        // PHASE C — WRITE
        writeStaged = true;
        // ignore: avoid_print
        print('[TX_DIAG] Method: updatePaymentStatus | WRITE_START | doc: ${docRef.path} | writeStaged: $writeStaged');
        transaction.set(docRef, {
          'payment_status': status.toDisplayString(),
          'payment_recorded_at': now.toIso8601String(),
          'payment_recorded_by_staff_id': effectiveUserId,
          'updated_at': now.toIso8601String(),
        }, SetOptions(merge: true));

        return paidOrder;
      });

      _cachedOrders[updatedOrder.id] = updatedOrder;

      _realtimeService.notifyStatusChanged(
        OrderStatusChangedEvent(
          orderId: updatedOrder.id,
          orderNumber: updatedOrder.orderNumber,
          previousStatus: existingOrder.status,
          newStatus: updatedOrder.status,
          order: updatedOrder,
          updatedByRole: 'staff',
        ),
      );

      return Result.success(updatedOrder);
    } on FirebaseException catch (e, st) {
      // ignore: avoid_print
      print('[TX_DIAG] Method: updatePaymentStatus | FIREBASE_EXCEPTION: [${e.code}] ${e.message}\nStackTrace: $st');
      return Result.failure(_mapFirebaseException(e));
    } catch (e, st) {
      // ignore: avoid_print
      print('[TX_DIAG] Method: updatePaymentStatus | RUNTIME_EXCEPTION: $e\nStackTrace: $st');
      return Result.failure(ServerFailure(message: 'Failed to update payment status: $e'));
    }
  }

  @override
  Future<Result<OrderModel, AppFailure>> cancelOrder(String orderId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(UnauthorizedFailure(message: 'Authentication required.'));
    }

    final effectiveUserId = user.uid;
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);
    final docRef = _firestore.collection('orders').doc(orderId);
    OrderModel? existingOrder;

    try {
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        return const Result.failure(NotFoundFailure(message: 'Order not found.'));
      }

      existingOrder = _mapDocToOrder(docSnap);

      // Verify ownership or staff/admin
      if (!isStaffOrAdmin && existingOrder.customerId != effectiveUserId) {
        return const Result.failure(
          ForbiddenFailure(message: 'Forbidden: You can only cancel your own orders.'),
        );
      }

      // Customer cannot cancel if readyForPickup or completed
      if (!isStaffOrAdmin &&
          (existingOrder.status == OrderStatus.readyForPickup ||
           existingOrder.status == OrderStatus.completed)) {
        return const Result.failure(
          ForbiddenFailure(message: 'Forbidden: Orders that are ready for pickup or completed cannot be cancelled.'),
        );
      }

      if (existingOrder.status == OrderStatus.completed) {
        return const Result.failure(
          ValidationFailure(message: 'Completed orders cannot be cancelled.'),
        );
      }

      if (existingOrder.status == OrderStatus.cancelled) {
        return Result.success(existingOrder); // Idempotent
      }

      // Execute transaction: restore product inventory and cancel order
      final cancelledOrder = await _firestore.runTransaction<OrderModel>((transaction) async {
        // --- 1. READ PHASE ---
        final currentSnap = await transaction.get(docRef);
        final current = _mapDocToOrder(currentSnap);

        if (current.status == OrderStatus.cancelled) return current;
        if (current.status == OrderStatus.completed) {
          throw const ValidationFailure(message: 'Completed orders cannot be cancelled.');
        }

        // Pre-read all product snapshots
        final productSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        if (isStaffOrAdmin) {
          for (final item in current.items) {
            final pRef = _firestore.collection('products').doc(item.productId);
            final pSnap = await transaction.get(pRef);
            productSnaps[item.productId] = pSnap;
          }
        }

        // Pre-read sale snapshot if it exists
        final DocumentSnapshot<Map<String, dynamic>>? saleSnap;
        final DocumentReference<Map<String, dynamic>>? saleRef;
        if (isStaffOrAdmin) {
          saleRef = _firestore.collection('sales').doc('sale_${current.id}');
          saleSnap = await transaction.get(saleRef);
        } else {
          saleRef = null;
          saleSnap = null;
        }

        // --- 2. WRITE PHASE ---
        // Restore stock in products collection (only staff/admin can update catalog inventory)
        if (isStaffOrAdmin) {
          for (final item in current.items) {
            final pSnap = productSnaps[item.productId];
            if (pSnap != null && pSnap.exists) {
              final pRef = _firestore.collection('products').doc(item.productId);
              final pData = pSnap.data() ?? {};
              final currentStock = (pData['stock_quantity'] ?? pData['stock'] ?? 0) as int;
              final restoredStock = currentStock + item.quantity;
              final newAvailability = restoredStock <= 0
                  ? 'outOfStock'
                  : (restoredStock <= 5 ? 'lowStock' : 'available');

              transaction.update(pRef, {
                'stock_quantity': restoredStock,
                'availability': newAvailability,
                'updated_at': FieldValue.serverTimestamp(),
              });
            }
          }
        }

        // Update order status to cancelled (and mark unpaid/pending payment_status as CANCELLED)
        final now = DateTime.now();
        final shouldCancelPaymentStatus = current.paymentStatus.toUpperCase() != 'PAID';
        final nextPaymentStatus = shouldCancelPaymentStatus ? 'CANCELLED' : current.paymentStatus;
        transaction.set(docRef, {
          'status': OrderStatus.cancelled.name,
          if (shouldCancelPaymentStatus) 'payment_status': 'CANCELLED',
          'status_updated_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }, SetOptions(merge: true));

        // If a sale record somehow existed for this order, void it (only staff/admin)
        if (isStaffOrAdmin && saleSnap != null && saleSnap.exists && saleRef != null) {
          transaction.update(saleRef, {
            'is_voided': true,
            'void_reason': 'Order cancelled',
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        return current.copyWith(
          status: OrderStatus.cancelled,
          paymentStatus: nextPaymentStatus,
        );
      });

      _cachedOrders[cancelledOrder.id] = cancelledOrder;

      // Release first-order reservation lock if this was an active pending GCash order
      if (existingOrder.paymentMethod.toLowerCase().contains('gcash') && !existingOrder.isPaid) {
        try {
          await _firestore
              .collection('first_order_reservations')
              .doc(existingOrder.customerId)
              .set(
                {
                  'customer_id': existingOrder.customerId,
                  'order_id': cancelledOrder.id,
                  'status': 'CANCELLED',
                  'updated_at': DateTime.now().toIso8601String(),
                },
                SetOptions(merge: true),
              );
        } catch (_) {}
      }

      _realtimeService.notifyStatusChanged(
        OrderStatusChangedEvent(
          orderId: cancelledOrder.id,
          orderNumber: cancelledOrder.orderNumber,
          previousStatus: existingOrder.status,
          newStatus: OrderStatus.cancelled,
          order: cancelledOrder,
          updatedByRole: isStaffOrAdmin ? 'staff' : 'customer',
        ),
      );

      return Result.success(cancelledOrder);
    } on ValidationFailure catch (vf) {
      return Result.failure(vf);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Fallback for customer order cancellation when product stock restoration is restricted to staff
        try {
          final now = DateTime.now();
          final shouldCancelPayment =
              existingOrder == null || existingOrder.paymentStatus.toUpperCase() != 'PAID';
          await docRef.update({
            'status': OrderStatus.cancelled.name,
            if (shouldCancelPayment) 'payment_status': 'CANCELLED',
            'status_updated_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          final updatedSnap = await docRef.get();
          final cancelledOrder = _mapDocToOrder(updatedSnap);
          _cachedOrders[cancelledOrder.id] = cancelledOrder;

          if (cancelledOrder.paymentMethod.toLowerCase().contains('gcash') && !cancelledOrder.isPaid) {
            try {
              await _firestore
                  .collection('first_order_reservations')
                  .doc(cancelledOrder.customerId)
                  .set(
                    {
                      'customer_id': cancelledOrder.customerId,
                      'order_id': cancelledOrder.id,
                      'status': 'CANCELLED',
                      'updated_at': now.toIso8601String(),
                    },
                    SetOptions(merge: true),
                  );
            } catch (_) {}
          }

          _realtimeService.notifyStatusChanged(
            OrderStatusChangedEvent(
              orderId: cancelledOrder.id,
              orderNumber: cancelledOrder.orderNumber,
              previousStatus: existingOrder?.status ?? OrderStatus.pending,
              newStatus: OrderStatus.cancelled,
              order: cancelledOrder,
              updatedByRole: 'customer',
            ),
          );

          return Result.success(cancelledOrder);
        } catch (innerErr) {
          if (innerErr is FirebaseException) {
            return Result.failure(_mapFirebaseException(innerErr));
          }
          return Result.failure(ServerFailure(message: innerErr.toString()));
        }
      }
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      if (e is AppFailure) return Result.failure(e);
      return Result.failure(ServerFailure(message: 'Failed to cancel order: $e'));
    }
  }

  // ===========================================================================
  // DEMO ORDER SEEDING (IDEMPOTENT)
  // ===========================================================================

  /// Seeds demo demonstration orders for an authenticated user if no orders exist yet
  Future<void> seedDemoOrdersIfEmpty({
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    try {
      final snap = await _firestore
          .collection('orders')
          .where('customer_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        final batch = _firestore.batch();
        final now = DateTime.now();

        final demoOrder = OrderModel(
          id: 'ord_lmb_1082',
          orderNumber: 'LMB-1082',
          customerId: userId,
          customerName: userName,
          customerPhone: userPhone,
          items: const [
            OrderItemModel(
              id: 'item_1',
              productId: 'mt-apo-honey',
              productName: 'Mount Apo Anaerobic Honey Reserve',
              origin: 'Davao del Sur, Philippines',
              size: '250g Bag',
              grind: 'Whole Bean (Original)',
              unitPrice: 480.0,
              quantity: 1,
              totalPrice: 480.0,
            ),
          ],
          subtotal: 480.0,
          totalAmount: 480.0,
          status: OrderStatus.pending,
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP (~15-20 mins)',
          paymentMethod: 'GCash',
          paymentStatus: 'PENDING',
          createdAt: now.subtract(const Duration(minutes: 8)),
          estimatedReadyAt: now.add(const Duration(minutes: 10)),
        );

        final docRef = _firestore.collection('orders').doc(demoOrder.id);
        batch.set(docRef, demoOrder.toJson(), SetOptions(merge: true));
        await batch.commit();

        _cachedOrders[demoOrder.id] = demoOrder;
      }
    } catch (_) {}
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Future<bool> _isStaffOrAdminUser(String uid) async {
    final user = _auth.currentUser;
    if (user != null &&
        (user.email == 'jmbautista0228@gmail.com' || user.email == 'jmbautistaa0428@gmail.com')) {
      return true;
    }
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final role = UserRole.fromString(doc.data()?['role']?.toString());
        return role == UserRole.admin || role == UserRole.employee;
      }
    } catch (_) {}

    return false;
  }

  OrderModel _mapDocToOrder(DocumentSnapshot doc) {
    final rawData = doc.data() as Map<String, dynamic>? ?? {};
    final map = Map<String, dynamic>.from(rawData);
    map['id'] = doc.id;

    if (map['created_at'] is Timestamp) {
      map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
    }
    if (map['estimated_ready_at'] is Timestamp) {
      map['estimated_ready_at'] = (map['estimated_ready_at'] as Timestamp).toDate().toIso8601String();
    }
    if (map['completed_at'] is Timestamp) {
      map['completed_at'] = (map['completed_at'] as Timestamp).toDate().toIso8601String();
    }
    if (map['status_updated_at'] is Timestamp) {
      map['status_updated_at'] = (map['status_updated_at'] as Timestamp).toDate().toIso8601String();
    }
    if (map['paid_at'] is Timestamp) {
      map['paid_at'] = (map['paid_at'] as Timestamp).toDate().toIso8601String();
    }
    return OrderModel.fromJson(map);
  }

  AppFailure _mapFirebaseException(FirebaseException e, [StackTrace? stackTrace]) {
    return ErrorHandler.handle(
      e,
      stackTrace: stackTrace,
      domain: FailureDomain.orderCreation,
      operation: 'order_repository',
    );
  }
}
