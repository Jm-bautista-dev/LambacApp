import 'dart:typed_data';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../products/data/models/product_image_file.dart';
import '../../../products/data/models/product_model.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';
import '../models/business_metrics_model.dart';

/// Concrete AdminRepository implementation
class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepositoryImpl({required AdminRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<BusinessMetricsModel, AppFailure>> getBusinessMetrics() {
    return _remoteDataSource.getBusinessMetrics();
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getProducts({String? search, String? categoryId}) {
    return _remoteDataSource.getProducts(search: search, categoryId: categoryId);
  }

  @override
  Future<Result<ProductModel, AppFailure>> addProduct(ProductModel product) {
    return _remoteDataSource.addProduct(product);
  }

  @override
  Future<Result<ProductModel, AppFailure>> updateProduct(ProductModel product) {
    return _remoteDataSource.updateProduct(product);
  }

  @override
  Future<Result<bool, AppFailure>> toggleProductAvailability(String productId, bool isAvailable) {
    return _remoteDataSource.toggleProductAvailability(productId, isAvailable);
  }

  @override
  Future<Result<bool, AppFailure>> setProductAvailabilityAndVisibility({
    required String productId,
    required bool isEnabled,
    required ProductVisibility customerVisibility,
  }) {
    return _remoteDataSource.setProductAvailabilityAndVisibility(
      productId: productId,
      isEnabled: isEnabled,
      customerVisibility: customerVisibility,
    );
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
  Future<Result<ProductImageUploadResponse, AppFailure>> uploadProductImage({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return _remoteDataSource.uploadProductImage(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }
}
