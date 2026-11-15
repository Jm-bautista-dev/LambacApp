import 'dart:async';
import 'dart:convert';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/mock_ledger_store.dart';
import '../../../auth/data/datasources/mock_user_database.dart';
import '../../../cart/data/models/pickup_location_model.dart';
import '../../../products/data/datasources/mock_product_database.dart';
import '../../../sales/data/datasources/mock_sales_remote_datasource.dart';
import '../models/create_order_request.dart';
import '../models/first_order_eligibility_model.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../../domain/events/order_events.dart';
import '../../domain/services/order_realtime_service.dart';
import '../../domain/services/pickup_scheduling_service.dart';
import 'order_remote_datasource.dart';

/// Secure, Multi-Tenant Mock Data Source for Customer & Business Orders
/// Enforces Server-Side Ownership, User Isolation, and Role-Based Access Control
class MockOrderRemoteDataSource implements OrderRemoteDataSource {
  static final MockOrderRemoteDataSource _instance = MockOrderRemoteDataSource._internal();
  factory MockOrderRemoteDataSource() => _instance;

  final List<OrderModel> _orders = [];
  final OrderRealtimeService _realtimeService = OrderRealtimeService();

  /// Synchronous lock set for in-flight first-order creations to block concurrent bypass attempts
  final Set<String> _inFlightFirstOrderCustomerIds = {};

  /// Backend reservation ledger mapping customerId -> activepending orderId or COMPLETED:<orderId>
  final Map<String, String> _firstOrderReservations = {};

  /// Idempotency ledger for processed PayMongo webhook event IDs
  final Set<String> _processedWebhookEventIds = {};

  /// Pre-existing legacy test customer IDs grandfathered from historical counter orders
  static const Set<String> _defaultLegacyCustomerIds = {
    'usr_customer_demo',
    'usr_lambac_1001',
    'cust_1',
    'usr_cust_1',
    'usr_cust_2',
    'cust_bob_999',
  };
  final Set<String> _grandfatheredCustomerIds = Set<String>.from(_defaultLegacyCustomerIds);

  List<OrderModel> get allOrders => List.unmodifiable(_orders);

  /// Failure injection hook: simulates the sales ledger failing during completion
  /// so the atomic rollback path can be verified.
  bool simulateSaleFailureForTesting = false;

  MockOrderRemoteDataSource._internal() {
    if (!_loadPersistedOrders()) {
      _seedDefaultOrders();
      _persistOrders();
    }
  }

  /// Restores the durable order ledger. Returns false when nothing was persisted.
  bool _loadPersistedOrders() {
    final raw = MockLedgerStore.read(MockLedgerStore.ordersKey);
    if (raw == null) return false;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _orders.clear();
      _orders.addAll(decoded.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)));
      return true;
    } catch (_) {
      _orders.clear();
      return false;
    }
  }

  /// Writes the committed order ledger to durable storage
  void _persistOrders() {
    if (!MockLedgerStore.isEnabled) return;
    MockLedgerStore.write(
      MockLedgerStore.ordersKey,
      jsonEncode(_orders.map((o) => o.toJson()).toList()),
    );
  }

  /// Reloads persisted orders from storage after MockLedgerStore.init() finishes
  void reloadPersistedOrders() {
    if (MockLedgerStore.isEnabled) {
      if (!_loadPersistedOrders()) {
        _seedDefaultOrders();
        _persistOrders();
      }
    }
  }

  void _seedDefaultOrders() {
    const demoCustomerId = 'usr_customer_demo';
    _orders.addAll([
      OrderModel(
        id: 'ord_lmb_1082',
        orderNumber: 'LMB-1082',
        customerId: demoCustomerId,
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
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
        status: OrderStatus.preparing,
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: 'ASAP (~15-20 mins)',
        paymentMethod: 'Pay at Counter',
        paymentStatus: 'UNPAID',
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        estimatedReadyAt: DateTime.now().add(const Duration(minutes: 10)),
      ),
      OrderModel(
        id: 'ord_lmb_0941',
        orderNumber: 'LMB-0941',
        customerId: demoCustomerId,
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
        items: const [
          OrderItemModel(
            id: 'item_2',
            productId: 'benguet-typica',
            productName: 'Benguet Arabica Typica Heirloom',
            origin: 'Atok, Benguet Highlands',
            size: '250g Bag',
            grind: 'V60 / Pourover (Medium-Fine)',
            unitPrice: 420.0,
            quantity: 2,
            totalPrice: 840.0,
          ),
        ],
        subtotal: 840.0,
        totalAmount: 840.0,
        status: OrderStatus.completed,
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: 'Aug 14, 2026 • 2:30 PM',
        paymentMethod: 'Pay at Counter',
        paymentStatus: 'PAID',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      OrderModel(
        id: 'ord_lmb_0812',
        orderNumber: 'LMB-0812',
        customerId: demoCustomerId,
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
        items: const [
          OrderItemModel(
            id: 'item_3',
            productId: 'tokyo-blend',
            productName: 'Tokyo Kissaten Signature Blend',
            origin: 'Lambac Roastery House Blend',
            size: '250g Bag',
            grind: 'Espresso (Fine Grind)',
            unitPrice: 380.0,
            quantity: 1,
            totalPrice: 380.0,
          ),
        ],
        subtotal: 380.0,
        totalAmount: 380.0,
        status: OrderStatus.completed,
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: 'Jul 29, 2026 • 10:15 AM',
        paymentMethod: 'Pay at Counter',
        paymentStatus: 'PAID',
        createdAt: DateTime.now().subtract(const Duration(days: 23)),
      ),
    ]);
  }

  UserModel? get _currentUser => MockUserDatabase().currentUser;
  void setCurrentUser(UserModel? user) => MockUserDatabase().setCurrentUser(user);

  /// Explicitly enforces first-order mandatory GCash requirement for a customer ID in tests
  void enforceFirstOrderRequirementForCustomer(String customerId) {
    _grandfatheredCustomerIds.remove(customerId);
    _firstOrderReservations.remove(customerId);
    _inFlightFirstOrderCustomerIds.remove(customerId);
  }

  bool _isQualifyingFirstOrder(OrderModel order) {
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

  bool _isActivePendingFirstOrder(OrderModel order) {
    if (order.status == OrderStatus.cancelled || order.status == OrderStatus.completed) {
      return false;
    }
    final pStatus = order.paymentStatus.toUpperCase();
    final isGcash = order.paymentMethod.toLowerCase().contains('gcash');
    return isGcash && pStatus == 'PENDING';
  }

  @override
  FirstOrderEligibility getFirstOrderEligibilitySync(String? userId) {
    final effectiveUserId = userId ?? _currentUser?.id ?? '';
    if (effectiveUserId.isEmpty) {
      return FirstOrderEligibility.firstOrderRequired(customerId: '');
    }

    // 1. Check authoritative backend orders collection for a verified PAID qualifying order
    for (final order in _orders) {
      final matchesUser = order.customerId == effectiveUserId ||
          ((effectiveUserId == 'usr_customer_demo' || effectiveUserId == 'usr_lambac_1001') &&
              (order.customerId == 'usr_customer_demo' || order.customerId == 'usr_lambac_1001'));
      if (matchesUser && _isQualifyingFirstOrder(order)) {
        return FirstOrderEligibility.completed(
          customerId: effectiveUserId,
          qualifyingOrderId: order.id,
        );
      }
    }

    // 2. Check backend reservation ledger for COMPLETED status
    final reservation = _firstOrderReservations[effectiveUserId];
    if (reservation != null && reservation.startsWith('COMPLETED:')) {
      return FirstOrderEligibility.completed(
        customerId: effectiveUserId,
        qualifyingOrderId: reservation.substring('COMPLETED:'.length),
      );
    }

    // 3. Check grandfathered historical test customer accounts
    if (_grandfatheredCustomerIds.contains(effectiveUserId)) {
      return FirstOrderEligibility.completed(
        customerId: effectiveUserId,
        qualifyingOrderId: 'historical_order',
      );
    }

    // 4. Identify any active pending first-order GCash order
    String? activePendingOrderId;
    for (final order in _orders) {
      if (order.customerId == effectiveUserId && _isActivePendingFirstOrder(order)) {
        activePendingOrderId = order.id;
        break;
      }
    }

    return FirstOrderEligibility.firstOrderRequired(
      customerId: effectiveUserId,
      activeFirstOrderId: activePendingOrderId,
    );
  }

  @override
  Future<Result<FirstOrderEligibility, AppFailure>> checkFirstOrderEligibility() async {
    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to check payment eligibility.'),
      );
    }
    return Result.success(getFirstOrderEligibilitySync(user.id));
  }

  @override
  Future<Result<OrderModel, AppFailure>> createOrder(CreateOrderRequest request) async {
    final initialUser = _currentUser;
    if (initialUser == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to place orders.'),
      );
    }

    // 0. Synchronous First-Order GCash Enforcement & Simultaneous Request Lock (BEFORE any await)
    var acquiredFirstOrderLock = false;
    final bool isRetryWithIdempotency = request.idempotencyKey != null &&
        request.idempotencyKey!.trim().isNotEmpty &&
        _orders.any((o) => o.idempotencyKey == request.idempotencyKey!.trim());

    if (initialUser.isCustomer && !isRetryWithIdempotency) {
      final eligibility = getFirstOrderEligibilitySync(initialUser.id);
      if (eligibility.requiresFirstOrderGcash) {
        final isGcashMethod = request.paymentMethod.toLowerCase().contains('gcash');
        if (!isGcashMethod) {
          return const Result.failure(
            ValidationFailure(
              message: 'Your first order must be paid through GCash. Pay at Counter is unavailable until your first GCash order is verified as PAID.',
            ),
          );
        }

        if (_inFlightFirstOrderCustomerIds.contains(initialUser.id) ||
            eligibility.activeFirstOrderId != null) {
          return Result.failure(
            ValidationFailure(
              message: 'You already have an active first-order GCash checkout in progress${eligibility.activeFirstOrderId != null ? " (${eligibility.activeFirstOrderId})" : ""}. Simultaneous first-order requests are not allowed.',
            ),
          );
        }

        _inFlightFirstOrderCustomerIds.add(initialUser.id);
        acquiredFirstOrderLock = true;
      }
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final user = _currentUser ?? initialUser;

      if (request.items.isEmpty) {
        return const Result.failure(
          ValidationFailure(message: 'Cannot place an order with an empty cart.'),
        );
      }

      // 1. Idempotency Check: Fast return if request is a retry of an existing submission
      if (request.idempotencyKey != null && request.idempotencyKey!.trim().isNotEmpty) {
        final existingIndex = _orders.indexWhere((o) => o.idempotencyKey == request.idempotencyKey!.trim());
        if (existingIndex >= 0) {
          return Result.success(_orders[existingIndex]);
        }
      }

      // Re-verify first-order lock after async delay in case another order was committed
      if (user.isCustomer) {
        final eligibility = getFirstOrderEligibilitySync(user.id);
        if (eligibility.requiresFirstOrderGcash) {
          if (!request.paymentMethod.toLowerCase().contains('gcash')) {
            return const Result.failure(
              ValidationFailure(
                message: 'Your first order must be paid through GCash. Pay at Counter is unavailable until your first GCash order is verified as PAID.',
              ),
            );
          }
          if (eligibility.activeFirstOrderId != null) {
            return Result.failure(
              ValidationFailure(
                message: 'You already have an active first-order GCash checkout in progress (${eligibility.activeFirstOrderId}). Simultaneous first-order requests are not allowed.',
              ),
            );
          }
        }
      }

      // 2. Server-Side Catalog, Stock & Pricing Enforcement
      final productDb = MockProductDatabase();
      final verifiedOrderItems = <OrderItemModel>[];

      for (final item in request.items) {
        final product = productDb.getProductById(item.productId);
        if (product == null) {
          return Result.failure(
            ValidationFailure(message: 'Product "${item.productName}" is no longer available in the catalog.'),
          );
        }
        if (!product.isEnabled || !product.isOrderable) {
          return Result.failure(
            ValidationFailure(
              message: 'Product "${product.name}" is currently unavailable or sold out. Please remove it from your cart to proceed.',
            ),
          );
        }

        if (product.stockQuantity < item.quantity) {
          return Result.failure(
            ValidationFailure(
              message: 'Insufficient stock for "${product.name}". Requested: ${item.quantity}, Available: ${product.stockQuantity}.',
            ),
          );
        }

        final liveBasePrice = product.basePrice;
        final sizeDelta = item.sizeVariant?.priceDelta ?? 0.0;
        final grindDelta = item.grindVariant?.priceDelta ?? 0.0;
        final liveExpectedUnitPrice = liveBasePrice + sizeDelta + grindDelta;

        if ((liveExpectedUnitPrice - item.unitPrice).abs() > 0.01) {
          return Result.failure(
            ValidationFailure(
              message: 'Price change detected on "${item.productName}". Current price is ₱${liveExpectedUnitPrice.toStringAsFixed(2)} (Cart had ₱${item.unitPrice.toStringAsFixed(2)}). Please refresh your cart.',
            ),
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

      // Server-Side Pickup Schedule & Operating Hours Validation
      final pickupDate = request.pickupDate;
      final pickupTimeSlot = request.pickupTimeSlot;
      final scheduleValidation = PickupSchedulingService().validateSchedule(
        dateStr: pickupDate,
        timeSlotStr: pickupTimeSlot,
        location: request.pickupLocation,
      );

      if (scheduleValidation.isFailure) {
        return Result.failure(scheduleValidation.failureOrNull!);
      }

      // 3. Atomically decrement stock
      for (final item in request.items) {
        productDb.updateStock(item.productId, -item.quantity);
      }

      final verifiedSubtotal = verifiedOrderItems.fold(0.0, (acc, item) => acc + item.totalPrice);
      final randomSuffix = (1000 + (DateTime.now().microsecondsSinceEpoch % 8999)).toString();
      final orderId = 'ord_lmb_$randomSuffix';
      final orderNumber = 'LMB-$randomSuffix';
      final isGcash = request.paymentMethod.toLowerCase().contains('gcash');

      // Server-Side Authorization: Derive customerId strictly from authenticated session token
      final newOrder = OrderModel(
        id: orderId,
        orderNumber: orderNumber,
        customerId: user.id,
        customerName: request.customerName.isNotEmpty ? request.customerName : user.fullName,
        customerPhone: request.customerPhone.isNotEmpty ? request.customerPhone : (user.phoneNumber ?? '09171234567'),
        items: verifiedOrderItems,
        subtotal: verifiedSubtotal,
        totalAmount: verifiedSubtotal,
        status: OrderStatus.pending,
        pickupLocation: request.pickupLocation,
        pickupDate: request.pickupDate,
        pickupTimeSlot: request.pickupTimeSlot,
        paymentMethod: request.paymentMethod,
        paymentStatus: isGcash ? 'PENDING' : 'UNPAID',
        paymentProvider: isGcash ? 'paymongo' : null,
        notes: request.notes,
        createdAt: DateTime.now(),
        estimatedReadyAt: DateTime.now().add(const Duration(minutes: 20)),
        idempotencyKey: request.idempotencyKey,
      );

      _orders.insert(0, newOrder);
      if (acquiredFirstOrderLock) {
        _firstOrderReservations[user.id] = newOrder.id;
      }
      _persistOrders();
      _realtimeService.notifyOrderCreated(OrderCreatedEvent(order: newOrder));
      return Result.success(newOrder);
    } finally {
      if (acquiredFirstOrderLock) {
        _inFlightFirstOrderCustomerIds.remove(initialUser.id);
      }
    }
  }

  @override
  Future<Result<PaginatedList<OrderModel>, AppFailure>> getOrders({
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
    OrderStatus? statusFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to access orders.'),
      );
    }

    List<OrderModel> visibleOrders;
    if (user.isAdmin || user.isEmployee) {
      // Business Admin & Authorized Staff see all business orders
      visibleOrders = List.from(_orders);
    } else {
      // Customer sees strictly their own orders (alias usr_lambac_1001 for legacy demo)
      visibleOrders = _orders.where((o) {
        return o.customerId == user.id ||
            ((user.id == 'usr_customer_demo' || user.id == 'usr_lambac_1001') &&
                (o.customerId == 'usr_customer_demo' || o.customerId == 'usr_lambac_1001'));
      }).toList();
    }

    if (statusFilter != null) {
      visibleOrders = visibleOrders.where((o) => o.status == statusFilter).toList();
    }

    visibleOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int startIndex = (page - 1) * limit;
    if (lastDocument is int) {
      startIndex = lastDocument;
    } else if (lastDocument is String) {
      final idx = visibleOrders.indexWhere((o) => o.id == lastDocument);
      if (idx != -1) {
        startIndex = idx + 1;
      }
    }

    final endIndex = (startIndex + limit) > visibleOrders.length ? visibleOrders.length : startIndex + limit;
    final paginatedItems = startIndex < visibleOrders.length ? visibleOrders.sublist(startIndex, endIndex) : <OrderModel>[];
    final nextCursor = paginatedItems.isNotEmpty ? paginatedItems.last.id : null;

    return Result.success(
      PaginatedList<OrderModel>(
        items: List.unmodifiable(paginatedItems),
        page: page,
        pageSize: limit,
        totalCount: visibleOrders.length,
        hasNextPage: endIndex < visibleOrders.length,
        cursor: nextCursor,
      ),
    );
  }

  @override
  Future<Result<OrderModel, AppFailure>> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 80));

    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to view order details.'),
      );
    }

    final index = _orders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    if (index == -1) {
      return const Result.failure(NotFoundFailure(message: 'Order not found.'));
    }

    final order = _orders[index];

    // Server-Side RBAC & IDOR Protection:
    // If regular customer, verify order ownership
    final isOwner = order.customerId == user.id ||
        ((user.id == 'usr_customer_demo' || user.id == 'usr_lambac_1001') &&
            (order.customerId == 'usr_customer_demo' || order.customerId == 'usr_lambac_1001'));

    if (user.isCustomer && !isOwner) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Access denied to this order.'),
      );
    }

    return Result.success(order);
  }

  @override
  Future<Result<OrderModel, AppFailure>> updateOrderStatus(String orderId, OrderStatus status) async {
    await Future.delayed(const Duration(milliseconds: 60));

    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to process orders.'),
      );
    }

    if (!user.isBusinessUser) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Processing orders requires Staff, Barista, or Admin access.'),
      );
    }

    final index = _orders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    if (index == -1) {
      return const Result.failure(NotFoundFailure(message: 'Order not found.'));
    }

    final existingOrder = _orders[index];

    // Idempotent: a duplicate / retried request for the already-persisted status
    // is a safe no-op (no duplicate sale, no duplicate broadcast).
    if (existingOrder.status == status) {
      return Result.success(existingOrder);
    }

    // Enforce valid status transition lifecycle (backend is the security layer)
    if (!existingOrder.status.canTransitionTo(status)) {
      return Result.failure(
        ValidationFailure(
          message: 'Cannot transition order #${existingOrder.orderNumber} from ${existingOrder.status.toDisplayString()} to ${status.toDisplayString()}.',
        ),
      );
    }

    final isCompleting = status == OrderStatus.completed;
    final isGcashOrder = existingOrder.paymentMethod.toLowerCase().contains('gcash');
    final existingPaymentUpper = existingOrder.paymentStatus.toUpperCase();

    // Prevent staff from advancing a failed, expired, or cancelled GCash order
    if (isGcashOrder &&
        status != OrderStatus.cancelled &&
        (existingPaymentUpper == 'FAILED' ||
            existingPaymentUpper == 'EXPIRED' ||
            existingPaymentUpper == 'CANCELLED')) {
      return Result.failure(
        ValidationFailure(
          message: 'Cannot advance GCash order #${existingOrder.orderNumber} to ${status.toDisplayString()} while payment status is $existingPaymentUpper.',
        ),
      );
    }

    // Prevent staff from completing an unverified GCash order
    if (isCompleting &&
        isGcashOrder &&
        existingPaymentUpper != 'PAID') {
      return Result.failure(
        ValidationFailure(
          message: 'Cannot complete GCash order #${existingOrder.orderNumber} while payment status is ${existingOrder.paymentStatus}. GCash payment must be verified by PayMongo first.',
        ),
      );
    }

    // Business rule: Status transitions (confirmed, preparing, prepared, readyForPickup) NEVER change payment status.
    // Upon pickup completion, Pay at Counter orders settle counter payment to PAID, while GCash orders must already be verified PAID.
    final paymentStatus = (isCompleting && !isGcashOrder) ? 'PAID' : existingOrder.paymentStatus;

    final updatedOrder = existingOrder.copyWith(
      status: status,
      paymentStatus: paymentStatus,
      completedAt: isCompleting ? (existingOrder.completedAt ?? DateTime.now()) : existingOrder.completedAt,
    );

    // ---- BEGIN TRANSACTION: order completion + sale recording are atomic ----
    final salesLedger = MockSalesRemoteDataSource();
    final hadSaleBefore = salesLedger.hasSaleForOrder(updatedOrder.id);
    _orders[index] = updatedOrder;

    if (isCompleting) {
      var saleRecorded = false;
      try {
        if (simulateSaleFailureForTesting) {
          throw StateError('Simulated sales ledger failure');
        }
        saleRecorded = salesLedger.recordCompletedOrderSale(updatedOrder);
      } catch (_) {
        saleRecorded = false;
      }

      if (!saleRecorded) {
        // ROLLBACK: restore previous persisted order state and remove any partial sale
        _orders[index] = existingOrder;
        if (!hadSaleBefore) salesLedger.rollbackSaleForOrder(updatedOrder.id);
        return const Result.failure(
          ServerFailure(message: 'Could not complete the order because the sale could not be recorded. The order was not changed. Please try again.'),
        );
      }
    }
    // ---- COMMIT ----
    _persistOrders();

    // Broadcast real-time event only AFTER the change is committed
    _realtimeService.notifyStatusChanged(
      OrderStatusChangedEvent(
        orderId: updatedOrder.id,
        orderNumber: updatedOrder.orderNumber,
        previousStatus: existingOrder.status,
        newStatus: status,
        order: updatedOrder,
        updatedByRole: user.role.name,
      ),
    );

    return Result.success(updatedOrder);
  }

  @override
  Future<Result<OrderModel, AppFailure>> updatePaymentStatus(String orderId, PaymentStatus status) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    if (!user.isBusinessUser) {
      return const Result.failure(
        ForbiddenFailure(message: 'Recording counter payments requires staff or admin access.'),
      );
    }

    final index = _orders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    if (index == -1) {
      return const Result.failure(NotFoundFailure(message: 'Order not found.'));
    }

    final existingOrder = _orders[index];

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

    final updatedOrder = existingOrder.copyWith(
      paymentStatus: status.toDisplayString(),
    );

    _orders[index] = updatedOrder;
    _persistOrders();

    // Broadcast real-time event so UI and stream listeners receive the update immediately
    _realtimeService.notifyStatusChanged(
      OrderStatusChangedEvent(
        orderId: updatedOrder.id,
        orderNumber: updatedOrder.orderNumber,
        previousStatus: existingOrder.status,
        newStatus: updatedOrder.status,
        order: updatedOrder,
        updatedByRole: user.role.name,
      ),
    );

    return Result.success(updatedOrder);
  }

  @override
  Future<Result<OrderModel, AppFailure>> cancelOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    final index = _orders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    if (index == -1) {
      return const Result.failure(NotFoundFailure(message: 'Order not found.'));
    }

    final order = _orders[index];

    // Verify ownership or administrative permission
    final isOwner = order.customerId == user.id ||
        ((user.id == 'usr_customer_demo' || user.id == 'usr_lambac_1001') &&
            (order.customerId == 'usr_customer_demo' || order.customerId == 'usr_lambac_1001'));

    if (user.isCustomer && !isOwner) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: You can only cancel your own orders.'),
      );
    }

    // Customer cannot cancel if readyForPickup or completed
    if (user.isCustomer &&
        (order.status == OrderStatus.readyForPickup ||
         order.status == OrderStatus.completed)) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Orders that are ready for pickup or completed cannot be cancelled.'),
      );
    }

    if (order.status == OrderStatus.completed) {
      return const Result.failure(
        ValidationFailure(message: 'Completed orders cannot be cancelled.'),
      );
    }

    if (order.status == OrderStatus.cancelled) {
      return Result.success(order); // Idempotent
    }

    // Restore stock in catalog
    final productDb = MockProductDatabase();
    for (final item in order.items) {
      productDb.updateStock(item.productId, item.quantity);
    }

    final shouldCancelPayment = order.paymentStatus.toUpperCase() != 'PAID';
    final updated = order.copyWith(
      status: OrderStatus.cancelled,
      paymentStatus: shouldCancelPayment ? 'CANCELLED' : order.paymentStatus,
    );
    _orders[index] = updated;
    if (_firstOrderReservations[order.customerId] == order.id) {
      _firstOrderReservations.remove(order.customerId);
    }
    _persistOrders();

    _realtimeService.notifyStatusChanged(
      OrderStatusChangedEvent(
        orderId: updated.id,
        orderNumber: updated.orderNumber,
        previousStatus: order.status,
        newStatus: OrderStatus.cancelled,
        order: updated,
        updatedByRole: user.role.name,
      ),
    );

    return Result.success(updated);
  }

  /// Helper to manually add an order for testing
  void addOrder(OrderModel order) {
    _orders.insert(0, order);
  }

  /// Override orders directly for testing
  void setOrdersForTesting(List<OrderModel> orders) {
    _orders.clear();
    _orders.addAll(orders);
  }

  /// Clear all orders for testing empty queue
  void clearOrdersForTesting() {
    _orders.clear();
    _inFlightFirstOrderCustomerIds.clear();
    _firstOrderReservations.clear();
    _processedWebhookEventIds.clear();
    _grandfatheredCustomerIds
      ..clear()
      ..addAll(_defaultLegacyCustomerIds);
  }

  /// Reset all orders for test isolation
  void resetForTesting() {
    _orders.clear();
    _inFlightFirstOrderCustomerIds.clear();
    _firstOrderReservations.clear();
    _processedWebhookEventIds.clear();
    _grandfatheredCustomerIds
      ..clear()
      ..addAll(_defaultLegacyCustomerIds);
    _seedDefaultOrders();
  }

  // ===========================================================================
  // BACKEND PAYMONGO GCASH CHECKOUT & WEBHOOK VERIFICATION (SERVER SIMULATION)
  // ===========================================================================

  /// Creates a PayMongo GCash Checkout Session for an order, enforcing first-order rules
  Future<Result<OrderModel, AppFailure>> createPaymongoCheckoutSession(String orderId) async {
    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to create a GCash checkout session.'),
      );
    }

    final index = _orders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    if (index == -1) {
      return const Result.failure(NotFoundFailure(message: 'Order not found.'));
    }

    final order = _orders[index];
    if (user.isCustomer && order.customerId != user.id) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: You do not own this order.'),
      );
    }

    if (!order.paymentMethod.toLowerCase().contains('gcash')) {
      return const Result.failure(
        ValidationFailure(message: 'PayMongo checkout session requires GCash payment method.'),
      );
    }

    if (order.paymentStatus.toUpperCase() == 'PAID') {
      return const Result.failure(
        ValidationFailure(message: 'Order is already verified as PAID.'),
      );
    }

    // Check simultaneous active first-order session lock
    final eligibility = getFirstOrderEligibilitySync(order.customerId);
    if (eligibility.requiresFirstOrderGcash &&
        eligibility.activeFirstOrderId != null &&
        eligibility.activeFirstOrderId != order.id) {
      return Result.failure(
        ValidationFailure(
          message: 'You already have an active first-order GCash checkout session in progress (${eligibility.activeFirstOrderId}).',
        ),
      );
    }

    final sessionId = order.paymentReference ?? 'cs_lmb_${order.id}';
    final checkoutUrl = order.checkoutUrl ?? 'https://checkout.paymongo.com/$sessionId';

    final updated = order.copyWith(
      paymentStatus: 'PENDING',
      paymentProvider: 'paymongo',
      paymentReference: sessionId,
      checkoutUrl: checkoutUrl,
    );

    _orders[index] = updated;
    if (eligibility.requiresFirstOrderGcash) {
      _firstOrderReservations[order.customerId] = updated.id;
    }
    _persistOrders();
    return Result.success(updated);
  }

  /// Processes a verified PayMongo webhook event (`checkout_session.payment.paid`, `payment.failed`, `checkout_session.expired`)
  /// Only a verified PAID event completes the customer's first-order GCash requirement.
  Future<Result<OrderModel, AppFailure>> processPaymongoWebhookEvent({
    required String orderId,
    required String eventType,
    String? eventId,
    String? paymentId,
    String? failureReason,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    if (index == -1) {
      return const Result.failure(NotFoundFailure(message: 'Order not found for webhook event.'));
    }

    final existingOrder = _orders[index];

    // Idempotency check
    if (eventId != null && eventId.isNotEmpty) {
      if (_processedWebhookEventIds.contains(eventId)) {
        return Result.success(existingOrder);
      }
      _processedWebhookEventIds.add(eventId);
    }

    final now = DateTime.now();
    OrderModel updatedOrder = existingOrder;

    if (eventType == 'checkout_session.payment.paid' || eventType == 'payment.paid') {
      final resolvedRef = paymentId ?? existingOrder.paymentReference ?? 'pay_gcash_${existingOrder.id}';
      updatedOrder = existingOrder.copyWith(
        paymentStatus: 'PAID',
        paymentProvider: 'paymongo',
        paymentReference: resolvedRef,
        paidAt: existingOrder.paidAt ?? now,
      );
      _orders[index] = updatedOrder;

      // Mark first-order requirement as completed in backend reservation ledger & user database
      _firstOrderReservations[existingOrder.customerId] = 'COMPLETED:${existingOrder.id}';
      final userDb = MockUserDatabase();
      final userRecord = userDb.getById(existingOrder.customerId);
      if (userRecord != null) {
        final updatedUser = userRecord.user.copyWith(
          firstOrderGcashCompleted: true,
          firstOrderCompletedOrderId: existingOrder.id,
          firstOrderCompletedAt: now,
        );
        userDb.records[userRecord.user.email.toLowerCase()] = UserDatabaseRecord(
          user: updatedUser,
          passwordHash: userRecord.passwordHash,
        );
        if (userDb.currentUser?.id == updatedUser.id) {
          userDb.setCurrentUser(updatedUser);
        }
      }
    } else if (eventType == 'payment.failed') {
      // Never downgrade an already verified PAID order
      if (existingOrder.paymentStatus.toUpperCase() != 'PAID') {
        updatedOrder = existingOrder.copyWith(
          paymentStatus: 'FAILED',
          paymentProvider: 'paymongo',
          paymentFailureReason: failureReason ?? 'GCash payment failed or was declined.',
        );
        _orders[index] = updatedOrder;
        if (_firstOrderReservations[existingOrder.customerId] == existingOrder.id) {
          _firstOrderReservations.remove(existingOrder.customerId);
        }
      }
    } else if (eventType == 'checkout_session.expired') {
      // Never downgrade an already verified PAID order
      if (existingOrder.paymentStatus.toUpperCase() != 'PAID') {
        updatedOrder = existingOrder.copyWith(
          paymentStatus: 'EXPIRED',
          paymentProvider: 'paymongo',
          paymentFailureReason: failureReason ?? 'PayMongo GCash checkout session expired.',
        );
        _orders[index] = updatedOrder;
        if (_firstOrderReservations[existingOrder.customerId] == existingOrder.id) {
          _firstOrderReservations.remove(existingOrder.customerId);
        }
      }
    } else {
      return Result.failure(
        ValidationFailure(message: 'Unsupported PayMongo webhook event type: $eventType'),
      );
    }

    _persistOrders();
    _realtimeService.notifyStatusChanged(
      OrderStatusChangedEvent(
        orderId: updatedOrder.id,
        orderNumber: updatedOrder.orderNumber,
        previousStatus: existingOrder.status,
        newStatus: updatedOrder.status,
        order: updatedOrder,
        updatedByRole: 'paymongo_webhook',
      ),
    );

    return Result.success(updatedOrder);
  }

  @override
  void clearSession() {
    // Teardown mock session state
  }
}
