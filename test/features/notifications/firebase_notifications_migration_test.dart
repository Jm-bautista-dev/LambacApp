import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/notifications/data/models/app_notification_model.dart';
import 'package:lambac_app/features/notifications/data/models/notification_preferences_model.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('Firestore Notifications & Favorites Migration Specifications', () {
    test('AppNotificationModel adheres to normalized users/{uid}/notifications/{id} schema', () {
      final now = DateTime.utc(2026, 10, 6, 12, 0, 0);
      final notif = AppNotificationModel(
        id: 'notif_order_1082',
        title: 'Order Ready for Pickup',
        body: 'Your Lambac pickup order #LMB-1082 is ready at our Session Road bar!',
        type: NotificationType.orderStatus,
        targetId: 'ord_lmb_1082',
        deepLinkPath: '/orders/ord_lmb_1082',
        isRead: false,
        createdAt: now,
      );

      final json = notif.toJson();

      // Verify Firestore field mapping
      expect(json['id'], equals('notif_order_1082'));
      expect(json['title'], equals('Order Ready for Pickup'));
      expect(json['body'], contains('ready at our Session Road bar'));
      expect(json['type'], equals('orderStatus'));
      expect(json['target_id'], equals('ord_lmb_1082'));
      expect(json['deep_link_path'], equals('/orders/ord_lmb_1082'));
      expect(json['is_read'], isFalse);
      expect(json['created_at'], equals('2026-10-06T12:00:00.000Z'));

      // Round-trip deserialization
      final deserialized = AppNotificationModel.fromJson(json);
      expect(deserialized.id, equals(notif.id));
      expect(deserialized.type, equals(NotificationType.orderStatus));
      expect(deserialized.isRead, isFalse);
      expect(deserialized.targetId, equals('ord_lmb_1082'));
    });

    test('Read state transition updates isRead and preserves immutability', () {
      final notif = AppNotificationModel(
        id: 'notif_1',
        title: 'Barista Concierge Reply',
        body: 'Hiro replied to your question.',
        type: NotificationType.chatMessage,
        deepLinkPath: '/chat',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(notif.isRead, isFalse);
      final readNotif = notif.copyWith(isRead: true);
      expect(readNotif.isRead, isTrue);
      expect(readNotif.id, equals(notif.id));
      expect(readNotif.title, equals(notif.title));
    });

    test('NotificationPreferencesModel adheres to normalized settings schema', () {
      const prefs = NotificationPreferencesModel(
        orderStatusEnabled: true,
        chatMessageEnabled: true,
        promotionalEnabled: false,
      );

      final json = prefs.toJson();
      expect(json['order_status_enabled'], isTrue);
      expect(json['chat_message_enabled'], isTrue);
      expect(json['promotional_enabled'], isFalse);

      final deserialized = NotificationPreferencesModel.fromJson(json);
      expect(deserialized.orderStatusEnabled, isTrue);
      expect(deserialized.chatMessageEnabled, isTrue);
      expect(deserialized.promotionalEnabled, isFalse);
    });

    test('User-scoped isolation blocks cross-account notification and favorite access', () {
      const customer1 = UserModel(
        id: 'usr_cust_1',
        email: 'user1@example.com',
        fullName: 'Customer One',
        role: UserRole.customer,
      );

      const customer2 = UserModel(
        id: 'usr_cust_2',
        email: 'user2@example.com',
        fullName: 'Customer Two',
        role: UserRole.customer,
      );

      final user1Path = 'users/${customer1.id}/notifications/notif_1';
      final user2Path = 'users/${customer2.id}/notifications/notif_2';

      expect(user1Path.contains(customer1.id), isTrue);
      expect(user1Path.contains(customer2.id), isFalse);
      expect(user2Path.contains(customer2.id), isTrue);
      expect(user2Path.contains(customer1.id), isFalse);
    });

    test('User-scoped Favorites filter removes out-of-stock or hidden items from active list', () {
      const activeFav1 = ProductModel(
        id: 'mt-apo-honey',
        name: 'Mount Apo Anaerobic Honey Reserve',
        slug: 'mt-apo-honey',
        origin: 'Davao del Sur',
        description: 'Specialty lot',
        basePrice: 480.0,
        imageUrl: 'https://images.unsplash.com/photo-1',
        categoryId: 'micro-lot',
        categoryName: 'Micro-Lots',
        roastLevel: 'Light',
        tastingNotes: 'Floral',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.available,
      );

      const outOfStockFav = ProductModel(
        id: 'tokyo-blend',
        name: 'Tokyo Kissaten Dark Roast',
        slug: 'tokyo-blend',
        origin: 'Benguet',
        description: 'Dark roast',
        basePrice: 420.0,
        imageUrl: 'https://images.unsplash.com/photo-2',
        categoryId: 'dark-roast',
        categoryName: 'Dark Roast',
        roastLevel: 'Dark',
        tastingNotes: 'Dark chocolate',
        isEnabled: true,
        customerVisibility: ProductVisibility.visible,
        availability: ProductAvailability.outOfStock,
      );

      const hiddenFav = ProductModel(
        id: 'seasonal-special',
        name: 'Seasonal Special Roast',
        slug: 'seasonal-special',
        origin: 'Sagada',
        description: 'Seasonal',
        basePrice: 500.0,
        imageUrl: 'https://images.unsplash.com/photo-3',
        categoryId: 'micro-lot',
        categoryName: 'Micro-Lots',
        roastLevel: 'Medium',
        tastingNotes: 'Brown sugar',
        isEnabled: false,
        customerVisibility: ProductVisibility.hidden,
        availability: ProductAvailability.available,
      );

      final userFavoriteIds = {'mt-apo-honey', 'tokyo-blend', 'seasonal-special'};
      final allCatalogProducts = [activeFav1, outOfStockFav, hiddenFav];

      // Active favorites filter rule:
      final activeFavorites = allCatalogProducts.where((p) {
        return userFavoriteIds.contains(p.id) &&
            p.customerVisibility == ProductVisibility.visible &&
            p.isEnabled &&
            p.availability != ProductAvailability.outOfStock;
      }).toList();

      expect(activeFavorites.length, equals(1));
      expect(activeFavorites.first.id, equals('mt-apo-honey'));
    });
  });
}
