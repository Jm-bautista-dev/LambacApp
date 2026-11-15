import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/data/models/send_message_request.dart';
import 'package:lambac_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lambac_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:lambac_app/features/notifications/data/datasources/mock_notification_remote_datasource.dart';
import 'package:lambac_app/features/notifications/data/models/app_notification_model.dart';
import 'package:lambac_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:lambac_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:lambac_app/shared/models/auth_state.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Production-Critical Fix — Customer Data Isolation Comprehensive Test Suite', () {
    late MockUserDatabase userDb;
    late MockNotificationRemoteDataSource notifDataSource;
    late NotificationRepositoryImpl notifRepository;
    late MockChatRemoteDataSource chatDataSource;
    late ChatRepositoryImpl chatRepository;
    late InMemoryStorageService storageService;

    // Distinct customer accounts with unique Firebase UIDs
    final customer1 = UserModel(
      id: 'usr_c1_alpha_101',
      email: 'customer1@test.com',
      fullName: 'Alice Roastery',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    final customer2 = UserModel(
      id: 'usr_c2_bravo_202',
      email: 'customer2@test.com',
      fullName: 'Bob Roastery',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 2),
    );

    // Authorized staff account
    final baristaUser = UserModel(
      id: 'usr_barista_staff_303',
      email: 'barista@lambaccoffee.com',
      fullName: 'Kenji Barista',
      role: UserRole.employee,
      status: UserStatus.active,
      permissions: const [EmployeePermission.manageInbox],
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      userDb = MockUserDatabase();
      notifDataSource = MockNotificationRemoteDataSource();
      notifDataSource.resetForTesting();
      notifRepository = NotificationRepositoryImpl(remoteDataSource: notifDataSource);

      chatDataSource = MockChatRemoteDataSource();
      chatDataSource.resetForTesting();
      storageService = InMemoryStorageService();
      chatRepository = ChatRepositoryImpl(
        remoteDataSource: chatDataSource,
        storageService: storageService,
      );
    });

    // =========================================================================
    // TEST A: Customer Notification Isolation
    // =========================================================================
    group('Test A — Customer Notification Isolation', () {
      test('Customer 1 notifications and unread counts are strictly isolated from Customer 2', () async {
        // 1. Seed Customer 1 with 3 notifications (2 unread, 1 read)
        notifDataSource.addNotificationForUser(
          customer1.id,
          AppNotificationModel(
            id: 'notif_c1_1',
            title: 'Order LMB-101 Confirmed',
            body: 'Your single origin pour-over is being brewed.',
            type: NotificationType.orderStatus,
            deepLinkPath: '/orders/ord_101',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
        );
        notifDataSource.addNotificationForUser(
          customer1.id,
          AppNotificationModel(
            id: 'notif_c1_2',
            title: 'Concierge Message',
            body: 'Barista replied to your coffee inquiry.',
            type: NotificationType.chatMessage,
            deepLinkPath: '/chat',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        );
        notifDataSource.addNotificationForUser(
          customer1.id,
          AppNotificationModel(
            id: 'notif_c1_3',
            title: 'Welcome to Lambac Roastery',
            body: 'Enjoy our signature roasts.',
            type: NotificationType.promo,
            deepLinkPath: '/home',
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        );

        // 2. Customer 1 logs in
        userDb.setCurrentUser(customer1);
        final c1NotifsResult = await notifRepository.getNotifications();
        expect(c1NotifsResult.isSuccess, isTrue);

        final c1List = c1NotifsResult.dataOrNull!;
        expect(c1List.length, equals(3));
        final c1Unread = c1List.where((n) => !n.isRead).length;
        expect(c1Unread, equals(2));

        // 3. Customer 1 logs out
        userDb.setCurrentUser(null);
        notifRepository.clearSession();

        // 4. Customer 2 logs in (currently zero notifications)
        userDb.setCurrentUser(customer2);
        final c2InitialResult = await notifRepository.getNotifications();
        expect(c2InitialResult.isSuccess, isTrue);
        expect(c2InitialResult.dataOrNull!, isEmpty, reason: 'Must show genuine empty state without fallback to Customer 1');

        // 5. Customer 2 receives 1 notification
        notifDataSource.addNotificationForUser(
          customer2.id,
          AppNotificationModel(
            id: 'notif_c2_1',
            title: 'Customer 2 Harvest Alert',
            body: 'Geisha Lot #12 arrived.',
            type: NotificationType.promo,
            deepLinkPath: '/home',
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );

        final c2UpdatedResult = await notifRepository.getNotifications();
        expect(c2UpdatedResult.isSuccess, isTrue);
        final c2List = c2UpdatedResult.dataOrNull!;
        expect(c2List.length, equals(1));
        expect(c2List.first.id, equals('notif_c2_1'));
        expect(c2List.first.isRead, isFalse);

        // 6. Customer 2 marks their notification as read
        await notifRepository.markAsRead('notif_c2_1');

        // 7. Customer 2 logs out and Customer 1 logs back in
        userDb.setCurrentUser(null);
        notifRepository.clearSession();
        userDb.setCurrentUser(customer1);

        final c1ReturnResult = await notifRepository.getNotifications();
        expect(c1ReturnResult.isSuccess, isTrue);
        final c1ReturnList = c1ReturnResult.dataOrNull!;
        // Verify Customer 1 still has 3 notifications with 2 unread (unaffected by Customer 2)
        expect(c1ReturnList.length, equals(3));
        expect(c1ReturnList.where((n) => !n.isRead).length, equals(2));
      });
    });

    // =========================================================================
    // TEST B: Customer Chat & Conversation Isolation
    // =========================================================================
    group('Test B — Customer Chat & Conversation Isolation', () {
      test('Customer 1 conversation and messages are forbidden to Customer 2; staff can respond', () async {
        // 1. Customer 1 logs in and starts a conversation
        userDb.setCurrentUser(customer1);
        final c1ConvResult = await chatRepository.getConversation();
        expect(c1ConvResult.isSuccess, isTrue);
        final c1ConvId = c1ConvResult.dataOrNull!.id;
        expect(c1ConvId, equals('conv_cust_${customer1.id}'));

        // Customer 1 sends a confidential message
        final c1SendResult = await chatRepository.sendMessage(
          SendMessageRequest(
            conversationId: c1ConvId,
            text: 'Hello, this is Customer 1 private message.',
          ),
        );
        expect(c1SendResult.isSuccess, isTrue);

        // 2. Customer 1 logs out
        userDb.setCurrentUser(null);
        chatRepository.clearSession();

        // 3. Customer 2 logs in
        userDb.setCurrentUser(customer2);
        final c2ConvResult = await chatRepository.getConversation();
        expect(c2ConvResult.isSuccess, isTrue);
        final c2ConvId = c2ConvResult.dataOrNull!.id;
        expect(c2ConvId, equals('conv_cust_${customer2.id}'));
        expect(c2ConvId, isNot(equals(c1ConvId)));

        // Customer 2 messages query should only contain Customer 2 messages
        final c2MsgsResult = await chatRepository.getMessages(c2ConvId);
        expect(c2MsgsResult.isSuccess, isTrue);
        expect(c2MsgsResult.dataOrNull!.any((m) => m.text.contains('Customer 1')), isFalse);

        // 4. Unauthorized direct read: Customer 2 attempts to open Customer 1's conversation
        final directReadResult = await chatRepository.getMessages(c1ConvId);
        expect(directReadResult.isFailure, isTrue);
        expect(directReadResult.failureOrNull, isA<ForbiddenFailure>());

        // 5. Unauthorized direct write: Customer 2 attempts to post into Customer 1's conversation
        final directWriteResult = await chatRepository.sendMessage(
          SendMessageRequest(
            conversationId: c1ConvId,
            text: 'Unauthorized injection attempt',
          ),
        );
        expect(directWriteResult.isFailure, isTrue);
        expect(directWriteResult.failureOrNull, isA<ForbiddenFailure>());

        // 6. Authorized Staff Access: Barista can open Customer 1 conversation and reply
        userDb.setCurrentUser(baristaUser);
        final staffReadResult = await chatRepository.getMessages(c1ConvId);
        expect(staffReadResult.isSuccess, isTrue);
        expect(staffReadResult.dataOrNull!.any((m) => m.text == 'Hello, this is Customer 1 private message.'), isTrue);

        final staffReplyResult = await chatRepository.sendMessage(
          SendMessageRequest(
            conversationId: c1ConvId,
            text: 'Hello Customer 1, Barista here to assist you!',
          ),
        );
        expect(staffReplyResult.isSuccess, isTrue);
        expect(staffReplyResult.dataOrNull!.senderRole, equals(SenderRole.barista));

        // 7. Customer 1 logs back in and sees their conversation + barista reply
        userDb.setCurrentUser(null);
        chatRepository.clearSession();
        userDb.setCurrentUser(customer1);

        final c1FinalMsgs = await chatRepository.getMessages(c1ConvId);
        expect(c1FinalMsgs.isSuccess, isTrue);
        final texts = c1FinalMsgs.dataOrNull!.map((m) => m.text).toList();
        expect(texts, contains('Hello, this is Customer 1 private message.'));
        expect(texts, contains('Hello Customer 1, Barista here to assist you!'));
      });
    });

    // =========================================================================
    // TEST C: Real-time Stream Isolation
    // =========================================================================
    group('Test C — Real-time Stream Isolation', () {
      test('Customer 1 real-time notifications stream emits only Customer 1 events', () async {
        userDb.setCurrentUser(customer1);

        final stream = notifRepository.watchNotifications();
        final emittedBatches = <List<AppNotificationModel>>[];

        final sub = stream.listen((batch) {
          emittedBatches.add(batch);
        });

        // Add notification for Customer 1
        notifDataSource.addNotificationForUser(
          customer1.id,
          AppNotificationModel(
            id: 'live_notif_c1',
            title: 'Live Alert for C1',
            body: 'Fresh roast is ready',
            type: NotificationType.orderStatus,
            deepLinkPath: '/orders/1',
            createdAt: DateTime.now(),
          ),
        );

        // Add notification for Customer 2 while Customer 1 stream is active
        notifDataSource.addNotificationForUser(
          customer2.id,
          AppNotificationModel(
            id: 'live_notif_c2',
            title: 'Live Alert for C2',
            body: 'Private alert for C2',
            type: NotificationType.orderStatus,
            deepLinkPath: '/orders/2',
            createdAt: DateTime.now(),
          ),
        );

        // Allow microtask cycle to flush stream
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        // Verify Customer 1 never received live_notif_c2
        final allReceived = emittedBatches.expand((b) => b).toList();
        expect(allReceived.any((n) => n.id == 'live_notif_c1'), isTrue);
        expect(allReceived.any((n) => n.id == 'live_notif_c2'), isFalse);
      });
    });

    // =========================================================================
    // TEST D: Complete Session Switching Lifecycle & State Invalidation
    // =========================================================================
    group('Test D — Session Switching Lifecycle', () {
      test('Riverpod container invalidation on logout cleanly resets all customer state', () async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
            notificationRemoteDataSourceProvider.overrideWithValue(notifDataSource),
            chatRemoteDataSourceProvider.overrideWithValue(chatDataSource),
          ],
        );

        // Keep notifiers alive with active listeners to simulate mounted UI
        final notifSub = container.listen(notificationsNotifierProvider, (_, __) {});
        final chatSub = container.listen(chatNotifierProvider, (_, __) {});

        // 1. Initial State: Unauthenticated (wait for initial restoreSession to resolve)
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(container.read(currentUserProvider), isNull);
        expect(container.read(notificationsNotifierProvider).notifications, isEmpty);
        expect(container.read(chatNotifierProvider).conversation, isNull);

        // 2. Pre-seed notifications for C1
        notifDataSource.addNotificationForUser(
          customer1.id,
          AppNotificationModel(
            id: 'sess_notif_c1',
            title: 'C1 Notification',
            body: 'Private body',
            type: NotificationType.orderStatus,
            deepLinkPath: '/home',
            createdAt: DateTime.now(),
          ),
        );

        // Customer 1 logs in
        userDb.setCurrentUser(customer1);
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: customer1,
          token: 'token_c1',
        );

        // Customer 1 loads chat and notifications
        await container.read(notificationsNotifierProvider.notifier).loadNotifications();
        await container.read(chatNotifierProvider.notifier).loadChat();

        expect(container.read(currentUserProvider)?.id, equals(customer1.id));
        expect(container.read(notificationsNotifierProvider).notifications.length, equals(1));
        expect(container.read(chatNotifierProvider).conversation?.customerId, equals(customer1.id));

        // 3. Customer 1 logs out: simulate full logout teardown
        await container.read(authNotifierProvider.notifier).logout();
        userDb.setCurrentUser(null);

        // Verify unauthenticated state and complete flush
        expect(container.read(currentUserProvider), isNull);
        expect(container.read(notificationsNotifierProvider).notifications, isEmpty);
        expect(container.read(chatNotifierProvider).conversation, isNull);

        // 4. Customer 2 logs in
        userDb.setCurrentUser(customer2);
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: customer2,
          token: 'token_c2',
        );

        await container.read(notificationsNotifierProvider.notifier).loadNotifications();
        await container.read(chatNotifierProvider.notifier).loadChat();

        // Verify Customer 2 has isolated state without transient leakage of Customer 1
        expect(container.read(currentUserProvider)?.id, equals(customer2.id));
        expect(container.read(notificationsNotifierProvider).notifications, isEmpty);
        expect(container.read(chatNotifierProvider).conversation?.customerId, equals(customer2.id));

        notifSub.close();
        chatSub.close();
        container.dispose();
      });
    });

    // =========================================================================
    // TEST E: Authorization Regression & Privilege Escalation Prevention
    // =========================================================================
    group('Test E — Authorization Regression & Privilege Protection', () {
      test('Customer cannot spoof customerId parameter to load another user chat', () async {
        userDb.setCurrentUser(customer2);

        final notifier = ChatNotifier(
          repository: chatRepository,
          currentUser: customer2,
        );

        // Customer 2 attempts to pass Customer 1's ID into loadChat
        await notifier.loadChat(customer1.id);

        // Server and notifier enforce customer identity: stays customer2
        expect(notifier.state.conversation?.customerId, equals(customer2.id));
        expect(notifier.state.conversation?.customerId, isNot(equals(customer1.id)));

        notifier.dispose();
      });

      test('Unauthenticated user receives empty or unauthenticated state without crashes', () {
        final unauthNotif = NotificationNotifier(
          repository: notifRepository,
          currentUser: null,
        );
        expect(unauthNotif.state.isLoading, isFalse);
        expect(unauthNotif.state.notifications, isEmpty);
        expect(unauthNotif.state.unreadCount, equals(0));

        final unauthChat = ChatNotifier(
          repository: chatRepository,
          currentUser: null,
        );
        expect(unauthChat.state.isLoading, isFalse);
        expect(unauthChat.state.conversation, isNull);
        expect(unauthChat.state.messages, isEmpty);
      });
    });
  });
}
