import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../../data/models/product_category_model.dart';
import '../../data/models/product_model.dart';

/// Clean Domain Repository Contract for Products & Menu
abstract class ProductRepository {
  /// Fetch paginated products with category, search and roast filters
  Future<Result<PaginatedList<ProductModel>, AppFailure>> getProducts({
    String? categoryId,
    String? search,
    String? roastLevel,
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
  });

  /// Fetch a single product by unique ID or slug
  Future<Result<ProductModel, AppFailure>> getProductById(String id);

  /// Fetch list of all product categories
  Future<Result<List<ProductCategoryModel>, AppFailure>> getCategories();

  /// Fetch curated featured products
  Future<Result<List<ProductModel>, AppFailure>> getFeaturedProducts();

  /// Toggle favorite status on a product
  Future<Result<bool, AppFailure>> toggleFavorite(String productId);

  /// Fetch customer's favorite products
  Future<Result<List<ProductModel>, AppFailure>> getFavorites();
}
