import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../models/product_category_model.dart';
import '../models/product_model.dart';

/// Contract for Product Catalog and Category API calls
abstract class ProductRemoteDataSource {
  Future<Result<PaginatedList<ProductModel>, AppFailure>> getProducts({
    String? categoryId,
    String? search,
    String? roastLevel,
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
  });

  Future<Result<ProductModel, AppFailure>> getProductById(String id);
  Future<Result<List<ProductCategoryModel>, AppFailure>> getCategories();
  Future<Result<List<ProductModel>, AppFailure>> getFeaturedProducts();
  Future<Result<bool, AppFailure>> toggleFavorite(String productId);
  Future<Result<List<ProductModel>, AppFailure>> getFavorites();
}

/// Concrete Dio-based implementation
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<PaginatedList<ProductModel>, AppFailure>> getProducts({
    String? categoryId,
    String? search,
    String? roastLevel,
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
  }) {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (categoryId != null && categoryId != 'all') 'category': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (roastLevel != null && roastLevel != 'all') 'roast': roastLevel,
    };

    return _apiClient.get(
      ApiEndpoints.products,
      queryParameters: queryParams,
      requiresAuth: false,
      decoder: (data) => PaginatedList<ProductModel>.fromJson(
        data as Map<String, dynamic>,
        (item) => ProductModel.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  @override
  Future<Result<ProductModel, AppFailure>> getProductById(String id) {
    return _apiClient.get(
      ApiEndpoints.productDetail(id),
      requiresAuth: false,
      decoder: (data) => ProductModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<List<ProductCategoryModel>, AppFailure>> getCategories() {
    return _apiClient.get(
      ApiEndpoints.categories,
      requiresAuth: false,
      decoder: (data) {
        final list = data is List ? data : (data['categories'] ?? data['data']) as List;
        return list.map((item) => ProductCategoryModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFeaturedProducts() {
    return _apiClient.get(
      ApiEndpoints.featuredProducts,
      requiresAuth: false,
      decoder: (data) {
        final list = data is List ? data : (data['products'] ?? data['data']) as List;
        return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<Result<bool, AppFailure>> toggleFavorite(String productId) {
    return _apiClient.post(
      '/products/$productId/favorite',
      requiresAuth: true,
      decoder: (data) => (data as Map<String, dynamic>)['is_favorite'] as bool? ?? true,
    );
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFavorites() {
    return _apiClient.get(
      '/products/favorites',
      requiresAuth: true,
      decoder: (data) {
        final list = data is List ? data : (data['favorites'] ?? data['data']) as List;
        return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }
}
