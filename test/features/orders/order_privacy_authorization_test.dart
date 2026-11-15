import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Customer Order Privacy & Backend Authorization Tests', () {
    late MockUserDatabase userDb;
    late MockOrderRemoteDataSource remoteDataSource;
    late OrderRepositoryImpl repository;
    late InMemoryStorageService storageService;

    final customer1 = UserModel(
      id: 'usr_cust_1',
      email: 'customer1@test.com',
      fullName: 'Alice Walker',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    final customer2 = UserModel(
      id: 'usr_cust_2',
      email: 'customer2@test.com',
      fullName: 'Bob Smith',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 2),
    );

    final adminUser = UserModel(
      id: 'usr_admin_owner',
      email: 'jmbautista0228@gmail.com',
      fullName: 'JM Bautista (Owner)',
      role: UserRole.admin,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      userDb = MockUserDatabase();
      remoteDataSource = MockOrderRemoteDataSource();
      remoteDataSource.resetForTesting();
      storageService = InMemoryStorageService();
      repository = OrderRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
    });

    test('Test A: Customer 1 logs in -> only Customer 1 orders are returned', () async {
      remoteDataSource.addOrder(
        OrderModel(
          id: 'ord_c1_101',
          orderNumber: 'LMB-101',
          customerId: 'usr_cust_1',
          customerName: 'Alice Walker',
          customerPhone: '09171111111',
          items: const [],
          subtotal: 480,
          totalAmount: 480,
          status: OrderStatus.confirmed,
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'GCash',
          createdAt: DateTime.now(),
        ),
      );

      remoteDataSource.addOrder(
        OrderModel(
          id: 'ord_c2_202',
          orderNumber: 'LMB-202',
          customerId: 'usr_cust_2',
          customerName: 'Bob Smith',
          customerPhone: '09172222222',
          items: const [],
          subtotal: 900,
          totalAmount: 900,
          status: OrderStatus.preparing,
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'Maya',
          createdAt: DateTime.now(),
        ),
      );

      userDb.setCurrentUser(customer1);

      final result = await repository.getOrders();
      expect(result.isSuccess, isTrue);

      final orders = result.dataOrNull!.items;
      expect(orders.length, equals(1));
      expect(orders.first.id, equals('ord_c1_101'));
      expect(orders.any((o) => o.id == 'ord_c2_202'), isFalse);
    });

    test('Test B: Customer 2 logs in -> only Customer 2 orders are returned', () async {
      remoteDataSource.addOrder(
        OrderModel(
          id: 'ord_c1_101',
          orderNumber: 'LMB-101',
          customerId: 'usr_cust_1',
          customerName: 'Alice Walker',
          customerPhone: '09171111111',
          items: const [],
          subtotal: 480,
          totalAmount: 480,
          status: OrderStatus.confirmed,
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'GCash',
          createdAt: DateTime.now(),
        ),
      );

      remoteDataSource.addOrder(
        OrderModel(
          id: 'ord_c2_202',
          orderNumber: 'LMB-202',
          customerId: 'usr_cust_2',
          customerName: 'Bob Smith',
          customerPhone: '09172222222',
          items: const [],
          subtotal: 900,
          totalAmount: 900,
          status: OrderStatus.preparing,
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'Maya',
          createdAt: DateTime.now(),
        ),
      );

      userDb.setCurrentUser(customer2);

      final result = await repository.getOrders();
      expect(result.isSuccess, isTrue);

      final orders = result.dataOrNull!.items;
      expect(orders.length, equals(1));
      expect(orders.first.id, equals('ord_c2_202'));
      expect(orders.any((o) => o.id == 'ord_c1_101'), isFalse);
    });

    test('Test C: Customer 1 attempts IDOR access to Customer 2 order -> returns 403 Forbidden', () async {
      remoteDataSource.addOrder(
        OrderModel(
          id: 'ord_c2_secret',
          orderNumber: 'LMB-777',
          customerId: 'usr_cust_2',
          customerName: 'Bob Smith',
          customerPhone: '09172222222',
          items: const [],
          subtotal: 1200,
          totalAmount: 1200,
          status: OrderStatus.completed,
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'Card',
          createdAt: DateTime.now(),
        ),
      );

      // Customer 1 queries Customer 2's order ID
      userDb.setCurrentUser(customer1);

      final result = await repository.getOrderById('ord_c2_secret');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(result.failureOrNull?.message, contains('Forbidden'));
    });

    test('Test D: Order creation derives customerId strictly from authenticated user', () async {
      userDb.setCurrentUser(customer1);

      final result = await repository.createOrder(
        CreateOrderRequest(
          customerName: 'Alice Walker',
          customerPhone: '09171111111',
          items: const [
            CartItemModel(
              id: 'cart_1',
              productId: 'mt-apo',
              productName: 'Mount Apo',
              origin: 'Davao',
              roastLevel: 'Light Roast',
              unitPrice: 480,
              quantity: 1,
            ),
          ],
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'GCash',
        ),
      );

      expect(result.isSuccess, isTrue);
      final newOrder = result.dataOrNull!;
      expect(newOrder.customerId, equals('usr_cust_1'));
    });

    test('Test E: Business Admin logs in -> can access all business orders', () async {
      remoteDataSource.addOrder(
        OrderModel(
          id: 'ord_c1_101',
          orderNumber: 'LMB-101',
          customerId: 'usr_cust_1',
          customerName: 'Alice Walker',
          customerPhone: '09171111111',
          items: const [],
          subtotal: 480,
          totalAmount: 480,
          status: OrderStatus.confirmed,
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'GCash',
          createdAt: DateTime.now(),
        ),
      );

      remoteDataSource.addOrder(
        OrderModel(
          id: 'ord_c2_202',
          orderNumber: 'LMB-202',
          customerId: 'usr_cust_2',
          customerName: 'Bob Smith',
          customerPhone: '09172222222',
          items: const [],
          subtotal: 900,
          totalAmount: 900,
          status: OrderStatus.preparing,
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'Maya',
          createdAt: DateTime.now(),
        ),
      );

      userDb.setCurrentUser(adminUser);

      final result = await repository.getOrders();
      expect(result.isSuccess, isTrue);

      final orders = result.dataOrNull!.items;
      expect(orders.any((o) => o.id == 'ord_c1_101'), isTrue);
      expect(orders.any((o) => o.id == 'ord_c2_202'), isTrue);
    });

    test('Test F: Customer 1 cannot cancel Customer 2 order -> returns 403 Forbidden', () async {
      remoteDataSource.addOrder(
        OrderModel(
          id: 'ord_c2_202',
          orderNumber: 'LMB-202',
          customerId: 'usr_cust_2',
          customerName: 'Bob Smith',
          customerPhone: '09172222222',
          items: const [],
          subtotal: 900,
          totalAmount: 900,
          status: OrderStatus.preparing,
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'Maya',
          createdAt: DateTime.now(),
        ),
      );

      userDb.setCurrentUser(customer1);

      final result = await repository.cancelOrder('ord_c2_202');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });
  });
}
