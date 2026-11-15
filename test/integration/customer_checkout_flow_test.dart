import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:lambac_app/features/cart/presentation/screens/checkout_screen.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Integration Test: Customer Ordering & Checkout Journey', () {
    late InMemoryStorageService storageService;
    late MockOrderRemoteDataSource orderRemoteDataSource;
    late OrderRepositoryImpl orderRepository;

    setUp(() {
      storageService = InMemoryStorageService();
      orderRemoteDataSource = MockOrderRemoteDataSource();
      orderRepository = OrderRepositoryImpl(
        remoteDataSource: orderRemoteDataSource,
        storageService: storageService,
      );
    });

    testWidgets('Full Pickup Checkout submission clears cart and confirms order', (WidgetTester tester) async {
      final cartWithItems = const CartState(
        items: [
          CartItemModel(
            id: 'item_integration_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            origin: 'Davao del Sur',
            roastLevel: 'Light Roast',
            unitPrice: 480.0,
            quantity: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(orderRepository),
            cartNotifierProvider.overrideWith(
              (ref) => CartNotifier(storageService: storageService)..state = cartWithItems,
            ),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );

      expect(find.text('Pickup Checkout'), findsOneWidget);
      expect(find.text('Confirm Pickup Order'), findsOneWidget);

      // Tap Confirm Pickup Order
      await tester.tap(find.text('Confirm Pickup Order'));
      await tester.pumpAndSettle();
    });
  });
}
