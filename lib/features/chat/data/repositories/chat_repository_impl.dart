import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/services/storage_service.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/services/chat_realtime_service.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/send_message_request.dart';

/// Concrete ChatRepository implementation
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final ChatRealtimeService _realtimeService;

  StorageService get storageService => _storageService;

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required StorageService storageService,
    ChatRealtimeService? realtimeService,
  })  : _remoteDataSource = remoteDataSource,
        _storageService = storageService,
        _realtimeService = realtimeService ?? ChatRealtimeService();

  @override
  Future<Result<ConversationModel, AppFailure>> getConversation([String? customerId]) {
    return _remoteDataSource.getConversation(customerId);
  }

  @override
  Future<Result<List<ConversationModel>, AppFailure>> getConversations() {
    return _remoteDataSource.getConversations();
  }

  @override
  Future<Result<List<MessageModel>, AppFailure>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
    dynamic lastDocument,
  }) {
    return _remoteDataSource.getMessages(
      conversationId,
      page: page,
      limit: limit,
      lastDocument: lastDocument,
    );
  }

  @override
  Future<Result<MessageModel, AppFailure>> sendMessage(SendMessageRequest request) {
    return _remoteDataSource.sendMessage(request);
  }

  @override
  Future<Result<void, AppFailure>> markConversationAsRead(String conversationId) {
    return _remoteDataSource.markConversationAsRead(conversationId);
  }

  @override
  Stream<MessageModel> watchConversation(String conversationId) {
    return _realtimeService.watchConversation(conversationId);
  }

  @override
  Stream<ChatTypingStatusEvent> watchTyping(String conversationId) {
    return _realtimeService.watchTyping(conversationId);
  }

  @override
  void clearSession() {
    _remoteDataSource.clearSession();
    _realtimeService.clearSession();
  }
}
