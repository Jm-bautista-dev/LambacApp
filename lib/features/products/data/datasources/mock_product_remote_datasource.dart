import 'dart:async';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/pagination_model.dart';
import '../models/product_category_model.dart';
import '../models/product_model.dart';
import 'mock_product_database.dart';
import 'product_remote_datasource.dart';

/// Offline & Development Mock Data Source for Product Catalog
/// Integrates with central MockProductDatabase for real-time customer and admin synchronization.
class MockProductRemoteDataSource implements ProductRemoteDataSource {
  final MockProductDatabase _db = MockProductDatabase();

  @override
  Future<Result<PaginatedList<ProductModel>, AppFailure>> getProducts({
    String? categoryId,
    String? search,
    String? roastLevel,
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    // Customer catalog strictly queries customer visible products (hiding disabled + hidden products)
    var filtered = _db.getCustomerVisibleProducts();

    if (categoryId != null && categoryId != 'all' && categoryId.isNotEmpty) {
      filtered = filtered.where((p) => p.categoryId == categoryId).toList();
    }

    if (roastLevel != null && roastLevel != 'all' && roastLevel.isNotEmpty) {
      filtered = filtered.where((p) => p.roastLevel.toLowerCase().contains(roastLevel.toLowerCase())).toList();
    }

    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.origin.toLowerCase().contains(query) ||
            p.tastingNotes.toLowerCase().contains(query) ||
            p.categoryName.toLowerCase().contains(query);
      }).toList();
    }

    // Cursor-based or page-based index
    int startIndex = (page - 1) * limit;
    if (lastDocument is int) {
      startIndex = lastDocument;
    } else if (lastDocument is String) {
      final index = filtered.indexWhere((p) => p.id == lastDocument);
      if (index != -1) {
        startIndex = index + 1;
      }
    }

    final endIndex = (startIndex + limit) > filtered.length ? filtered.length : startIndex + limit;
    final paginatedItems = startIndex < filtered.length ? filtered.sublist(startIndex, endIndex) : <ProductModel>[];
    final nextCursor = paginatedItems.isNotEmpty ? paginatedItems.last.id : null;

    return Result.success(
      PaginatedList<ProductModel>(
        items: paginatedItems,
        page: page,
        pageSize: limit,
        totalCount: filtered.length,
        hasNextPage: endIndex < filtered.length,
        cursor: nextCursor,
      ),
    );
  }

  @override
  Future<Result<ProductModel, AppFailure>> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final product = _db.getProductById(id);

    if (product == null) {
      return const Result.failure(
        NotFoundFailure(message: 'Product not found in catalog.'),
      );
    }

    return Result.success(product);
  }

  @override
  Future<Result<List<ProductCategoryModel>, AppFailure>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return const Result.success(MockProductDatabase.categories);
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFeaturedProducts() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final featured = _db.getCustomerVisibleProducts().where((p) => p.isFeatured).toList();
    return Result.success(featured);
  }

  @override
  Future<Result<bool, AppFailure>> toggleFavorite(String productId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final isFav = _db.toggleFavorite(productId);
    return Result.success(isFav);
  }

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFavorites() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final favorites = _db
        .getCustomerVisibleProducts()
        .where((p) => _db.favoriteIds.contains(p.id))
        .toList();
    return Result.success(favorites);
  }
}
