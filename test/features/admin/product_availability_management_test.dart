import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_database.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_remote_datasource.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';

void main() {
  group('Product Availability & Customer Visibility Lifecycle (Test Matrix)', () {
    late MockProductDatabase productDb;
    late MockAdminRemoteDataSource adminDataSource;
    late AdminRepositoryImpl adminRepository;
    late MockProductRemoteDataSource customerProductDataSource;
    late MockOrderRemoteDataSource orderDataSource;

    setUp(() {
      productDb = MockProductDatabase();
      productDb.resetForTesting();

      MockUserDatabase().seedDefaultUsers();
      // Authenticate admin user
      MockUserDatabase().setCurrentUser(
        MockUserDatabase().getByEmail('jmbautista0228@gmail.com')!.user,
      );

      adminDataSource = MockAdminRemoteDataSource();
      adminRepository = AdminRepositoryImpl(remoteDataSource: adminDataSource);
      customerProductDataSource = MockProductRemoteDataSource();
      orderDataSource = MockOrderRemoteDataSource();
      orderDataSource.resetForTesting();
    });

    test('Test 1: Admin enables product -> Customer catalog shows available and purchasable', () async {
      const productId = 'mt-apo-honey';

      // Ensure product is enabled
      final result = await adminRepository.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
      );
      expect(result.isSuccess, isTrue);

      // Customer fetches products
      final customerCatalogResult = await customerProductDataSource.getProducts();
      expect(customerCatalogResult.isSuccess, isTrue);

      final customerProduct = customerCatalogResult.dataOrNull!.items.firstWhere((p) => p.id == productId);
      expect(customerProduct.isEnabled, isTrue);
      expect(customerProduct.customerVisibility, equals(ProductVisibility.visible));
      expect(customerProduct.isOrderable, isTrue);
      expect(customerProduct.isSoldOut, isFalse);
      expect(customerProduct.isVisibleToCustomer, isTrue);
      expect(customerProduct.availability, equals(ProductAvailability.available));
    });

    test('Test 2: Admin disables product as "Show as Sold Out" -> Customer sees SOLD OUT and non-purchasable', () async {
      const productId = 'mt-apo-honey';

      // Admin disables with visible option
      final result = await adminRepository.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: false,
        customerVisibility: ProductVisibility.visible,
      );
      expect(result.isSuccess, isTrue);

      // Customer fetches products
      final customerCatalogResult = await customerProductDataSource.getProducts();
      expect(customerCatalogResult.isSuccess, isTrue);

      final customerProduct = customerCatalogResult.dataOrNull!.items.firstWhere((p) => p.id == productId);
      expect(customerProduct.isEnabled, isFalse);
      expect(customerProduct.customerVisibility, equals(ProductVisibility.visible));
      expect(customerProduct.isOrderable, isFalse);
      expect(customerProduct.isSoldOut, isTrue);
      expect(customerProduct.isVisibleToCustomer, isTrue);
      expect(customerProduct.availability, equals(ProductAvailability.outOfStock));
    });

    test('Test 3: Admin disables product as "Hide Product" -> Product is completely absent from customer catalog & search', () async {
      const productId = 'mt-apo-honey';

      // Admin disables with hidden option
      final result = await adminRepository.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: false,
        customerVisibility: ProductVisibility.hidden,
      );
      expect(result.isSuccess, isTrue);

      // Customer fetches catalog
      final customerCatalogResult = await customerProductDataSource.getProducts();
      expect(customerCatalogResult.isSuccess, isTrue);

      final matches = customerCatalogResult.dataOrNull!.items.where((p) => p.id == productId).toList();
      expect(matches, isEmpty, reason: 'Hidden product must not appear in customer catalog');

      // Customer searches specifically for the hidden product name
      final searchResult = await customerProductDataSource.getProducts(search: 'Mount Apo');
      expect(searchResult.isSuccess, isTrue);
      final searchMatches = searchResult.dataOrNull!.items.where((p) => p.id == productId).toList();
      expect(searchMatches, isEmpty, reason: 'Hidden product must not appear in search results');

      // Admin STILL sees the product in admin catalog
      final adminProductsResult = await adminRepository.getProducts();
      expect(adminProductsResult.isSuccess, isTrue);
      final adminMatches = adminProductsResult.dataOrNull!.where((p) => p.id == productId).toList();
      expect(adminMatches.length, equals(1));
      expect(adminMatches.first.customerVisibility, equals(ProductVisibility.hidden));
    });

    test('Test 4: Hidden product is re-enabled -> Immediately restores customer visibility and purchasability', () async {
      const productId = 'benguet-typica';

      // Step A: Hide product
      await adminRepository.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: false,
        customerVisibility: ProductVisibility.hidden,
      );

      // Verify hidden from customer
      var catalog = await customerProductDataSource.getProducts();
      expect(catalog.dataOrNull!.items.any((p) => p.id == productId), isFalse);

      // Step B: Re-enable product
      final enableResult = await adminRepository.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
      );
      expect(enableResult.isSuccess, isTrue);

      // Verify restored to customer
      catalog = await customerProductDataSource.getProducts();
      final restored = catalog.dataOrNull!.items.firstWhere((p) => p.id == productId);
      expect(restored.isEnabled, isTrue);
      expect(restored.isOrderable, isTrue);
      expect(restored.isVisibleToCustomer, isTrue);
    });

    test('Test 5: Sold-Out product is re-enabled -> Becomes available and purchasable again', () async {
      const productId = 'sagada-natural';

      // Set to Sold Out
      await adminRepository.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: false,
        customerVisibility: ProductVisibility.visible,
      );

      var detail = await customerProductDataSource.getProductById(productId);
      expect(detail.dataOrNull!.isSoldOut, isTrue);
      expect(detail.dataOrNull!.isOrderable, isFalse);

      // Re-enable
      await adminRepository.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
      );

      detail = await customerProductDataSource.getProductById(productId);
      expect(detail.dataOrNull!.isEnabled, isTrue);
      expect(detail.dataOrNull!.isOrderable, isTrue);
      expect(detail.dataOrNull!.isSoldOut, isFalse);
    });

    test('Test 6: Attempting direct API order creation with disabled product is rejected by backend', () async {
      const productId = 'mt-apo-honey';

      // Disable product
      await adminRepository.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: false,
        customerVisibility: ProductVisibility.visible,
      );

      // Attempt to place order with the disabled product
      final orderRequest = CreateOrderRequest(
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
        items: [
          CartItemModel(
            id: 'cart_item_1',
            productId: productId,
            productName: 'Mount Apo Anaerobic Honey Reserve',
            origin: 'Davao del Sur',
            roastLevel: 'Medium-Light Roast',
            unitPrice: 480.0,
            quantity: 1,
          ),
        ],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Today',
        pickupTimeSlot: 'ASAP (~15-20 mins)',
        paymentMethod: 'Pay at Counter',
      );

      final orderResult = await orderDataSource.createOrder(orderRequest);
      expect(orderResult.isFailure, isTrue);
      expect(orderResult.failureOrNull!.message, contains('unavailable or sold out'));
    });

    test('Test 7: Attempting direct API order creation with hidden product is rejected by backend', () async {
      const productId = 'tokyo-blend';

      // Hide product
      await adminRepository.setProductAvailabilityAndVisibility(
        productId: productId,
        isEnabled: false,
        customerVisibility: ProductVisibility.hidden,
      );

      // Attempt to place order
      final orderRequest = CreateOrderRequest(
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
        items: [
          CartItemModel(
            id: 'cart_item_2',
            productId: productId,
            productName: 'Tokyo Kissaten Signature Blend',
            origin: 'House Blend',
            roastLevel: 'Dark Roast',
            unitPrice: 380.0,
            quantity: 1,
          ),
        ],
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Today',
        pickupTimeSlot: 'ASAP (~15-20 mins)',
        paymentMethod: 'Pay at Counter',
      );

      final orderResult = await orderDataSource.createOrder(orderRequest);
      expect(orderResult.isFailure, isTrue);
      expect(orderResult.failureOrNull!.message, contains('unavailable or sold out'));
    });

    test('Test 8: Updating non-existent product returns failure and does not corrupt state', () async {
      final result = await adminRepository.setProductAvailabilityAndVisibility(
        productId: 'invalid_non_existent_id',
        isEnabled: false,
        customerVisibility: ProductVisibility.hidden,
      );

      expect(result.isFailure, isTrue);
    });

    test('Test 9: ProductModel JSON serialization preserves isEnabled and customerVisibility', () {
      final product = ProductModel(
        id: 'test-roast',
        name: 'Test Roast',
        slug: 'test-roast',
        origin: 'Atok',
        description: 'Test description',
        basePrice: 400.0,
        categoryId: 'single-origin',
        categoryName: 'Single Origin',
        roastLevel: 'Medium Roast',
        tastingNotes: 'Citrus, honey',
        isEnabled: false,
        customerVisibility: ProductVisibility.hidden,
      );

      final json = product.toJson();
      expect(json['is_enabled'], isFalse);
      expect(json['customer_visibility'], equals('hidden'));

      final restored = ProductModel.fromJson(json);
      expect(restored.isEnabled, isFalse);
      expect(restored.customerVisibility, equals(ProductVisibility.hidden));
      expect(restored.isOrderable, isFalse);
      expect(restored.isVisibleToCustomer, isFalse);
    });
  });
}
