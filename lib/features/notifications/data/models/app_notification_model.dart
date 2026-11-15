import 'package:equatable/equatable.dart';

enum NotificationType { orderStatus, chatMessage, promo }

/// Notification Item Entity with Deep Link Metadata
class AppNotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? targetId; // Order ID or Conversation ID
  final String deepLinkPath; // e.g. "/orders/ord_1082" or "/chat"
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    required this.deepLinkPath,
    this.isRead = false,
    required this.createdAt,
  });

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? targetId,
    String? deepLinkPath,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      deepLinkPath: deepLinkPath ?? this.deepLinkPath,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? 'order_status').toString().toLowerCase();
    final type = switch (typeStr) {
      'chat_message' || 'chat' => NotificationType.chatMessage,
      'promo' || 'promotional' => NotificationType.promo,
      _ => NotificationType.orderStatus,
    };

    return AppNotificationModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: type,
      targetId: json['target_id']?.toString(),
      deepLinkPath: (json['deep_link_path'] ?? json['target_path'] ?? '/home').toString(),
      isRead: (json['is_read'] ?? false) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      if (targetId != null) 'target_id': targetId,
      'deep_link_path': deepLinkPath,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, body, type, targetId, deepLinkPath, isRead, createdAt];
}
