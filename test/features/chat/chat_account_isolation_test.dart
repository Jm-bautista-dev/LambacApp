import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/data/models/send_message_request.dart';
import 'package:lambac_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lambac_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Chat Account Isolation & Backend Authorization Tests', () {
    late MockUserDatabase userDb;
    late MockChatRemoteDataSource chatDataSource;
    late ChatRepositoryImpl chatRepository;
    late InMemoryStorageService storageService;

    final customer1 = UserModel(
      id: 'usr_cust_1',
      email: 'customer1@test.com',
      fullName: 'Alice Walker',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    final customer2 = UserModel(
      id: 'usr_cust_2',
      email: 'customer2@test.com',
      fullName: 'Bob Smith',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 2),
    );

    final baristaUser = UserModel(
      id: 'usr_barista_staff',
      email: 'barista@lambaccoffee.com',
      fullName: 'Sora Tanaka',
      role: UserRole.employee,
      status: UserStatus.active,
      permissions: const [EmployeePermission.manageInbox],
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      userDb = MockUserDatabase();
      chatDataSource = MockChatRemoteDataSource();
      chatDataSource.resetForTesting();
      storageService = InMemoryStorageService();
      chatRepository = ChatRepositoryImpl(
        remoteDataSource: chatDataSource,
        storageService: storageService,
      );
    });

    test('Test 1: Customer 1 requests own conversation -> returns isolated Customer 1 conversation', () async {
      userDb.setCurrentUser(customer1);

      final result = await chatRepository.getConversation();
      expect(result.isSuccess, isTrue);

      final conversation = result.dataOrNull!;
      expect(conversation.customerId, equals('usr_cust_1'));
      expect(conversation.id, equals('conv_cust_usr_cust_1'));
    });

    test('Test 2: Customer 2 requests own conversation -> returns isolated Customer 2 conversation', () async {
      userDb.setCurrentUser(customer2);

      final result = await chatRepository.getConversation();
      expect(result.isSuccess, isTrue);

      final conversation = result.dataOrNull!;
      expect(conversation.customerId, equals('usr_cust_2'));
      expect(conversation.id, equals('conv_cust_usr_cust_2'));
    });

    test('Test 3: Customer 2 attempts to access Customer 1 conversation -> returns 403 Forbidden', () async {
      // 1. Initialize Customer 1 conversation
      userDb.setCurrentUser(customer1);
      final conv1Result = await chatRepository.getConversation();
      final conv1Id = conv1Result.dataOrNull!.id;

      // 2. Switch to Customer 2
      userDb.setCurrentUser(customer2);

      // Customer 2 attempts to query customer1's conversation ID
      final msgResult = await chatRepository.getMessages(conv1Id);
      expect(msgResult.isFailure, isTrue);
      expect(msgResult.failureOrNull, isA<ForbiddenFailure>());
      expect(msgResult.failureOrNull?.message, contains('Forbidden'));
    });

    test('Test 4: Customer 2 attempts to send message to Customer 1 conversation -> rejected with 403', () async {
      // 1. Initialize Customer 1 conversation
      userDb.setCurrentUser(customer1);
      final conv1Result = await chatRepository.getConversation();
      final conv1Id = conv1Result.dataOrNull!.id;

      // 2. Switch to Customer 2
      userDb.setCurrentUser(customer2);

      // Customer 2 attempts to inject message into Customer 1's conversation
      final sendResult = await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: conv1Id,
          text: 'Attacking Customer 1 conversation',
        ),
      );

      expect(sendResult.isFailure, isTrue);
      expect(sendResult.failureOrNull, isA<ForbiddenFailure>());
      expect(sendResult.failureOrNull?.message, contains('Forbidden'));
    });

    test('Test 5: Customer 2 attempts to manipulate customer_id in request -> server enforces authenticated identity', () async {
      userDb.setCurrentUser(customer2);

      // Customer 2 sends customerId="usr_cust_1" in getConversation
      final result = await chatRepository.getConversation('usr_cust_1');

      // The server ignores client-forged ID and returns either 403 or Customer 2's own conversation
      if (result.isSuccess) {
        expect(result.dataOrNull!.customerId, equals('usr_cust_2'));
      } else {
        expect(result.failureOrNull, isA<ForbiddenFailure>());
      }
    });

    test('Test 6: Barista / Admin can access customer conversations for support', () async {
      // 1. Customer 1 creates conversation and sends message
      userDb.setCurrentUser(customer1);
      final conv1Result = await chatRepository.getConversation();
      final conv1Id = conv1Result.dataOrNull!.id;
      await chatRepository.sendMessage(
        SendMessageRequest(conversationId: conv1Id, text: 'Hello from Customer 1'),
      );

      // 2. Barista logs in
      userDb.setCurrentUser(baristaUser);

      // Barista reads Customer 1 messages
      final msgsResult = await chatRepository.getMessages(conv1Id);
      expect(msgsResult.isSuccess, isTrue);
      expect(msgsResult.dataOrNull!.any((m) => m.text == 'Hello from Customer 1'), isTrue);

      // Barista replies to Customer 1
      final replyResult = await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: conv1Id,
          text: 'Barista reply to Customer 1',
        ),
      );
      expect(replyResult.isSuccess, isTrue);
      expect(replyResult.dataOrNull!.senderRole, equals(SenderRole.barista));
    });

    test('Test 7: Unauthenticated request is rejected with 401 UnauthorizedFailure', () async {
      userDb.setCurrentUser(null);

      final result = await chatRepository.getConversation();
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('Test 8: ChatNotifier lifecycle clears in-memory state when user is null', () async {
      final unauthenticatedNotifier = ChatNotifier(
        repository: chatRepository,
        currentUser: null,
      );

      expect(unauthenticatedNotifier.state.isLoading, isFalse);
      expect(unauthenticatedNotifier.state.conversation, isNull);
      expect(unauthenticatedNotifier.state.messages, isEmpty);
    });

    test('Test 9: ChatNotifier for Customer 1 loads only Customer 1 messages', () async {
      userDb.setCurrentUser(customer1);

      final notifier = ChatNotifier(
        repository: chatRepository,
        currentUser: customer1,
      );

      // Wait for loadChat async completion
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.conversation?.customerId, equals('usr_cust_1'));
      expect(notifier.state.messages.isNotEmpty, isTrue);
    });
  });
}
