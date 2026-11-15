import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../errors/app_failure.dart';
import '../errors/error_handler.dart';
import '../monitoring/operational_monitoring_service.dart';
import '../monitoring/secure_error_logger.dart';

/// State of a real-time listener subscription
enum RealtimeSyncStatus {
  initialLoading,
  active,
  empty,
  error,
  reconnecting,
  closed,
}

/// Robust, Lifecycle-Safe Real-Time Firestore Stream Manager
/// Prevents memory leaks, duplicate subscriptions, session bleeding, and unhandled permission errors
class RealtimeStreamHandler<T> {
  final String streamTag;
  final FailureDomain domain;
  final Stream<QuerySnapshot<Map<String, dynamic>>> Function() streamBuilder;
  final T Function(DocumentSnapshot<Map<String, dynamic>> doc) itemMapper;
  final void Function(List<T> items, bool isFromCache) onData;
  final void Function(AppFailure failure)? onError;
  final void Function(RealtimeSyncStatus status)? onStatusChanged;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _currentUserId;
  RealtimeSyncStatus _status = RealtimeSyncStatus.initialLoading;

  RealtimeStreamHandler({
    required this.streamTag,
    required this.domain,
    required this.streamBuilder,
    required this.itemMapper,
    required this.onData,
    this.onError,
    this.onStatusChanged,
  });

  RealtimeSyncStatus get status => _status;
  bool get isActive => _subscription != null;

  /// Starts listening for an authenticated user session
  void listen({required String userId}) {
    if (_subscription != null && _currentUserId == userId) {
      return; // Already actively subscribed for this user session
    }

    // Cancel any previous user session subscription immediately
    cancel();
    _currentUserId = userId;
    _updateStatus(RealtimeSyncStatus.initialLoading);

    try {
      _subscription = streamBuilder().listen(
        (snapshot) {
          // Guard: Verify current user session still matches before processing
          if (_currentUserId != userId) {
            cancel();
            return;
          }

          final isFromCache = snapshot.metadata.isFromCache;
          final items = snapshot.docs.map(itemMapper).toList();

          if (items.isEmpty) {
            _updateStatus(RealtimeSyncStatus.empty);
          } else {
            _updateStatus(RealtimeSyncStatus.active);
          }

          onData(items, isFromCache);
        },
        onError: (Object error, StackTrace stackTrace) {
          final failure = ErrorHandler.handle(
            error,
            stackTrace: stackTrace,
            operation: '$streamTag.listener',
            domain: domain,
            actorUid: userId,
          );

          _updateStatus(RealtimeSyncStatus.error);
          onError?.call(failure);
        },
        cancelOnError: false, // Maintain subscription across transient blips
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        operation: '$streamTag.subscription_init',
        domain: domain,
        actorUid: userId,
      );
      _updateStatus(RealtimeSyncStatus.error);
      onError?.call(failure);
    }
  }

  void _updateStatus(RealtimeSyncStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    onStatusChanged?.call(newStatus);
  }

  /// Cancels the subscription and cleans up active resources
  void cancel() {
    _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
    _updateStatus(RealtimeSyncStatus.closed);
  }

  void dispose() {
    cancel();
  }
}
