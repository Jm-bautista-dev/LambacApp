import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/firebase_order_remote_datasource.dart';
import '../../data/datasources/mock_order_remote_datasource.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/create_order_request.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/events/order_events.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/services/order_realtime_service.dart';

/// Provider for Order Remote Data Source (Cloud Firestore Production Data Source)
final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  try {
    if (Firebase.apps.isEmpty) {
      return MockOrderRemoteDataSource();
    }
  } catch (_) {
    return MockOrderRemoteDataSource();
  }
  return FirebaseOrderRemoteDataSource();
});

/// Provider for Domain OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final remoteDataSource = ref.watch(orderRemoteDataSourceProvider);
  final storageService = ref.watch(storageServiceProvider);

  return OrderRepositoryImpl(
    remoteDataSource: remoteDataSource,
    storageService: storageService,
  );
});

/// Orders State Container
class OrdersState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final dynamic lastDocument;
  final String? loadMoreError;
  final List<OrderModel> orders;
  final AppFailure? failure;

  const OrdersState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.lastDocument,
    this.loadMoreError,
    this.orders = const [],
    this.failure,
  });

  List<OrderModel> get activeOrders => orders.where((o) => o.status.isActive).toList();
  List<OrderModel> get pastOrders => orders.where((o) => !o.status.isActive).toList();

  OrdersState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    dynamic lastDocument,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    List<OrderModel>? orders,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      lastDocument: lastDocument ?? this.lastDocument,
      loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      orders: orders ?? this.orders,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingMore,
        hasMore,
        page,
        lastDocument,
        loadMoreError,
        orders,
        failure,
      ];
}

/// User-Scoped Orders StateNotifier Provider
/// Auto-disposes and resets cleanly upon logout or account switching
final ordersNotifierProvider = StateNotifierProvider.autoDispose<OrdersNotifier, OrdersState>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  return OrdersNotifier(
    repository: repository,
    currentUser: currentUser,
  );
});

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderRepository _repository;
  final UserModel? _currentUser;
  final String? _sessionUserId;
  StreamSubscription<OrderStatusChangedEvent>? _statusEventsSub;
  StreamSubscription<OrderCreatedEvent>? _createdEventsSub;

  OrdersNotifier({
    required OrderRepository repository,
    UserModel? currentUser,
  })  : _repository = repository,
        _currentUser = currentUser,
        _sessionUserId = currentUser?.id,
        super(const OrdersState(isLoading: true)) {
    loadOrders();
    _listenToRealtimeEvents();
  }

  void _listenToRealtimeEvents() {
    _statusEventsSub = _repository.orderStatusEvents.listen((event) {
      if (!mounted || _currentUser?.id != _sessionUserId) return;
      final index = state.orders.indexWhere((o) => o.id == event.orderId || o.orderNumber == event.orderNumber);
      if (index != -1) {
        final currentOrder = state.orders[index];
        // Guard 1: Completed orders must NEVER revert to an earlier non-terminal status
        if (currentOrder.status == OrderStatus.completed && event.order.status != OrderStatus.completed) {
          return; // Prevent stale overwrite of completed order
        }
        // Guard 2: never regress an order to a lower lifecycle step unless cancelled
        if (event.order.status != OrderStatus.cancelled &&
            event.order.status.stepIndex < currentOrder.status.stepIndex) {
          return; // Ignore stale/regressive event
        }
        final updatedList = List<OrderModel>.from(state.orders);
        updatedList[index] = event.order;
        state = state.copyWith(orders: updatedList);
      } else if (_currentUser?.isAdmin == true || _currentUser?.isEmployee == true) {
        // Business staff see newly updated orders in queue immediately (deduplicating)
        state = state.copyWith(orders: [event.order, ...state.orders.where((o) => o.id != event.order.id)]);
      }
    });

    _createdEventsSub = OrderRealtimeService().orderCreatedEvents.listen((event) {
      if (!mounted || _currentUser?.id != _sessionUserId) return;
      if (_currentUser?.isAdmin == true || _currentUser?.isEmployee == true) {
        final exists = state.orders.any((o) => o.id == event.order.id);
        if (!exists) {
          state = state.copyWith(orders: [event.order, ...state.orders]);
        }
      }
    });
  }

  Future<void> loadOrders({bool isRefresh = false}) async {
    if (_currentUser == null) {
      state = const OrdersState(isLoading: false);
      return;
    }

    if (!isRefresh) {
      state = state.copyWith(
        isLoading: true,
        clearFailure: true,
        hasMore: true,
        page: 1,
        lastDocument: null,
        clearLoadMoreError: true,
      );
    } else {
      state = state.copyWith(
        hasMore: true,
        page: 1,
        lastDocument: null,
        clearLoadMoreError: true,
      );
    }

    final result = await _repository.getOrders(
      page: 1,
      limit: 20,
      lastDocument: null,
    );

    if (!mounted || _currentUser.id != _sessionUserId) return;

    result.when(
      success: (paginated) {
        state = state.copyWith(
          isLoading: false,
          orders: paginated.items,
          hasMore: paginated.hasNextPage,
          page: 1,
          lastDocument: paginated.cursor,
          clearFailure: true,
          clearLoadMoreError: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
    );
  }

  Future<void> loadMoreOrders() async {
    if (_currentUser == null || state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    final nextPage = state.page + 1;

    final result = await _repository.getOrders(
      page: nextPage,
      limit: 20,
      lastDocument: state.lastDocument,
    );

    if (!mounted || _currentUser.id != _sessionUserId) return;

    result.when(
      success: (paginated) {
        // Deduplicate incoming orders
        final existingIds = state.orders.map((o) => o.id).toSet();
        final newOrders = paginated.items.where((o) => !existingIds.contains(o.id)).toList();

        state = state.copyWith(
          isLoadingMore: false,
          orders: [...state.orders, ...newOrders],
          hasMore: paginated.hasNextPage,
          page: nextPage,
          lastDocument: paginated.cursor,
          clearLoadMoreError: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          loadMoreError: failure.message,
        );
      },
    );
  }

  /// Create and place a new pickup order
  Future<Result<OrderModel, AppFailure>> submitOrder(CreateOrderRequest request) async {
    final result = await _repository.createOrder(request);

    if (!mounted || _currentUser?.id != _sessionUserId) return result;

    result.when(
      success: (newOrder) {
        state = state.copyWith(
          orders: [newOrder, ...state.orders],
        );
      },
      failure: (_) {},
    );

    return result;
  }

  /// Advance order status from Staff, Barista, or Admin
  Future<Result<OrderModel, AppFailure>> advanceOrderStatus(String orderId, OrderStatus newStatus) async {
    final result = await _repository.updateOrderStatus(orderId, newStatus);
    if (!mounted || _currentUser?.id != _sessionUserId) return result;

    result.when(
      success: (updated) {
        final index = state.orders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
        if (index != -1) {
          final updatedList = List<OrderModel>.from(state.orders);
          updatedList[index] = updated;
          state = state.copyWith(orders: updatedList);
        }
      },
      failure: (_) {},
    );

    return result;
  }

  /// Directly applies a confirmed order update to local state.
  /// This avoids re-fetching from Firestore which can race with write propagation
  /// and temporarily show stale/reverted status.
  void applyOrderUpdate(OrderModel updatedOrder) {
    final index = state.orders.indexWhere(
      (o) => o.id == updatedOrder.id || o.orderNumber == updatedOrder.orderNumber,
    );
    if (index != -1) {
      final currentOrder = state.orders[index];
      // Guard: never overwrite a completed order with an earlier non-terminal status
      if (currentOrder.status == OrderStatus.completed && updatedOrder.status != OrderStatus.completed) {
        return;
      }
      final updatedList = List<OrderModel>.from(state.orders);
      updatedList[index] = updatedOrder;
      state = state.copyWith(orders: updatedList);
    } else {
      // Order not yet in local state — prepend it
      state = state.copyWith(orders: [updatedOrder, ...state.orders]);
    }
  }

  /// Record counter payment (Staff / Barista / Admin)
  Future<Result<OrderModel, AppFailure>> recordCounterPayment(String orderId) async {
    final result = await _repository.updatePaymentStatus(orderId, PaymentStatus.paid);
    if (!mounted || _currentUser?.id != _sessionUserId) return result;

    result.when(
      success: (updated) {
        final index = state.orders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
        if (index != -1) {
          final updatedList = List<OrderModel>.from(state.orders);
          updatedList[index] = updated;
          state = state.copyWith(orders: updatedList);
        }
      },
      failure: (_) {},
    );

    return result;
  }

  @override
  void dispose() {
    _statusEventsSub?.cancel();
    _createdEventsSub?.cancel();
    super.dispose();
  }
}

/// FutureProvider family for single order detail
final orderDetailProvider = FutureProvider.family.autoDispose<OrderModel, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  final result = await repository.getOrderById(orderId);

  return result.when(
    success: (order) => order,
    failure: (failure) => throw Exception(failure.message),
  );
});

/// Convenience provider for the most recent active order (if any)
final activeOrderProvider = Provider.autoDispose<OrderModel?>((ref) {
  final orders = ref.watch(ordersNotifierProvider).activeOrders;
  return orders.isNotEmpty ? orders.first : null;
});
