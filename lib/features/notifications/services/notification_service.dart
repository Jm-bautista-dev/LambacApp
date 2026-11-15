import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/app_notification_model.dart';
import '../domain/repositories/notification_repository.dart';

/// Central Notification Service managing Token Registration, Permissions, Deduplication & Deep-Link Navigation
class NotificationService {
  final NotificationRepository _repository;
  final Set<String> _processedNotificationIds = {};

  NotificationService({required NotificationRepository repository})
      : _repository = repository;

  Future<bool> requestPermission() async {
    // Simulates native FCM / APNs permission dialog request
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  Future<void> registerDeviceToken(String fcmToken) async {
    await _repository.registerDeviceToken(fcmToken);
  }

  /// Handles deep-link navigation when a notification payload is tapped
  void handleNotificationTap(BuildContext context, AppNotificationModel notification) {
    if (_processedNotificationIds.contains(notification.id)) {
      // Deduplication check: prevent multiple tap triggers
      return;
    }

    _processedNotificationIds.add(notification.id);

    // Mark as read in repository
    _repository.markAsRead(notification.id);

    final path = notification.deepLinkPath;

    if (path.startsWith('/orders/') || path == '/chat' || path == '/home') {
      context.push(path);
    } else if (notification.type == NotificationType.orderStatus && notification.targetId != null) {
      context.push('/orders/${notification.targetId}');
    } else if (notification.type == NotificationType.chatMessage) {
      context.push('/chat');
    } else {
      context.go('/home');
    }
  }
}
