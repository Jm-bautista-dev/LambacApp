import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lambac_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:lambac_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/features/orders/presentation/providers/order_tracking_provider.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  late InMemoryStorageService storageService;
  late MockChatRemoteDataSource chatRemoteDataSource;
  late ChatRepositoryImpl chatRepository;
  late MockOrderRemoteDataSource orderRemoteDataSource;
  late OrderRepositoryImpl orderRepository;

  setUp(() {
    final userDb = MockUserDatabase();
    userDb.seedDefaultUsers();
    userDb.setCurrentUser(userDb.records['coffee.lover@lambac.com']!.user);

    storageService = InMemoryStorageService();
    chatRemoteDataSource = MockChatRemoteDataSource();
    chatRemoteDataSource.resetForTesting();
    chatRepository = ChatRepositoryImpl(
      remoteDataSource: chatRemoteDataSource,
      storageService: storageService,
    );
    orderRemoteDataSource = MockOrderRemoteDataSource();
    orderRepository = OrderRepositoryImpl(
      remoteDataSource: orderRemoteDataSource,
      storageService: storageService,
    );
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => MockUserDatabase().currentUser),
        chatRepositoryProvider.overrideWithValue(chatRepository),
        orderRepositoryProvider.overrideWithValue(orderRepository),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Chat & Order Tracking Widget Tests', () {
    testWidgets('ChatScreen renders header status, message bubbles, and inquiry chips', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const ChatScreen()));

      expect(find.text('Roastery Concierge'), findsOneWidget);
      expect(find.text('Master Barista Active'), findsOneWidget);
      expect(find.text('Recommend grind for V60'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('Welcome to Lambac Roastery Concierge'), findsOneWidget);
    });

    testWidgets('orderTrackingStreamProvider emits initial order status update', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Consumer(
            builder: (context, ref, _) {
              final asyncOrder = ref.watch(orderTrackingStreamProvider('ord_lmb_1082'));
              return asyncOrder.when(
                data: (order) => Text('Tracked Order #${order.orderNumber}'),
                loading: () => const Text('Loading...'),
                error: (err, _) => Text('Error: $err'),
              );
            },
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Tracked Order #LMB-1082'), findsOneWidget);
    });
  });
}
