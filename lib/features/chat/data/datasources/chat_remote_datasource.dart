import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/send_message_request.dart';

/// Contract for Remote In-App Chat API calls
abstract class ChatRemoteDataSource {
  Future<Result<ConversationModel, AppFailure>> getConversation([String? customerId]);
  Future<Result<List<ConversationModel>, AppFailure>> getConversations();
  Future<Result<List<MessageModel>, AppFailure>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
    dynamic lastDocument,
  });
  Future<Result<MessageModel, AppFailure>> sendMessage(SendMessageRequest request);
  Future<Result<void, AppFailure>> markConversationAsRead(String conversationId);
  void clearSession();
}

/// Concrete Dio-based implementation
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _apiClient;

  ChatRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Result<ConversationModel, AppFailure>> getConversation([String? customerId]) {
    return _apiClient.get(
      '/chat/conversation',
      queryParameters: customerId != null ? {'customer_id': customerId} : null,
      requiresAuth: true,
      decoder: (data) => ConversationModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<List<ConversationModel>, AppFailure>> getConversations() {
    return _apiClient.get(
      '/chat/conversations',
      requiresAuth: true,
      decoder: (data) {
        final list = data is List ? data : (data['conversations'] ?? data['data']) as List;
        return list.map((item) => ConversationModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<Result<List<MessageModel>, AppFailure>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
    dynamic lastDocument,
  }) {
    return _apiClient.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'limit': limit},
      requiresAuth: true,
      decoder: (data) {
        final list = data is List ? data : (data['messages'] ?? data['data']) as List;
        return list.map((item) => MessageModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  @override
  Future<Result<MessageModel, AppFailure>> sendMessage(SendMessageRequest request) {
    return _apiClient.post(
      '/chat/messages',
      data: request.toJson(),
      requiresAuth: true,
      decoder: (data) => MessageModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<void, AppFailure>> markConversationAsRead(String conversationId) {
    return _apiClient.post(
      '/chat/conversations/$conversationId/read',
      requiresAuth: true,
      decoder: (_) {},
    );
  }

  @override
  void clearSession() {}
}
