import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/network/result.dart';
import '../models/app_notification_model.dart';
import '../models/notification_preferences_model.dart';
import 'notification_remote_datasource.dart';

/// Cloud Firestore Data Source for In-App Activity & Roastery Notifications
class FirebaseNotificationRemoteDataSource implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationsSubscription;
  final StreamController<List<AppNotificationModel>> _notificationsStreamController =
      StreamController<List<AppNotificationModel>>.broadcast();

  FirebaseNotificationRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Stream of user-scoped notifications for real-time badge and inbox updates
  Stream<List<AppNotificationModel>> get notificationsStream => _notificationsStreamController.stream;

  @override
  Stream<List<AppNotificationModel>> watchNotifications() => _notificationsStreamController.stream;

  @override
  void clearSession() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    if (!_notificationsStreamController.isClosed) {
      _notificationsStreamController.add(const []);
    }
  }

  // ===========================================================================
  // NOTIFICATIONS LISTING
  // ===========================================================================

  @override
  Future<Result<List<AppNotificationModel>, AppFailure>> getNotifications({
    int limit = 20,
    dynamic lastDocument,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to access notifications.'),
      );
    }

    final effectiveUserId = user.uid;

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(effectiveUserId)
          .collection('notifications')
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastDocument is DocumentSnapshot<Map<String, dynamic>>) {
        query = query.startAfterDocument(lastDocument);
      } else if (lastDocument is String && lastDocument.isNotEmpty) {
        try {
          final doc = await _firestore
              .collection('users')
              .doc(effectiveUserId)
              .collection('notifications')
              .doc(lastDocument)
              .get();
          if (doc.exists) query = query.startAfterDocument(doc);
        } catch (_) {}
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty && lastDocument == null) {
        _startRealtimeListener(effectiveUserId);
        return const Result.success([]);
      }

      final list = snapshot.docs.map((doc) => _mapDocToNotification(doc)).toList();

      if (lastDocument == null) {
        _startRealtimeListener(effectiveUserId);
      }
      return Result.success(List.unmodifiable(list));
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to load notifications: $e'));
    }
  }

  /// Calculates actual unread count using server-side Firestore aggregation
  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    try {
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('is_read', isEqualTo: false)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void _startRealtimeListener(String userId) {
    _notificationsSubscription?.cancel();
    try {
      // Bounded real-time listener for the latest 20 notifications
      _notificationsSubscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('created_at', descending: true)
          .limit(20)
          .snapshots()
          .listen((snapshot) {
        // Verify caller is still authenticated as userId
        final current = _auth.currentUser;
        if (current == null || current.uid != userId) {
          _notificationsSubscription?.cancel();
          _notificationsSubscription = null;
          return;
        }

        final list = snapshot.docs.map((doc) => _mapDocToNotification(doc)).toList();
        if (!_notificationsStreamController.isClosed) {
          _notificationsStreamController.add(list);
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  // ===========================================================================
  // READ STATUS MUTATIONS
  // ===========================================================================

  @override
  Future<Result<void, AppFailure>> markAsRead(String notificationId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    final effectiveUserId = user.uid;

    try {
      await _firestore
          .collection('users')
          .doc(effectiveUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      });

      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to update notification: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> markAllAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    final effectiveUserId = user.uid;

    try {
      final notifsSnapshot = await _firestore
          .collection('users')
          .doc(effectiveUserId)
          .collection('notifications')
          .where('is_read', isEqualTo: false)
          .get();

      if (notifsSnapshot.docs.isEmpty) {
        return const Result.success(null);
      }

      final batch = _firestore.batch();
      final now = DateTime.now().toIso8601String();

      for (final doc in notifsSnapshot.docs) {
        batch.update(doc.reference, {
          'is_read': true,
          'read_at': now,
        });
      }

      await batch.commit();
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to mark notifications read: $e'));
    }
  }

  // ===========================================================================
  // PREFERENCES & DEVICE TOKEN
  // ===========================================================================

  @override
  Future<Result<void, AppFailure>> registerDeviceToken(String fcmToken) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    final effectiveUserId = user.uid;

    try {
      await _firestore.collection('users').doc(effectiveUserId).set({
        'fcm_device_token': fcmToken,
        'token_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to register device token: $e'));
    }
  }

  @override
  Future<Result<NotificationPreferencesModel, AppFailure>> getPreferences() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    final effectiveUserId = user.uid;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(effectiveUserId)
          .collection('preferences')
          .doc('notifications')
          .get();

      if (doc.exists && doc.data() != null) {
        return Result.success(NotificationPreferencesModel.fromJson(doc.data()!));
      }

      return const Result.success(NotificationPreferencesModel());
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to load preferences: $e'));
    }
  }

  @override
  Future<Result<NotificationPreferencesModel, AppFailure>> updatePreferences(
    NotificationPreferencesModel prefs,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required.'),
      );
    }

    final effectiveUserId = user.uid;

    try {
      await _firestore
          .collection('users')
          .doc(effectiveUserId)
          .collection('preferences')
          .doc('notifications')
          .set(prefs.toJson(), SetOptions(merge: true));

      return Result.success(prefs);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to update preferences: $e'));
    }
  }

  // ===========================================================================
  // HELPERS & SEEDING
  // ===========================================================================

  AppNotificationModel _mapDocToNotification(DocumentSnapshot doc) {
    final rawData = doc.data() as Map<String, dynamic>? ?? {};
    final map = Map<String, dynamic>.from(rawData);
    map['id'] = doc.id;

    if (map['created_at'] is Timestamp) {
      map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
    }
    return AppNotificationModel.fromJson(map);
  }

  /// Adds an in-app notification for a designated user (e.g. staff or customer)
  Future<void> addNotificationForUser(String userId, AppNotificationModel notification) async {
    try {
      final json = notification.toJson();
      json['created_at'] = Timestamp.fromDate(notification.createdAt);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id)
          .set(json);
    } catch (_) {
      // Non-blocking in offline / test environments
    }
  }

  Future<void> _seedDefaultNotificationsIfEmpty(String userId) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      final defaults = [
        AppNotificationModel(
          id: 'notif_seed_1',
          title: 'Order Ready for Pickup',
          body: 'Your Lambac pickup order #LMB-1082 is ready for pickup at our Session Road bar!',
          type: NotificationType.orderStatus,
          targetId: 'ord_lmb_1082',
          deepLinkPath: '/orders/ord_lmb_1082',
          isRead: false,
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
        AppNotificationModel(
          id: 'notif_seed_2',
          title: 'Barista Concierge Reply',
          body: 'Hiro (Head Roaster) replied: "For Mount Apo Anaerobic, we recommend medium-fine grind..."',
          type: NotificationType.chatMessage,
          targetId: 'conv_concierge',
          deepLinkPath: '/chat',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        AppNotificationModel(
          id: 'notif_seed_3',
          title: 'Micro-Lot Harvest Arrival',
          body: 'Fresh crop Mount Matutum Washed Typica is now roasted and available in limited batches.',
          type: NotificationType.promo,
          targetId: 'mt-matutum',
          deepLinkPath: '/products/mt-matutum',
          isRead: true,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      for (final n in defaults) {
        final ref = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(n.id);
        batch.set(ref, n.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (_) {}
  }

  void dispose() {
    clearSession();
    _notificationsStreamController.close();
  }

  AppFailure _mapFirebaseException(FirebaseException e, [StackTrace? stackTrace]) {
    return ErrorHandler.handle(
      e,
      stackTrace: stackTrace,
      domain: FailureDomain.notificationDelivery,
      operation: 'notifications',
    );
  }
}
