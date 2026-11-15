import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/datasources/firebase_notification_remote_datasource.dart';
import '../../data/datasources/mock_notification_remote_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/models/notification_preferences_model.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../services/notification_service.dart';

/// Provider for Notification Remote Data Source (Cloud Firestore Production Data Source)
final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  try {
    if (Firebase.apps.isEmpty) {
      return MockNotificationRemoteDataSource();
    }
  } catch (_) {
    return MockNotificationRemoteDataSource();
  }
  return FirebaseNotificationRemoteDataSource();
});

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remoteDataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationService(repository: repository);
});

/// Unread Notification Count Provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsNotifierProvider);
  return state.notifications.where((n) => !n.isRead).length;
});

class NotificationState extends Equatable {
  final bool isLoading;
  final List<AppNotificationModel> notifications;
  final NotificationPreferencesModel preferences;
  final AppFailure? failure;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.preferences = const NotificationPreferencesModel(),
    this.failure,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  NotificationState copyWith({
    bool? isLoading,
    List<AppNotificationModel>? notifications,
    NotificationPreferencesModel? preferences,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      preferences: preferences ?? this.preferences,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [isLoading, notifications, preferences, failure];
}

/// User-Scoped Notifications StateNotifier Provider
/// Auto-disposes and resets cleanly upon logout or account switching
final notificationsNotifierProvider = StateNotifierProvider.autoDispose<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  return NotificationNotifier(
    repository: repository,
    currentUser: currentUser,
  );
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  final UserModel? _currentUser;
  final String? _sessionUserId;
  StreamSubscription<List<AppNotificationModel>>? _streamSub;

  NotificationNotifier({
    required NotificationRepository repository,
    UserModel? currentUser,
  })  : _repository = repository,
        _currentUser = currentUser,
        _sessionUserId = currentUser?.id,
        super(
          currentUser == null
              ? const NotificationState(isLoading: false)
              : const NotificationState(isLoading: true),
        ) {
    if (currentUser != null) {
      loadNotifications();
      _subscribeToStream();
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  void _subscribeToStream() {
    _streamSub?.cancel();
    _streamSub = _repository.watchNotifications().listen((list) {
      if (!mounted || _currentUser?.id != _sessionUserId) return;
      state = state.copyWith(
        isLoading: false,
        notifications: list,
        clearFailure: true,
      );
    }, onError: (Object err, StackTrace stackTrace) {
      if (!mounted || _currentUser?.id != _sessionUserId) return;
      final failure = ErrorHandler.handle(
        err,
        stackTrace: stackTrace,
        operation: 'watchNotifications',
        domain: FailureDomain.firestoreAccess,
      );
      state = state.copyWith(isLoading: false, failure: failure);
    });
  }

  Future<void> loadNotifications({bool isRefresh = false}) async {
    if (_currentUser == null) {
      state = const NotificationState(isLoading: false);
      return;
    }

    if (!isRefresh) {
      state = state.copyWith(isLoading: true, clearFailure: true);
    }

    final notifResult = await _repository.getNotifications();
    final prefResult = await _repository.getPreferences();

    if (!mounted || _currentUser?.id != _sessionUserId) return;

    notifResult.when(
      success: (list) {
        final prefs = prefResult.dataOrNull ?? state.preferences;
        state = state.copyWith(
          isLoading: false,
          notifications: list,
          preferences: prefs,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
      },
    );
  }

  Future<void> markAsRead(String id) async {
    final previous = state.notifications;
    final updated = state.notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    state = state.copyWith(notifications: updated);

    final result = await _repository.markAsRead(id);
    if (!mounted || _currentUser?.id != _sessionUserId) return;
    if (result.isFailure) {
      state = state.copyWith(notifications: previous, failure: result.failureOrNull);
    }
  }

  Future<void> markAllAsRead() async {
    final previous = state.notifications;
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);

    final result = await _repository.markAllAsRead();
    if (!mounted || _currentUser?.id != _sessionUserId) return;
    if (result.isFailure) {
      state = state.copyWith(notifications: previous, failure: result.failureOrNull);
    }
  }

  Future<void> updatePreferences(NotificationPreferencesModel prefs) async {
    final previous = state.preferences;
    state = state.copyWith(preferences: prefs);
    final result = await _repository.updatePreferences(prefs);
    if (!mounted || _currentUser?.id != _sessionUserId) return;
    if (result.isFailure) {
      state = state.copyWith(preferences: previous, failure: result.failureOrNull);
    }
  }
}
