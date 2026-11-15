import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/analytics/data/datasources/mock_analytics_remote_datasource.dart';
import 'package:lambac_app/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:lambac_app/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/forecasting/data/datasources/mock_forecasting_remote_datasource.dart';
import 'package:lambac_app/features/forecasting/data/repositories/forecasting_repository_impl.dart';
import 'package:lambac_app/features/forecasting/presentation/providers/forecasting_provider.dart';
import 'package:lambac_app/features/prescriptive/data/datasources/mock_prescriptive_remote_datasource.dart';
import 'package:lambac_app/features/prescriptive/data/repositories/prescriptive_repository_impl.dart';
import 'package:lambac_app/features/prescriptive/presentation/providers/prescriptive_provider.dart';
import 'package:lambac_app/features/prescriptive/presentation/screens/business_intelligence_screen.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:lambac_app/features/sales/presentation/providers/sales_provider.dart';
import 'package:lambac_app/features/sales/presentation/screens/admin_sales_screen.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  late InMemoryStorageService storageService;
  late MockAnalyticsRemoteDataSource analyticsRemoteDataSource;
  late AnalyticsRepositoryImpl analyticsRepository;

  late MockForecastingRemoteDataSource forecastingRemoteDataSource;
  late ForecastingRepositoryImpl forecastingRepository;

  late MockPrescriptiveRemoteDataSource prescriptiveRemoteDataSource;
  late PrescriptiveRepositoryImpl prescriptiveRepository;

  late MockSalesRemoteDataSource salesRemoteDataSource;
  late SalesRepositoryImpl salesRepository;

  const adminUser = UserModel(
    id: 'usr_admin',
    email: 'admin@lambac.com',
    fullName: 'Master Roaster Admin',
    role: UserRole.admin,
  );

  setUp(() {
    storageService = InMemoryStorageService();

    analyticsRemoteDataSource = MockAnalyticsRemoteDataSource();
    analyticsRepository = AnalyticsRepositoryImpl(remoteDataSource: analyticsRemoteDataSource);

    forecastingRemoteDataSource = MockForecastingRemoteDataSource();
    forecastingRepository = ForecastingRepositoryImpl(remoteDataSource: forecastingRemoteDataSource);

    prescriptiveRemoteDataSource = MockPrescriptiveRemoteDataSource();
    prescriptiveRepository = PrescriptiveRepositoryImpl(remoteDataSource: prescriptiveRemoteDataSource);

    salesRemoteDataSource = MockSalesRemoteDataSource();
    salesRepository = SalesRepositoryImpl(remoteDataSource: salesRemoteDataSource);
  });

  group('Final Capstone Integration Tests: Customer & Business Journeys', () {
    testWidgets('1. Admin Centralized Sales Ledger Journey', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(adminUser),
            storageServiceProvider.overrideWithValue(storageService),
            salesRepositoryProvider.overrideWithValue(salesRepository),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const AdminSalesScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('Centralized Sales Ledger'), findsOneWidget);
      expect(find.text('All Transactions'), findsOneWidget);
    });

    testWidgets('2. Business Intelligence Journey: Descriptive + Forecasting + Prescriptive Hub', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(adminUser),
            storageServiceProvider.overrideWithValue(storageService),
            analyticsRepositoryProvider.overrideWithValue(analyticsRepository),
            forecastingRepositoryProvider.overrideWithValue(forecastingRepository),
            prescriptiveRepositoryProvider.overrideWithValue(prescriptiveRepository),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const BusinessIntelligenceScreen(initialTabIndex: 2),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('Business Intelligence Hub'), findsOneWidget);
      expect(find.text('3. Prescriptive'), findsOneWidget);
    });
  });
}
