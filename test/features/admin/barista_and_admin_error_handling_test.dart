import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/errors/error_handler.dart';
import 'package:lambac_app/core/utils/validators.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/domain/services/order_queue_service.dart';
import 'package:lambac_app/features/pos/data/datasources/mock_pos_remote_datasource.dart';
import 'package:lambac_app/features/pos/data/models/pos_cart_item_model.dart';
import 'package:lambac_app/features/pos/data/models/pos_checkout_request.dart';
import 'package:lambac_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  const testLocation = PickupLocationModel(
    id: 'loc_flagship',
    name: 'Flagship Roastery',
    address: 'Session Road',
    city: 'Baguio City',
    operatingHours: '7AM - 9PM',
    phoneNumber: '09170000000',
  );

  group('B01 & A01: Role Resolution, Verification, and Session Access', () {
    test('UserRole.tryParse rejects unknown, malicious, or malformed role strings', () {
      expect(UserRole.tryParse('invalid_role'), isNull);
      expect(UserRole.tryParse('super_hacker'), isNull);
      expect(UserRole.tryParse(''), isNull);
      expect(UserRole.tryParse(null), isNull);
      expect(UserRole.tryParse('customer'), equals(UserRole.customer));
      expect(UserRole.tryParse('barista'), equals(UserRole.barista));
      expect(UserRole.tryParse('employee'), equals(UserRole.employee));
      expect(UserRole.tryParse('admin'), equals(UserRole.admin));
    });

    test('UserStatus correctly detects disabled/suspended employee or admin accounts', () {
      final disabledUser = UserModel(
        id: 'usr_disabled_1',
        email: 'barista.disabled@lambac.com',
        fullName: 'Disabled Staff',
        role: UserRole.barista,
        status: UserStatus.disabled,
      );

      final activeBarista = UserModel(
        id: 'usr_active_1',
        email: 'barista.active@lambac.com',
        fullName: 'Active Barista',
        role: UserRole.barista,
        status: UserStatus.active,
      );

      expect(disabledUser.status, equals(UserStatus.disabled));
      expect(disabledUser.isBarista, isTrue);
      expect(activeBarista.status, equals(UserStatus.active));
      expect(activeBarista.isBusinessUser, isTrue);
    });

    test('Role checks distinguish Barista from Admin and Customer', () {
      final customer = UserModel(
        id: 'cust_1',
        email: 'cust@gmail.com',
        fullName: 'Customer One',
        role: UserRole.customer,
      );

      final barista = UserModel(
        id: 'bar_1',
        email: 'barista@lambac.com',
        fullName: 'Barista One',
        role: UserRole.barista,
      );

      final admin = UserModel(
        id: 'adm_1',
        email: 'admin@lambac.com',
        fullName: 'Admin One',
        role: UserRole.admin,
      );

      expect(customer.isCustomer, isTrue);
      expect(customer.isBarista, isFalse);
      expect(customer.isAdmin, isFalse);
      expect(customer.isBusinessUser, isFalse);

      expect(barista.isCustomer, isFalse);
      expect(barista.isBarista, isTrue);
      expect(barista.isAdmin, isFalse);
      expect(barista.isBusinessUser, isTrue);

      expect(admin.isCustomer, isFalse);
      expect(admin.isBarista, isFalse);
      expect(admin.isAdmin, isTrue);
      expect(admin.isBusinessUser, isTrue);
    });
  });

  group('B02 & B03: Barista Dashboard and Order Queue Metrics', () {
    final queueService = OrderQueueService();

    test('Empty queue returns genuine 0 metrics, not fallback demo figures', () {
      final metrics = queueService.calculateMetrics([]);

      expect(metrics.activeCount, equals(0));
      expect(metrics.preparingCount, equals(0));
      expect(metrics.readyCount, equals(0));
      expect(metrics.completedCount, equals(0));
      expect(metrics.totalCount, equals(0));
    });

    test('Active queue badge counts only active orders and excludes terminal orders', () {
      final orders = <OrderModel>[
        OrderModel(
          id: 'ord_1',
          orderNumber: '001',
          customerId: 'c1',
          customerName: 'Alice',
          customerPhone: '09171234567',
          pickupLocation: testLocation,
          pickupTimeSlot: '10:00 AM',
          pickupDate: 'Today',
          status: OrderStatus.pending,
          subtotal: 350.0,
          totalAmount: 350.0,
          items: const [],
          createdAt: DateTime.now(),
        ),
        OrderModel(
          id: 'ord_2',
          orderNumber: '002',
          customerId: 'c2',
          customerName: 'Bob',
          customerPhone: '09171234568',
          pickupLocation: testLocation,
          pickupTimeSlot: '10:15 AM',
          pickupDate: 'Today',
          status: OrderStatus.preparing,
          subtotal: 420.0,
          totalAmount: 420.0,
          items: const [],
          createdAt: DateTime.now(),
        ),
        OrderModel(
          id: 'ord_3',
          orderNumber: '003',
          customerId: 'c3',
          customerName: 'Charlie',
          customerPhone: '09171234569',
          pickupLocation: testLocation,
          pickupTimeSlot: '10:30 AM',
          pickupDate: 'Today',
          status: OrderStatus.readyForPickup,
          subtotal: 250.0,
          totalAmount: 250.0,
          items: const [],
          createdAt: DateTime.now(),
        ),
        // Terminal orders:
        OrderModel(
          id: 'ord_4',
          orderNumber: '004',
          customerId: 'c4',
          customerName: 'Dave',
          customerPhone: '09171234570',
          pickupLocation: testLocation,
          pickupTimeSlot: '09:00 AM',
          pickupDate: 'Today',
          status: OrderStatus.completed,
          subtotal: 500.0,
          totalAmount: 500.0,
          items: const [],
          createdAt: DateTime.now(),
        ),
        OrderModel(
          id: 'ord_5',
          orderNumber: '005',
          customerId: 'c5',
          customerName: 'Eve',
          customerPhone: '09171234571',
          pickupLocation: testLocation,
          pickupTimeSlot: '09:15 AM',
          pickupDate: 'Today',
          status: OrderStatus.cancelled,
          subtotal: 300.0,
          totalAmount: 300.0,
          items: const [],
          createdAt: DateTime.now(),
        ),
      ];

      final metrics = queueService.calculateMetrics(orders);

      expect(metrics.activeCount, equals(3));
      expect(metrics.preparingCount, equals(1));
      expect(metrics.readyCount, equals(1));
      expect(metrics.completedCount, equals(1));

      // Active status filtering
      final activeList = orders.where((o) => o.status.isActive).toList();
      expect(activeList.length, equals(3));
      expect(activeList.any((o) => o.status == OrderStatus.completed), isFalse);
      expect(activeList.any((o) => o.status == OrderStatus.cancelled), isFalse);
    });
  });

  group('B04–B07: Barista Order Lifecycle and Status Transitions', () {
    test('OrderStatus transitions adhere to standard roastery pipeline', () {
      expect(OrderStatus.pending.isActive, isTrue);
      expect(OrderStatus.confirmed.isActive, isTrue);
      expect(OrderStatus.preparing.isActive, isTrue);
      expect(OrderStatus.prepared.isActive, isTrue);
      expect(OrderStatus.readyForPickup.isActive, isTrue);

      expect(OrderStatus.completed.isActive, isFalse);
      expect(OrderStatus.cancelled.isActive, isFalse);
    });

    test('Failure messages in Barista actions expose userFriendlyMessage', () {
      final networkFailure = ErrorHandler.handle(
        const SocketException('connection timed out'),
        operation: 'baristaQueue',
      );
      expect(networkFailure, isA<NetworkFailure>());
      expect(networkFailure.userFriendlyMessage, contains('connection'));

      const serverFailure = ServerFailure(message: 'Firestore batch transaction conflict: 503');
      expect(serverFailure.userFriendlyMessage, isNotEmpty);
    });
  });

  group('B10–B12: Shared POS Catalog, Cart, and Checkout Hardening', () {
    const sampleProduct = ProductModel(
      id: 'prod_benguet_1',
      name: 'Benguet Typica Heirloom',
      slug: 'benguet-typica-heirloom',
      origin: 'Atok, Benguet',
      description: 'Bright citrus with floral finish',
      basePrice: 450.0,
      categoryId: 'coffee',
      categoryName: 'Coffee',
      roastLevel: 'Medium Roast',
      tastingNotes: 'Citrus, honey, cocoa',
      stockQuantity: 25,
      isEnabled: true,
      availability: ProductAvailability.available,
    );

    test('POS Cart rejects negative or 0 quantity additions', () {
      final cartNotifier = PosCartNotifier();
      cartNotifier.addItem(product: sampleProduct, quantity: 0);
      expect(cartNotifier.state.items, isEmpty);

      cartNotifier.addItem(product: sampleProduct, quantity: -2);
      expect(cartNotifier.state.items, isEmpty);

      cartNotifier.addItem(product: sampleProduct, quantity: 2);
      expect(cartNotifier.state.items.length, equals(1));
      expect(cartNotifier.state.itemCount, equals(2));
      expect(cartNotifier.state.subtotal, equals(900.0));
    });

    test('POS Cart detects stale price and marks item as needing review', () {
      final cartNotifier = PosCartNotifier();
      cartNotifier.addItem(product: sampleProduct, quantity: 1);

      // Price changed from 450 to 520
      final List<ProductModel> updatedCatalog = [
        sampleProduct.copyWith(basePrice: 520.0),
      ];

      cartNotifier.reconcileWithLiveProducts(updatedCatalog);

      final cartItem = cartNotifier.state.items.first;
      expect(cartItem.isPriceStale, isTrue);
      expect(cartItem.currentLiveUnitPrice, equals(520.0));
      expect(cartNotifier.state.hasStalePrices, isTrue);
    });

    test('POS Cart detects product sold out or disabled and marks item unavailable', () {
      final cartNotifier = PosCartNotifier();
      cartNotifier.addItem(product: sampleProduct, quantity: 1);

      // Product disabled/sold out by admin
      final List<ProductModel> updatedCatalog = [
        sampleProduct.copyWith(isEnabled: false),
      ];

      cartNotifier.reconcileWithLiveProducts(updatedCatalog);

      final cartItem = cartNotifier.state.items.first;
      expect(cartItem.isUnavailable, isTrue);
      expect(cartNotifier.state.hasUnavailableItems, isTrue);
    });

    test('POS Checkout rejects empty cart', () async {
      final remoteDataSource = MockPosRemoteDataSource();
      const request = PosCheckoutRequest(
        items: [],
        paymentMethod: 'Cash',
        tenderedAmount: 500.0,
        staffId: 'staff_1',
        staffName: 'Barista John',
        idempotencyKey: 'tx_empty_001',
      );

      final result = await remoteDataSource.completeSaleTransaction(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message.contains('Cart cannot be empty'), isTrue);
    });

    test('POS Checkout rejects cart with price discrepancies', () async {
      final remoteDataSource = MockPosRemoteDataSource();
      remoteDataSource.simulateAdminUpdateProduct(sampleProduct);
      final staleItem = PosCartItemModel(
        id: 'prod_benguet_1_default_default',
        product: sampleProduct,
        capturedUnitPrice: 400.0, // Stale! Live price is 450.0
        currentLiveUnitPrice: 450.0,
        isPriceStale: true,
        quantity: 1,
      );

      final request = PosCheckoutRequest(
        items: [staleItem],
        paymentMethod: 'Cash',
        tenderedAmount: 500.0,
        staffId: 'staff_1',
        staffName: 'Barista John',
        idempotencyKey: 'tx_stale_002',
      );

      final result = await remoteDataSource.completeSaleTransaction(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message.contains('Price discrepancy detected'), isTrue);
    });

    test('POS Checkout rejects cart with sold-out or unavailable items', () async {
      final remoteDataSource = MockPosRemoteDataSource();
      final disabledProduct = sampleProduct.copyWith(isEnabled: false);
      remoteDataSource.simulateAdminUpdateProduct(disabledProduct);

      final unavailableItem = PosCartItemModel.fromProduct(
        product: disabledProduct,
        quantity: 1,
      );

      final request = PosCheckoutRequest(
        items: [unavailableItem],
        paymentMethod: 'Cash',
        tenderedAmount: 500.0,
        staffId: 'staff_1',
        staffName: 'Barista John',
        idempotencyKey: 'tx_unavail_003',
      );

      final result = await remoteDataSource.completeSaleTransaction(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message.contains('unavailable'), isTrue);
    });
  });

  group('A02–A06: Admin Validation and Integrity', () {
    test('Validators.price rejects negative, empty, or zero prices', () {
      expect(Validators.price(null, fieldName: 'Base price'), isNotNull);
      expect(Validators.price('', fieldName: 'Base price'), isNotNull);
      expect(Validators.price('-50', fieldName: 'Base price'), isNotNull);
      expect(Validators.price('0', fieldName: 'Base price'), isNotNull);
      expect(Validators.price('abc', fieldName: 'Base price'), isNotNull);
      expect(Validators.price('450.00', fieldName: 'Base price'), isNull);
    });

    test('Validators.productName rejects empty or too-short names', () {
      expect(Validators.productName(null), isNotNull);
      expect(Validators.productName(''), isNotNull);
      expect(Validators.productName('   '), isNotNull);
      expect(Validators.productName('A'), isNotNull); // Min 2 chars
      expect(Validators.productName('Benguet Typica'), isNull);
    });
  });
}
