import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../../../shared/services/storage_service.dart';
import '../../domain/events/order_events.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/services/order_realtime_service.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/create_order_request.dart';
import '../models/first_order_eligibility_model.dart';
import '../models/order_model.dart';

/// Concrete OrderRepository implementation
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final OrderRealtimeService _realtimeService;

  OrderRepositoryImpl({
    required OrderRemoteDataSource remoteDataSource,
    required StorageService storageService,
    OrderRealtimeService? realtimeService,
  })  : _remoteDataSource = remoteDataSource,
        _storageService = storageService,
        _realtimeService = realtimeService ?? OrderRealtimeService();

  @override
  Future<Result<OrderModel, AppFailure>> createOrder(CreateOrderRequest request) {
    return _remoteDataSource.createOrder(request);
  }

  @override
  Future<Result<FirstOrderEligibility, AppFailure>> checkFirstOrderEligibility() {
    return _remoteDataSource.checkFirstOrderEligibility();
  }

  @override
  FirstOrderEligibility getFirstOrderEligibilitySync(String? userId) {
    return _remoteDataSource.getFirstOrderEligibilitySync(userId);
  }

  @override
  Future<Result<PaginatedList<OrderModel>, AppFailure>> getOrders({
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
    OrderStatus? statusFilter,
  }) {
    return _remoteDataSource.getOrders(
      page: page,
      limit: limit,
      lastDocument: lastDocument,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<Result<OrderModel, AppFailure>> getOrderById(String orderId) {
    return _remoteDataSource.getOrderById(orderId);
  }

  @override
  Future<Result<OrderModel, AppFailure>> updateOrderStatus(String orderId, OrderStatus status) {
    return _remoteDataSource.updateOrderStatus(orderId, status);
  }

  @override
  Future<Result<OrderModel, AppFailure>> updatePaymentStatus(String orderId, PaymentStatus status) {
    return _remoteDataSource.updatePaymentStatus(orderId, status);
  }

  @override
  Future<Result<OrderModel, AppFailure>> cancelOrder(String orderId) {
    return _remoteDataSource.cancelOrder(orderId);
  }

  @override
  Stream<OrderStatusChangedEvent> get orderStatusEvents => _realtimeService.orderStatusEvents;

  @override
  Stream<OrderModel> watchOrder(String orderId) => _realtimeService.watchOrder(orderId);

  @override
  void clearSession() {
    _remoteDataSource.clearSession();
  }
}
