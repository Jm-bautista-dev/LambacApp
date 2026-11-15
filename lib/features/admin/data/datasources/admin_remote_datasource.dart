import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../products/data/models/product_image_file.dart';
import '../../../products/data/models/product_model.dart';
import '../models/business_metrics_model.dart';

/// Contract for Business Admin API calls
abstract class AdminRemoteDataSource {
  Future<Result<BusinessMetricsModel, AppFailure>> getBusinessMetrics();
  Future<Result<List<ProductModel>, AppFailure>> getProducts({String? search, String? categoryId});
  Future<Result<ProductModel, AppFailure>> addProduct(ProductModel product);
  Future<Result<ProductModel, AppFailure>> updateProduct(ProductModel product);
  Future<Result<bool, AppFailure>> toggleProductAvailability(String productId, bool isAvailable);
  Future<Result<bool, AppFailure>> setProductAvailabilityAndVisibility({
    required String productId,
    required bool isEnabled,
    required ProductVisibility customerVisibility,
  });
  Future<Result<OrderModel, AppFailure>> updateOrderStatus(String orderId, OrderStatus status);
  Future<Result<OrderModel, AppFailure>> updatePaymentStatus(String orderId, PaymentStatus status);
  Future<Result<ProductImageUploadResponse, AppFailure>> uploadProductImage({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  });
}

/// Concrete Dio-based implementation
class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient _apiClient;

  AdminRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<BusinessMetricsModel, AppFailure>> getBusinessMetrics() {
    return _apiClient.get(
      '/admin/metrics',
      requiresAuth: true,
      decoder: (data) => BusinessMetricsModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getProducts({String? search, String? categoryId}) {
    final queryParams = <String, dynamic>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId != 'all') 'category': categoryId,
    };
    return _apiClient.get(
      '/admin/products',
      queryParameters: queryParams,
      requiresAuth: true,
      decoder: (data) {
        final list = data is List ? data : (data['items'] ?? data['data'] ?? data['products']) as List;
        return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<Result<ProductModel, AppFailure>> addProduct(ProductModel product) {
    return _apiClient.post(
      '/admin/products',
      data: product.toJson(),
      requiresAuth: true,
      decoder: (data) => ProductModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<ProductModel, AppFailure>> updateProduct(ProductModel product) {
    return _apiClient.put(
      '/admin/products/${product.id}',
      data: product.toJson(),
      requiresAuth: true,
      decoder: (data) => ProductModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<bool, AppFailure>> toggleProductAvailability(String productId, bool isAvailable) {
    return setProductAvailabilityAndVisibility(
      productId: productId,
      isEnabled: isAvailable,
      customerVisibility: ProductVisibility.visible,
    );
  }

  @override
  Future<Result<bool, AppFailure>> setProductAvailabilityAndVisibility({
    required String productId,
    required bool isEnabled,
    required ProductVisibility customerVisibility,
  }) {
    return _apiClient.patch(
      '/admin/products/$productId/availability',
      data: {
        'is_enabled': isEnabled,
        'customer_visibility': customerVisibility.name,
      },
      requiresAuth: true,
      decoder: (data) => (data as Map<String, dynamic>)['is_enabled'] as bool? ?? isEnabled,
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
  Future<Result<ProductImageUploadResponse, AppFailure>> uploadProductImage({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: contentType != null ? DioMediaType.parse(contentType) : null,
      ),
    });

    return _apiClient.post(
      '/admin/products/upload-image',
      data: formData,
      requiresAuth: true,
      decoder: (data) => ProductImageUploadResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
