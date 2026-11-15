import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../../../shared/services/storage_service.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_category_model.dart';
import '../models/product_model.dart';

/// Concrete ProductRepository implementation
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
    required StorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _storageService = storageService;

  @override
  Future<Result<PaginatedList<ProductModel>, AppFailure>> getProducts({
    String? categoryId,
    String? search,
    String? roastLevel,
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
  }) {
    return _remoteDataSource.getProducts(
      categoryId: categoryId,
      search: search,
      roastLevel: roastLevel,
      page: page,
      limit: limit,
      lastDocument: lastDocument,
    );
  }

  @override
  Future<Result<ProductModel, AppFailure>> getProductById(String id) {
    return _remoteDataSource.getProductById(id);
  }

  @override
  Future<Result<List<ProductCategoryModel>, AppFailure>> getCategories() {
    return _remoteDataSource.getCategories();
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFeaturedProducts() {
    return _remoteDataSource.getFeaturedProducts();
  }

  @override
  Future<Result<bool, AppFailure>> toggleFavorite(String productId) {
    return _remoteDataSource.toggleFavorite(productId);
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFavorites() {
    return _remoteDataSource.getFavorites();
  }
}
