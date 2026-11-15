import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../data/models/create_order_request.dart';
import '../../data/models/first_order_eligibility_model.dart';
import '../../data/models/order_model.dart';

import '../events/order_events.dart';

/// Clean Domain Repository Contract for Customer Pickup Orders
abstract class OrderRepository {
  /// Submit a new pickup order to the roastery
  Future<Result<OrderModel, AppFailure>> createOrder(CreateOrderRequest request);

  /// Determine whether the active customer must pay with GCash for their first eligible order
  Future<Result<FirstOrderEligibility, AppFailure>> checkFirstOrderEligibility();

  /// Synchronous evaluation of first-order eligibility using cached/trusted backend state
  FirstOrderEligibility getFirstOrderEligibilitySync(String? userId);

  /// Fetch list of orders for the active customer with server-side pagination
  Future<Result<PaginatedList<OrderModel>, AppFailure>> getOrders({
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
    OrderStatus? statusFilter,
  });

  /// Fetch single order details by ID or order number
  Future<Result<OrderModel, AppFailure>> getOrderById(String orderId);

  /// Advance or transition the status of an order (Staff / Barista / Admin)
  Future<Result<OrderModel, AppFailure>> updateOrderStatus(String orderId, OrderStatus status);

  /// Record or update the counter payment status of an order (Staff / Barista / Admin)
  Future<Result<OrderModel, AppFailure>> updatePaymentStatus(String orderId, PaymentStatus status);

  /// Request order cancellation
  Future<Result<OrderModel, AppFailure>> cancelOrder(String orderId);

  /// Stream of real-time order status transition events
  Stream<OrderStatusChangedEvent> get orderStatusEvents;

  /// Watch a specific order by ID with live event broadcasting
  Stream<OrderModel> watchOrder(String orderId);

  /// Tear down customer order stream subscriptions and clear memory caches on session end
  void clearSession();
}
