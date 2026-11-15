import 'dart:async';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/data/datasources/mock_user_database.dart';
import '../models/app_notification_model.dart';
import '../models/notification_preferences_model.dart';
import 'notification_remote_datasource.dart';

/// Secure, Multi-Tenant Mock Data Source for Push & Activity Notifications
/// Enforces Server-Side Ownership, User Isolation, and RBAC
class MockNotificationRemoteDataSource implements NotificationRemoteDataSource {
  static final MockNotificationRemoteDataSource _instance = MockNotificationRemoteDataSource._internal();
  factory MockNotificationRemoteDataSource() => _instance;

  final Map<String, List<AppNotificationModel>> _userNotifications = {};
  final Map<String, NotificationPreferencesModel> _userPreferences = {};
  final StreamController<List<AppNotificationModel>> _notificationsStreamController =
      StreamController<List<AppNotificationModel>>.broadcast();

  MockNotificationRemoteDataSource._internal() {
    _seedDefaultNotifications();
  }

  @override
  Stream<List<AppNotificationModel>> watchNotifications() => _notificationsStreamController.stream;

  @override
  void clearSession() {
    if (!_notificationsStreamController.isClosed) {
      _notificationsStreamController.add(const []);
    }
  }

  void _seedDefaultNotifications() {
    const demoCustomerId = 'usr_customer_demo';
    final demoNotifs = [
      AppNotificationModel(
        id: 'notif_101',
        title: 'Order Ready for Pickup',
        body: 'Your Lambac pickup order #LMB-1082 is ready for pickup at our Session Road bar!',
        type: NotificationType.orderStatus,
        targetId: 'ord_lmb_1082',
        deepLinkPath: '/orders/ord_lmb_1082',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AppNotificationModel(
        id: 'notif_102',
        title: 'Barista Concierge Reply',
        body: 'Hiro (Head Roaster) replied: "For Mount Apo Anaerobic, we recommend medium-fine grind..."',
        type: NotificationType.chatMessage,
        targetId: 'conv_concierge',
        deepLinkPath: '/chat',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotificationModel(
        id: 'notif_103',
        title: 'Micro-Lot Harvest Arrival',
        body: 'Fresh crop Mount Matutum Washed Typica is now roasted and available in limited batches.',
        type: NotificationType.promo,
        targetId: 'mt-matutum',
        deepLinkPath: '/products/mt-matutum',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    _userNotifications[demoCustomerId] = List.from(demoNotifs);
    _userNotifications['usr_lambac_1001'] = List.from(demoNotifs);
  }

  UserModel? get _currentUser => MockUserDatabase().currentUser;

  @override
  Future<Result<void, AppFailure>> registerDeviceToken(String fcmToken) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }
    return const Result.success(null);
  }

  @override
  Future<Result<List<AppNotificationModel>, AppFailure>> getNotifications({
    int limit = 20,
    dynamic lastDocument,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to access notifications.'),
      );
    }

    final list = List<AppNotificationModel>.from(_userNotifications[user.id] ?? []);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int startIndex = 0;
    if (lastDocument is String) {
      final idx = list.indexWhere((n) => n.id == lastDocument);
      if (idx != -1) startIndex = idx + 1;
    }
    final endIndex = (startIndex + limit) > list.length ? list.length : startIndex + limit;
    final paged = startIndex < list.length ? list.sublist(startIndex, endIndex) : <AppNotificationModel>[];

    return Result.success(List.unmodifiable(paged));
  }

  @override
  Future<Result<void, AppFailure>> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    final list = _userNotifications[user.id];
    if (list != null) {
      final idx = list.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isRead: true);
        if (!_notificationsStreamController.isClosed) {
          _notificationsStreamController.add(List.unmodifiable(list));
        }
      }
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppFailure>> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 30));
    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    final list = _userNotifications[user.id];
    if (list != null) {
      final updated = list.map((n) => n.copyWith(isRead: true)).toList();
      _userNotifications[user.id] = updated;
      if (!_notificationsStreamController.isClosed) {
        _notificationsStreamController.add(List.unmodifiable(updated));
      }
    }
    return const Result.success(null);
  }

  @override
  Future<Result<NotificationPreferencesModel, AppFailure>> getPreferences() async {
    await Future.delayed(const Duration(milliseconds: 30));
    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    final prefs = _userPreferences[user.id] ?? const NotificationPreferencesModel();
    return Result.success(prefs);
  }

  @override
  Future<Result<NotificationPreferencesModel, AppFailure>> updatePreferences(NotificationPreferencesModel prefs) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    _userPreferences[user.id] = prefs;
    return Result.success(prefs);
  }

  /// Add a simulated notification for a specific recipient
  void addNotificationForUser(String userId, AppNotificationModel notification) {
    _userNotifications.putIfAbsent(userId, () => []).insert(0, notification);
    if (_currentUser?.id == userId && !_notificationsStreamController.isClosed) {
      _notificationsStreamController.add(List.unmodifiable(_userNotifications[userId]!));
    }
  }

  /// Reset all notifications state for clean testing
  void resetForTesting() {
    _userNotifications.clear();
    _userPreferences.clear();
    clearSession();
    _seedDefaultNotifications();
  }
}
