import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../models/create_order_request.dart';
import '../models/first_order_eligibility_model.dart';
import '../models/order_model.dart';

/// Contract for Remote Order Management API calls
abstract class OrderRemoteDataSource {
  Future<Result<OrderModel, AppFailure>> createOrder(CreateOrderRequest request);
  Future<Result<FirstOrderEligibility, AppFailure>> checkFirstOrderEligibility();
  FirstOrderEligibility getFirstOrderEligibilitySync(String? userId);
  Future<Result<PaginatedList<OrderModel>, AppFailure>> getOrders({
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
    OrderStatus? statusFilter,
  });
  Future<Result<OrderModel, AppFailure>> getOrderById(String orderId);
  Future<Result<OrderModel, AppFailure>> updateOrderStatus(String orderId, OrderStatus status);
  Future<Result<OrderModel, AppFailure>> updatePaymentStatus(String orderId, PaymentStatus status);
  Future<Result<OrderModel, AppFailure>> cancelOrder(String orderId);
  void clearSession();
}

/// Concrete Dio-based implementation
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient _apiClient;

  OrderRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  void clearSession() {}

  @override
  Future<Result<FirstOrderEligibility, AppFailure>> checkFirstOrderEligibility() {
    return _apiClient.get(
      '/first-order-eligibility',
      requiresAuth: true,
      decoder: (data) => FirstOrderEligibility.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  FirstOrderEligibility getFirstOrderEligibilitySync(String? userId) {
    return FirstOrderEligibility.firstOrderRequired(customerId: userId ?? '');
  }

  @override
  Future<Result<OrderModel, AppFailure>> createOrder(CreateOrderRequest request) {
    return _apiClient.post(
      ApiEndpoints.createOrder,
      data: request.toJson(),
      requiresAuth: true,
      decoder: (data) => OrderModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<PaginatedList<OrderModel>, AppFailure>> getOrders({
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
    OrderStatus? statusFilter,
  }) {
    return _apiClient.get(
      ApiEndpoints.orders,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (statusFilter != null) 'status': statusFilter.name,
      },
      requiresAuth: true,
      decoder: (data) => PaginatedList<OrderModel>.fromJson(
        data as Map<String, dynamic>,
        (item) => OrderModel.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  @override
  Future<Result<OrderModel, AppFailure>> getOrderById(String orderId) {
    return _apiClient.get(
      ApiEndpoints.orderDetail(orderId),
      requiresAuth: true,
      decoder: (data) => OrderModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<OrderModel, AppFailure>> updateOrderStatus(String orderId, OrderStatus status) {
    return _apiClient.patch(
      '/admin/orders/$orderId/status',
      data: {'status': status.name},
      requiresAuth: true,
      decoder: (data) => OrderModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<OrderModel, AppFailure>> updatePaymentStatus(String orderId, PaymentStatus status) {
    return _apiClient.patch(
      '/admin/orders/$orderId/payment-status',
      data: {'payment_status': status.toDisplayString()},
      requiresAuth: true,
      decoder: (data) => OrderModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<OrderModel, AppFailure>> cancelOrder(String orderId) {
    return _apiClient.post(
      '/orders/$orderId/cancel',
      requiresAuth: true,
      decoder: (data) => OrderModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
