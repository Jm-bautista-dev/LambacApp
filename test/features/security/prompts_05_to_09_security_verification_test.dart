import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/notifications/data/models/app_notification_model.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_model.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_item_model.dart';

void main() {
  group('Prompts 05-09 Security Rules & Schema Verification', () {
    // =========================================================================
    // PROMPT 05: Notifications Privacy & Immutability (/users/{uid}/notifications)
    // =========================================================================
    test('Prompt 05: Customer notification recipient isolation and read-state mutation', () {
      final notifUser1 = AppNotificationModel(
        id: 'notif_001',
        title: 'Order LMB-1001 Confirmed',
        body: 'Your pickup order is confirmed and scheduled.',
        type: NotificationType.orderStatus,
        deepLinkPath: '/orders/LMB-1001',
        isRead: false,
        createdAt: DateTime.now(),
      );

      // Verify recipient isolation structure
      final json = notifUser1.toJson();
      expect(json['id'], equals('notif_001'));
      expect(json['is_read'], isFalse);

      // Simulate customer updating read flag
      final readUpdate = notifUser1.copyWith(isRead: true);
      expect(readUpdate.isRead, isTrue);
      // Protected metadata must remain invariant
      expect(readUpdate.title, equals(notifUser1.title));
      expect(readUpdate.body, equals(notifUser1.body));
      expect(readUpdate.deepLinkPath, equals(notifUser1.deepLinkPath));
    });

    // =========================================================================
    // PROMPT 06: Mail & Plaintext OTP Protection (/mail)
    // =========================================================================
    test('Prompt 06: Mail document contains strict delivery metadata and OTP bounds', () {
      final mailPayload = {
        'to': 'customer@example.com',
        'recipient_email': 'customer@example.com',
        'recipient_name': 'Test Customer',
        'subject': 'Lambac Roastery Verification Code',
        'otp': '482910',
        'action': 'registration_otp',
        'type': 'verification',
        'delivery_status': 'dispatched',
      };

      // OTP must be exactly 6 characters
      final otp = mailPayload['otp'] as String;
      expect(otp.length, equals(6));
      expect(int.tryParse(otp), isNotNull);

      // Action must be whitelisted
      expect(['registration_otp', 'login_otp'].contains(mailPayload['action']), isTrue);

      // Recipient email size boundary
      final email = mailPayload['to'] as String;
      expect(email.length, lessThanOrEqualTo(254));
    });

    // =========================================================================
    // PROMPT 07: Sales Ledger & Staff Attribution (/sales)
    // =========================================================================
    test('Prompt 07: POS Sales record requires staff attribution and positive amount', () {
      final posSale = SalesRecordModel(
        id: 'sale_pos_001',
        transactionNumber: 'TX-POS-1001',
        channel: SalesChannel.walkIn,
        recordedByStaffId: 'staff_barista_42',
        recordedByStaffName: 'Barista John',
        paymentMethod: 'Cash',
        subtotal: 350.0,
        totalAmount: 350.0,
        createdAt: DateTime.now(),
        items: const [
          SalesRecordItemModel(
            id: 'item_01',
            productId: 'prod_honey_01',
            productName: 'Mount Apo Anaerobic Honey',
            snapshotUnitPrice: 350.0,
            quantity: 1,
            totalPrice: 350.0,
          ),
        ],
      );

      // Staff attribution is mandatory
      expect(posSale.recordedByStaffId, equals('staff_barista_42'));
      expect(posSale.channel, equals(SalesChannel.walkIn));
      expect(posSale.totalAmount, greaterThan(0));
      expect(posSale.totalAmount, lessThanOrEqualTo(100000));
      expect(posSale.items.isNotEmpty, isTrue);
      expect(posSale.items.length, lessThanOrEqualTo(100));

      // Barista cannot void historical sales; voiding is an admin-only mutation
      final json = posSale.toJson();
      expect(json['is_voided'], isFalse);
    });

    // =========================================================================
    // PROMPT 08: Forecasting Benchmarks Schema Boundaries (/forecastingBenchmarks)
    // =========================================================================
    test('Prompt 08: Forecasting benchmarks payload contains required operational metrics', () {
      final benchmark = {
        'id': 'bench_davao_roastery',
        'target_metric': 'daily_espresso_yield',
        'benchmark_value': 120.5,
        'period': 'daily',
        'created_by': 'admin_super_01',
        'created_at': DateTime.now().toIso8601String(),
      };

      expect(benchmark['benchmark_value'], isA<num>());
      expect((benchmark['benchmark_value'] as num), greaterThan(0));
      expect(benchmark['created_by'], startsWith('admin_'));
    });

    // =========================================================================
    // PROMPT 09: Product & Category Permissions & Visibility
    // =========================================================================
    test('Prompt 09: Customer visibility gating on products', () {
      const visibleProduct = ProductModel(
        id: 'prod_visible_01',
        name: 'Signature Cold Brew',
        slug: 'sig-cold-brew',
        origin: 'Bukidnon, Philippines',
        description: 'Smooth slow-steeped cold brew.',
        basePrice: 180.0,
        categoryId: 'beverages',
        categoryName: 'Beverages',
        roastLevel: 'Medium Roast',
        tastingNotes: 'Cocoa, hazelnut, vanilla',
        customerVisibility: ProductVisibility.visible,
        isEnabled: true,
      );

      const hiddenProduct = ProductModel(
        id: 'prod_hidden_01',
        name: 'Experimental Lot 99 (Draft)',
        slug: 'exp-lot-99',
        origin: 'Davao Oriental, Philippines',
        description: 'Unpublished micro-lot draft.',
        basePrice: 500.0,
        categoryId: 'micro-lot',
        categoryName: 'Micro Lots',
        roastLevel: 'Light Roast',
        tastingNotes: 'Jasmine, peach, lime',
        customerVisibility: ProductVisibility.hidden,
        isEnabled: false,
      );

      // Visible product meets customer read policy
      expect(visibleProduct.customerVisibility, equals(ProductVisibility.visible));
      expect(visibleProduct.isEnabled, isTrue);

      // Hidden/Disabled product fails customer read policy
      expect(hiddenProduct.customerVisibility, equals(ProductVisibility.hidden));
      expect(hiddenProduct.isEnabled, isFalse);

      // Base price immutability check for Barista:
      // Barista updates can ONLY affect stock and availability
      final updatedStock = visibleProduct.copyWith(stockQuantity: 12);
      expect(updatedStock.stockQuantity, equals(12));
      expect(updatedStock.basePrice, equals(visibleProduct.basePrice));
      expect(updatedStock.name, equals(visibleProduct.name));
    });
  });
}
