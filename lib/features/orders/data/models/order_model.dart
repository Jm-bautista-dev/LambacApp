import 'package:equatable/equatable.dart';
import '../../../cart/data/models/pickup_location_model.dart';
import 'order_item_model.dart';

/// Status of a Pickup Order
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  prepared,
  readyForPickup,
  completed,
  cancelled;

  static OrderStatus fromString(String? val) {
    if (val == null || val.trim().isEmpty) {
      return OrderStatus.pending;
    }
    final clean = val.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');
    return switch (clean) {
      'pending' || 'order_placed' || 'placed' => OrderStatus.pending,
      'confirmed' || 'accepted' || 'order_confirmed' => OrderStatus.confirmed,
      'preparing' || 'roasting' || 'brewing' || 'in_progress' => OrderStatus.preparing,
      'prepared' => OrderStatus.prepared,
      'ready_for_pickup' || 'readyforpickup' || 'ready_to_pick_up' || 'readytopickup' || 'ready' => OrderStatus.readyForPickup,
      'completed' || 'complete' || 'picked_up' || 'pickedup' || 'finished' || 'done' => OrderStatus.completed,
      'cancelled' || 'canceled' || 'voided' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }

  String toDisplayString() {
    return switch (this) {
      OrderStatus.pending => 'Order Placed',
      OrderStatus.confirmed => 'Order Confirmed',
      OrderStatus.preparing => 'Preparing',
      OrderStatus.prepared => 'Prepared',
      OrderStatus.readyForPickup => 'Ready for Pickup',
      OrderStatus.completed => 'Completed',
      OrderStatus.cancelled => 'Cancelled',
    };
  }

  int get stepIndex {
    return switch (this) {
      OrderStatus.pending => 0,
      OrderStatus.confirmed => 1,
      OrderStatus.preparing => 2,
      OrderStatus.prepared => 3,
      OrderStatus.readyForPickup => 4,
      OrderStatus.completed => 5,
      OrderStatus.cancelled => -1,
    };
  }

  bool get isActive => this != OrderStatus.completed && this != OrderStatus.cancelled;

  /// Validates if transition to [next] is allowed by business rules
  bool canTransitionTo(OrderStatus next) {
    if (this == next) return true; // Idempotent
    return switch (this) {
      OrderStatus.pending => next == OrderStatus.confirmed || next == OrderStatus.preparing || next == OrderStatus.cancelled,
      OrderStatus.confirmed => next == OrderStatus.preparing || next == OrderStatus.cancelled,
      OrderStatus.preparing => next == OrderStatus.prepared || next == OrderStatus.readyForPickup || next == OrderStatus.cancelled,
      OrderStatus.prepared => next == OrderStatus.readyForPickup || next == OrderStatus.cancelled,
      OrderStatus.readyForPickup => next == OrderStatus.completed,
      OrderStatus.completed => false, // Terminal
      OrderStatus.cancelled => false, // Terminal
    };
  }

  /// Next standard progression in the pickup lifecycle
  OrderStatus? get nextLifecycleStatus {
    return switch (this) {
      OrderStatus.pending => OrderStatus.preparing,
      OrderStatus.confirmed => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.prepared,
      OrderStatus.prepared => OrderStatus.readyForPickup,
      OrderStatus.readyForPickup => OrderStatus.completed,
      OrderStatus.completed => null,
      OrderStatus.cancelled => null,
    };
  }
}

/// Payment Status for Lambac Roastery Pickup Orders
enum PaymentStatus {
  unpaid,
  paid,
  pending,
  failed,
  cancelled,
  expired,
  refunded;

  static PaymentStatus fromString(String? val) {
    return switch (val?.toLowerCase().trim()) {
      'paid' || 'paid at counter' => PaymentStatus.paid,
      'pending' || 'awaiting_payment' || 'processing' => PaymentStatus.pending,
      'failed' => PaymentStatus.failed,
      'cancelled' || 'canceled' => PaymentStatus.cancelled,
      'expired' => PaymentStatus.expired,
      'refunded' => PaymentStatus.refunded,
      _ => PaymentStatus.unpaid,
    };
  }

  String toDisplayString() {
    return switch (this) {
      PaymentStatus.unpaid => 'UNPAID',
      PaymentStatus.paid => 'PAID',
      PaymentStatus.pending => 'PENDING',
      PaymentStatus.failed => 'FAILED',
      PaymentStatus.cancelled => 'CANCELLED',
      PaymentStatus.expired => 'EXPIRED',
      PaymentStatus.refunded => 'REFUNDED',
    };
  }

  bool get isPaid => this == PaymentStatus.paid;
  bool get isUnpaid => this == PaymentStatus.unpaid;
  bool get isPending => this == PaymentStatus.pending;
  bool get isFailed => this == PaymentStatus.failed || this == PaymentStatus.expired || this == PaymentStatus.cancelled;
  bool get isRefunded => this == PaymentStatus.refunded;
}

/// Core Order Entity for Lambac Roastery Pickup Orders
class OrderModel extends Equatable {
  final String id;
  final String orderNumber; // e.g. "LMB-1089"
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItemModel> items;
  final double subtotal;
  final double totalAmount;
  final OrderStatus status;
  final PickupLocationModel pickupLocation;
  final String pickupDate;
  final String pickupTimeSlot;
  final String paymentMethod;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime? estimatedReadyAt;

  /// Timestamp at which the customer pickup was completed (null until completed)
  final DateTime? completedAt;

  /// Idempotency key for preventing duplicate submission / retried creation
  final String? idempotencyKey;

  /// Payment Gateway / Provider details (e.g. PayMongo, In-Store)
  final String? paymentProvider;

  /// Transaction / Payment Reference ID (e.g. PayMongo pay_... or cs_...)
  final String? paymentReference;

  /// Hosted Checkout URL from payment gateway
  final String? checkoutUrl;

  /// Timestamp when online payment was confirmed
  final DateTime? paidAt;

  /// Failure reason if online payment failed or expired
  final String? paymentFailureReason;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.totalAmount,
    required this.status,
    required this.pickupLocation,
    this.pickupDate = 'Today',
    required this.pickupTimeSlot,
    this.paymentMethod = 'Pay at Counter',
    this.paymentStatus = 'UNPAID',
    this.notes,
    required this.createdAt,
    this.estimatedReadyAt,
    this.completedAt,
    this.idempotencyKey,
    this.paymentProvider,
    this.paymentReference,
    this.checkoutUrl,
    this.paidAt,
    this.paymentFailureReason,
  });

  int get totalItemCount => items.fold(0, (acc, item) => acc + item.quantity);

  PaymentStatus get paymentStatusEnum => PaymentStatus.fromString(paymentStatus);
  bool get isPaid => paymentStatusEnum.isPaid;
  bool get isUnpaid => paymentStatusEnum.isUnpaid;
  bool get isPending => paymentStatusEnum.isPending;
  bool get isPaymentFailed => paymentStatusEnum.isFailed;
  bool get isPaymentRefunded => paymentStatusEnum.isRefunded;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedStatus = OrderStatus.fromString(json['status']?.toString());
    final resolvedPaymentMethod =
        (json['payment_method'] ?? json['paymentMethod'] ?? 'Pay at Counter').toString();
    final isGcashMethod = resolvedPaymentMethod.toLowerCase().contains('gcash');
    final rawPaymentStatus = json['payment_status'] ?? json['paymentStatus'];
    // Strictly separate fulfillment status from payment status:
    // Never assume status == OrderStatus.completed means payment_status == 'PAID'.
    final resolvedPaymentStatus = (rawPaymentStatus != null &&
            rawPaymentStatus.toString().trim().isNotEmpty)
        ? PaymentStatus.fromString(rawPaymentStatus.toString()).toDisplayString()
        : (isGcashMethod ? 'PENDING' : 'UNPAID');

    return OrderModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      orderNumber: (json['order_number'] ?? json['orderNumber'] ?? 'LMB-${DateTime.now().millisecond}').toString(),
      customerId: (json['customer_id'] ?? json['userId'] ?? '').toString(),
      customerName: (json['customer_name'] ?? json['userName'] ?? 'Customer').toString(),
      customerPhone: (json['customer_phone'] ?? json['phone'] ?? '').toString(),
      items: rawItems.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      subtotal: ((json['subtotal'] ?? json['total'] ?? 0.0) as num).toDouble(),
      totalAmount: ((json['total_amount'] ?? json['total'] ?? 0.0) as num).toDouble(),
      status: parsedStatus,
      pickupLocation: json['pickup_location'] != null
          ? PickupLocationModel.fromJson(json['pickup_location'] as Map<String, dynamic>)
          : PickupLocationModel.flagship,
      pickupDate: (json['pickup_date'] ?? json['pickupDate'] ?? 'Today').toString(),
      pickupTimeSlot: (json['pickup_time_slot'] ?? json['pickupTime'] ?? 'ASAP (~15-20 mins)').toString(),
      paymentMethod: (json['payment_method'] ?? json['paymentMethod'] ?? 'Pay at Counter').toString(),
      paymentStatus: resolvedPaymentStatus,
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estimatedReadyAt: json['estimated_ready_at'] != null
          ? DateTime.tryParse(json['estimated_ready_at'].toString())
          : null,
      completedAt: (json['completed_at'] ?? json['picked_up_at']) != null
          ? DateTime.tryParse((json['completed_at'] ?? json['picked_up_at']).toString())
          : null,
      idempotencyKey: json['idempotency_key']?.toString(),
      paymentProvider: json['payment_provider']?.toString() ?? json['paymentProvider']?.toString(),
      paymentReference: (json['payment_reference'] ?? json['paymentReference'] ?? json['checkout_session_id'])?.toString(),
      checkoutUrl: json['checkout_url']?.toString() ?? json['checkoutUrl']?.toString(),
      paidAt: (json['paid_at'] ?? json['paidAt']) != null
          ? DateTime.tryParse((json['paid_at'] ?? json['paidAt']).toString())
          : null,
      paymentFailureReason:
          (json['payment_failure_reason'] ?? json['paymentFailureReason'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'total_amount': totalAmount,
      'status': status.name,
      'pickup_location': pickupLocation.toJson(),
      'pickup_date': pickupDate,
      'pickup_time_slot': pickupTimeSlot,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (estimatedReadyAt != null) 'estimated_ready_at': estimatedReadyAt?.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt?.toIso8601String(),
      if (idempotencyKey != null && idempotencyKey!.isNotEmpty) 'idempotency_key': idempotencyKey,
      if (paymentProvider != null) 'payment_provider': paymentProvider,
      if (paymentReference != null) 'payment_reference': paymentReference,
      if (checkoutUrl != null) 'checkout_url': checkoutUrl,
      if (paidAt != null) 'paid_at': paidAt?.toIso8601String(),
      if (paymentFailureReason != null) 'payment_failure_reason': paymentFailureReason,
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<OrderItemModel>? items,
    double? subtotal,
    double? totalAmount,
    OrderStatus? status,
    PickupLocationModel? pickupLocation,
    String? pickupDate,
    String? pickupTimeSlot,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? estimatedReadyAt,
    DateTime? completedAt,
    String? idempotencyKey,
    String? paymentProvider,
    String? paymentReference,
    String? checkoutUrl,
    DateTime? paidAt,
    String? paymentFailureReason,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTimeSlot: pickupTimeSlot ?? this.pickupTimeSlot,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      estimatedReadyAt: estimatedReadyAt ?? this.estimatedReadyAt,
      completedAt: completedAt ?? this.completedAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      paymentReference: paymentReference ?? this.paymentReference,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      paidAt: paidAt ?? this.paidAt,
      paymentFailureReason: paymentFailureReason ?? this.paymentFailureReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        customerId,
        customerName,
        customerPhone,
        items,
        subtotal,
        totalAmount,
        status,
        pickupLocation,
        pickupDate,
        pickupTimeSlot,
        paymentMethod,
        paymentStatus,
        notes,
        createdAt,
        estimatedReadyAt,
        completedAt,
        idempotencyKey,
        paymentProvider,
        paymentReference,
        checkoutUrl,
        paidAt,
        paymentFailureReason,
      ];
}
