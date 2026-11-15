import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/data/models/send_message_request.dart';
import 'package:lambac_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('ChatRepository Unit Tests', () {
    late InMemoryStorageService storageService;
    late MockChatRemoteDataSource remoteDataSource;
    late ChatRepositoryImpl chatRepository;

    setUp(() {
      final userDb = MockUserDatabase();
      userDb.seedDefaultUsers();
      userDb.setCurrentUser(userDb.records['coffee.lover@lambac.com']!.user);

      storageService = InMemoryStorageService();
      remoteDataSource = MockChatRemoteDataSource();
      remoteDataSource.resetForTesting();
      chatRepository = ChatRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
    });

    test('getConversation retrieves active roastery conversation', () async {
      final result = await chatRepository.getConversation('usr_customer_demo');

      expect(result.isSuccess, isTrue);
      final conv = result.dataOrNull!;
      expect(conv.participantName, equals('Hiro (Head Roaster)'));
      expect(conv.isOnline, isTrue);
    });

    test('getMessages retrieves existing message history', () async {
      final result = await chatRepository.getMessages('conv_concierge');

      expect(result.isSuccess, isTrue);
      final messages = result.dataOrNull!;
      expect(messages.length, greaterThanOrEqualTo(3));
      expect(messages.first.senderRole, equals(SenderRole.barista));
    });

    test('sendMessage posts new message to concierge', () async {
      final request = const SendMessageRequest(
        conversationId: 'conv_concierge',
        text: 'What is the recommended brewing temperature?',
      );

      final result = await chatRepository.sendMessage(request);

      expect(result.isSuccess, isTrue);
      final msg = result.dataOrNull!;
      expect(msg.text, equals('What is the recommended brewing temperature?'));
      expect(msg.status, equals(MessageStatus.sent));
    });

    test('sendMessage handles network failure gracefully', () async {
      final request = const SendMessageRequest(
        conversationId: 'conv_concierge',
        text: 'fail_test error simulation',
      );

      final result = await chatRepository.sendMessage(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Failed to send message'));
    });
  });
}
