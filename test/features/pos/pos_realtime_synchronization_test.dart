import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/pos/data/datasources/mock_pos_remote_datasource.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';

void main() {
  group('POS Real-Time Product Synchronization Tests', () {
    late MockPosRemoteDataSource remoteDataSource;

    setUp(() {
      remoteDataSource = MockPosRemoteDataSource();
    });

    tearDown(() {
      remoteDataSource.dispose();
    });

    test('watchProducts emits real-time stream of products on connection', () async {
      final stream = remoteDataSource.watchProducts();
      final initialProducts = await stream.first;

      expect(initialProducts.isNotEmpty, isTrue);
      expect(initialProducts.any((p) => p.id == 'tokyo-blend'), isTrue);
    });

    test('Scenario A: Price update propagates automatically without manual reload', () async {
      final emittedLists = <List<ProductModel>>[];
      final subscription = remoteDataSource.watchProducts().listen((list) {
        emittedLists.add(list);
      });

      // Wait for initial emission
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emittedLists.isNotEmpty, isTrue);

      final initialProduct = emittedLists.first.firstWhere((p) => p.id == 'tokyo-blend');
      final originalPrice = initialProduct.basePrice;

      // Admin updates product price from ₱380 to ₱410
      final updatedProduct = initialProduct.copyWith(basePrice: 410.0);
      remoteDataSource.simulateAdminUpdateProduct(updatedProduct);

      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Stream should have emitted the new snapshot automatically
      expect(emittedLists.length, greaterThanOrEqualTo(2));
      final latestList = emittedLists.last;
      final latestTokyo = latestList.firstWhere((p) => p.id == 'tokyo-blend');

      expect(latestTokyo.basePrice, 410.0);
      expect(latestTokyo.basePrice, isNot(equals(originalPrice)));

      await subscription.cancel();
    });

    test('Scenario B: New product added automatically appears in POS catalog', () async {
      final emittedLists = <List<ProductModel>>[];
      final subscription = remoteDataSource.watchProducts().listen((list) {
        emittedLists.add(list);
      });

      await Future<void>.delayed(const Duration(milliseconds: 30));

      const newProduct = ProductModel(
        id: 'sagada-peaberry-limited',
        name: 'Sagada Reserve Peaberry Micro-Lot',
        slug: 'sagada-peaberry-limited',
        origin: 'Sagada, Mountain Province',
        description: 'Rare hand-sorted peaberry roast with jasmine notes.',
        basePrice: 520.0,
        categoryId: 'single_origin',
        categoryName: 'Single Origin',
        roastLevel: 'Light-Medium Roast',
        tastingNotes: 'Jasmine, White Peach, Bergamot',
        isEnabled: true,
        stockQuantity: 15,
      );

      remoteDataSource.simulateAdminUpdateProduct(newProduct);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final latestList = emittedLists.last;
      expect(latestList.any((p) => p.id == 'sagada-peaberry-limited'), isTrue);
      final found = latestList.firstWhere((p) => p.id == 'sagada-peaberry-limited');
      expect(found.basePrice, 520.0);
      expect(found.stockQuantity, 15);

      await subscription.cancel();
    });

    test('Scenario C: Disabled product immediately reflects unavailable status', () async {
      final emittedLists = <List<ProductModel>>[];
      final subscription = remoteDataSource.watchProducts().listen((list) {
        emittedLists.add(list);
      });

      await Future<void>.delayed(const Duration(milliseconds: 30));
      final initialProduct = emittedLists.first.firstWhere((p) => p.id == 'mt-apo-honey');

      // Admin disables product
      final disabledProduct = initialProduct.copyWith(
        isEnabled: false,
        availability: ProductAvailability.outOfStock,
      );
      remoteDataSource.simulateAdminUpdateProduct(disabledProduct);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final latestMtApo = emittedLists.last.firstWhere((p) => p.id == 'mt-apo-honey');
      expect(latestMtApo.isEnabled, isFalse);
      expect(latestMtApo.isSoldOut, isTrue);

      await subscription.cancel();
    });

    test('Scenario D: Product image update propagates without application restart', () async {
      final emittedLists = <List<ProductModel>>[];
      final subscription = remoteDataSource.watchProducts().listen((list) {
        emittedLists.add(list);
      });

      await Future<void>.delayed(const Duration(milliseconds: 30));
      final initialProduct = emittedLists.first.firstWhere((p) => p.id == 'tokyo-blend');

      const newImageUrl = 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80';
      final updatedProduct = initialProduct.copyWith(imageUrl: newImageUrl);
      remoteDataSource.simulateAdminUpdateProduct(updatedProduct);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final latestProduct = emittedLists.last.firstWhere((p) => p.id == 'tokyo-blend');
      expect(latestProduct.imageUrl, newImageUrl);

      await subscription.cancel();
    });
  });
}
