import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import '../events/order_events.dart';

/// Centralized Real-Time Event Broker for Roastery Orders
/// Implements backend-driven event broadcasting to instantly reflect status changes
/// across customer, barista, and admin screens without requiring manual reload.
class OrderRealtimeService {
  static final OrderRealtimeService _instance = OrderRealtimeService._internal();
  factory OrderRealtimeService() => _instance;

  OrderRealtimeService._internal();

  final _statusEventController = StreamController<OrderStatusChangedEvent>.broadcast();
  final _createdEventController = StreamController<OrderCreatedEvent>.broadcast();

  /// Stream of all real-time order status transition events
  Stream<OrderStatusChangedEvent> get orderStatusEvents => _statusEventController.stream;

  /// Stream of newly placed customer orders
  Stream<OrderCreatedEvent> get orderCreatedEvents => _createdEventController.stream;

  /// Watch a specific order by ID or order number in real-time
  Stream<OrderModel> watchOrder(String orderId) {
    return _statusEventController.stream
        .where((event) => event.orderId == orderId || event.orderNumber == orderId)
        .map((event) => event.order);
  }

  /// Broadcast an order status advancement event
  void notifyStatusChanged(OrderStatusChangedEvent event) {
    if (!_statusEventController.isClosed) {
      _statusEventController.add(event);
    }
  }

  /// Broadcast a newly placed order event
  void notifyOrderCreated(OrderCreatedEvent event) {
    if (!_createdEventController.isClosed) {
      _createdEventController.add(event);
    }
  }

  /// Clean up streams (primarily for test teardown)
  void dispose() {
    // Keep singleton controller alive unless resetting
  }
}

/// Riverpod provider for real-time order event broker
final orderRealtimeServiceProvider = Provider<OrderRealtimeService>((ref) {
  return OrderRealtimeService();
});
