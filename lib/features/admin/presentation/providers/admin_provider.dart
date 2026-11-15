import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../products/data/datasources/firebase_product_remote_datasource.dart';
import '../../../products/data/models/product_image_file.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/providers/categories_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/datasources/firebase_admin_remote_datasource.dart';
import '../../data/datasources/mock_admin_remote_datasource.dart';
import '../../data/models/business_metrics_model.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';

/// Provider for Admin Remote Data Source
final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  try {
    if (Firebase.apps.isEmpty) {
      return MockAdminRemoteDataSource();
    }
  } catch (_) {
    return MockAdminRemoteDataSource();
  }
  final productRemote = ref.watch(productRemoteDataSourceProvider);
  final orderRemote = ref.watch(orderRemoteDataSourceProvider);
  return FirebaseAdminRemoteDataSource(
    productDataSource: productRemote is FirebaseProductRemoteDataSource ? productRemote : null,
    orderDataSource: orderRemote,
  );
});

/// Provider for Domain AdminRepository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final remoteDataSource = ref.watch(adminRemoteDataSourceProvider);
  return AdminRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// FutureProvider for Dashboard Business Metrics
final businessMetricsProvider = FutureProvider<BusinessMetricsModel>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.getBusinessMetrics();

  return result.when(
    success: (metrics) => metrics,
    failure: (failure) => throw Exception(failure.message),
  );
});

/// Filter for Admin Product Catalog
enum AdminProductFilter {
  all,
  available,
  soldOut,
  hidden,
}

/// State for Admin Product Catalog
class AdminProductsState {
  final bool isLoading;
  final List<ProductModel> products;
  final AdminProductFilter filter;
  final String searchQuery;
  final AppFailure? failure;

  const AdminProductsState({
    this.isLoading = false,
    this.products = const [],
    this.filter = AdminProductFilter.all,
    this.searchQuery = '',
    this.failure,
  });

  List<ProductModel> get filteredProducts {
    var list = products;
    switch (filter) {
      case AdminProductFilter.all:
        break;
      case AdminProductFilter.available:
        list = list.where((p) => p.isEnabled).toList();
        break;
      case AdminProductFilter.soldOut:
        list = list.where((p) => !p.isEnabled && p.customerVisibility == ProductVisibility.visible).toList();
        break;
      case AdminProductFilter.hidden:
        list = list.where((p) => p.customerVisibility == ProductVisibility.hidden).toList();
        break;
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.origin.toLowerCase().contains(q) ||
            p.roastLevel.toLowerCase().contains(q) ||
            p.tastingNotes.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  int get availableCount => products.where((p) => p.isEnabled).length;
  int get soldOutCount => products.where((p) => !p.isEnabled && p.customerVisibility == ProductVisibility.visible).length;
  int get hiddenCount => products.where((p) => p.customerVisibility == ProductVisibility.hidden).length;

  AdminProductsState copyWith({
    bool? isLoading,
    List<ProductModel>? products,
    AdminProductFilter? filter,
    String? searchQuery,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return AdminProductsState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

/// StateNotifier for Admin Products Catalog
class AdminProductsNotifier extends StateNotifier<AdminProductsState> {
  final AdminRepository _repository;

  AdminProductsNotifier({required AdminRepository repository})
      : _repository = repository,
        super(const AdminProductsState(isLoading: true)) {
    loadProducts();
  }

  Future<void> loadProducts({bool isRefresh = false}) async {
    if (!isRefresh) {
      state = state.copyWith(isLoading: true, clearFailure: true);
    }

    final result = await _repository.getProducts();

    if (!mounted) return;

    result.when(
      success: (items) {
        state = state.copyWith(
          isLoading: false,
          products: items,
          clearFailure: true,
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

  void setFilter(AdminProductFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// Provider for Admin Products StateNotifier
final adminProductsNotifierProvider =
    StateNotifierProvider<AdminProductsNotifier, AdminProductsState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminProductsNotifier(repository: repository);
});

/// Admin Product Management Notifier Provider
final adminProductNotifierProvider = Provider<AdminProductController>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminProductController(repository: repository, ref: ref);
});

class AdminProductController {
  final AdminRepository _repository;
  final Ref _ref;

  AdminProductController({
    required AdminRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref;

  Future<Result<ProductModel, AppFailure>> addProduct(ProductModel product) async {
    final result = await _repository.addProduct(product);
    if (result.isSuccess) {
      _ref.read(adminProductsNotifierProvider.notifier).loadProducts(isRefresh: true);
      _ref.read(productsNotifierProvider.notifier).loadProducts(isRefresh: true);
    }
    return result;
  }

  Future<Result<ProductModel, AppFailure>> updateProduct(ProductModel product) async {
    final result = await _repository.updateProduct(product);
    if (result.isSuccess) {
      _ref.read(adminProductsNotifierProvider.notifier).loadProducts(isRefresh: true);
      _ref.read(productsNotifierProvider.notifier).loadProducts(isRefresh: true);
    }
    return result;
  }

  Future<Result<bool, AppFailure>> toggleAvailability(String productId, bool isAvailable) async {
    return setProductAvailabilityAndVisibility(
      productId: productId,
      isEnabled: isAvailable,
      customerVisibility: ProductVisibility.visible,
    );
  }

  Future<Result<bool, AppFailure>> setProductAvailabilityAndVisibility({
    required String productId,
    required bool isEnabled,
    required ProductVisibility customerVisibility,
  }) async {
    final result = await _repository.setProductAvailabilityAndVisibility(
      productId: productId,
      isEnabled: isEnabled,
      customerVisibility: customerVisibility,
    );
    if (result.isSuccess) {
      _ref.read(adminProductsNotifierProvider.notifier).loadProducts(isRefresh: true);
      _ref.read(productsNotifierProvider.notifier).loadProducts(isRefresh: true);
    }
    return result;
  }

  final Set<String> _inFlightOrderOps = <String>{};

  Future<Result<OrderModel, AppFailure>> advanceOrderStatus(String orderId, OrderStatus status) async {
    final opKey = '$orderId:${status.name}';
    if (_inFlightOrderOps.contains(opKey)) {
      // In-flight guard: prevent concurrent execution on double click
      final cachedList = _ref.read(ordersNotifierProvider).orders;
      final existing = cachedList.where((o) => o.id == orderId || o.orderNumber == orderId).firstOrNull;
      if (existing != null) return Result.success(existing);
    }
    _inFlightOrderOps.add(opKey);
    try {
      final result = await _repository.updateOrderStatus(orderId, status);
      if (result.isSuccess) {
        // Optimistically update local state with the confirmed server response
        // instead of re-fetching (which can race with Firestore write propagation
        // and temporarily revert the status).
        final updatedOrder = result.dataOrNull!;
        final notifier = _ref.read(ordersNotifierProvider.notifier);
        notifier.applyOrderUpdate(updatedOrder);
        _ref.invalidate(businessMetricsProvider);
      }
      return result;
    } finally {
      _inFlightOrderOps.remove(opKey);
    }
  }

  Future<Result<OrderModel, AppFailure>> recordCounterPayment(String orderId) async {
    final opKey = '$orderId:payment';
    if (_inFlightOrderOps.contains(opKey)) {
      // In-flight guard: prevent concurrent execution on double click
      final cachedList = _ref.read(ordersNotifierProvider).orders;
      final existing = cachedList.where((o) => o.id == orderId || o.orderNumber == orderId).firstOrNull;
      if (existing != null) return Result.success(existing);
    }
    _inFlightOrderOps.add(opKey);
    try {
      final result = await _repository.updatePaymentStatus(orderId, PaymentStatus.paid);
      if (result.isSuccess) {
        final updatedOrder = result.dataOrNull!;
        final notifier = _ref.read(ordersNotifierProvider.notifier);
        notifier.applyOrderUpdate(updatedOrder);
      }
      return result;
    } finally {
      _inFlightOrderOps.remove(opKey);
    }
  }

  Future<Result<ProductImageUploadResponse, AppFailure>> uploadProductImage({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return _repository.uploadProductImage(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }
}
