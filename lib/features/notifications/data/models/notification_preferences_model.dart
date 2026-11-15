import 'package:equatable/equatable.dart';

/// User Notification Settings Model
class NotificationPreferencesModel extends Equatable {
  final bool orderStatusEnabled;
  final bool chatMessageEnabled;
  final bool promotionalEnabled;

  const NotificationPreferencesModel({
    this.orderStatusEnabled = true,
    this.chatMessageEnabled = true,
    this.promotionalEnabled = false,
  });

  NotificationPreferencesModel copyWith({
    bool? orderStatusEnabled,
    bool? chatMessageEnabled,
    bool? promotionalEnabled,
  }) {
    return NotificationPreferencesModel(
      orderStatusEnabled: orderStatusEnabled ?? this.orderStatusEnabled,
      chatMessageEnabled: chatMessageEnabled ?? this.chatMessageEnabled,
      promotionalEnabled: promotionalEnabled ?? this.promotionalEnabled,
    );
  }

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      orderStatusEnabled: (json['order_status_enabled'] ?? true) as bool,
      chatMessageEnabled: (json['chat_message_enabled'] ?? true) as bool,
      promotionalEnabled: (json['promotional_enabled'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_status_enabled': orderStatusEnabled,
      'chat_message_enabled': chatMessageEnabled,
      'promotional_enabled': promotionalEnabled,
    };
  }

  @override
  List<Object?> get props => [orderStatusEnabled, chatMessageEnabled, promotionalEnabled];
}
