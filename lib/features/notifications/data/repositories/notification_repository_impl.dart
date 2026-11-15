import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/app_notification_model.dart';
import '../models/notification_preferences_model.dart';

/// Concrete NotificationRepository implementation
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl({required NotificationRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<void, AppFailure>> registerDeviceToken(String fcmToken) {
    return _remoteDataSource.registerDeviceToken(fcmToken);
  }

  @override
  Future<Result<List<AppNotificationModel>, AppFailure>> getNotifications() {
    return _remoteDataSource.getNotifications();
  }

  @override
  Future<Result<void, AppFailure>> markAsRead(String notificationId) {
    return _remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<Result<void, AppFailure>> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }

  @override
  Future<Result<NotificationPreferencesModel, AppFailure>> getPreferences() {
    return _remoteDataSource.getPreferences();
  }

  @override
  Future<Result<NotificationPreferencesModel, AppFailure>> updatePreferences(NotificationPreferencesModel prefs) {
    return _remoteDataSource.updatePreferences(prefs);
  }

  @override
  Stream<List<AppNotificationModel>> watchNotifications() {
    return _remoteDataSource.watchNotifications();
  }

  @override
  void clearSession() {
    _remoteDataSource.clearSession();
  }
}
