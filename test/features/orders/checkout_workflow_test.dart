import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:lambac_app/features/cart/presentation/screens/checkout_screen.dart';
import 'package:lambac_app/features/cart/presentation/screens/order_confirmation_screen.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
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

  Widget buildTestableWidget(Widget child, {CartState? initialCartState}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(
          const UserModel(
            id: 'cust_1',
            email: 'test@lambac.com',
            fullName: 'Test Customer',
            role: UserRole.customer,
            phoneNumber: '09171234567',
          ),
        ),
        orderRepositoryProvider.overrideWithValue(orderRepository),
        if (initialCartState != null)
          cartNotifierProvider.overrideWith(
            (ref) => CartNotifier(storageService: storageService)..state = initialCartState,
          ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Checkout & Order Confirmation Widget Tests', () {
    testWidgets('CheckoutScreen renders pickup location, time slots, and payment options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartWithItems = const CartState(
        items: [
          CartItemModel(
            id: 'item_1',
            productId: 'mt-apo-honey',
            productName: 'Mount Apo Honey Reserve',
            origin: 'Davao del Sur',
            roastLevel: 'Light Roast',
            unitPrice: 480.0,
            quantity: 1,
          ),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(const CheckoutScreen(), initialCartState: cartWithItems));

      expect(find.text('Pickup Checkout'), findsOneWidget);
      expect(find.text('Roastery Pickup Order Only'), findsOneWidget);
      expect(find.text('Lambac Flagship Roastery Bar'), findsOneWidget);
      expect(find.text('Select Pickup Time'), findsOneWidget);
      expect(find.text('ASAP (~15-20 mins)'), findsOneWidget);
      expect(find.text('GCash E-Wallet'), findsOneWidget);
      expect(find.text('Confirm Pickup Order'), findsOneWidget);
    });

    testWidgets('OrderConfirmationScreen renders order number and pickup receipt', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          const OrderConfirmationScreen(orderId: 'ord_lmb_1082'),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Your Order is Confirmed!'), findsOneWidget);
      expect(find.text('Order Number'), findsOneWidget);
      expect(find.text('LMB-1082'), findsOneWidget);
      expect(find.text('Track Order Status'), findsOneWidget);
      expect(find.text('Back to Roastery Home'), findsOneWidget);
    });

    testWidgets('OrderDetailScreen renders live status stepper and ordered items', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          const OrderDetailScreen(orderId: 'ord_lmb_1082'),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Order Status'), findsOneWidget);
      expect(find.text('Order #LMB-1082'), findsOneWidget);
      expect(find.text('Placed'), findsOneWidget);
      expect(find.text('Brewing'), findsOneWidget);
      expect(find.text('Pickup Details'), findsOneWidget);
    });
  });
}
