import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_database.dart';
import 'package:lambac_app/features/products/data/models/product_category_model.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';

void main() {
  group('Firestore Product & Category Migration Specifications', () {
    test('ProductModel adheres to normalized Firestore structure', () {
      const product = ProductModel(
        id: 'mt-apo-honey',
        name: 'Mount Apo Anaerobic Honey Reserve',
        slug: 'mt-apo-honey',
        origin: 'Davao del Sur, Philippines',
        description: 'Hand-picked Catimor cherries fermented anaerobically in stainless tanks.',
        basePrice: 480.0,
        imageUrl: 'https://images.unsplash.com/photo-1587734195503-904fca47e0e9',
        categoryId: 'micro-lot',
        categoryName: 'Anaerobic Lots',
        roastLevel: 'Light-Medium Roast',
        tastingNotes: 'Wild raspberry, honey & bergamot finish.',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 18,
        isFeatured: true,
      );

      final json = product.toJson();

      // Verify Firestore field normalization
      expect(json['id'], equals('mt-apo-honey'));
      expect(json['name'], equals('Mount Apo Anaerobic Honey Reserve'));
      expect(json['price'], equals(480.0));
      expect(json['category_id'], equals('micro-lot'));
      expect(json['is_enabled'], isTrue);
      expect(json['customer_visibility'], equals('visible'));
      expect(json['availability'], equals('available'));
      expect(json['stock_quantity'], equals(18));
      expect(json['image_url'], startsWith('https://'));

      // Round-trip deserialization
      final deserialized = ProductModel.fromJson(json);
      expect(deserialized.id, equals(product.id));
      expect(deserialized.basePrice, equals(product.basePrice));
      expect(deserialized.customerVisibility, equals(ProductVisibility.visible));
      expect(deserialized.isEnabled, isTrue);
    });

    test('ProductCategoryModel adheres to normalized Firestore structure', () {
      const category = ProductCategoryModel(
        id: 'micro-lot',
        name: 'Anaerobic Lots',
        slug: 'micro-lot',
        sortOrder: 2,
      );

      final json = category.toJson();
      expect(json['id'], equals('micro-lot'));
      expect(json['name'], equals('Anaerobic Lots'));
      expect(json['slug'], equals('micro-lot'));
      expect(json['sort_order'], equals(2));

      final deserialized = ProductCategoryModel.fromJson(json);
      expect(deserialized.id, equals('micro-lot'));
      expect(deserialized.name, equals('Anaerobic Lots'));
      expect(deserialized.sortOrder, equals(2));
    });

    test('Catalog default categories preserve stable identifiers and sorting', () {
      final categories = MockProductDatabase.categories;

      expect(categories.length, equals(6));
      final ids = categories.map((c) => c.id).toList();
      expect(ids, containsAll(['all', 'single-origin', 'micro-lot', 'blends', 'cold-brew', 'drip-kits']));

      // Idempotency: verify no duplicate IDs in seed categories
      expect(ids.toSet().length, equals(categories.length));
    });

    test('Catalog default products preserve stable identifiers and image URLs', () {
      final products = MockProductDatabase().getAllProducts();

      expect(products.length, greaterThanOrEqualTo(8));
      final ids = products.map((p) => p.id).toList();
      expect(ids, contains('mt-apo-honey'));
      expect(ids, contains('tokyo-blend'));
      expect(ids, contains('benguet-typica'));

      // Verify no duplicates
      expect(ids.toSet().length, equals(products.length));

      // Image URLs must be valid and NOT large binary/base64 strings
      for (final p in products) {
        if (p.imageUrl != null) {
          expect(p.imageUrl!.startsWith('http://') || p.imageUrl!.startsWith('https://'), isTrue);
          expect(p.imageUrl!.contains('data:image'), isFalse);
        }
      }
    });

    test('Customer catalog visibility semantics properly filters hidden products', () {
      final db = MockProductDatabase();
      db.resetToDefaults();

      // Disable a product and hide it
      db.setProductStatus(
        productId: 'tokyo-blend',
        isEnabled: false,
        customerVisibility: ProductVisibility.hidden,
      );

      final customerVisible = db.getCustomerVisibleProducts();
      expect(customerVisible.any((p) => p.id == 'tokyo-blend'), isFalse);

      final allProducts = db.getAllProducts();
      expect(allProducts.any((p) => p.id == 'tokyo-blend'), isTrue);
    });

    test('Sold-out products remain visible to customers but marked unavailable', () {
      final db = MockProductDatabase();
      db.resetToDefaults();

      // Mark product as sold out (disabled but visible)
      db.setProductStatus(
        productId: 'benguet-typica',
        isEnabled: false,
        customerVisibility: ProductVisibility.visible,
      );

      final customerVisible = db.getCustomerVisibleProducts();
      final benguet = customerVisible.firstWhere((p) => p.id == 'benguet-typica');
      expect(benguet.isSoldOut, isTrue);
      expect(benguet.isOrderable, isFalse);
      expect(benguet.isVisibleToCustomer, isTrue);
    });

    test('Admin product management updates survive and propagate to catalog', () {
      final db = MockProductDatabase();
      db.resetToDefaults();

      const newRoast = ProductModel(
        id: 'sagada-dark-reserve',
        name: 'Sagada Dark Roast Reserve',
        slug: 'sagada-dark-reserve',
        origin: 'Sagada, Mountain Province',
        description: 'Intense dark roast with notes of molasses and baker\'s chocolate.',
        basePrice: 460.0,
        categoryId: 'single-origin',
        categoryName: 'Single Origin',
        roastLevel: 'Dark Roast',
        tastingNotes: 'Molasses, dark cocoa & cedar.',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
        stockQuantity: 15,
      );

      final saved = db.addProduct(newRoast);
      expect(saved.id, equals('sagada-dark-reserve'));

      final retrieved = db.getProductById('sagada-dark-reserve');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Sagada Dark Roast Reserve'));

      // Edit specs
      final updated = db.updateProduct(retrieved.copyWith(basePrice: 490.0));
      expect(updated.basePrice, equals(490.0));

      final afterUpdate = db.getProductById('sagada-dark-reserve');
      expect(afterUpdate!.basePrice, equals(490.0));
    });
  });
}
