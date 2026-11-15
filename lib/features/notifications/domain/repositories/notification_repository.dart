import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/models/notification_preferences_model.dart';

/// Clean Domain Repository Contract for Notifications
abstract class NotificationRepository {
  Future<Result<void, AppFailure>> registerDeviceToken(String fcmToken);

  Future<Result<List<AppNotificationModel>, AppFailure>> getNotifications();

  Future<Result<void, AppFailure>> markAsRead(String notificationId);

  Future<Result<void, AppFailure>> markAllAsRead();

  Future<Result<NotificationPreferencesModel, AppFailure>> getPreferences();

  Future<Result<NotificationPreferencesModel, AppFailure>> updatePreferences(NotificationPreferencesModel prefs);

  Stream<List<AppNotificationModel>> watchNotifications();

  void clearSession();
}
