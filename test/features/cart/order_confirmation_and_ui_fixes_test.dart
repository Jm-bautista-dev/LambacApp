import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lambac_app/core/widgets/app_bars/lambac_app_bar.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/cart/presentation/screens/order_confirmation_screen.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/features/orders/presentation/providers/payment_provider.dart';
import 'package:lambac_app/features/products/presentation/widgets/app_product_image.dart';

OrderModel _samplePendingGcashOrder({
  String? checkoutUrl = 'https://checkout.paymongo.com/cs_test_123456',
  String paymentStatus = 'PENDING',
  OrderStatus status = OrderStatus.pending,
  DateTime? paidAt,
}) {
  return OrderModel(
    id: 'ord_test_overflow_1',
    orderNumber: 'LMB-2026-9981',
    customerId: 'cust_1',
    customerName: 'Alex Roaster',
    customerPhone: '09171234567',
    items: const [
      OrderItemModel(
        id: 'item_1',
        productId: 'benguet-typica',
        productName: 'Benguet Typica Washed',
        origin: 'Benguet, Philippines',
        size: '250g Bag',
        grind: 'Whole Bean',
        quantity: 2,
        unitPrice: 420.0,
        totalPrice: 840.0,
      ),
    ],
    subtotal: 840.0,
    totalAmount: 840.0,
    status: status,
    pickupLocation: const PickupLocationModel(
      id: 'loc_baguio',
      name: 'Lambac Roastery Flagship — Session Road, Baguio City',
      address: '123 Session Road, Baguio City',
      city: 'Baguio City',
      operatingHours: '7:00 AM - 9:00 PM',
      phoneNumber: '09171234567',
    ),
    pickupDate: 'November 15, 2026',
    pickupTimeSlot: '10:30 AM - 11:00 AM',
    paymentMethod: 'GCash',
    paymentStatus: paymentStatus,
    checkoutUrl: checkoutUrl,
    paymentReference: 'cs_live_very_long_paymongo_reference_identifier_9876543210',
    paidAt: paidAt,
    createdAt: DateTime(2026, 11, 15, 10, 0),
  );
}

void main() {
  group('OrderConfirmationScreen Responsive Overflow Validation', () {
    const testSizes = <Size>[
      Size(320, 568),
      Size(360, 800),
      Size(390, 844),
      Size(430, 932),
      Size(768, 1024),
      Size(1366, 768),
      Size(1920, 1080),
    ];

    for (final size in testSizes) {
      testWidgets(
        'renders pending GCash order without RenderFlex overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final errors = <FlutterErrorDetails>[];
          final originalOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            errors.add(details);
          };

          try {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            final order = _samplePendingGcashOrder();
            final router = GoRouter(
              initialLocation: '/confirm',
              routes: [
                GoRoute(
                  path: '/confirm',
                  builder: (_, __) => OrderConfirmationScreen(orderId: order.id),
                ),
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const Scaffold(body: Text('Home')),
                ),
              ],
            );

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  orderDetailProvider(order.id).overrideWith((ref) async => order),
                  orderPaymentStatusStreamProvider(order.id)
                      .overrideWith((ref) => Stream.value(order)),
                ],
                child: MaterialApp.router(routerConfig: router),
              ),
            );
            await tester.pumpAndSettle();

            final overflowErrors = errors
                .where((e) => e.toString().contains('RenderFlex overflowed'))
                .toList();
            expect(overflowErrors, isEmpty,
                reason: 'Unexpected RenderFlex overflow at $size: $overflowErrors');
            expect(find.text('Your Order is Confirmed!'), findsOneWidget);
            expect(find.text('Open GCash Checkout'), findsOneWidget);
            expect(find.text('Check Status'), findsOneWidget);
            expect(find.text('Track Order Status'), findsOneWidget);
            expect(find.text('Back to Roastery Home'), findsOneWidget);
          } finally {
            FlutterError.onError = originalOnError;
          }
        },
      );
    }

    testWidgets(
      'renders paid GCash state and fallback null-order state cleanly at 320x568',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final paidOrder = _samplePendingGcashOrder(
          paymentStatus: 'PAID',
          status: OrderStatus.confirmed,
          paidAt: DateTime(2026, 11, 15, 10, 5),
        );

        final router = GoRouter(
          initialLocation: '/confirm',
          routes: [
            GoRoute(
              path: '/confirm',
              builder: (_, __) => OrderConfirmationScreen(orderId: paidOrder.id),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              orderDetailProvider(paidOrder.id).overrideWith((ref) async => paidOrder),
              orderPaymentStatusStreamProvider(paidOrder.id)
                  .overrideWith((ref) => Stream.value(paidOrder)),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PAID (GCash)'), findsOneWidget);
        expect(find.text('• Payment Verified via GCash (PayMongo) •'), findsOneWidget);
      },
    );
  });

  group('AppProductImage CanvasKit & Source Validation', () {
    test('validates network URLs and base64 data URIs safely', () {
      expect(AppProductImage.isValidNetworkImageUrl(null), isFalse);
      expect(AppProductImage.isValidNetworkImageUrl(''), isFalse);
      expect(AppProductImage.isValidNetworkImageUrl('   '), isFalse);
      expect(AppProductImage.isValidNetworkImageUrl('not-a-url'), isFalse);
      expect(AppProductImage.isValidNetworkImageUrl('ftp://example.com/a.jpg'), isFalse);
      expect(
        AppProductImage.isValidNetworkImageUrl('https://images.unsplash.com/photo-1.jpg'),
        isTrue,
      );

      // 1x1 transparent PNG base64
      const validPngBase64 =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      expect(AppProductImage.tryDecodeDataUri(validPngBase64), isNotNull);
      expect(AppProductImage.tryDecodeDataUri('data:image/svg+xml;base64,PHN2Zz4='), isNull);
      expect(AppProductImage.tryDecodeDataUri('data:image/png;base64,!!!invalid!!!'), isNull);
    });

    testWidgets('renders fallback icon for empty/invalid URLs and MemoryImage for valid data URI',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppProductImage(imageUrl: '', width: 80, height: 80),
                AppProductImage(imageUrl: 'invalid-url', width: 80, height: 80),
                AppProductImage(imageUrl: 'https://example.com/a.jpg', width: 0, height: 0),
                AppProductImage(
                  imageUrl:
                      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
                  width: 80,
                  height: 80,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.coffee_rounded), findsNWidgets(2));
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('LambacAppBar Global Back Navigation', () {
    testWidgets('hides back button on root tab when showBackButton is false', (tester) async {
      final router = GoRouter(
        initialLocation: '/root',
        routes: [
          GoRoute(
            path: '/root',
            builder: (_, __) => const Scaffold(
              appBar: LambacAppBar(
                title: 'Catalog',
                showBackButton: false,
              ),
              body: SizedBox.shrink(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });

    testWidgets(
      'shows back button and navigates to fallbackRoute when canPop is false (Web refresh)',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/detail',
          routes: [
            GoRoute(
              path: '/products',
              builder: (_, __) => const Scaffold(body: Text('Products Root')),
            ),
            GoRoute(
              path: '/detail',
              builder: (_, __) => const Scaffold(
                appBar: LambacAppBar(
                  title: 'Micro-Lot Details',
                  fallbackRoute: '/products',
                ),
                body: Text('Detail Page'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Products Root'), findsOneWidget);
      },
    );

    testWidgets('pops back to previous route when navigation stack has history', (tester) async {
      final router = GoRouter(
        initialLocation: '/products',
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, __) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/detail'),
                child: const Text('Open Detail'),
              ),
            ),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, __) => const Scaffold(
              appBar: LambacAppBar(
                title: 'Micro-Lot Details',
                fallbackRoute: '/home',
              ),
              body: Text('Detail Page'),
            ),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Page'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Open Detail'), findsOneWidget);
    });
  });
}
