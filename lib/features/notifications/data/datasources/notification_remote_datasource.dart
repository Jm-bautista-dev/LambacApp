import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../models/app_notification_model.dart';
import '../models/notification_preferences_model.dart';

/// Contract for Remote Push Notifications API
abstract class NotificationRemoteDataSource {
  Future<Result<void, AppFailure>> registerDeviceToken(String fcmToken);

  Future<Result<List<AppNotificationModel>, AppFailure>> getNotifications({
    int limit = 20,
    dynamic lastDocument,
  });

  Future<Result<void, AppFailure>> markAsRead(String notificationId);

  Future<Result<void, AppFailure>> markAllAsRead();

  Future<Result<NotificationPreferencesModel, AppFailure>> getPreferences();

  Future<Result<NotificationPreferencesModel, AppFailure>> updatePreferences(NotificationPreferencesModel prefs);

  Stream<List<AppNotificationModel>> watchNotifications();

  void clearSession();
}

/// Concrete Dio-based implementation
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<void, AppFailure>> registerDeviceToken(String fcmToken) {
    return _apiClient.post(
      '/notifications/device-token',
      data: {'device_token': fcmToken},
      requiresAuth: true,
      decoder: (_) {},
    );
  }

  @override
  Future<Result<List<AppNotificationModel>, AppFailure>> getNotifications({
    int limit = 20,
    dynamic lastDocument,
  }) {
    return _apiClient.get(
      '/notifications',
      queryParameters: {'limit': limit},
      requiresAuth: true,
      decoder: (data) {
        final list = data is List ? data : (data['notifications'] ?? data['data']) as List;
        return list.map((item) => AppNotificationModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<Result<void, AppFailure>> markAsRead(String notificationId) {
    return _apiClient.patch(
      '/notifications/$notificationId/read',
      requiresAuth: true,
      decoder: (_) {},
    );
  }

  @override
  Future<Result<void, AppFailure>> markAllAsRead() {
    return _apiClient.post(
      '/notifications/mark-all-read',
      requiresAuth: true,
      decoder: (_) {},
    );
  }

  @override
  Future<Result<NotificationPreferencesModel, AppFailure>> getPreferences() {
    return _apiClient.get(
      '/notifications/preferences',
      requiresAuth: true,
      decoder: (data) => NotificationPreferencesModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<NotificationPreferencesModel, AppFailure>> updatePreferences(NotificationPreferencesModel prefs) {
    return _apiClient.put(
      '/notifications/preferences',
      data: prefs.toJson(),
      requiresAuth: true,
      decoder: (data) => NotificationPreferencesModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Stream<List<AppNotificationModel>> watchNotifications() => const Stream.empty();

  @override
  void clearSession() {}
}
