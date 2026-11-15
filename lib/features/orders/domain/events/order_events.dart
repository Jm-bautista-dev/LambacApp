import 'package:equatable/equatable.dart';
import '../../data/models/order_model.dart';

/// Event dispatched across the application when an order status advances in real time
class OrderStatusChangedEvent extends Equatable {
  final String orderId;
  final String orderNumber;
  final OrderStatus previousStatus;
  final OrderStatus newStatus;
  final OrderModel order;
  final String? updatedByRole;
  final DateTime timestamp;

  OrderStatusChangedEvent({
    required this.orderId,
    required this.orderNumber,
    required this.previousStatus,
    required this.newStatus,
    required this.order,
    this.updatedByRole,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [
        orderId,
        orderNumber,
        previousStatus,
        newStatus,
        order,
        updatedByRole,
        timestamp,
      ];
}

/// Event dispatched when a customer submits a new pickup order
class OrderCreatedEvent extends Equatable {
  final OrderModel order;
  final DateTime timestamp;

  OrderCreatedEvent({
    required this.order,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [order, timestamp];
}
