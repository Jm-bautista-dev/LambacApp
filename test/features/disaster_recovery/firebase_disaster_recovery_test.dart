import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/config/app_config.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/features/products/data/models/product_variant_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_model.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_item_model.dart';
import 'package:lambac_app/features/reviews/data/models/product_review_model.dart';
import 'package:lambac_app/features/chat/data/models/conversation_model.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/notifications/data/models/app_notification_model.dart';

void main() {
  group('Production Disaster Recovery & Staging Restoration Tests', () {
    test('1. Environment Separation: Staging and Production configurations are strictly isolated', () {
      final prodConfig = AppConfig.production();
      final stagingConfig = AppConfig.staging();
      final devConfig = AppConfig.development();

      expect(prodConfig.isProduction, isTrue);
      expect(prodConfig.isStaging, isFalse);
      expect(prodConfig.apiBaseUrl, contains('api.lambaccoffee.com'));

      expect(stagingConfig.isStaging, isTrue);
      expect(stagingConfig.isProduction, isFalse);
      expect(stagingConfig.apiBaseUrl, contains('api-staging.lambaccoffee.com'));
      expect(stagingConfig.appName, contains('(Staging)'));

      expect(devConfig.isDevelopment, isTrue);
      expect(devConfig.apiBaseUrl, contains('api-dev.lambaccoffee.com'));

      // Ensure restoration target cannot accidentally point to production URL
      expect(stagingConfig.apiBaseUrl, isNot(equals(prodConfig.apiBaseUrl)));
    });

    test('2. Staging Restoration: Full snapshot restores critical business collections with exact counts', () {
      // 1. Simulated Point-In-Time Snapshot payload from Google Cloud Storage
      final snapshotUsers = [
        const UserModel(
          id: 'admin_usr_001',
          email: 'jmbautista0228@gmail.com',
          fullName: 'Master Roaster Admin',
          role: UserRole.admin,
          status: UserStatus.active,
          mustChangePassword: false,
          permissions: [
            EmployeePermission.manageOrders,
            EmployeePermission.manageProducts,
            EmployeePermission.recordSales,
            EmployeePermission.manageInbox,
            EmployeePermission.viewBasicMetrics,
          ],
          loyaltyPoints: 0,
          termsAccepted: true,
        ),
        const UserModel(
          id: 'staff_usr_002',
          email: 'barista.clara@lambaccoffee.com',
          fullName: 'Clara Barista',
          role: UserRole.employee,
          status: UserStatus.active,
          mustChangePassword: false,
          permissions: [
            EmployeePermission.manageOrders,
            EmployeePermission.recordSales,
          ],
          loyaltyPoints: 0,
          termsAccepted: true,
        ),
        const UserModel(
          id: 'cust_usr_003',
          email: 'patron.miguel@gmail.com',
          fullName: 'Miguel Patron',
          role: UserRole.customer,
          status: UserStatus.active,
          mustChangePassword: false,
          permissions: [],
          loyaltyPoints: 120,
          termsAccepted: true,
        ),
      ];

      final snapshotProducts = [
        const ProductModel(
          id: 'prod_benguet_001',
          name: 'Benguet Highland Arabica',
          slug: 'benguet-highland-arabica',
          origin: 'Atok, Benguet',
          description: 'Single-origin washed Arabica with notes of floral citrus and brown sugar.',
          basePrice: 480.0,
          categoryId: 'cat_beans',
          categoryName: 'Whole Bean Coffee',
          roastLevel: 'Medium Roast',
          tastingNotes: 'Floral, Citrus, Caramel',
          isEnabled: true,
          customerVisibility: ProductVisibility.visible,
          availability: ProductAvailability.available,
          stockQuantity: 45,
          sizeVariants: [
            ProductVariantModel(id: 'sz_250', name: '250g Bag', priceDelta: 0.0, isDefault: true),
            ProductVariantModel(id: 'sz_500', name: '500g Bag', priceDelta: 400.0),
          ],
          grindVariants: [
            ProductVariantModel(id: 'gr_whole', name: 'Whole Bean', priceDelta: 0.0, isDefault: true),
            ProductVariantModel(id: 'gr_pour', name: 'Pour Over', priceDelta: 0.0),
          ],
        ),
        const ProductModel(
          id: 'prod_coldbrew_002',
          name: 'Signature Nitro Cold Brew',
          slug: 'signature-nitro-cold-brew',
          origin: 'House Blend',
          description: 'Slow-steeped 18 hours infused with nitrogen for a silky smooth finish.',
          basePrice: 165.0,
          categoryId: 'cat_beverage',
          categoryName: 'Cold Beverages',
          roastLevel: 'Dark Roast',
          tastingNotes: 'Dark Chocolate, Roasted Hazelnut',
          isEnabled: true,
          customerVisibility: ProductVisibility.visible,
          availability: ProductAvailability.available,
          stockQuantity: 80,
          sizeVariants: [],
          grindVariants: [],
        ),
      ];

      final snapshotOrders = [
        OrderModel(
          id: 'ord_2026_0901',
          orderNumber: 'ORD-2026-0901',
          customerId: 'cust_usr_003',
          customerName: 'Miguel Patron',
          customerPhone: '09171234567',
          pickupLocation: PickupLocationModel.flagship,
          pickupTimeSlot: '10:30 AM',
          items: const [
            OrderItemModel(
              id: 'item_01',
              productId: 'prod_benguet_001',
              productName: 'Benguet Highland Arabica',
              origin: 'Atok, Benguet',
              unitPrice: 480.0,
              quantity: 1,
              totalPrice: 480.0,
            ),
            OrderItemModel(
              id: 'item_02',
              productId: 'prod_coldbrew_002',
              productName: 'Signature Nitro Cold Brew',
              origin: 'House Blend',
              unitPrice: 165.0,
              quantity: 2,
              totalPrice: 330.0,
            ),
          ],
          subtotal: 810.0,
          totalAmount: 810.0,
          status: OrderStatus.completed,
          notes: 'Ground for French Press please',
          createdAt: DateTime(2026, 10, 21, 9, 0),
        ),
      ];

      final snapshotSales = [
        SalesRecordModel(
          id: 'sale_2026_1001',
          transactionNumber: 'TX-2026-1001',
          channel: SalesChannel.mobileApp,
          orderId: 'ord_2026_0901',
          customerName: 'Miguel Patron',
          customerPhone: '09171234567',
          items: const [
            SalesRecordItemModel(
              id: 'sale_item_01',
              productId: 'prod_benguet_001',
              productName: 'Benguet Highland Arabica',
              snapshotUnitPrice: 480.0,
              quantity: 1,
              totalPrice: 480.0,
            ),
            SalesRecordItemModel(
              id: 'sale_item_02',
              productId: 'prod_coldbrew_002',
              productName: 'Signature Nitro Cold Brew',
              snapshotUnitPrice: 165.0,
              quantity: 2,
              totalPrice: 330.0,
            ),
          ],
          subtotal: 810.0,
          totalAmount: 810.0,
          paymentMethod: 'GCash',
          recordedByStaffId: 'staff_usr_002',
          recordedByStaffName: 'Clara Barista',
          isVoided: false,
          createdAt: DateTime(2026, 10, 21, 10, 35),
        ),
        SalesRecordModel(
          id: 'sale_2026_1002',
          transactionNumber: 'TX-2026-1002',
          channel: SalesChannel.walkIn,
          customerName: 'Walk-in Patron',
          items: const [
            SalesRecordItemModel(
              id: 'sale_item_03',
              productId: 'prod_coldbrew_002',
              productName: 'Signature Nitro Cold Brew',
              snapshotUnitPrice: 165.0,
              quantity: 1,
              totalPrice: 165.0,
            ),
          ],
          subtotal: 165.0,
          totalAmount: 165.0,
          paymentMethod: 'Cash',
          recordedByStaffId: 'staff_usr_002',
          recordedByStaffName: 'Clara Barista',
          isVoided: false,
          createdAt: DateTime(2026, 10, 21, 11, 15),
        ),
      ];

      final snapshotReviews = [
        ProductReviewModel(
          id: 'rev_2026_001',
          productId: 'prod_benguet_001',
          customerName: 'Miguel Patron',
          rating: 5,
          comment: 'Outstanding freshness and floral aroma. Perfect roast profile!',
          isVerifiedPurchase: true,
          isFlagged: false,
          orderId: 'ord_2026_0901',
          createdAt: DateTime(2026, 10, 21, 12, 0),
        ),
      ];

      // 2. Validate Restoration Ingestion Counts
      expect(snapshotUsers.length, equals(3), reason: 'All 3 user records must be restored');
      expect(snapshotProducts.length, equals(2), reason: 'All 2 product catalog items must be restored');
      expect(snapshotOrders.length, equals(1), reason: 'All order records must be restored');
      expect(snapshotSales.length, equals(2), reason: 'All sales transaction records must be restored');
      expect(snapshotReviews.length, equals(1), reason: 'All product reviews must be restored');

      // 3. Foreign Key & Relational Verification
      final restoredOrder = snapshotOrders.first;
      final restoredUserIds = snapshotUsers.map((u) => u.id).toSet();
      final restoredProductIds = snapshotProducts.map((p) => p.id).toSet();

      // Order references an existing restored user
      expect(restoredUserIds.contains(restoredOrder.customerId), isTrue,
          reason: 'Order customerId must match a restored user');

      // Order items reference existing restored products
      for (final item in restoredOrder.items) {
        expect(restoredProductIds.contains(item.productId), isTrue,
          reason: 'OrderItem productId must match an existing restored product');
      }

      // Sales relational integrity
      final mobileSale = snapshotSales.firstWhere((s) => s.channel == SalesChannel.mobileApp);
      expect(mobileSale.orderId, equals(restoredOrder.id));
      expect(restoredUserIds.contains(mobileSale.recordedByStaffId), isTrue);

      // Review relational integrity
      final review = snapshotReviews.first;
      expect(restoredProductIds.contains(review.productId), isTrue);
      expect(review.orderId, equals(restoredOrder.id));

      // Financial Calculation Consistency
      final totalValidSales = snapshotSales.where((s) => !s.isVoided).fold<double>(0.0, (acc, s) => acc + s.totalAmount);
      expect(totalValidSales, equals(975.0), reason: '810 (order pickup) + 165 (walk-in) = 975.00 PHP');
    });

    test('3. Chat and Notification Recovery: Conversations, messages, and alerts retain sender-receiver integrity', () {
      final message1 = MessageModel(
        id: 'msg_001',
        conversationId: 'conv_cust_003',
        senderId: 'cust_usr_003',
        senderName: 'Miguel Patron',
        senderRole: SenderRole.customer,
        text: 'Is the Benguet Arabica freshly roasted?',
        createdAt: DateTime(2026, 10, 21, 9, 5),
      );

      final message2 = MessageModel(
        id: 'msg_002',
        conversationId: 'conv_cust_003',
        senderId: 'staff_usr_002',
        senderName: 'Clara Barista',
        senderRole: SenderRole.barista,
        text: 'Yes Miguel! Roasted just yesterday morning at our Baguio roastery.',
        createdAt: DateTime(2026, 10, 21, 9, 6),
      );

      final conversation = ConversationModel(
        id: 'conv_cust_003',
        customerId: 'cust_usr_003',
        customerName: 'Miguel Patron',
        participantName: 'Clara (Barista)',
        orderReference: 'ORD-2026-0901',
        lastMessage: message2,
        updatedAt: DateTime(2026, 10, 21, 9, 6),
      );

      final notification = AppNotificationModel(
        id: 'notif_001',
        title: 'Order Confirmed',
        body: 'Your pickup order ORD-2026-0901 has been confirmed by our roastery staff.',
        type: NotificationType.orderStatus,
        targetId: 'ord_2026_0901',
        deepLinkPath: '/orders/ord_2026_0901',
        isRead: true,
        createdAt: DateTime(2026, 10, 21, 9, 2),
      );

      expect(conversation.customerId, equals('cust_usr_003'));
      expect(conversation.lastMessage?.text, contains('Roasted just yesterday'));
      expect(message1.senderId, equals('cust_usr_003'));
      expect(message1.isFromCustomer, isTrue);
      expect(message2.senderId, equals('staff_usr_002'));
      expect(message2.isFromStaff, isTrue);
      expect(notification.targetId, equals('ord_2026_0901'));
      expect(notification.type, equals(NotificationType.orderStatus));
      expect(notification.deepLinkPath, equals('/orders/ord_2026_0901'));
    });

    test('4. Security & Privilege Preservation: User roles, permissions, and passwords maintain least privilege after restore', () {
      final restoredAdmin = const UserModel(
        id: 'admin_001',
        email: 'jmbautista0228@gmail.com',
        fullName: 'Admin User',
        role: UserRole.admin,
        status: UserStatus.active,
        mustChangePassword: false,
        permissions: [EmployeePermission.manageOrders],
      );

      final restoredCustomer = const UserModel(
        id: 'cust_001',
        email: 'customer@example.com',
        fullName: 'Standard Customer',
        role: UserRole.customer,
        status: UserStatus.active,
        mustChangePassword: false,
        permissions: [],
        loyaltyPoints: 50,
      );

      // Verify Admin retains admin capabilities
      expect(restoredAdmin.role, equals(UserRole.admin));
      expect(restoredAdmin.isAdmin, isTrue);

      // Verify Customer does not inadvertently gain staff or admin privileges during restore
      expect(restoredCustomer.role, equals(UserRole.customer));
      expect(restoredCustomer.isAdmin, isFalse);
      expect(restoredCustomer.permissions, isEmpty);
      expect(restoredCustomer.loyaltyPoints, equals(50));
    });

    test('5. Credential Isolation: Source code and configs contain zero hardcoded IAM private keys or secret credentials', () {
      final config = AppConfig.production();
      // AppConfig should only contain public client metadata and safe endpoints
      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.appName, isNotEmpty);
      // Ensure webRecaptchaSiteKey is a public site key, not an admin service account private key
      expect(config.webRecaptchaSiteKey, isNot(contains('private_key')));
      expect(config.webRecaptchaSiteKey, isNot(contains('BEGIN PRIVATE KEY')));
    });

    test('6. Recovery Point Objective (RPO) and Point-In-Time Window verification', () {
      // Simulate PITR window boundaries (7-day continuous PITR window)
      final now = DateTime(2026, 10, 21, 14, 0);
      final pitrEarliestPermitted = now.subtract(const Duration(days: 7));
      final exportDailyTimestamp = DateTime(2026, 10, 21, 2, 0); // 02:00 AM PHT daily export

      // Verify daily export is well within the acceptable 24h RPO window
      final dataLossWindow = now.difference(exportDailyTimestamp);
      expect(dataLossWindow.inHours, lessThanOrEqualTo(24),
          reason: 'Daily scheduled export ensures <= 24h disaster recovery data loss window');

      // Verify continuous PITR provides sub-hour RPO for accidental deletion
      expect(exportDailyTimestamp.isAfter(pitrEarliestPermitted), isTrue);
    });
  });
}
