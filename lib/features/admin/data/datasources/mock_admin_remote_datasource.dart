import 'dart:async';
import 'dart:typed_data';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../core/utils/business_time_service.dart';
import '../../../../core/utils/image_validator.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/data/datasources/mock_user_database.dart';
import '../../../orders/data/datasources/mock_order_remote_datasource.dart';
import '../../../orders/data/datasources/order_remote_datasource.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../products/data/datasources/firebase_product_remote_datasource.dart';
import '../../../products/data/datasources/mock_product_database.dart';
import '../../../products/data/models/product_image_file.dart';
import '../../../products/data/models/product_model.dart';
import '../../../sales/data/datasources/mock_sales_remote_datasource.dart';
import '../../../sales/data/models/sales_channel.dart';
import '../models/business_metrics_model.dart';
import 'admin_remote_datasource.dart';

/// Dynamic In-Memory Data Source for Business Admin Platform
/// Integrates directly with FirebaseProductRemoteDataSource and OrderRemoteDataSource for Cloud Firestore persistence.
class MockAdminRemoteDataSource implements AdminRemoteDataSource {
  UserModel? get _currentUser => MockUserDatabase().currentUser;
  final MockSalesRemoteDataSource _salesDataSource = MockSalesRemoteDataSource();
  final MockOrderRemoteDataSource _orderDataSource = MockOrderRemoteDataSource();
  final MockProductDatabase _productDb = MockProductDatabase();
  final FirebaseProductRemoteDataSource? _firebaseProductDataSource;
  final OrderRemoteDataSource? _orderRemoteDataSource;

  MockAdminRemoteDataSource({
    FirebaseProductRemoteDataSource? productRemoteDataSource,
    OrderRemoteDataSource? orderRemoteDataSource,
  })  : _firebaseProductDataSource = productRemoteDataSource,
        _orderRemoteDataSource = orderRemoteDataSource;

  // In-memory registry of uploaded product images for audit and mock storage
  final Map<String, ProductImageUploadResponse> _uploadedImages = {};

  @override
  Future<Result<BusinessMetricsModel, AppFailure>> getBusinessMetrics() async {
    await Future.delayed(const Duration(milliseconds: 80));

    final user = _currentUser;
    if (user == null || !user.isBusinessUser) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Access denied to business metrics.'),
      );
    }

    final todayRange = BusinessTimeService.getTodayRange();

    final todaySalesList = _salesDataSource.getSalesForDateRange(
      todayRange.startUtc,
      todayRange.endUtcExclusive,
      includeVoided: false,
    );
    final todaySalesAmount = todaySalesList.fold(0.0, (acc, s) => acc + s.totalAmount);
    final todayOrdersCount = todaySalesList.length;

    final allOrders = _orderDataSource.allOrders;
    final pendingOrdersCount = allOrders.where((o) => o.status.isActive).length;
    final completedOrdersCount = allOrders.where((o) => o.status == OrderStatus.completed).length;

    final popularProducts = _productDb.getAllProducts().take(2).toList();

    return Result.success(
      BusinessMetricsModel(
        todaySales: todaySalesAmount,
        todayOrdersCount: todayOrdersCount,
        pendingOrdersCount: pendingOrdersCount,
        completedOrdersCount: completedOrdersCount,
        unreadInboxCount: 1,
        popularProducts: popularProducts,
      ),
    );
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getProducts({String? search, String? categoryId}) async {
    final firebaseDs = _firebaseProductDataSource;
    if (firebaseDs != null) {
      return firebaseDs.getAllProductsAdmin(
        search: search,
        categoryId: categoryId,
      );
    }

    await Future.delayed(const Duration(milliseconds: 60));
    var products = _productDb.getAllProducts();

    if (categoryId != null && categoryId != 'all' && categoryId.isNotEmpty) {
      products = products.where((p) => p.categoryId == categoryId).toList();
    }

    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      products = products.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.origin.toLowerCase().contains(query) ||
            p.tastingNotes.toLowerCase().contains(query);
      }).toList();
    }

    return Result.success(products);
  }

  @override
  Future<Result<ProductModel, AppFailure>> addProduct(ProductModel product) async {
    final firebaseDs = _firebaseProductDataSource;
    if (firebaseDs != null) {
      final res = await firebaseDs.addProduct(product);
      if (res.isSuccess && res.dataOrNull != null) {
        _productDb.addProduct(res.dataOrNull!);
      }
      return res;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final user = _currentUser;
    if (user == null || !user.isBusinessUser) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Product management requires business staff or admin access.'),
      );
    }
    if (product.name.trim().length < 2 || product.name.trim().length > 120) {
      return const Result.failure(
        ValidationFailure(message: 'Product name must be between 2 and 120 characters.'),
      );
    }
    if (product.basePrice <= 0 || product.basePrice > 50000) {
      return const Result.failure(
        ValidationFailure(message: 'Product price must be greater than 0 and at most ₱50,000.'),
      );
    }
    if (product.stockQuantity < 0 || product.stockQuantity > 1000000) {
      return const Result.failure(
        ValidationFailure(message: 'Stock quantity must be between 0 and 1,000,000.'),
      );
    }
    if (product.description.length > 2000) {
      return const Result.failure(
        ValidationFailure(message: 'Product description cannot exceed 2000 characters.'),
      );
    }
    final saved = _productDb.addProduct(product);
    return Result.success(saved);
  }

  @override
  Future<Result<ProductModel, AppFailure>> updateProduct(ProductModel product) async {
    final firebaseDs = _firebaseProductDataSource;
    if (firebaseDs != null) {
      final res = await firebaseDs.updateProduct(product);
      if (res.isSuccess && res.dataOrNull != null) {
        _productDb.updateProduct(res.dataOrNull!);
      }
      return res;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final user = _currentUser;
    if (user == null || !user.isBusinessUser) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Product management requires business staff or admin access.'),
      );
    }
    if (product.name.trim().length < 2 || product.name.trim().length > 120) {
      return const Result.failure(
        ValidationFailure(message: 'Product name must be between 2 and 120 characters.'),
      );
    }
    if (product.basePrice <= 0 || product.basePrice > 50000) {
      return const Result.failure(
        ValidationFailure(message: 'Product price must be greater than 0 and at most ₱50,000.'),
      );
    }
    if (product.stockQuantity < 0 || product.stockQuantity > 1000000) {
      return const Result.failure(
        ValidationFailure(message: 'Stock quantity must be between 0 and 1,000,000.'),
      );
    }
    if (product.description.length > 2000) {
      return const Result.failure(
        ValidationFailure(message: 'Product description cannot exceed 2000 characters.'),
      );
    }
    final updated = _productDb.updateProduct(product);
    return Result.success(updated);
  }

  @override
  Future<Result<bool, AppFailure>> toggleProductAvailability(String productId, bool isAvailable) async {
    final res = await setProductAvailabilityAndVisibility(
      productId: productId,
      isEnabled: isAvailable,
      customerVisibility: ProductVisibility.visible,
    );
    if (res.isFailure) return res;
    return Result.success(isAvailable);
  }

  @override
  Future<Result<bool, AppFailure>> setProductAvailabilityAndVisibility({
    required String productId,
    required bool isEnabled,
    required ProductVisibility customerVisibility,
  }) async {
    final firebaseDs = _firebaseProductDataSource;
    if (firebaseDs != null) {
      final res = await firebaseDs.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: isEnabled,
        customerVisibility: customerVisibility,
      );
      if (res.isSuccess) {
        _productDb.setProductStatus(
          productId: productId,
          isEnabled: isEnabled,
          customerVisibility: customerVisibility,
        );
      }
      return res;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final user = _currentUser;
    if (user == null || !user.isBusinessUser) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Product management requires business staff or admin access.'),
      );
    }

    final success = _productDb.setProductStatus(
      productId: productId,
      isEnabled: isEnabled,
      customerVisibility: customerVisibility,
    );

    if (!success) {
      return const Result.failure(
        NotFoundFailure(message: 'Product not found in roastery registry.'),
      );
    }

    return const Result.success(true);
  }

  @override
  Future<Result<OrderModel, AppFailure>> updateOrderStatus(String orderId, OrderStatus status) {
    final orderDs = _orderRemoteDataSource;
    if (orderDs != null) {
      return orderDs.updateOrderStatus(orderId, status);
    }
    return _orderDataSource.updateOrderStatus(orderId, status);
  }

  @override
  Future<Result<OrderModel, AppFailure>> updatePaymentStatus(String orderId, PaymentStatus status) {
    final orderDs = _orderRemoteDataSource;
    if (orderDs != null) {
      return orderDs.updatePaymentStatus(orderId, status);
    }
    return _orderDataSource.updatePaymentStatus(orderId, status);
  }

  @override
  Future<Result<ProductImageUploadResponse, AppFailure>> uploadProductImage({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));

    // 1. Backend Authentication & Authorization Guard
    final user = _currentUser;
    if (user == null || !user.isBusinessUser) {
      return const Result.failure(
        ForbiddenFailure(
          message: 'Access denied. Only administrators and authorized staff can upload product images.',
        ),
      );
    }

    // 2. Empty Payload Validation
    if (bytes.isEmpty) {
      return const Result.failure(
        ValidationFailure(
          message: 'Uploaded file is empty.',
          fieldErrors: {
            'image': ['Please select a non-empty image file.'],
          },
        ),
      );
    }

    // 3. Exact 5 MB Byte Limit Enforcement (Independent Server Validation)
    if (bytes.length > ImageValidator.maxProductImageSizeBytes) {
      return Result.failure(
        ValidationFailure(
          message: 'Image is too large. Please choose an image smaller than 5 MB.',
          fieldErrors: {
            'image': [
              'Image exceeds 5 MB (${ImageValidator.formatFileSize(bytes.length)}). Maximum allowed is 5 MB.',
            ],
          },
        ),
      );
    }

    // 4. Magic-Byte Signature & Content Decoding Validation (Never trust filename/extension)
    final validation = ImageValidator.validateImageBytes(bytes, filename: filename);
    if (!validation.isValid || validation.format == null) {
      return Result.failure(
        ValidationFailure(
          message: validation.errorMessage ?? 'Unsupported file type. Please upload a JPG, PNG, or WebP image.',
          fieldErrors: {
            'image': [
              validation.errorMessage ?? 'Please upload a JPG, PNG, or WebP image.',
            ],
          },
        ),
      );
    }

    // 5. Generate Safe, Injection-Resistant Storage Filename (UUID-based)
    final format = validation.format!;
    final secureFilename = ImageValidator.generateSecureFilename(format: format);
    final secureUrl = 'https://media.lambac.com/products/$secureFilename';

    final uploadRecord = ProductImageUploadResponse(
      imageUrl: secureUrl,
      storageKey: 'products/$secureFilename',
      fileSizeBytes: bytes.length,
      mimeType: format.mimeType,
      width: validation.width,
      height: validation.height,
      uploadedAt: DateTime.now(),
    );

    _uploadedImages[secureFilename] = uploadRecord;
    return Result.success(uploadRecord);
  }
}
