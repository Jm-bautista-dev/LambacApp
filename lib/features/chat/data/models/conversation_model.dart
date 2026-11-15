import 'package:equatable/equatable.dart';
import 'message_model.dart';

/// Conversation Handling Mode (Section 11 — Human Override & Handover)
enum ConversationHandlingMode {
  aiAvailable,
  humanActive,
  humanHandoffRequested;

  static ConversationHandlingMode fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'humanactive' || 'human_active' => ConversationHandlingMode.humanActive,
      'humanhandoffrequested' || 'human_handoff_requested' => ConversationHandlingMode.humanHandoffRequested,
      _ => ConversationHandlingMode.aiAvailable,
    };
  }
}

/// Conversation Container Model
class ConversationModel extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String participantName; // e.g. "Hiro (Head Roaster)"
  final String? participantAvatarUrl;
  final String? orderReference; // e.g. "ORDER #LMB-1082 • Preparing"
  final bool isOnline;
  final bool isTyping;
  final MessageModel? lastMessage;
  final int unreadCount;
  final Map<String, int> unreadCountsByRole;
  final ConversationHandlingMode handlingMode;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.customerId,
    this.customerName = 'Kenji Takahashi',
    this.participantName = 'Hiro (Head Roaster)',
    this.participantAvatarUrl,
    this.orderReference,
    this.isOnline = true,
    this.isTyping = false,
    this.lastMessage,
    this.unreadCount = 0,
    this.unreadCountsByRole = const {},
    this.handlingMode = ConversationHandlingMode.aiAvailable,
    required this.updatedAt,
  });

  /// Check unread count for a specific user role (e.g. 'barista', 'admin', 'customer')
  int unreadForRole(String role) {
    if (unreadCountsByRole.containsKey(role)) {
      return unreadCountsByRole[role]!;
    }
    return unreadCount;
  }

  ConversationModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? participantName,
    String? participantAvatarUrl,
    String? orderReference,
    bool? isOnline,
    bool? isTyping,
    MessageModel? lastMessage,
    int? unreadCount,
    Map<String, int>? unreadCountsByRole,
    ConversationHandlingMode? handlingMode,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      participantName: participantName ?? this.participantName,
      participantAvatarUrl: participantAvatarUrl ?? this.participantAvatarUrl,
      orderReference: orderReference ?? this.orderReference,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadCountsByRole: unreadCountsByRole ?? this.unreadCountsByRole,
      handlingMode: handlingMode ?? this.handlingMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> parsedUnreads = {};
    if (json['unread_counts_by_role'] is Map) {
      (json['unread_counts_by_role'] as Map).forEach((k, v) {
        if (v is num) parsedUnreads[k.toString()] = v.toInt();
      });
    }

    return ConversationModel(
      id: (json['id'] ?? json['_id'] ?? 'conv_concierge').toString(),
      customerId: (json['customer_id'] ?? json['customerId'] ?? '').toString(),
      customerName: (json['customer_name'] ?? json['customerName'] ?? 'Kenji Takahashi').toString(),
      participantName: (json['participant_name'] ?? json['participantName'] ?? 'Hiro (Head Roaster)').toString(),
      participantAvatarUrl: (json['participant_avatar_url'] ?? json['participantAvatarUrl'])?.toString(),
      orderReference: (json['order_reference'] ?? json['orderReference'])?.toString(),
      isOnline: (json['is_online'] ?? json['isOnline'] ?? true) as bool,
      isTyping: (json['is_typing'] ?? json['isTyping'] ?? false) as bool,
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : (json['lastMessage'] != null ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>) : null),
      unreadCount: (json['unread_count'] ?? json['unreadCount'] ?? 0) as int,
      unreadCountsByRole: parsedUnreads,
      handlingMode: ConversationHandlingMode.fromString((json['handling_mode'] ?? json['handlingMode'])?.toString()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : (json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'participant_name': participantName,
      if (participantAvatarUrl != null) 'participant_avatar_url': participantAvatarUrl,
      if (orderReference != null) 'order_reference': orderReference,
      'is_online': isOnline,
      'is_typing': isTyping,
      if (lastMessage != null) 'last_message': lastMessage!.toJson(),
      'unread_count': unreadCount,
      'unread_counts_by_role': unreadCountsByRole,
      'handling_mode': handlingMode.name,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        participantName,
        participantAvatarUrl,
        orderReference,
        isOnline,
        isTyping,
        lastMessage,
        unreadCount,
        unreadCountsByRole,
        handlingMode,
        updatedAt,
      ];
}
