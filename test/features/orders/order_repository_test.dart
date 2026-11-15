import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('OrderRepository Unit Tests', () {
    late InMemoryStorageService storageService;
    late MockOrderRemoteDataSource remoteDataSource;
    late OrderRepositoryImpl orderRepository;

    setUp(() {
      storageService = InMemoryStorageService();
      remoteDataSource = MockOrderRemoteDataSource();
      orderRepository = OrderRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
    });

    test('createOrder creates pending pickup order with generated order number', () async {
      final request = CreateOrderRequest(
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
        items: const [
          CartItemModel(
            id: 'item_test_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Honey Reserve',
            origin: 'Davao del Sur',
            roastLevel: 'Light Roast',
            unitPrice: 480.0,
            quantity: 2,
          ),
        ],
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: 'ASAP (~15-20 mins)',
        paymentMethod: 'Pay at Counter',
      );

      final result = await orderRepository.createOrder(request);

      expect(result.isSuccess, isTrue);
      final order = result.dataOrNull!;
      expect(order.orderNumber, startsWith('LMB-'));
      expect(order.customerName, equals('Kenji Takahashi'));
      expect(order.totalAmount, equals(960.0));
      expect(order.status, equals(OrderStatus.pending));
    });

    test('getOrders returns list of active and completed orders', () async {
      final result = await orderRepository.getOrders();

      expect(result.isSuccess, isTrue);
      final paginated = result.dataOrNull!;
      expect(paginated.items.isNotEmpty, isTrue);
      expect(paginated.items.any((o) => o.status.isActive), isTrue);
    });

    test('getOrderById returns matching order', () async {
      final result = await orderRepository.getOrderById('ord_lmb_1082');

      expect(result.isSuccess, isTrue);
      final order = result.dataOrNull!;
      expect(order.id, equals('ord_lmb_1082'));
      expect(order.items.isNotEmpty, isTrue);
    });

    test('cancelOrder updates order status to cancelled', () async {
      final result = await orderRepository.cancelOrder('ord_lmb_1082');

      expect(result.isSuccess, isTrue);
      final order = result.dataOrNull!;
      expect(order.status, equals(OrderStatus.cancelled));
    });
  });
}
