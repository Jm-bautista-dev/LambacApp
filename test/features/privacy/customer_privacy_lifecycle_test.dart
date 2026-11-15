import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/security/audit_logger.dart';
import 'package:lambac_app/features/profile/domain/services/account_privacy_service.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';

void main() {
  late AccountPrivacyService privacyService;
  late AuditLogger auditLogger;

  setUp(() {
    privacyService = AccountPrivacyService();
    auditLogger = AuditLogger();
    auditLogger.clearForTest();
  });

  group('Production Privacy and Customer Data Lifecycle Suite', () {
    final customer = UserModel(
      id: 'usr_cust_privacy_101',
      email: 'maria.santos@gmail.com',
      fullName: 'Maria Santos',
      phoneNumber: '09171234567',
      role: UserRole.customer,
      status: UserStatus.active,
      loyaltyPoints: 350,
      termsAccepted: true,
      acceptedTermsVersion: '2026.1',
      termsAcceptedAt: DateTime(2026, 2, 1),
      createdAt: DateTime(2026, 2, 1, 9, 30),
    );

    final completedOrder = OrderModel(
      id: 'ord_2026_501',
      orderNumber: 'ORD-2026-501',
      customerId: customer.id,
      customerName: customer.fullName,
      customerPhone: customer.phoneNumber ?? '',
      pickupLocation: PickupLocationModel.flagship,
      pickupDate: 'Yesterday',
      pickupTimeSlot: '2:30 PM',
      items: const [
        OrderItemModel(
          id: 'item_01',
          productId: 'benguet-typica',
          productName: 'Benguet Arabica Typica',
          origin: 'Atok, Benguet',
          unitPrice: 420.0,
          quantity: 2,
          totalPrice: 840.0,
        ),
      ],
      subtotal: 840.0,
      totalAmount: 840.0,
      status: OrderStatus.completed,
      paymentMethod: 'GCash',
      paymentStatus: 'PAID',
      createdAt: DateTime(2026, 10, 20, 14, 0),
    );

    test('1. Account Data Export (Portability): Customer data can be extracted as structured JSON without leakage', () {
      final exportData = privacyService.generateExport(
        user: customer,
        orders: [completedOrder],
        reviews: [
          {
            'product_name': 'Benguet Arabica Typica',
            'rating': 5,
            'comment': 'Exceptional clean floral profile and sweetness.',
            'created_at': DateTime(2026, 10, 20, 15, 0).toIso8601String(),
          }
        ],
        notifications: [
          {
            'title': 'Order Ready',
            'body': 'Your pickup order is ready at the roastery counter',
          }
        ],
      );

      // Verify export payload structure
      final json = exportData.toJson();
      expect(json['format_version'], equals('1.0'));
      expect(json['profile']['full_name'], equals('Maria Santos'));
      expect(json['profile']['email'], equals('maria.santos@gmail.com'));
      expect(json['profile']['loyalty_points'], equals(350));

      final orders = json['orders'] as List;
      expect(orders.length, equals(1));
      expect(orders.first['order_number'], equals('ORD-2026-501'));
      expect(orders.first['total_amount'], equals(840.0));

      final reviews = json['reviews'] as List;
      expect(reviews.length, equals(1));
      expect(reviews.first['rating'], equals(5));

      // Verify that no sensitive internal cryptographic tokens or passwords exist in export
      expect(json.toString(), isNot(contains('password')));
      expect(json.toString(), isNot(contains('private_key')));
      expect(json.toString(), isNot(contains('auth_token')));
    });

    test('2. Statutory Financial Preservation: Completed orders are NOT deleted indiscriminately on account deletion', () {
      // In accordance with statutory tax and accounting standards (NIRC 7-year retention rule):
      // Business transactions must remain in the ledger, but PII must be anonymized.
      final anonymizedOrder = privacyService.anonymizeOrder(completedOrder);

      // 1. PII is scrubbed
      expect(anonymizedOrder.customerName, equals('Former Customer'));
      expect(anonymizedOrder.customerPhone, equals('0000000000'));

      // 2. Critical business and financial ledger fields remain intact
      expect(anonymizedOrder.id, equals(completedOrder.id));
      expect(anonymizedOrder.orderNumber, equals(completedOrder.orderNumber));
      expect(anonymizedOrder.items.length, equals(1));
      expect(anonymizedOrder.items.first.productName, equals('Benguet Arabica Typica'));
      expect(anonymizedOrder.subtotal, equals(840.0));
      expect(anonymizedOrder.totalAmount, equals(840.0));
      expect(anonymizedOrder.status, equals(OrderStatus.completed));
      expect(anonymizedOrder.paymentMethod, equals('GCash'));
      expect(anonymizedOrder.paymentStatus, equals('PAID'));
      expect(anonymizedOrder.createdAt, equals(completedOrder.createdAt));
    });

    test('3. Profile Anonymization: Customer profile strips email, phone, and avatar while disabling status', () {
      final anonymizedUser = privacyService.anonymizeProfile(customer);

      // PII removed / scrubbed
      expect(anonymizedUser.fullName, equals('Former Customer'));
      expect(anonymizedUser.email, contains('@anonymized.lambac'));
      expect(anonymizedUser.phoneNumber, isNull);
      expect(anonymizedUser.avatarUrl, isNull);
      expect(anonymizedUser.loyaltyPoints, equals(0));

      // Account status deactivated
      expect(anonymizedUser.status, equals(UserStatus.disabled));
      expect(anonymizedUser.role, equals(UserRole.customer));
      expect(anonymizedUser.isAdmin, isFalse);
    });

    test('4. Administrative Audit Non-Repudiation: Account anonymization writes compliance audit record', () {
      privacyService.logAccountAnonymization(
        actorUid: customer.id,
        actorEmail: customer.email,
        targetUserId: customer.id,
      );

      final logs = auditLogger.getLogs();
      expect(logs.length, equals(1));

      final log = logs.first;
      expect(log.action, equals(AuditActionType.accountDisabled));
      expect(log.actorUid, equals(customer.id));
      expect(log.details, contains('7-year retention policy'));
      expect(log.details, contains('PII anonymization completed'));
    });

    test('5. Policy Separation: Privacy Policy is decoupled from Terms & Conditions acceptance record', () {
      // Terms acceptance records contractual agreement version and timestamp
      expect(customer.termsAccepted, isTrue);
      expect(customer.acceptedTermsVersion, equals('2026.1'));
      expect(customer.termsAcceptedAt, isNotNull);

      // Anonymizing profile clears terms acceptance agreement for deactivated entity
      final anonymized = privacyService.anonymizeProfile(customer);
      expect(anonymized.termsAccepted, isFalse);
    });
  });
}
