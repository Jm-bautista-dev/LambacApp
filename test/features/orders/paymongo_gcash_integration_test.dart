import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/domain/services/paymongo_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('PayMongo GCash OrderModel & Data Integration Tests', () {
    final now = DateTime(2026, 11, 14, 15, 30, 0);

    test('OrderModel serialization with GCash and PayMongo metadata', () {
      final order = OrderModel(
        id: 'LMB-9999',
        orderNumber: 'LMB-9999',
        customerId: 'cust-123',
        customerName: 'Maria Santos',
        customerPhone: '09171234567',
        items: const [
          OrderItemModel(
            id: 'item-1',
            productId: 'prod-1',
            productName: 'Signature Pour-Over',
            origin: 'Benguet',
            quantity: 2,
            unitPrice: 180.0,
            totalPrice: 360.0,
          ),
        ],
        subtotal: 360.0,
        totalAmount: 360.0,
        status: OrderStatus.pending,
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: '15:45',
        paymentMethod: 'GCash',
        paymentStatus: 'PENDING',
        createdAt: now,
        paymentProvider: 'PayMongo',
        paymentReference: 'cs_test_sample_checkout_session_123',
        checkoutUrl: 'https://paymongo.page/l/test-session-123',
        paidAt: null,
      );

      final json = order.toJson();

      expect(json['id'], 'LMB-9999');
      expect(json['payment_method'], 'GCash');
      expect(json['payment_status'], 'PENDING');
      expect(json['payment_provider'], 'PayMongo');
      expect(json['payment_reference'], 'cs_test_sample_checkout_session_123');
      expect(json['checkout_url'], 'https://paymongo.page/l/test-session-123');
      expect(json['paid_at'], isNull);
    });

    test('OrderModel deserialization handles all PaymentStatus representations', () {
      final baseMap = {
        'id': 'LMB-1001',
        'order_number': 'LMB-1001',
        'customer_id': 'cust-456',
        'customer_name': 'Juan Dela Cruz',
        'customer_phone': '09181234567',
        'items': <Map<String, dynamic>>[],
        'subtotal': 250.0,
        'total_amount': 250.0,
        'status': 'PENDING',
        'pickup_location': PickupLocationModel.flagship.toJson(),
        'pickup_time_slot': '16:00',
        'payment_method': 'GCash',
        'created_at': now.toIso8601String(),
        'payment_provider': 'PayMongo',
        'payment_reference': 'cs_test_reference_xyz',
      };

      // 1. PENDING
      var order = OrderModel.fromJson({...baseMap, 'payment_status': 'PENDING'});
      expect(order.paymentStatusEnum, PaymentStatus.pending);
      expect(order.paymentStatus, 'PENDING');

      // 2. PAID
      order = OrderModel.fromJson({
        ...baseMap,
        'payment_status': 'PAID',
        'paid_at': now.toIso8601String(),
      });
      expect(order.paymentStatusEnum, PaymentStatus.paid);
      expect(order.paymentStatus, 'PAID');
      expect(order.paidAt, isNotNull);

      // 3. FAILED
      order = OrderModel.fromJson({
        ...baseMap,
        'payment_status': 'FAILED',
        'payment_failure_reason': 'Payment expired by user',
      });
      expect(order.paymentStatusEnum, PaymentStatus.failed);
      expect(order.paymentFailureReason, 'Payment expired by user');

      // 4. EXPIRED
      order = OrderModel.fromJson({...baseMap, 'payment_status': 'EXPIRED'});
      expect(order.paymentStatusEnum, PaymentStatus.expired);

      // 5. CANCELLED
      order = OrderModel.fromJson({...baseMap, 'payment_status': 'CANCELLED'});
      expect(order.paymentStatusEnum, PaymentStatus.cancelled);

      // 6. UNPAID (Counter order)
      order = OrderModel.fromJson({
        ...baseMap,
        'payment_method': 'Pay at Counter',
        'payment_status': 'UNPAID',
      });
      expect(order.paymentStatusEnum, PaymentStatus.unpaid);
    });

    test('OrderModel copyWith preserves and updates PayMongo fields correctly', () {
      final order = OrderModel(
        id: 'LMB-2002',
        orderNumber: 'LMB-2002',
        customerId: 'cust-789',
        customerName: 'Anna Reyes',
        customerPhone: '09191234567',
        items: const [],
        subtotal: 450.0,
        totalAmount: 450.0,
        status: OrderStatus.pending,
        pickupLocation: PickupLocationModel.flagship,
        pickupTimeSlot: '17:00',
        paymentMethod: 'GCash',
        paymentStatus: 'PENDING',
        createdAt: now,
        paymentProvider: 'PayMongo',
      );

      final paidOrder = order.copyWith(
        paymentStatus: 'PAID',
        paymentReference: 'pay_test_payment_id_999',
        paidAt: now,
      );

      expect(paidOrder.paymentStatusEnum, PaymentStatus.paid);
      expect(paidOrder.paymentStatus, 'PAID');
      expect(paidOrder.paymentReference, 'pay_test_payment_id_999');
      expect(paidOrder.paidAt, now);
      expect(paidOrder.paymentProvider, 'PayMongo');
      expect(paidOrder.totalAmount, 450.0);
    });
  });

  group('PaymongoCheckoutResponse Unit Tests', () {
    test('PaymongoCheckoutResponse models checkout URL and session data', () {
      const response = PaymongoCheckoutResponse(
        orderId: 'LMB-1234',
        orderNumber: 'LMB-1234',
        checkoutSessionId: 'cs_12345678',
        checkoutUrl: 'https://paymongo.page/l/test_url',
        amount: 250.0,
        currency: 'PHP',
        paymentMethod: 'GCash',
      );

      expect(response.orderId, 'LMB-1234');
      expect(response.orderNumber, 'LMB-1234');
      expect(response.checkoutSessionId, 'cs_12345678');
      expect(response.checkoutUrl, 'https://paymongo.page/l/test_url');
      expect(response.amount, 250.0);
      expect(response.currency, 'PHP');
      expect(response.paymentMethod, 'GCash');
    });

    test('PaymongoCheckoutResponse.fromJson handles payload correctly', () {
      final json = {
        'orderId': 'order_abc_123',
        'orderNumber': 'LMB-7788',
        'checkoutSessionId': 'cs_sample_987654321',
        'checkoutUrl': 'https://paymongo.page/l/sample_checkout',
        'amount': 520.0,
        'currency': 'PHP',
        'paymentMethod': 'GCash',
      };

      final response = PaymongoCheckoutResponse.fromJson(json);

      expect(response.orderId, 'order_abc_123');
      expect(response.orderNumber, 'LMB-7788');
      expect(response.checkoutSessionId, 'cs_sample_987654321');
      expect(response.checkoutUrl, 'https://paymongo.page/l/sample_checkout');
      expect(response.amount, 520.0);
      expect(response.currency, 'PHP');
      expect(response.paymentMethod, 'GCash');
    });

    test('PaymongoService targets standalone backend URL instead of Firebase Cloud Functions', () {
      final defaultService = PaymongoService();
      expect(defaultService.backendBaseUrl, isNot(contains('cloudfunctions.net')));
      expect(defaultService.backendBaseUrl, 'https://lambacapp.onrender.com/api');

      final customService = PaymongoService(
        backendBaseUrl: 'https://my-custom-paymongo-host.onrender.com/api/',
      );
      expect(customService.backendBaseUrl, 'https://my-custom-paymongo-host.onrender.com/api');
    });

    test('Flutter Web checkout navigation opens _blank and falls back to _self when popup is blocked', () async {
      final recordedCalls = <String>[];

      // Case A: _blank is blocked by browser popup blocker after async network call -> falls back to _self
      final webServicePopupBlocked = PaymongoService(
        isWebOverride: true,
        urlLauncher: (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) async {
          recordedCalls.add('${uri.toString()}|$webOnlyWindowName');
          if (webOnlyWindowName == '_blank') {
            return false; // Simulate browser blocking window.open(_blank)
          }
          return true; // _self succeeds
        },
      );

      final result = await webServicePopupBlocked.launchCheckoutUrl(
        'https://checkout.paymongo.com/cs_test_web_123',
      );
      expect(result.isSuccess, isTrue);
      expect(recordedCalls, [
        'https://checkout.paymongo.com/cs_test_web_123|_blank',
        'https://checkout.paymongo.com/cs_test_web_123|_self',
      ]);
    });

    test('Android/iOS checkout navigation uses externalApplication with platformDefault fallback', () async {
      final recordedModes = <LaunchMode>[];

      final mobileService = PaymongoService(
        isWebOverride: false,
        urlLauncher: (uri, {mode = LaunchMode.platformDefault, webOnlyWindowName}) async {
          recordedModes.add(mode);
          if (mode == LaunchMode.externalApplication) {
            return false; // Simulate external app launch returning false -> falls back to platformDefault
          }
          return true;
        },
      );

      final res = await mobileService.launchCheckoutUrl(
        'https://checkout.paymongo.com/cs_test_mobile_456',
      );
      expect(res.isSuccess, isTrue);
      expect(recordedModes, [
        LaunchMode.externalApplication,
        LaunchMode.platformDefault,
      ]);
    });

    test('launchCheckoutUrl rejects empty or invalid checkout URLs with understandable message', () async {
      final service = PaymongoService();

      final emptyRes = await service.launchCheckoutUrl('   ');
      expect(emptyRes.isFailure, isTrue);
      expect(emptyRes.failureOrNull!.userFriendlyMessage, contains('GCash checkout link is missing'));

      final invalidSchemeRes = await service.launchCheckoutUrl('javascript:alert(1)');
      expect(invalidSchemeRes.isFailure, isTrue);
      expect(invalidSchemeRes.failureOrNull!.userFriendlyMessage, contains('Invalid GCash checkout link'));
    });

    test('checkBackendHealth maps net::ERR_FAILED connectionError to understandable message and supports local dev fallback', () async {
      final requestedUrls = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedUrls.add(options.uri.toString());
            if (options.uri.toString().contains('lambacapp.onrender.com')) {
              return handler.reject(
                DioException.connectionError(
                  requestOptions: options,
                  reason: 'XMLHttpRequest error (net::ERR_FAILED)',
                ),
              );
            }
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'status': 'ok', 'service': 'lambac-paymongo-standalone-backend'},
              ),
            );
          },
        ),
      );

      final serviceWithFallback = PaymongoService(
        dio: dio,
        backendBaseUrl: 'https://lambacapp.onrender.com/api',
        allowLocalDevFallback: true,
      );

      final healthRes = await serviceWithFallback.checkBackendHealth();
      expect(healthRes.isSuccess, isTrue);
      expect(healthRes.dataOrNull?['status'], 'ok');
      expect(requestedUrls.length, 2);
      expect(requestedUrls.first, 'https://lambacapp.onrender.com/api/health');
      expect(requestedUrls.last, contains(':3000/api/health'));
    });
  });
}
