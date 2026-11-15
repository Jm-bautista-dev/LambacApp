import 'package:equatable/equatable.dart';

/// Delivery/Send Status of a Message
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  static MessageStatus fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'sending' => MessageStatus.sending,
      'delivered' => MessageStatus.delivered,
      'read' => MessageStatus.read,
      'failed' => MessageStatus.failed,
      _ => MessageStatus.sent,
    };
  }
}

/// Role of Message Sender
enum SenderRole {
  customer,
  barista,
  admin,
  system;

  static SenderRole fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'admin' => SenderRole.admin,
      'barista' || 'employee' => SenderRole.barista,
      'system' => SenderRole.system,
      _ => SenderRole.customer,
    };
  }
}

/// Message Model
class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final SenderRole senderRole;
  final String text;
  final MessageStatus status;
  final String? attachmentUrl;
  final bool isAiGenerated;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    this.status = MessageStatus.sent,
    this.attachmentUrl,
    this.isAiGenerated = false,
    required this.createdAt,
  });

  bool get isFromCustomer => senderRole == SenderRole.customer;
  bool get isFromBarista => senderRole == SenderRole.barista;
  bool get isFromAdmin => senderRole == SenderRole.admin;
  bool get isFromStaff => senderRole == SenderRole.barista || senderRole == SenderRole.admin;
  bool get isFailed => status == MessageStatus.failed;
  bool get isSending => status == MessageStatus.sending;

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    SenderRole? senderRole,
    String? text,
    MessageStatus? status,
    String? attachmentUrl,
    bool? isAiGenerated,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? json['conversationId'] ?? 'conv_default').toString(),
      senderId: (json['sender_id'] ?? json['senderId'] ?? '').toString(),
      senderName: (json['sender_name'] ?? json['senderName'] ?? 'Barista').toString(),
      senderRole: SenderRole.fromString(json['sender_role']?.toString() ?? json['senderRole']?.toString()),
      text: (json['text'] ?? json['content'] ?? '').toString(),
      status: MessageStatus.fromString(json['status']?.toString()),
      attachmentUrl: json['attachment_url']?.toString(),
      isAiGenerated: (json['is_ai_generated'] ?? false) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole.name,
      'text': text,
      'status': status.name,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      'is_ai_generated': isAiGenerated,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        senderRole,
        text,
        status,
        attachmentUrl,
        isAiGenerated,
        createdAt,
      ];
}
