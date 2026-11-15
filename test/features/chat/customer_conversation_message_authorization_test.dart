import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/data/models/send_message_request.dart';
import 'package:lambac_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('PROMPT 04 — Customer Conversations and Message Authorization Test Suite', () {
    late MockUserDatabase userDb;
    late MockChatRemoteDataSource chatDataSource;
    late ChatRepositoryImpl chatRepository;
    late InMemoryStorageService storageService;

    final customer1 = UserModel(
      id: 'cust_alice_101',
      email: 'alice.customer@lambac.com',
      fullName: 'Alice Customer',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    final customer2 = UserModel(
      id: 'cust_bob_202',
      email: 'bob.customer@lambac.com',
      fullName: 'Bob Customer',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 2),
    );

    final authorizedBarista = UserModel(
      id: 'usr_barista_hiro',
      email: 'hiro.barista@lambac.com',
      fullName: 'Hiro Tanaka',
      role: UserRole.employee,
      status: UserStatus.active,
      permissions: const [EmployeePermission.manageInbox, EmployeePermission.manageOrders],
      createdAt: DateTime(2026, 1, 1),
    );

    final unauthorizedEmployee = UserModel(
      id: 'usr_employee_kitchen',
      email: 'kitchen.staff@lambac.com',
      fullName: 'Kenji Kitchen',
      role: UserRole.employee,
      status: UserStatus.active,
      permissions: const [EmployeePermission.manageOrders], // Lacks manageInbox!
      createdAt: DateTime(2026, 1, 1),
    );

    final adminUser = UserModel(
      id: 'usr_admin_jmb',
      email: 'jmbautista0228@gmail.com',
      fullName: 'Lead Administrator',
      role: UserRole.admin,
      status: UserStatus.active,
      permissions: const [
        EmployeePermission.manageOrders,
        EmployeePermission.manageProducts,
        EmployeePermission.recordSales,
        EmployeePermission.manageInbox,
      ],
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

    test('1. Customer 1 can read their own conversation and messages', () async {
      userDb.setCurrentUser(customer1);

      final convResult = await chatRepository.getConversation();
      expect(convResult.isSuccess, isTrue);

      final conversation = convResult.dataOrNull!;
      expect(conversation.customerId, equals(customer1.id));

      final sendResult = await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: conversation.id,
          text: 'Hello from Customer 1 Alice!',
        ),
      );
      expect(sendResult.isSuccess, isTrue);

      final msgsResult = await chatRepository.getMessages(conversation.id);
      expect(msgsResult.isSuccess, isTrue);
      expect(msgsResult.dataOrNull!.any((m) => m.text == 'Hello from Customer 1 Alice!'), isTrue);
    });

    test('2. Customer 2 cannot read Customer 1 conversation or messages', () async {
      // 1. Customer 1 creates thread
      userDb.setCurrentUser(customer1);
      final conv1Result = await chatRepository.getConversation();
      final conv1Id = conv1Result.dataOrNull!.id;
      await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: conv1Id,
          text: 'Customer 1 private secret message',
        ),
      );

      // 2. Customer 2 attempts to read Customer 1's messages
      userDb.setCurrentUser(customer2);
      final directLookup = await chatRepository.getMessages(conv1Id);

      expect(directLookup.isFailure, isTrue);
      expect(directLookup.failureOrNull, isA<ForbiddenFailure>());
      expect(directLookup.failureOrNull?.message, contains('Forbidden'));
    });

    test('3. Customer cannot spoof sender IDs — authoritatively bound to authenticated UID', () async {
      userDb.setCurrentUser(customer1);
      final convResult = await chatRepository.getConversation();
      final convId = convResult.dataOrNull!.id;

      // Customer sends a message
      final result = await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: convId,
          text: 'Testing identity binding',
        ),
      );

      expect(result.isSuccess, isTrue);
      final msg = result.dataOrNull!;
      // Message senderId must strictly equal authenticated UID
      expect(msg.senderId, equals(customer1.id));
      expect(msg.senderName, equals(customer1.fullName));
      expect(msg.senderRole, equals(SenderRole.customer));
    });

    test('4. Customer cannot modify conversation ownership or participants', () async {
      userDb.setCurrentUser(customer1);
      final convResult = await chatRepository.getConversation();
      final originalConv = convResult.dataOrNull!;

      expect(originalConv.customerId, equals(customer1.id));

      // Customer 2 attempts to claim or pass customer1 id
      userDb.setCurrentUser(customer2);
      final foreignLookup = await chatRepository.getConversation(customer1.id);

      // Server rejects cross-customer manipulation with 403 Forbidden
      expect(foreignLookup.isFailure, isTrue);
      expect(foreignLookup.failureOrNull, isA<ForbiddenFailure>());
    });

    test('5. Barista can send a reply as their own authenticated UID when authorized', () async {
      // 1. Customer 1 asks question
      userDb.setCurrentUser(customer1);
      final convResult = await chatRepository.getConversation();
      final convId = convResult.dataOrNull!.id;
      await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: convId,
          text: 'What beans do you recommend for pour-over?',
        ),
      );

      // 2. Authorized Barista logs in
      userDb.setCurrentUser(authorizedBarista);

      // Barista reads Customer 1 messages
      final msgsResult = await chatRepository.getMessages(convId);
      expect(msgsResult.isSuccess, isTrue);

      // Barista sends reply
      final replyResult = await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: convId,
          text: 'We recommend our Mount Apo Honey Anaerobic!',
        ),
      );

      expect(replyResult.isSuccess, isTrue);
      final replyMsg = replyResult.dataOrNull!;
      // Reply must authoritatively be signed by Barista's UID
      expect(replyMsg.senderId, equals(authorizedBarista.id));
      expect(replyMsg.senderName, equals(authorizedBarista.fullName));
      expect(replyMsg.senderRole, equals(SenderRole.barista));
    });

    test('6. Admin can access legitimate staff conversations across all customers', () async {
      // Customer 1 message
      userDb.setCurrentUser(customer1);
      final conv1Result = await chatRepository.getConversation();
      final conv1Id = conv1Result.dataOrNull!.id;
      await chatRepository.sendMessage(
        SendMessageRequest(conversationId: conv1Id, text: 'Customer 1 query'),
      );

      // Admin logs in
      userDb.setCurrentUser(adminUser);

      // Admin accesses all conversations
      final inboxResult = await chatRepository.getConversations();
      expect(inboxResult.isSuccess, isTrue);
      expect(inboxResult.dataOrNull!.any((c) => c.customerId == customer1.id), isTrue);

      // Admin reads Customer 1 messages
      final msgsResult = await chatRepository.getMessages(conv1Id);
      expect(msgsResult.isSuccess, isTrue);

      // Admin sends reply
      final adminReply = await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: conv1Id,
          text: 'Official Admin support response from Lambac.',
        ),
      );

      expect(adminReply.isSuccess, isTrue);
      expect(adminReply.dataOrNull!.senderRole, equals(SenderRole.admin));
      expect(adminReply.dataOrNull!.senderId, equals(adminUser.id));
    });

    test('7. Unauthorized direct-document and query access is denied', () async {
      // 1. Unauthenticated request
      userDb.setCurrentUser(null);
      final unauthConv = await chatRepository.getConversation();
      expect(unauthConv.isFailure, isTrue);
      expect(unauthConv.failureOrNull, isA<UnauthorizedFailure>());

      final unauthSend = await chatRepository.sendMessage(
        const SendMessageRequest(conversationId: 'conv_123', text: 'Hack'),
      );
      expect(unauthSend.isFailure, isTrue);
      expect(unauthSend.failureOrNull, isA<UnauthorizedFailure>());

      // 2. Staff without manageInbox permission
      userDb.setCurrentUser(unauthorizedEmployee);
      final unauthStaffLookup = await chatRepository.getConversation(customer1.id);
      expect(unauthStaffLookup.isFailure, isTrue);
      expect(unauthStaffLookup.failureOrNull, isA<ForbiddenFailure>());
      expect(unauthStaffLookup.failureOrNull?.message, contains('Forbidden'));
    });
  });
}

