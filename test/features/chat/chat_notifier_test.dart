import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lambac_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('ChatNotifier State Management Tests', () {
    late InMemoryStorageService storageService;
    late MockChatRemoteDataSource remoteDataSource;
    late ChatRepositoryImpl chatRepository;
    late ChatNotifier notifier;

    setUp(() {
      final userDb = MockUserDatabase();
      userDb.seedDefaultUsers();
      final demoUser = userDb.records['coffee.lover@lambac.com']!.user;
      userDb.setCurrentUser(demoUser);

      storageService = InMemoryStorageService();
      remoteDataSource = MockChatRemoteDataSource();
      remoteDataSource.resetForTesting();
      chatRepository = ChatRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
      notifier = ChatNotifier(
        repository: chatRepository,
        currentUser: demoUser,
      );
    });

    tearDown(() {
      notifier.dispose();
    });

    test('Initial load populates messages history', () async {
      await notifier.loadChat();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.messages.isNotEmpty, isTrue);
      expect(notifier.state.conversation, isNotNull);
    });

    test('sendMessage adds optimistic sending message and updates to sent', () async {
      await notifier.loadChat();
      final initialCount = notifier.state.messages.length;

      await notifier.sendMessage('Recommend grind size for V60');

      expect(notifier.state.messages.length, greaterThan(initialCount));
      final sentMsg = notifier.state.messages.firstWhere((m) => m.text == 'Recommend grind size for V60');
      expect(sentMsg.status, equals(MessageStatus.sent));
    });

    test('sendMessage handles failure and retryMessage resends successfully', () async {
      await notifier.loadChat();

      // Trigger failure with mock failure text
      await notifier.sendMessage('fail_test trigger error');

      final failedMsg = notifier.state.messages.firstWhere((m) => m.text.contains('fail_test'));
      expect(failedMsg.status, equals(MessageStatus.failed));

      // Retry message with normal text
      final fixedMsg = failedMsg.copyWith(text: 'Fixed query after retry');
      await notifier.retryMessage(fixedMsg);

      final retriedMsg = notifier.state.messages.firstWhere((m) => m.text.contains('Fixed query'));
      expect(retriedMsg.status, equals(MessageStatus.sent));
    });
  });
}
