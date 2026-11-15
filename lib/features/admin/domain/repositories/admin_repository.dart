import 'dart:typed_data';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../products/data/models/product_image_file.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/business_metrics_model.dart';

/// Domain Repository Contract for Business Admin Operations
abstract class AdminRepository {
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
