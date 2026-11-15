import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/message_model.dart';

/// Real-time event emitted when a new chat message arrives
class ChatMessageReceivedEvent {
  final MessageModel message;
  const ChatMessageReceivedEvent({required this.message});
}

/// Real-time event emitted when a participant starts or stops typing
class ChatTypingStatusEvent {
  final String conversationId;
  final bool isTyping;
  final String participantName;

  const ChatTypingStatusEvent({
    required this.conversationId,
    required this.isTyping,
    required this.participantName,
  });
}

/// Centralized Real-Time Event Broker for Roastery Concierge Chat
/// Dispatches incoming customer and barista messages across screens in real-time
class ChatRealtimeService {
  static final ChatRealtimeService _instance = ChatRealtimeService._internal();
  factory ChatRealtimeService() => _instance;

  ChatRealtimeService._internal();

  final _messageEventController = StreamController<ChatMessageReceivedEvent>.broadcast();
  final _typingEventController = StreamController<ChatTypingStatusEvent>.broadcast();

  /// Stream of all message events
  Stream<ChatMessageReceivedEvent> get messageEvents => _messageEventController.stream;

  /// Stream of all typing events
  Stream<ChatTypingStatusEvent> get typingEvents => _typingEventController.stream;

  /// Watch incoming messages for a specific conversation in real-time (or '*' for all)
  Stream<MessageModel> watchConversation(String conversationId) {
    if (conversationId == '*' || conversationId.isEmpty) {
      return _messageEventController.stream.map((event) => event.message);
    }
    return _messageEventController.stream
        .where((event) => event.message.conversationId == conversationId)
        .map((event) => event.message);
  }

  /// Watch typing indicators for a specific conversation
  Stream<ChatTypingStatusEvent> watchTyping(String conversationId) {
    return _typingEventController.stream
        .where((event) => event.conversationId == conversationId);
  }

  /// Broadcast a newly sent message (from Customer or Barista)
  void notifyMessageSent(MessageModel message) {
    if (!_messageEventController.isClosed) {
      _messageEventController.add(ChatMessageReceivedEvent(message: message));
    }
  }

  /// Broadcast typing state updates
  void notifyTyping({
    required String conversationId,
    required bool isTyping,
    required String participantName,
  }) {
    if (!_typingEventController.isClosed) {
      _typingEventController.add(ChatTypingStatusEvent(
        conversationId: conversationId,
        isTyping: isTyping,
        participantName: participantName,
      ));
    }
  }

  /// Reset streams for testing
  void resetForTesting() {
    // Keep internal stream controllers open for subsequent events
  }

  /// Reset session state on logout
  void clearSession() {
    // Reset any state on session change
  }
}

/// Riverpod provider for real-time chat event broker
final chatRealtimeServiceProvider = Provider<ChatRealtimeService>((ref) {
  return ChatRealtimeService();
});
