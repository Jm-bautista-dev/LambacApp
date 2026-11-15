import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_remote_datasource.dart';
import 'package:lambac_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:lambac_app/features/products/presentation/providers/products_provider.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('ProductsNotifier State Management Tests', () {
    late InMemoryStorageService storageService;
    late MockProductRemoteDataSource remoteDataSource;
    late ProductRepositoryImpl productRepository;
    late ProductsNotifier notifier;

    setUp(() {
      storageService = InMemoryStorageService();
      remoteDataSource = MockProductRemoteDataSource();
      productRepository = ProductRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
      notifier = ProductsNotifier(repository: productRepository);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('Initial load populates products list successfully', () async {
      await notifier.loadProducts();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.products.isNotEmpty, isTrue);
      expect(notifier.state.selectedCategoryId, equals('all'));
    });

    test('selectCategory updates state and loads filtered products', () async {
      notifier.selectCategory('single-origin');
      expect(notifier.state.selectedCategoryId, equals('single-origin'));

      await Future.delayed(const Duration(milliseconds: 500));
      expect(notifier.state.products.isNotEmpty, isTrue);
      for (final p in notifier.state.products) {
        expect(p.categoryId, equals('single-origin'));
      }
    });

    test('toggleViewMode toggles grid and list presentation', () {
      final initialMode = notifier.state.isGridView;
      notifier.toggleViewMode();
      expect(notifier.state.isGridView, equals(!initialMode));
      notifier.toggleViewMode();
      expect(notifier.state.isGridView, equals(initialMode));
    });

    test('clearSearch resets query and category filter', () async {
      notifier.setSearchQuery('non-existent-bean');
      await Future.delayed(const Duration(milliseconds: 400));

      notifier.clearSearch();
      expect(notifier.state.searchQuery, isEmpty);
      expect(notifier.state.selectedCategoryId, equals('all'));
    });
  });
}
