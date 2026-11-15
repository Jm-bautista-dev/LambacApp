import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_remote_datasource.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('ProductRepository Unit Tests', () {
    late InMemoryStorageService storageService;
    late MockProductRemoteDataSource remoteDataSource;
    late ProductRepositoryImpl productRepository;

    setUp(() {
      storageService = InMemoryStorageService();
      remoteDataSource = MockProductRemoteDataSource();
      productRepository = ProductRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
    });

    test('getProducts returns all available roasts', () async {
      final result = await productRepository.getProducts();

      expect(result.isSuccess, isTrue);
      final paginated = result.dataOrNull!;
      expect(paginated.items.isNotEmpty, isTrue);
      expect(paginated.items.any((p) => p.name.contains('Mount Apo')), isTrue);
    });

    test('getProducts with category filter returns matching products only', () async {
      final result = await productRepository.getProducts(categoryId: 'cold-brew');

      expect(result.isSuccess, isTrue);
      final products = result.dataOrNull!.items;
      expect(products.isNotEmpty, isTrue);
      for (final p in products) {
        expect(p.categoryId, equals('cold-brew'));
      }
    });

    test('getProducts with search query filters correctly', () async {
      final result = await productRepository.getProducts(search: 'Benguet');

      expect(result.isSuccess, isTrue);
      final products = result.dataOrNull!.items;
      expect(products.isNotEmpty, isTrue);
      for (final p in products) {
        final matches = p.name.contains('Benguet') ||
            p.origin.contains('Benguet') ||
            p.tastingNotes.contains('Benguet');
        expect(matches, isTrue);
      }
    });

    test('getProductById returns accurate product detail with variants', () async {
      final result = await productRepository.getProductById('mt-apo-honey');

      expect(result.isSuccess, isTrue);
      final product = result.dataOrNull!;
      expect(product.id, equals('mt-apo-honey'));
      expect(product.sizeVariants.isNotEmpty, isTrue);
      expect(product.grindVariants.isNotEmpty, isTrue);
      expect(product.availability, equals(ProductAvailability.available));
    });

    test('getCategories returns category list including all roasts', () async {
      final result = await productRepository.getCategories();

      expect(result.isSuccess, isTrue);
      final categories = result.dataOrNull!;
      expect(categories.any((c) => c.slug == 'single-origin'), isTrue);
      expect(categories.any((c) => c.slug == 'cold-brew'), isTrue);
    });

    test('toggleFavorite updates product favorite state', () async {
      final isFav1 = await productRepository.toggleFavorite('benguet-typica');
      expect(isFav1.isSuccess, isTrue);

      final favs = await productRepository.getFavorites();
      expect(favs.dataOrNull?.any((p) => p.id == 'benguet-typica'), isTrue);
    });
  });
}
