import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/notifications/data/datasources/mock_notification_remote_datasource.dart';
import 'package:lambac_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:lambac_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:lambac_app/features/notifications/presentation/widgets/notification_center_sheet.dart';
import 'package:lambac_app/features/notifications/presentation/widgets/notification_preferences_sheet.dart';

void main() {
  late MockNotificationRemoteDataSource remoteDataSource;
  late NotificationRepositoryImpl repository;

  setUp(() {
    final userDb = MockUserDatabase();
    userDb.seedDefaultUsers();
    userDb.setCurrentUser(userDb.records['coffee.lover@lambac.com']!.user);

    remoteDataSource = MockNotificationRemoteDataSource();
    remoteDataSource.resetForTesting();
    repository = NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  Widget buildTestableWidget(Widget child) {
    final demoUser = MockUserDatabase().records['coffee.lover@lambac.com']!.user;
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(demoUser),
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Notification Center & Preferences Widget Tests', () {
    testWidgets('NotificationCenterSheet renders notification list', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const NotificationCenterSheet()));

      expect(find.text('Preferences'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Order Ready for Pickup'), findsOneWidget);
      expect(find.text('Barista Concierge Reply'), findsOneWidget);
    });

    testWidgets('NotificationPreferencesSheet renders preference switches', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const NotificationPreferencesSheet()));

      expect(find.text('Order Status Updates'), findsOneWidget);
      expect(find.text('Barista Concierge Messages'), findsOneWidget);
      expect(find.text('Special Roast Releases & Promos'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
    });
  });
}
