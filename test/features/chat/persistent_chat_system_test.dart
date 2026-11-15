import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lambac_app/features/chat/domain/services/chat_realtime_service.dart';
import 'package:lambac_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:lambac_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Lambac Coffee Roastery — Persistent Chat System & 15-Step Acceptance Tests', () {
    late InMemoryStorageService storageService;
    late MockChatRemoteDataSource chatDataSource;
    late ChatRepositoryImpl chatRepository;
    late ChatRealtimeService realtimeService;
    late MockUserDatabase userDb;
    late UserModel customerUser;
    late UserModel baristaUser;

    setUp(() {
      userDb = MockUserDatabase();
      userDb.seedDefaultUsers();

      customerUser = userDb.records['coffee.lover@lambac.com']!.user;
      baristaUser = userDb.records['barista.staff@lambac.com']!.user;
      userDb.setCurrentUser(customerUser);

      storageService = InMemoryStorageService();
      realtimeService = ChatRealtimeService();
      chatDataSource = MockChatRemoteDataSource(storageService: storageService);
      chatDataSource.resetForTesting();

      chatRepository = ChatRepositoryImpl(
        remoteDataSource: chatDataSource,
        storageService: storageService,
        realtimeService: realtimeService,
      );
    });

    Widget buildTestApp(Widget child, {Key? key}) {
      return ProviderScope(
        key: key ?? UniqueKey(),
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          chatRemoteDataSourceProvider.overrideWithValue(chatDataSource),
          chatRepositoryProvider.overrideWithValue(chatRepository),
          chatRealtimeServiceProvider.overrideWithValue(realtimeService),
          currentUserProvider.overrideWith((ref) => customerUser),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('Full 15-Step Acceptance Test: End-to-End Persistence Across Screen Navigation & App Restart', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // -------------------------------------------------------------
      // 1. Customer opens chat
      // -------------------------------------------------------------
      await tester.pumpWidget(buildTestApp(const ChatScreen(), key: const Key('chat_session_1')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Roastery Concierge'), findsOneWidget);
      expect(find.textContaining('Welcome to Lambac Roastery Concierge'), findsOneWidget);

      // -------------------------------------------------------------
      // 2. Customer sends a message
      // -------------------------------------------------------------
      const customerMsgText = 'Hello, I would like to ask about your coffee.';
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, customerMsgText);
      await tester.pump();

      final sendButton = find.byIcon(Icons.arrow_upward_rounded);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pump(const Duration(milliseconds: 50));

      // Customer message is visible immediately
      expect(find.text(customerMsgText), findsOneWidget);

      // -------------------------------------------------------------
      // 3. Barista receives it & 4. Barista replies & 5. Customer receives reply in real time
      // -------------------------------------------------------------
      // Wait for backend persistence & real-time broadcast
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      // Barista reply arrives via real-time stream without manual refresh
      expect(find.textContaining('Thank you for messaging Lambac Roastery'), findsOneWidget);

      // -------------------------------------------------------------
      // 6. Customer closes the chat
      // 7. Customer opens another screen (e.g. Products / Home)
      // -------------------------------------------------------------
      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            body: Center(child: Text('Products Screen')),
          ),
          key: const Key('products_screen'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Products Screen'), findsOneWidget);
      expect(find.text('Roastery Concierge'), findsNothing);

      // -------------------------------------------------------------
      // 8. Customer returns to Chat
      // 9. Both messages remain
      // -------------------------------------------------------------
      await tester.pumpWidget(buildTestApp(const ChatScreen(), key: const Key('chat_session_2')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text(customerMsgText), findsOneWidget);
      expect(find.textContaining('Thank you for messaging Lambac Roastery'), findsOneWidget);

      // -------------------------------------------------------------
      // 10. Customer closes the app (Simulated App Restart)
      // 11. Customer reopens the app with persistent StorageService
      // -------------------------------------------------------------
      // Create a completely fresh ProviderContainer and new ChatNotifier
      // simulating a brand-new process boot reading from persistent backend storage
      final brandNewChatDataSource = MockChatRemoteDataSource(storageService: storageService);
      final brandNewChatRepo = ChatRepositoryImpl(
        remoteDataSource: brandNewChatDataSource,
        storageService: storageService,
        realtimeService: realtimeService,
      );

      // -------------------------------------------------------------
      // 12. Customer opens Chat
      // 13. Entire conversation remains
      // -------------------------------------------------------------
      await tester.pumpWidget(
        ProviderScope(
          key: const Key('restarted_app'),
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
            chatRemoteDataSourceProvider.overrideWithValue(brandNewChatDataSource),
            chatRepositoryProvider.overrideWithValue(brandNewChatRepo),
            chatRealtimeServiceProvider.overrideWithValue(realtimeService),
            currentUserProvider.overrideWith((ref) => customerUser),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text(customerMsgText), findsOneWidget);
      expect(find.textContaining('Thank you for messaging Lambac Roastery'), findsOneWidget);

      // -------------------------------------------------------------
      // 14. Customer sends another message
      // 15. The conversation continues instead of creating a new conversation
      // -------------------------------------------------------------
      const secondMsgText = 'Do you offer whole beans for this roast?';
      await tester.enterText(find.byType(TextField), secondMsgText);
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text(customerMsgText), findsOneWidget);
      expect(find.text(secondMsgText), findsOneWidget);
    });

    test('Duplicate Message Protection: Real-Time replay or network retry does not duplicate messages', () async {
      final notifier = ChatNotifier(
        repository: chatRepository,
        currentUser: customerUser,
      );
      addTearDown(notifier.dispose);

      await notifier.loadChat();
      final conv = notifier.state.conversation!;
      final initialCount = notifier.state.messages.length;

      // Broadcast an existing message ID (simulating real-time replay or duplicate push)
      final existingMsg = notifier.state.messages.first;
      realtimeService.notifyMessageSent(existingMsg);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.messages.length, equals(initialCount));

      // Broadcast a brand new message
      final newMsg = MessageModel(
        id: 'msg_unique_dedup_test',
        conversationId: conv.id,
        senderId: 'barista_hiro',
        senderName: 'Hiro (Head Roaster)',
        senderRole: SenderRole.barista,
        text: 'Checking in on your brew method!',
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
      );

      realtimeService.notifyMessageSent(newMsg);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.messages.length, equals(initialCount + 1));

      // Re-broadcast the exact same message
      realtimeService.notifyMessageSent(newMsg);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Must remain at initialCount + 1 (no duplicate)
      expect(notifier.state.messages.length, equals(initialCount + 1));
    });

    testWidgets('Offline / Failed message state displays "Message wasn\'t sent" with Retry action', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const ChatScreen(), key: const Key('failed_chat_session')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Send a message that triggers the failure condition
      await tester.enterText(find.byType(TextField), 'fail_test network error');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text("Message wasn't sent"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
