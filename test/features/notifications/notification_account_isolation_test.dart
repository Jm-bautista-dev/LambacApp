import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/notifications/data/datasources/mock_notification_remote_datasource.dart';
import 'package:lambac_app/features/notifications/data/models/app_notification_model.dart';
import 'package:lambac_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:lambac_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('Notifications Center, Privacy & Account Isolation Tests', () {
    late MockUserDatabase userDb;
    late MockNotificationRemoteDataSource remoteDataSource;
    late NotificationRepositoryImpl repository;

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

    setUp(() {
      userDb = MockUserDatabase();
      remoteDataSource = MockNotificationRemoteDataSource();
      remoteDataSource.resetForTesting();
      repository = NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('1. Customer 1 receives only Customer 1 notifications', () async {
      // Seed notifications for Customer 1 and Customer 2
      remoteDataSource.addNotificationForUser(
        'usr_cust_1',
        AppNotificationModel(
          id: 'notif_c1_1',
          title: 'Order Ready for Customer 1',
          body: 'Order #LMB-101 is ready for pickup',
          type: NotificationType.orderStatus,
          targetId: 'ord_101',
          deepLinkPath: '/orders/ord_101',
          createdAt: DateTime.now(),
        ),
      );

      remoteDataSource.addNotificationForUser(
        'usr_cust_2',
        AppNotificationModel(
          id: 'notif_c2_1',
          title: 'Secret Notification for Customer 2',
          body: 'Customer 2 private information',
          type: NotificationType.orderStatus,
          targetId: 'ord_202',
          deepLinkPath: '/orders/ord_202',
          createdAt: DateTime.now(),
        ),
      );

      // Customer 1 logs in
      userDb.setCurrentUser(customer1);

      final result = await repository.getNotifications();
      expect(result.isSuccess, isTrue);

      final list = result.dataOrNull!;
      expect(list.length, equals(1));
      expect(list.first.id, equals('notif_c1_1'));
      expect(list.any((n) => n.id == 'notif_c2_1'), isFalse);
    });

    test('2. Customer 2 receives only Customer 2 notifications (zero leakage)', () async {
      remoteDataSource.addNotificationForUser(
        'usr_cust_1',
        AppNotificationModel(
          id: 'notif_c1_1',
          title: 'Order Ready for Customer 1',
          body: 'Order #LMB-101 is ready for pickup',
          type: NotificationType.orderStatus,
          deepLinkPath: '/orders/ord_101',
          createdAt: DateTime.now(),
        ),
      );

      remoteDataSource.addNotificationForUser(
        'usr_cust_2',
        AppNotificationModel(
          id: 'notif_c2_1',
          title: 'Order Ready for Customer 2',
          body: 'Order #LMB-202 is ready for pickup',
          type: NotificationType.orderStatus,
          deepLinkPath: '/orders/ord_202',
          createdAt: DateTime.now(),
        ),
      );

      // Customer 2 logs in
      userDb.setCurrentUser(customer2);

      final result = await repository.getNotifications();
      expect(result.isSuccess, isTrue);

      final list = result.dataOrNull!;
      expect(list.length, equals(1));
      expect(list.first.id, equals('notif_c2_1'));
      expect(list.any((n) => n.id == 'notif_c1_1'), isFalse);
    });

    test('3. Unauthenticated request is rejected with 401 UnauthorizedFailure', () async {
      userDb.setCurrentUser(null);

      final result = await repository.getNotifications();
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('4. Mark as read updates specific notification', () async {
      remoteDataSource.addNotificationForUser(
        'usr_cust_1',
        AppNotificationModel(
          id: 'notif_c1_1',
          title: 'Unread Alert',
          body: 'Some details',
          type: NotificationType.orderStatus,
          deepLinkPath: '/orders/ord_101',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      userDb.setCurrentUser(customer1);

      await repository.markAsRead('notif_c1_1');

      final result = await repository.getNotifications();
      expect(result.dataOrNull!.first.isRead, isTrue);
    });

    test('5. Mark all as read updates all notifications for active recipient', () async {
      remoteDataSource.addNotificationForUser(
        'usr_cust_1',
        AppNotificationModel(
          id: 'notif_1',
          title: 'Alert 1',
          body: 'Details 1',
          type: NotificationType.orderStatus,
          deepLinkPath: '/orders/1',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
      remoteDataSource.addNotificationForUser(
        'usr_cust_1',
        AppNotificationModel(
          id: 'notif_2',
          title: 'Alert 2',
          body: 'Details 2',
          type: NotificationType.chatMessage,
          deepLinkPath: '/chat',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      userDb.setCurrentUser(customer1);

      await repository.markAllAsRead();

      final result = await repository.getNotifications();
      expect(result.dataOrNull!.every((n) => n.isRead), isTrue);
    });

    test('6. NotificationNotifier lifecycle resets cleanly for null user', () async {
      final notifier = NotificationNotifier(
        repository: repository,
        currentUser: null,
      );

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.notifications, isEmpty);
      expect(notifier.state.hasUnread, isFalse);
    });
  });
}
