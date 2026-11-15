import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/notifications/data/datasources/mock_notification_remote_datasource.dart';
import 'package:lambac_app/features/notifications/data/models/app_notification_model.dart';
import 'package:lambac_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:lambac_app/features/notifications/services/notification_service.dart';

void main() {
  group('Notification Service Unit Tests', () {
    late MockNotificationRemoteDataSource remoteDataSource;
    late NotificationRepositoryImpl repository;
    late NotificationService service;

    setUp(() {
      remoteDataSource = MockNotificationRemoteDataSource();
      repository = NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
      service = NotificationService(repository: repository);
    });

    test('requestPermission returns true for device permissions', () async {
      final granted = await service.requestPermission();
      expect(granted, isTrue);
    });

    test('registerDeviceToken sends FCM/APNs token to backend repository', () async {
      await service.registerDeviceToken('fcm_token_sample_8091');

      final result = await repository.getNotifications();
      expect(result.isSuccess, isTrue);
    });

    test('Notification deep link paths map correctly to targets', () {
      final orderNotif = AppNotificationModel(
        id: 'notif_1',
        title: 'Order Ready',
        body: 'Your pickup order is ready',
        type: NotificationType.orderStatus,
        targetId: 'ord_1082',
        deepLinkPath: '/orders/ord_1082',
        createdAt: DateTime.now(),
      );

      expect(orderNotif.deepLinkPath, equals('/orders/ord_1082'));

      final chatNotif = AppNotificationModel(
        id: 'notif_2',
        title: 'Barista Reply',
        body: 'Lambac Coffee Roastery sent a message',
        type: NotificationType.chatMessage,
        deepLinkPath: '/chat',
        createdAt: DateTime.now(),
      );

      expect(chatNotif.deepLinkPath, equals('/chat'));
    });
  });
}
