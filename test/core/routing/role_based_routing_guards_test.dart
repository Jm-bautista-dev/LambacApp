import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lambac_app/core/routing/app_routes.dart';
import 'package:lambac_app/core/routing/route_guards.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/shared/models/auth_state.dart';
import 'package:lambac_app/shared/models/user_model.dart';

import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('Strict Role-Based Routing & Authorization Guards Tests', () {
    const adminUser = UserModel(
      id: 'usr_admin',
      email: 'admin@lambac.com',
      fullName: 'Master Roaster Administrator',
      role: UserRole.admin,
      termsAccepted: true,
      acceptedTermsVersion: '1.0.0',
    );

    const staffUser = UserModel(
      id: 'usr_staff',
      email: 'barista@lambac.com',
      fullName: 'Shift Barista Staff',
      role: UserRole.employee,
      permissions: [EmployeePermission.manageOrders, EmployeePermission.recordSales],
      termsAccepted: true,
      acceptedTermsVersion: '1.0.0',
    );

    const customerUser = UserModel(
      id: 'usr_cust',
      email: 'customer@example.com',
      fullName: 'Coffee Lover Customer',
      role: UserRole.customer,
      termsAccepted: true,
      acceptedTermsVersion: '1.0.0',
    );

    GoRouterState createState(String location) {
      final state = MockGoRouterState();
      when(() => state.matchedLocation).thenReturn(location);
      when(() => state.uri).thenReturn(Uri.parse(location));
      return state;
    }

    testWidgets('ADMIN is strictly redirected away from Customer shopping and cart routes to Admin Dashboard', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState.authenticated(user: adminUser, token: 'mock_token'),
              ),
            ),
          ],
          child: Builder(
            builder: (context) {
              final container = ProviderScope.containerOf(context);

              // Attempting to access customer screens as Admin
              expect(appRouteGuard(context, createState(AppRoutes.home), container), equals(AppRoutes.adminDashboard));
              expect(appRouteGuard(context, createState(AppRoutes.products), container), equals(AppRoutes.adminDashboard));
              expect(appRouteGuard(context, createState(AppRoutes.cart), container), equals(AppRoutes.adminDashboard));
              expect(appRouteGuard(context, createState(AppRoutes.checkout), container), equals(AppRoutes.adminDashboard));
              expect(appRouteGuard(context, createState(AppRoutes.orders), container), equals(AppRoutes.adminDashboard));
              expect(appRouteGuard(context, createState(AppRoutes.profile), container), equals(AppRoutes.adminDashboard));
              expect(appRouteGuard(context, createState('/products/item-123'), container), equals(AppRoutes.adminDashboard));

              // Admin is allowed on all admin screens
              expect(appRouteGuard(context, createState(AppRoutes.adminDashboard), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.adminOrders), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.adminProducts), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.businessIntelligence), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.adminAccounts), container), isNull);

              // Admin is allowed on chat operations without redirection
              expect(appRouteGuard(context, createState(AppRoutes.chat), container), isNull);
              expect(appRouteGuard(context, createState('${AppRoutes.chat}?customerId=usr_cust'), container), isNull);

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('STAFF / BARTENDER is strictly redirected away from customer shopping and admin-only screens', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState.authenticated(user: staffUser, token: 'mock_token'),
              ),
            ),
          ],
          child: Builder(
            builder: (context) {
              final container = ProviderScope.containerOf(context);

              // Staff forbidden from customer shopping
              expect(appRouteGuard(context, createState(AppRoutes.home), container), equals(AppRoutes.staffOrders));
              expect(appRouteGuard(context, createState(AppRoutes.products), container), equals(AppRoutes.staffOrders));
              expect(appRouteGuard(context, createState(AppRoutes.cart), container), equals(AppRoutes.staffOrders));
              expect(appRouteGuard(context, createState(AppRoutes.checkout), container), equals(AppRoutes.staffOrders));

              // Staff forbidden from admin-only routes (Accounts, Analytics, BI, Admin Dashboard)
              expect(appRouteGuard(context, createState(AppRoutes.adminDashboard), container), equals(AppRoutes.staffOrders));
              expect(appRouteGuard(context, createState(AppRoutes.adminAccounts), container), equals(AppRoutes.staffOrders));
              expect(appRouteGuard(context, createState(AppRoutes.businessIntelligence), container), equals(AppRoutes.staffOrders));
              expect(appRouteGuard(context, createState(AppRoutes.forecasting), container), equals(AppRoutes.staffOrders));

              // Staff IS allowed on operational staff screens
              expect(appRouteGuard(context, createState(AppRoutes.staffOrders), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.staffSales), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.staffInboxRoute), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.staffProfile), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.staffChat), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.chat), container), isNull);
              expect(appRouteGuard(context, createState('${AppRoutes.chat}?customerId=usr_cust'), container), isNull);

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('CUSTOMER is allowed on shopping routes and strictly blocked from business/staff routes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState.authenticated(user: customerUser, token: 'mock_token'),
              ),
            ),
          ],
          child: Builder(
            builder: (context) {
              final container = ProviderScope.containerOf(context);

              // Customer allowed on shopping & account
              expect(appRouteGuard(context, createState(AppRoutes.home), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.products), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.cart), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.orders), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.profile), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.chat), container), isNull);

              // Customer blocked from Admin and Staff routes
              expect(appRouteGuard(context, createState(AppRoutes.adminDashboard), container), equals(AppRoutes.home));
              expect(appRouteGuard(context, createState(AppRoutes.adminProducts), container), equals(AppRoutes.home));
              expect(appRouteGuard(context, createState(AppRoutes.adminOrders), container), equals(AppRoutes.home));
              expect(appRouteGuard(context, createState(AppRoutes.staffOrders), container), equals(AppRoutes.home));
              expect(appRouteGuard(context, createState(AppRoutes.staffSales), container), equals(AppRoutes.home));
              expect(appRouteGuard(context, createState(AppRoutes.staffChat), container), equals(AppRoutes.home));

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('UNAUTHENTICATED users cannot access protected member or staff/admin routes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(const AuthState.unauthenticated()),
            ),
          ],
          child: Builder(
            builder: (context) {
              final container = ProviderScope.containerOf(context);

              // Public routes allowed
              expect(appRouteGuard(context, createState(AppRoutes.login), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.home), container), isNull);
              expect(appRouteGuard(context, createState(AppRoutes.products), container), isNull);

              // Protected routes redirect to login
              expect(appRouteGuard(context, createState(AppRoutes.cart), container), contains(AppRoutes.login));
              expect(appRouteGuard(context, createState(AppRoutes.orders), container), contains(AppRoutes.login));
              expect(appRouteGuard(context, createState(AppRoutes.chat), container), contains(AppRoutes.login));
              expect(appRouteGuard(context, createState(AppRoutes.staffChat), container), contains(AppRoutes.login));
              expect(appRouteGuard(context, createState(AppRoutes.adminDashboard), container), contains(AppRoutes.login));
              expect(appRouteGuard(context, createState(AppRoutes.staffOrders), container), contains(AppRoutes.login));

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('AUTHENTICATED user who has NOT accepted current terms is redirected to Terms & Conditions page', (tester) async {
      const unacceptedUser = UserModel(
        id: 'usr_unaccepted',
        email: 'unaccepted@lambac.com',
        fullName: 'Pending Terms Acceptance',
        role: UserRole.customer,
        termsAccepted: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                const AuthState.authenticated(user: unacceptedUser, token: 'mock_token'),
              ),
            ),
          ],
          child: Builder(
            builder: (context) {
              final container = ProviderScope.containerOf(context);

              // Must be intercepted to terms and conditions
              expect(appRouteGuard(context, createState(AppRoutes.home), container), equals(AppRoutes.termsAndConditions));
              expect(appRouteGuard(context, createState(AppRoutes.cart), container), equals(AppRoutes.termsAndConditions));
              expect(appRouteGuard(context, createState(AppRoutes.termsAndConditions), container), isNull);

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
