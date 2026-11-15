import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lambac_app/core/config/app_config.dart';
import 'package:lambac_app/core/config/flavor_provider.dart';
import 'package:lambac_app/core/constants/app_constants.dart';
import 'package:lambac_app/core/routing/app_router.dart';
import 'package:lambac_app/core/routing/app_routes.dart';
import 'package:lambac_app/features/admin/presentation/screens/admin_profile_screen.dart';
import 'package:lambac_app/features/admin/presentation/screens/staff_operations_screen.dart';
import 'package:lambac_app/features/admin/presentation/screens/staff_profile_screen.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/shared/models/auth_state.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const customerUser = UserModel(
    id: 'usr_cust_test',
    email: 'kenji@lambac.com',
    fullName: 'Kenji Takahashi',
    role: UserRole.customer,
    termsAccepted: true,
    acceptedTermsVersion: AppConstants.currentTermsVersion,
  );

  const staffUser = UserModel(
    id: 'usr_staff_test',
    email: 'barista.staff@lambac.com',
    fullName: 'Sora Tanaka',
    role: UserRole.employee,
    permissions: [EmployeePermission.manageOrders, EmployeePermission.recordSales],
    termsAccepted: true,
    acceptedTermsVersion: AppConstants.currentTermsVersion,
  );

  const adminUser = UserModel(
    id: 'usr_admin_test',
    email: 'jmbautista0228@gmail.com',
    fullName: 'Master Roaster Administrator',
    role: UserRole.admin,
    termsAccepted: true,
    acceptedTermsVersion: AppConstants.currentTermsVersion,
  );

  group('Role-Based Shell Navigation Separation Tests', () {
    testWidgets('Customer Shell displays ONLY customer navigation (Home, Roastery, Cart, Orders, Profile)', (tester) async {
      MockUserDatabase().setCurrentUser(customerUser);
      final storage = InMemoryStorageService();
      await storage.setBool(AppConstants.onboardingSeenKey, true);
      await storage.setBool(AppConstants.customerTutorialCompletedKey, true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development()),
            storageServiceProvider.overrideWithValue(storage),
            currentUserProvider.overrideWithValue(customerUser),
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState.authenticated(user: customerUser, token: 'cust_token'),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      // Allow splash timer to complete
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 600));

      // Customer items MUST be present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Roastery'), findsOneWidget);
      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Admin & Staff Shell items MUST NOT be present
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Walk-In POS'), findsNothing);
      expect(find.text('Intelligence'), findsNothing);
      expect(find.text('My Shift'), findsNothing);
      expect(find.text('Control'), findsNothing);
    });

    testWidgets('Staff Shell displays ONLY staff operations navigation (Queue, POS, Concierge, My Shift)', (tester) async {
      MockUserDatabase().setCurrentUser(staffUser);
      final storage = InMemoryStorageService();
      await storage.setBool(AppConstants.staffTutorialCompletedKey, true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development()),
            storageServiceProvider.overrideWithValue(storage),
            currentUserProvider.overrideWithValue(staffUser),
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState.authenticated(user: staffUser, token: 'staff_token'),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      // Allow splash timer to complete and route to staff shell
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Staff items MUST be present in bottom navigation
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Concierge'), findsOneWidget);
      expect(find.text('My Shift'), findsOneWidget);
      expect(find.text('Walk-In POS'), findsNothing);

      // Customer shopping navigation MUST NOT be present
      expect(find.text('Home'), findsNothing);
      expect(find.text('Roastery'), findsNothing);
      expect(find.text('Cart'), findsNothing);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Intelligence'), findsNothing);
    });

    testWidgets('Admin Shell displays ONLY administrator governance navigation (Dashboard, Orders, Products, Intelligence, Control)', (tester) async {
      MockUserDatabase().setCurrentUser(adminUser);
      final storage = InMemoryStorageService();
      await storage.setBool(AppConstants.adminTutorialCompletedKey, true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development()),
            storageServiceProvider.overrideWithValue(storage),
            currentUserProvider.overrideWithValue(adminUser),
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState.authenticated(user: adminUser, token: 'admin_token'),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      // Allow splash timer to complete and route to admin shell
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Admin items MUST be present
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Intelligence'), findsOneWidget);
      expect(find.text('Control'), findsOneWidget);

      // Customer items MUST NOT be present
      expect(find.text('Home'), findsNothing);
      expect(find.text('Roastery'), findsNothing);
      expect(find.text('Cart'), findsNothing);
    });

    testWidgets('StaffOperationsScreen renders barista queue with status metrics', (tester) async {
      MockUserDatabase().setCurrentUser(staffUser);
      final storage = InMemoryStorageService();
      await storage.setBool(AppConstants.staffTutorialCompletedKey, true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(staffUser),
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: StaffOperationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Barista Operations Queue'), findsOneWidget);
      expect(find.textContaining('Flagship Store'), findsOneWidget);
    });

    testWidgets('StaffProfileScreen renders barista identity and shift sign out', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(staffUser),
            storageServiceProvider.overrideWithValue(InMemoryStorageService()),
          ],
          child: const MaterialApp(
            home: StaffProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Barista Station & Shift'), findsOneWidget);
      expect(find.text('STAFF / BARISTA'), findsOneWidget);
      expect(find.text('Sora Tanaka'), findsOneWidget);
      expect(find.text('End Shift & Sign Out'), findsOneWidget);
    });

    testWidgets('AdminProfileScreen renders administrator governance and sign out', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(adminUser),
            storageServiceProvider.overrideWithValue(InMemoryStorageService()),
          ],
          child: const MaterialApp(
            home: AdminProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Control Center'), findsOneWidget);
      expect(find.text('ADMINISTRATOR'), findsOneWidget);
      expect(find.text('Master Roaster Administrator'), findsOneWidget);
      expect(find.text('Account Management & RBAC'), findsOneWidget);
      expect(find.text('Sign Out of Business Platform'), findsOneWidget);
    });

    testWidgets('Navigating between routes and shells does not throw duplicate GlobalKey assertions', (tester) async {
      MockUserDatabase().setCurrentUser(staffUser);
      final storage = InMemoryStorageService();
      await storage.setBool(AppConstants.staffTutorialCompletedKey, true);

      late GoRouter router;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development()),
            storageServiceProvider.overrideWithValue(storage),
            currentUserProvider.overrideWithValue(staffUser),
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState.authenticated(user: staffUser, token: 'staff_token'),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      expect(find.text('Queue'), findsOneWidget);

      // Navigate between branches within Staff shell
      router.go(AppRoutes.staffInboxRoute);
      await tester.pumpAndSettle();

      router.go(AppRoutes.staffProfile);
      await tester.pumpAndSettle();

      router.go(AppRoutes.staffOrders);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
