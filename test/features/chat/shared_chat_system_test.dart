import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/presentation/screens/staff_inbox_screen.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/data/models/send_message_request.dart';
import 'package:lambac_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lambac_app/features/chat/domain/services/chat_realtime_service.dart';
import 'package:lambac_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:lambac_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Lambac Coffee Roastery — Shared Customer Chat for Barista and Admin', () {
    late InMemoryStorageService storageService;
    late MockChatRemoteDataSource chatDataSource;
    late ChatRepositoryImpl chatRepository;
    late ChatRealtimeService realtimeService;
    late MockUserDatabase userDb;
    late UserModel customerUser;
    late UserModel baristaUser;
    late UserModel adminUser;

    setUp(() {
      userDb = MockUserDatabase();
      userDb.seedDefaultUsers();

      customerUser = userDb.records['coffee.lover@lambac.com']!.user;
      baristaUser = userDb.records['barista.staff@lambac.com']!.user;
      adminUser = userDb.records['jmbautista0228@gmail.com']!.user;

      storageService = InMemoryStorageService();
      realtimeService = ChatRealtimeService();
      chatDataSource = MockChatRemoteDataSource(storageService: storageService);
      chatDataSource.resetForTesting();
      // Disable automated mock bot replies so human staff and admin handle replies manually
      chatDataSource.autoReplyEnabled = false;

      chatRepository = ChatRepositoryImpl(
        remoteDataSource: chatDataSource,
        storageService: storageService,
        realtimeService: realtimeService,
      );
    });

    Widget buildTestApp({
      required Widget child,
      required UserModel user,
      Key? key,
    }) {
      return ProviderScope(
        key: key ?? UniqueKey(),
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          chatRemoteDataSourceProvider.overrideWithValue(chatDataSource),
          chatRepositoryProvider.overrideWithValue(chatRepository),
          chatRealtimeServiceProvider.overrideWithValue(realtimeService),
          currentUserProvider.overrideWith((ref) => user),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('Full 12-Step Shared Chat Acceptance Test (Customer <-> Barista & Admin)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // -------------------------------------------------------------
      // Step 1: Customer sends message
      // -------------------------------------------------------------
      userDb.setCurrentUser(customerUser);

      await tester.pumpWidget(
        buildTestApp(
          user: customerUser,
          child: const ChatScreen(),
          key: const Key('customer_app_1'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Roastery Concierge'), findsOneWidget);

      const customerQuestion = 'Is my order ready?';
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, customerQuestion);
      await tester.pump();

      final sendBtn = find.byIcon(Icons.arrow_upward_rounded);
      expect(sendBtn, findsOneWidget);
      await tester.tap(sendBtn);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(customerQuestion), findsOneWidget);

      // -------------------------------------------------------------
      // Step 2: Barista receives it in operational inbox / chat
      // -------------------------------------------------------------
      userDb.setCurrentUser(baristaUser);

      await tester.pumpWidget(
        buildTestApp(
          user: baristaUser,
          child: const StaffInboxScreen(),
          key: const Key('barista_inbox_session'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Customer conversation preview is visible with last message
      expect(find.text(customerQuestion), findsOneWidget);
      // Unread indicator is present for Barista
      expect(find.text('1'), findsWidgets);

      // Barista opens the customer conversation
      await tester.pumpWidget(
        buildTestApp(
          user: baristaUser,
          child: ChatScreen(customerId: customerUser.id),
          key: const Key('barista_chat_session'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Barista can see the customer's question
      expect(find.text(customerQuestion), findsOneWidget);

      // -------------------------------------------------------------
      // Step 3: Admin can see the exact same conversation
      // -------------------------------------------------------------
      userDb.setCurrentUser(adminUser);

      await tester.pumpWidget(
        buildTestApp(
          user: adminUser,
          child: const StaffInboxScreen(),
          key: const Key('admin_inbox_session'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Admin also sees the customer conversation
      expect(find.text(customerQuestion), findsOneWidget);

      await tester.pumpWidget(
        buildTestApp(
          user: adminUser,
          child: ChatScreen(customerId: customerUser.id),
          key: const Key('admin_chat_session'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Admin sees the exact same message
      expect(find.text(customerQuestion), findsOneWidget);

      // -------------------------------------------------------------
      // Step 4: Barista replies
      // -------------------------------------------------------------
      userDb.setCurrentUser(baristaUser);
      const baristaReply = 'Yes, your order is ready for pickup.';

      final baristaSendResult = await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: 'conv_cust_${customerUser.id}',
          text: baristaReply,
        ),
      );
      expect(baristaSendResult.isSuccess, isTrue);
      expect(baristaSendResult.dataOrNull?.senderRole, SenderRole.barista);

      // -------------------------------------------------------------
      // Step 5: Customer receives reply in real time
      // -------------------------------------------------------------
      userDb.setCurrentUser(customerUser);

      await tester.pumpWidget(
        buildTestApp(
          user: customerUser,
          child: const ChatScreen(),
          key: const Key('customer_realtime_session'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text(baristaReply), findsOneWidget);

      // -------------------------------------------------------------
      // Step 6: Admin sees Barista's reply in real time
      // -------------------------------------------------------------
      userDb.setCurrentUser(adminUser);

      await tester.pumpWidget(
        buildTestApp(
          user: adminUser,
          child: ChatScreen(customerId: customerUser.id),
          key: const Key('admin_view_barista_reply'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text(baristaReply), findsOneWidget);

      // -------------------------------------------------------------
      // Step 7: Admin replies
      // -------------------------------------------------------------
      const adminReply = 'We have also packed a complimentary single-origin drip bag with your order!';

      final adminSendResult = await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: 'conv_cust_${customerUser.id}',
          text: adminReply,
        ),
      );
      expect(adminSendResult.isSuccess, isTrue);
      expect(adminSendResult.dataOrNull?.senderRole, SenderRole.admin);

      // -------------------------------------------------------------
      // Step 8: Customer receives Admin reply
      // -------------------------------------------------------------
      userDb.setCurrentUser(customerUser);

      await tester.pumpWidget(
        buildTestApp(
          user: customerUser,
          child: const ChatScreen(),
          key: const Key('customer_receives_admin_reply'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text(adminReply), findsOneWidget);

      // -------------------------------------------------------------
      // Step 9: Customer closes app (simulated by switching to empty screen)
      // -------------------------------------------------------------
      await tester.pumpWidget(
        buildTestApp(
          user: customerUser,
          child: const Scaffold(body: Center(child: Text('App Closed / Background'))),
          key: const Key('app_closed'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('App Closed / Background'), findsOneWidget);
      expect(find.text(customerQuestion), findsNothing);

      // -------------------------------------------------------------
      // Step 10: Customer returns
      // -------------------------------------------------------------
      await tester.pumpWidget(
        buildTestApp(
          user: customerUser,
          child: const ChatScreen(),
          key: const Key('customer_returns_to_app'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // -------------------------------------------------------------
      // Step 11: Entire conversation remains
      // -------------------------------------------------------------
      expect(find.text(customerQuestion), findsOneWidget);
      expect(find.text(baristaReply), findsOneWidget);
      expect(find.text(adminReply), findsOneWidget);

      // -------------------------------------------------------------
      // Step 12: No duplicate conversation was created (Single shared persistent thread)
      // -------------------------------------------------------------
      userDb.setCurrentUser(adminUser);
      final conversationsResult = await chatRepository.getConversations();
      expect(conversationsResult.isSuccess, isTrue);
      final allConversations = conversationsResult.dataOrNull!;

      // Ensure customer only has ONE conversation ID
      final matchingCustomerConvs = allConversations.where((c) => c.customerId == customerUser.id).toList();
      expect(matchingCustomerConvs.length, 1);
      expect(matchingCustomerConvs.first.id, 'conv_concierge');
    });

    test('Unread counts are maintained per-role and cleared upon viewing', () async {
      userDb.setCurrentUser(customerUser);

      // Customer sends a new inquiry
      const question = 'Can I customize the temperature?';
      await chatRepository.sendMessage(
        SendMessageRequest(
          conversationId: 'conv_cust_${customerUser.id}',
          text: question,
        ),
      );

      // Check unread counts on server
      final convResult = await chatDataSource.getConversation(customerUser.id);
      expect(convResult.isSuccess, isTrue);
      final conv = convResult.dataOrNull!;

      expect(conv.unreadForRole('barista'), 1);
      expect(conv.unreadForRole('employee'), 1);
      expect(conv.unreadForRole('admin'), 1);

      // Barista opens conversation -> clears Barista unread
      userDb.setCurrentUser(baristaUser);
      await chatRepository.markConversationAsRead(conv.id);

      final updatedConvResult = await chatDataSource.getConversation(customerUser.id);
      final updatedConv = updatedConvResult.dataOrNull!;

      // Barista unread cleared
      expect(updatedConv.unreadForRole('barista'), 0);
      expect(updatedConv.unreadForRole('employee'), 0);
      // Admin unread remains until Admin opens it
      expect(updatedConv.unreadForRole('admin'), 1);

      // Admin opens conversation -> clears Admin unread
      userDb.setCurrentUser(adminUser);
      await chatRepository.markConversationAsRead(conv.id);

      final adminClearedConvResult = await chatDataSource.getConversation(customerUser.id);
      final adminClearedConv = adminClearedConvResult.dataOrNull!;
      expect(adminClearedConv.unreadForRole('admin'), 0);
    });

    test('Access Control: Customer cannot query or access another customer conversation', () async {
      userDb.setCurrentUser(customerUser);

      // Attempt to access another customer's conversation
      final illicitResult = await chatDataSource.getConversation('usr_different_customer');
      expect(illicitResult.isFailure, isTrue);
      expect(illicitResult.failureOrNull?.message, contains('Forbidden'));

      // Customer can only access their own conversation via getConversations()
      final listResult = await chatDataSource.getConversations();
      expect(listResult.isSuccess, isTrue);
      expect(listResult.dataOrNull?.length, 1);
      expect(listResult.dataOrNull?.first.customerId, customerUser.id);
    });

    testWidgets('Order Context & Sender Identification are rendered accurately', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Admin views demo customer with active order
      userDb.setCurrentUser(adminUser);

      await tester.pumpWidget(
        buildTestApp(
          user: adminUser,
          child: const ChatScreen(customerId: 'usr_customer_demo'),
          key: const Key('admin_order_context_view'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Order context banner is visible
      expect(find.text('ORDER #LMB-1082 • Preparing'), findsOneWidget);
      expect(find.textContaining('Linked Order Context'), findsOneWidget);

      // Internal sender badges distinguish Barista from Customer
      expect(find.text('Barista'), findsWidgets);
      expect(find.text('Hiro (Head Roaster)'), findsWidgets);
    });
  });
}
