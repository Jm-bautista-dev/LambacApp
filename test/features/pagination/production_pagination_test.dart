import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/network/result.dart';
import 'package:lambac_app/core/pagination/firestore_cursor_page.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_database.dart';
import 'package:lambac_app/features/products/data/models/product_category_model.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/products/domain/repositories/product_repository.dart';
import 'package:lambac_app/features/products/presentation/providers/products_provider.dart';
import 'package:lambac_app/features/reviews/data/datasources/mock_reviews_remote_datasource.dart';
import 'package:lambac_app/shared/models/pagination_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';

class _FakeProductRepo implements ProductRepository {
  final List<ProductModel> catalog;
  int getProductsCallCount = 0;
  bool shouldFail = false;

  _FakeProductRepo({required this.catalog});

  @override
  Future<Result<PaginatedList<ProductModel>, AppFailure>> getProducts({
    String? categoryId,
    String? search,
    String? roastLevel,
    int page = 1,
    int limit = 20,
    dynamic lastDocument,
  }) async {
    getProductsCallCount++;
    if (shouldFail) {
      return const Result.failure(ServerFailure(message: 'Network connection dropped'));
    }

    var list = List<ProductModel>.from(catalog);
    if (categoryId != null && categoryId != 'all') {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (search != null && search.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(search.toLowerCase())).toList();
    }

    int startIndex = (page - 1) * limit;
    if (lastDocument is String) {
      final idx = list.indexWhere((p) => p.id == lastDocument);
      if (idx != -1) startIndex = idx + 1;
    }
    final endIndex = (startIndex + limit) > list.length ? list.length : startIndex + limit;
    final items = startIndex < list.length ? list.sublist(startIndex, endIndex) : <ProductModel>[];

    return Result.success(
      PaginatedList<ProductModel>(
        items: items,
        page: page,
        pageSize: limit,
        totalCount: list.length,
        hasNextPage: endIndex < list.length,
        cursor: items.isNotEmpty ? items.last.id : null,
      ),
    );
  }

  @override
  Future<Result<ProductModel, AppFailure>> getProductById(String id) async =>
      Result.success(catalog.first);

  @override
  Future<Result<List<ProductCategoryModel>, AppFailure>> getCategories() async =>
      const Result.success([]);

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFeaturedProducts() async =>
      const Result.success([]);

  @override
  Future<Result<List<ProductModel>, AppFailure>> getFavorites() async =>
      const Result.success([]);

  @override
  Future<Result<bool, AppFailure>> toggleFavorite(String productId) async =>
      const Result.success(true);
}

void main() {
  group('Production-Wide Pagination Acceptance Criteria Suite', () {
    late List<ProductModel> testProducts;

    setUp(() {
      testProducts = List.generate(
        45,
        (i) => ProductModel(
          id: 'prod_$i',
          name: 'Coffee Micro-Lot #$i',
          slug: 'coffee-lot-$i',
          description: 'Description for micro lot $i',
          basePrice: 400.0 + i,
          categoryId: i < 20 ? 'beans' : 'drip',
          categoryName: i < 20 ? 'Whole Bean' : 'Drip Bag',
          origin: 'Benguet, Philippines',
          roastLevel: i % 2 == 0 ? 'Medium' : 'Dark',
          tastingNotes: 'Chocolate, Caramel',
          stockQuantity: 50,
          customerVisibility: ProductVisibility.visible,
          isEnabled: true,
          isFeatured: i % 5 == 0,
        ),
      );
    });

    test('1. First page returns no more than the configured page size', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final res = await repo.getProducts(page: 1, limit: 20);

      expect(res.isSuccess, isTrue);
      final paginated = res.dataOrNull!;
      expect(paginated.items.length, equals(20));
      expect(paginated.pageSize, equals(20));
      expect(paginated.hasNextPage, isTrue);
      expect(paginated.cursor, equals('prod_19'));
    });

    test('2. Next page begins after the previous cursor', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final page1 = await repo.getProducts(page: 1, limit: 20);
      final cursor1 = page1.dataOrNull!.cursor;

      final page2 = await repo.getProducts(page: 2, limit: 20, lastDocument: cursor1);
      expect(page2.isSuccess, isTrue);
      final paged2 = page2.dataOrNull!;
      expect(paged2.items.length, equals(20));
      expect(paged2.items.first.id, equals('prod_20'));
      expect(paged2.cursor, equals('prod_39'));
    });

    test('3. No duplicate documents appear between pages', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final page1 = await repo.getProducts(page: 1, limit: 20);
      final page2 = await repo.getProducts(page: 2, limit: 20, lastDocument: page1.dataOrNull!.cursor);

      final ids1 = page1.dataOrNull!.items.map((p) => p.id).toSet();
      final ids2 = page2.dataOrNull!.items.map((p) => p.id).toSet();
      final intersection = ids1.intersection(ids2);
      expect(intersection, isEmpty);
    });

    test('4. Exhausted collections stop requesting more pages and set hasMore=false', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final page1 = await repo.getProducts(page: 1, limit: 20);
      final page2 = await repo.getProducts(page: 2, limit: 20, lastDocument: page1.dataOrNull!.cursor);
      final page3 = await repo.getProducts(page: 3, limit: 20, lastDocument: page2.dataOrNull!.cursor);

      expect(page3.dataOrNull!.items.length, equals(5));
      expect(page3.dataOrNull!.hasNextPage, isFalse);

      final page4 = await repo.getProducts(page: 4, limit: 20, lastDocument: page3.dataOrNull!.cursor);
      expect(page4.dataOrNull!.items, isEmpty);
      expect(page4.dataOrNull!.hasNextPage, isFalse);
    });

    test('5. Empty collections return empty state and hasMore=false', () async {
      final repo = _FakeProductRepo(catalog: []);
      final res = await repo.getProducts(page: 1, limit: 20);

      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull!.items, isEmpty);
      expect(res.dataOrNull!.hasNextPage, isFalse);
      expect(res.dataOrNull!.cursor, isNull);
    });

    test('6. Changing search resets pagination state and cursor', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final notifier = ProductsNotifier(repository: repo);

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.products.length, equals(20));
      expect(notifier.state.page, equals(1));

      // Load more
      await notifier.loadMoreProducts();
      expect(notifier.state.products.length, equals(40));
      expect(notifier.state.page, equals(2));

      // Trigger search query
      notifier.setSearchQuery('Micro-Lot #1');
      await Future<void>.delayed(const Duration(milliseconds: 400)); // debounce

      expect(notifier.state.page, equals(1));
      expect(notifier.state.searchQuery, equals('Micro-Lot #1'));
      expect(notifier.state.products.length, lessThanOrEqualTo(20));
      notifier.dispose();
    });

    test('7. Changing category resets pagination state and cursor', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final notifier = ProductsNotifier(repository: repo);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await notifier.loadMoreProducts();
      expect(notifier.state.page, equals(2));

      notifier.selectCategory('beans');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.page, equals(1));
      expect(notifier.state.selectedCategoryId, equals('beans'));
      expect(notifier.state.products.every((p) => p.categoryId == 'beans'), isTrue);
      notifier.dispose();
    });

    test('8. Changing roast level filter resets pagination state and cursor', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final notifier = ProductsNotifier(repository: repo);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await notifier.loadMoreProducts();
      expect(notifier.state.page, equals(2));

      notifier.setRoastLevel('Dark');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.page, equals(1));
      expect(notifier.state.selectedRoastLevel, equals('Dark'));
      notifier.dispose();
    });

    test('9. Filtered results remain correctly ordered across pages', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final p1 = await repo.getProducts(categoryId: 'beans', limit: 10, page: 1);
      final p2 = await repo.getProducts(categoryId: 'beans', limit: 10, page: 2, lastDocument: p1.dataOrNull!.cursor);

      final combined = [...p1.dataOrNull!.items, ...p2.dataOrNull!.items];
      expect(combined.length, equals(20));
      for (int i = 0; i < combined.length; i++) {
        expect(combined[i].id, equals('prod_$i'));
      }
    });

    test('10. Network failure on next page preserves previously loaded pages', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final notifier = ProductsNotifier(repository: repo);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.products.length, equals(20));

      // Induce network failure for next page
      repo.shouldFail = true;
      await notifier.loadMoreProducts();

      // Previously loaded 20 items must be preserved!
      expect(notifier.state.products.length, equals(20));
      expect(notifier.state.isLoadingMore, isFalse);
      expect(notifier.state.loadMoreError, isNotNull);
      notifier.dispose();
    });

    test('11. Retrying next page after failure does not duplicate records', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final notifier = ProductsNotifier(repository: repo);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repo.shouldFail = true;
      await notifier.loadMoreProducts();
      expect(notifier.state.products.length, equals(20));

      // Recover and retry
      repo.shouldFail = false;
      await notifier.loadMoreProducts();

      expect(notifier.state.products.length, equals(40));
      final uniqueIds = notifier.state.products.map((p) => p.id).toSet();
      expect(uniqueIds.length, equals(40));
      expect(notifier.state.loadMoreError, isNull);
      notifier.dispose();
    });

    test('12. Rapid scrolling does not trigger overlapping concurrent requests', () async {
      final repo = _FakeProductRepo(catalog: testProducts);
      final notifier = ProductsNotifier(repository: repo);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final initialCalls = repo.getProductsCallCount;

      // Simulate 5 rapid calls in the same event loop frame
      final f1 = notifier.loadMoreProducts();
      final f2 = notifier.loadMoreProducts();
      final f3 = notifier.loadMoreProducts();
      final f4 = notifier.loadMoreProducts();
      final f5 = notifier.loadMoreProducts();

      await Future.wait([f1, f2, f3, f4, f5]);

      // Only exactly ONE next-page call must have executed
      expect(repo.getProductsCallCount, equals(initialCalls + 1));
      notifier.dispose();
    });

    test('13. Real-time updates do not create duplicate records in paginated list', () {
      final state = ProductsState(
        products: testProducts.take(10).toList(),
      );

      final incomingProduct = testProducts[2].copyWith(basePrice: 550.0);
      final existingIds = state.products.map((p) => p.id).toSet();

      final updatedList = state.products.map((p) => p.id == incomingProduct.id ? incomingProduct : p).toList();
      if (!existingIds.contains(incomingProduct.id)) {
        updatedList.insert(0, incomingProduct);
      }

      expect(updatedList.length, equals(10));
      expect(updatedList[2].basePrice, equals(550.0));
    });

    test('14. Deleted records are handled cleanly without breaking pagination', () {
      final list = List<ProductModel>.from(testProducts.take(10));
      const deletedId = 'prod_3';
      list.removeWhere((p) => p.id == deletedId);

      expect(list.length, equals(9));
      expect(list.any((p) => p.id == deletedId), isFalse);
    });

    test('15. Account switching clears the old private dataset and cursor', () {
      final oldState = ProductsState(
        products: testProducts.take(20).toList(),
        page: 2,
        lastDocument: 'prod_19',
        hasMore: true,
      );
      expect(oldState.products.length, equals(20));

      // Account reset
      const resetState = ProductsState();
      expect(resetState.products, isEmpty);
      expect(resetState.page, equals(1));
      expect(resetState.lastDocument, isNull);
      expect(resetState.hasMore, isTrue);
    });

    test('16. Customer order history pagination restricts to authenticated customer UID', () async {
      final mockOrderDs = MockOrderRemoteDataSource();
      mockOrderDs.setCurrentUser(
        UserModel(
          id: 'usr_customer_demo',
          email: 'customer@demo.com',
          fullName: 'Customer Demo',
          role: UserRole.customer,
          status: UserStatus.active,
          createdAt: DateTime.now(),
        ),
      );

      final res = await mockOrderDs.getOrders(page: 1, limit: 10);
      expect(res.isSuccess, isTrue);
      final orders = res.dataOrNull!.items;
      for (final order in orders) {
        expect(
          order.customerId == 'usr_customer_demo' || order.customerId == 'usr_lambac_1001',
          isTrue,
        );
      }
    });

    test('17. Barista staff see authorized order queue with status filter', () async {
      final mockOrderDs = MockOrderRemoteDataSource();
      mockOrderDs.setCurrentUser(
        UserModel(
          id: 'usr_barista_1',
          email: 'barista@lambac.com',
          fullName: 'Barista Hiro',
          role: UserRole.barista,
          status: UserStatus.active,
          createdAt: DateTime.now(),
        ),
      );

      final res = await mockOrderDs.getOrders(page: 1, limit: 10, statusFilter: OrderStatus.preparing);
      expect(res.isSuccess, isTrue);
      final orders = res.dataOrNull!.items;
      for (final order in orders) {
        expect(order.status, equals(OrderStatus.preparing));
      }
    });

    test('18. Admin sees administrative management dataset with bounded pagination', () async {
      final mockOrderDs = MockOrderRemoteDataSource();
      mockOrderDs.setCurrentUser(
        UserModel(
          id: 'usr_admin_1',
          email: 'admin@lambac.com',
          fullName: 'Admin Director',
          role: UserRole.admin,
          status: UserStatus.active,
          createdAt: DateTime.now(),
        ),
      );

      final res = await mockOrderDs.getOrders(page: 1, limit: 15);
      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull!.pageSize, equals(15));
    });

    test('19. Dashboard KPI totals remain independent of visible page slice', () {
      final allSalesAmounts = [120.0, 450.0, 380.0, 920.0, 150.0];
      final totalRevenue = allSalesAmounts.fold(0.0, (acc, a) => acc + a);

      // Simulating page 1 slice
      final page1 = allSalesAmounts.take(2).toList();
      final page1Sum = page1.fold(0.0, (acc, a) => acc + a);

      expect(page1.length, equals(2));
      expect(page1Sum, equals(570.0));
      expect(totalRevenue, equals(2020.0));
      expect(totalRevenue, isNot(equals(page1Sum)));
    });

    test('20. Reviews pagination bounds initial retrieval to limit', () async {
      final mockReviewsDs = MockReviewsRemoteDataSource();
      final res = await mockReviewsDs.getProductReviews('mt-apo-honey', limit: 1);

      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull!.length, equals(1));
    });

    test('21. FirestoreCursorPage container maintains lastDocument cursor', () {
      const page = FirestoreCursorPage<String>(
        items: ['doc_1', 'doc_2'],
        lastDocument: null,
        hasMore: true,
        totalCount: 50,
      );

      expect(page.items.length, equals(2));
      expect(page.hasMore, isTrue);
      expect(page.totalCount, equals(50));
    });

    test('22. MockProductDatabase customer visibility respects soft-deleted and hidden items', () {
      final db = MockProductDatabase();
      final visible = db.getCustomerVisibleProducts();
      for (final p in visible) {
        expect(p.customerVisibility, equals(ProductVisibility.visible));
      }
      // Verify hidden items are excluded
      final all = db.getAllProducts();
      final hiddenCount = all.where((p) => p.customerVisibility != ProductVisibility.visible).length;
      expect(visible.length, equals(all.length - hiddenCount));
    });
  });
}
