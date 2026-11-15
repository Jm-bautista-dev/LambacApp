import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/send_message_request.dart';

/// Clean Domain Repository Contract for Customer Concierge Chat
abstract class ChatRepository {
  /// Fetch or initialize customer conversation (uses authenticated user identity if customerId is omitted)
  Future<Result<ConversationModel, AppFailure>> getConversation([String? customerId]);

  /// Fetch all active customer conversations (for staff/admin operational inbox, or own conversation for customer)
  Future<Result<List<ConversationModel>, AppFailure>> getConversations();

  /// Fetch message history for a conversation with cursor pagination (newest first slice)
  Future<Result<List<MessageModel>, AppFailure>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
    dynamic lastDocument,
  });

  /// Send a message to roastery concierge
  Future<Result<MessageModel, AppFailure>> sendMessage(SendMessageRequest request);

  /// Mark conversation messages as read
  Future<Result<void, AppFailure>> markConversationAsRead(String conversationId);

  /// Real-time stream of incoming messages for a conversation
  Stream<MessageModel> watchConversation(String conversationId);

  /// Real-time stream of participant typing indicators
  Stream<dynamic> watchTyping(String conversationId);

  /// Clears active subscriptions and in-memory caches on session termination
  void clearSession();
}
