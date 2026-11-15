import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lambac_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:lambac_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:lambac_app/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:lambac_app/features/admin/presentation/screens/admin_products_screen.dart';
import 'package:lambac_app/features/admin/presentation/screens/staff_inbox_screen.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:lambac_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

import 'package:lambac_app/features/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:lambac_app/features/analytics/data/datasources/mock_analytics_remote_datasource.dart';
import 'package:lambac_app/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:lambac_app/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:lambac_app/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:lambac_app/features/products/data/datasources/mock_product_remote_datasource.dart';
import 'package:lambac_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:lambac_app/features/products/presentation/providers/categories_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late MockAdminRemoteDataSource remoteDataSource;
  late AdminRepositoryImpl adminRepository;
  late InMemoryStorageService storageService;

  late MockOrderRemoteDataSource orderRemoteDataSource;
  late MockChatRemoteDataSource chatRemoteDataSource;
  late MockAnalyticsRemoteDataSource analyticsRemoteDataSource;
  late AnalyticsRepositoryImpl analyticsRepository;
  late MockProductRemoteDataSource productRemoteDataSource;
  late ProductRepositoryImpl productRepository;

  const adminUser = UserModel(
    id: 'usr_admin',
    email: 'admin@lambac.com',
    fullName: 'Master Roaster Admin',
    role: UserRole.admin,
  );

  setUp(() {
    MockUserDatabase().setCurrentUser(adminUser);
    storageService = InMemoryStorageService();
    storageService.setBool('admin_tutorial_completed_v1', true);
    orderRemoteDataSource = MockOrderRemoteDataSource();
    chatRemoteDataSource = MockChatRemoteDataSource();
    productRemoteDataSource = MockProductRemoteDataSource();
    productRepository = ProductRepositoryImpl(
      remoteDataSource: productRemoteDataSource,
      storageService: storageService,
    );
    analyticsRemoteDataSource = MockAnalyticsRemoteDataSource();
    analyticsRepository = AnalyticsRepositoryImpl(remoteDataSource: analyticsRemoteDataSource);
    remoteDataSource = MockAdminRemoteDataSource(
      orderRemoteDataSource: orderRemoteDataSource,
    );
    adminRepository = AdminRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(adminUser),
        storageServiceProvider.overrideWithValue(storageService),
        orderRemoteDataSourceProvider.overrideWithValue(orderRemoteDataSource),
        chatRemoteDataSourceProvider.overrideWithValue(chatRemoteDataSource),
        productRemoteDataSourceProvider.overrideWithValue(productRemoteDataSource),
        productRepositoryProvider.overrideWithValue(productRepository),
        analyticsRemoteDataSourceProvider.overrideWithValue(analyticsRemoteDataSource),
        analyticsRepositoryProvider.overrideWithValue(analyticsRepository),
        adminRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
        adminRepositoryProvider.overrideWithValue(adminRepository),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: child,
      ),
    );
  }

  group('Admin Dashboard & Management Screens Widget Tests', () {
    testWidgets('AdminDashboardScreen renders executive command center, KPIs, and charts', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AdminDashboardScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Executive Platform'), findsOneWidget);
      expect(find.text('Lambac Coffee Roastery'), findsOneWidget);
      expect(find.text('Sales Performance'), findsOneWidget);
    });

    testWidgets('AdminDashboardScreen renders without overflow on narrow viewport (150px)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(150, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(const AdminDashboardScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Executive Platform'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminOrdersScreen renders queue tabs and order status actions', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AdminOrdersScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Pickup Queue'), findsOneWidget);
    });

    testWidgets('AdminProductsScreen renders roastery products list with enable/disable switches', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AdminProductsScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Product Management'), findsOneWidget);
    });

    testWidgets('StaffInboxScreen renders concierge customer message threads', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const StaffInboxScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Customer Concierge Inbox'), findsOneWidget);
    });
  });
}
