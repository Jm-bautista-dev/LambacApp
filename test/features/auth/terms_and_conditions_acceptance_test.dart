import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lambac_app/core/constants/app_constants.dart';
import 'package:lambac_app/core/routing/app_routes.dart';
import 'package:lambac_app/core/routing/route_guards.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/data/models/terms_and_conditions_data.dart';
import 'package:lambac_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/shared/models/auth_state.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

import 'package:mocktail/mocktail.dart';

class MockGoRouterState extends Mock implements GoRouterState {}
class MockBuildContext extends Mock implements BuildContext {}

GoRouterState createMockState(String location, {Map<String, String>? queryParams}) {
  final state = MockGoRouterState();
  final uri = Uri(path: location, queryParameters: queryParams);
  when(() => state.matchedLocation).thenReturn(location);
  when(() => state.uri).thenReturn(uri);
  return state;
}

void main() {
  group('Mandatory First-Login Terms & Conditions Acceptance Suite', () {
    late MockUserDatabase userDb;
    late MockAuthRemoteDataSource remoteDataSource;
    late InMemoryStorageService storageService;
    late AuthRepositoryImpl repository;

    // Test accounts
    final unacceptedCustomer = UserModel(
      id: 'usr_cust_unaccepted',
      email: 'newbie@lambaccoffee.com',
      fullName: 'New Customer',
      role: UserRole.customer,
      status: UserStatus.active,
      termsAccepted: false,
      acceptedTermsVersion: null,
      createdAt: DateTime(2026, 1, 1),
    );

    final acceptedCustomer = UserModel(
      id: 'usr_cust_accepted',
      email: 'accepted@lambaccoffee.com',
      fullName: 'Regular Customer',
      role: UserRole.customer,
      status: UserStatus.active,
      termsAccepted: true,
      acceptedTermsVersion: AppConstants.currentTermsVersion,
      termsAcceptedAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );

    final outdatedTermsCustomer = UserModel(
      id: 'usr_cust_outdated',
      email: 'outdated@lambaccoffee.com',
      fullName: 'Legacy Customer',
      role: UserRole.customer,
      status: UserStatus.active,
      termsAccepted: true,
      acceptedTermsVersion: '0.9.0', // Older version
      termsAcceptedAt: DateTime(2025, 6, 1),
      createdAt: DateTime(2025, 6, 1),
    );

    final newBarista = UserModel(
      id: 'usr_barista_new',
      email: 'barista@lambaccoffee.com',
      fullName: 'New Barista Staff',
      role: UserRole.employee,
      status: UserStatus.active,
      termsAccepted: false,
      acceptedTermsVersion: null,
      createdAt: DateTime(2026, 1, 1),
    );

    final newAdmin = UserModel(
      id: 'usr_admin_new',
      email: 'admin@lambaccoffee.com',
      fullName: 'New Roastery Admin',
      role: UserRole.admin,
      status: UserStatus.active,
      termsAccepted: false,
      acceptedTermsVersion: null,
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      userDb = MockUserDatabase();
      userDb.resetForTests();
      remoteDataSource = MockAuthRemoteDataSource();
      storageService = InMemoryStorageService();
      repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
    });

    // =========================================================================
    // 1. ROUTE GUARD INTERCEPTION TESTS
    // =========================================================================
    group('Route Guard Interception', () {
      test('1. Unaccepted Customer navigating to /home is intercepted to /terms-and-conditions', () {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
        );
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: unacceptedCustomer,
          token: 'token_unaccepted',
        );

        final mockState = createMockState(AppRoutes.home);

        final redirect = appRouteGuard(MockBuildContext(), mockState, container);
        expect(redirect, equals(AppRoutes.termsAndConditions));
        container.dispose();
      });

      test('2. Unaccepted Barista navigating to /staff/orders is intercepted to /terms-and-conditions', () {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
        );
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: newBarista,
          token: 'token_barista',
        );

        final mockState = createMockState(AppRoutes.staffOrders);

        final redirect = appRouteGuard(MockBuildContext(), mockState, container);
        expect(redirect, equals(AppRoutes.termsAndConditions));
        container.dispose();
      });

      test('3. Unaccepted Admin navigating to /admin is intercepted to /terms-and-conditions', () {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
        );
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: newAdmin,
          token: 'token_admin',
        );

        final mockState = createMockState(AppRoutes.adminDashboard);

        final redirect = appRouteGuard(MockBuildContext(), mockState, container);
        expect(redirect, equals(AppRoutes.termsAndConditions));
        container.dispose();
      });

      test('4. Returning user with accepted current terms proceeds to role home', () {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
        );
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: acceptedCustomer,
          token: 'token_accepted',
        );

        final mockState = createMockState(AppRoutes.home);

        final redirect = appRouteGuard(MockBuildContext(), mockState, container);
        expect(redirect, isNull, reason: 'Accepted user should not be redirected away from home');
        container.dispose();
      });

      test('5. Accepted user visiting /terms-and-conditions without mode=review is redirected to role home', () {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
        );
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: acceptedCustomer,
          token: 'token_accepted',
        );

        final mockState = createMockState(AppRoutes.termsAndConditions);

        final redirect = appRouteGuard(MockBuildContext(), mockState, container);
        expect(redirect, equals(AppRoutes.home));
        container.dispose();
      });

      test('6. User visiting /terms-and-conditions?mode=review is allowed to review even if accepted', () {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
        );
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: acceptedCustomer,
          token: 'token_accepted',
        );

        final mockState = createMockState(AppRoutes.termsAndConditions, queryParams: {'mode': 'review'});

        final redirect = appRouteGuard(MockBuildContext(), mockState, container);
        expect(redirect, isNull, reason: 'Review mode must allow reading active document');
        container.dispose();
      });
    });

    // =========================================================================
    // 2. TERMS VERSION BUMP & RENEWED ACCEPTANCE
    // =========================================================================
    group('Terms Version Bump & Governance', () {
      test('User with outdated version (0.9.0) is forced to review and accept version 1.0.0', () {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
        );
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: outdatedTermsCustomer,
          token: 'token_outdated',
        );

        // Verify helper
        expect(outdatedTermsCustomer.hasAcceptedTerms(AppConstants.currentTermsVersion), isFalse);

        final mockState = createMockState(AppRoutes.home);

        final redirect = appRouteGuard(MockBuildContext(), mockState, container);
        expect(redirect, equals(AppRoutes.termsAndConditions));
        container.dispose();
      });
    });

    // =========================================================================
    // 3. PERSISTENCE & REPOSITORY ACCEPTANCE
    // =========================================================================
    group('Acceptance Persistence & State Updating', () {
      test('acceptTerms persists termsAccepted=true, version, and timestamp to UserModel and storage', () async {
        // Register record in mock database
        userDb.saveRecord(UserDatabaseRecord(
          user: unacceptedCustomer,
          passwordHash: 'dummy_hash',
        ));
        userDb.setCurrentUser(unacceptedCustomer);

        final result = await repository.acceptTerms(version: AppConstants.currentTermsVersion);
        expect(result.isSuccess, isTrue);

        final updatedUser = result.dataOrNull!;
        expect(updatedUser.termsAccepted, isTrue);
        expect(updatedUser.acceptedTermsVersion, equals(AppConstants.currentTermsVersion));
        expect(updatedUser.termsAcceptedAt, isNotNull);
        expect(updatedUser.hasAcceptedTerms(AppConstants.currentTermsVersion), isTrue);

        // Check local storage persistence
        final storedJson = await storageService.getString(AppConstants.userDataKey);
        expect(storedJson, isNotNull);
        expect(storedJson, contains('"terms_accepted":true'));
        expect(storedJson, contains('"accepted_terms_version":"1.0.0"'));
      });
    });

    // =========================================================================
    // 4. ACCOUNT ISOLATION ACROSS SESSIONS
    // =========================================================================
    group('Account Isolation Across Sessions', () {
      test('Customer 1 accepting terms does NOT bypass terms gate for Customer 2', () async {
        // Customer 1 logs in and accepts
        userDb.saveRecord(UserDatabaseRecord(
          user: unacceptedCustomer,
          passwordHash: 'dummy_hash',
        ));
        userDb.setCurrentUser(unacceptedCustomer);
        final c1Accepted = await repository.acceptTerms(version: AppConstants.currentTermsVersion);
        expect(c1Accepted.isSuccess, isTrue);

        // Customer 1 logs out
        await repository.logout();
        userDb.setCurrentUser(null);

        // Customer 2 logs in (has not accepted)
        final customer2 = UserModel(
          id: 'usr_cust_2_fresh',
          email: 'cust2@test.com',
          fullName: 'Customer Two',
          role: UserRole.customer,
          status: UserStatus.active,
          termsAccepted: false,
          acceptedTermsVersion: null,
          createdAt: DateTime(2026, 1, 1),
        );

        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
        );
        container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
          user: customer2,
          token: 'token_c2',
        );

        final mockState = createMockState(AppRoutes.home);

        final redirect = appRouteGuard(MockBuildContext(), mockState, container);
        expect(redirect, equals(AppRoutes.termsAndConditions),
            reason: 'Customer 2 must be independently evaluated and blocked until accepting.');
        container.dispose();
      });
    });

    // =========================================================================
    // 5. DOCUMENT STRUCTURE INTEGRITY
    // =========================================================================
    group('Terms Document Schema & Integrity', () {
      test('Document contains exactly 10 comprehensive sections and active version metadata', () {
        const doc = TermsAndConditionsDocument.current;
        expect(doc.version, equals(AppConstants.currentTermsVersion));
        expect(doc.effectiveDate, equals(AppConstants.termsEffectiveDate));
        expect(doc.sections.length, equals(10));
        expect(doc.sections.first.title, contains('Acceptance of Terms'));
        expect(doc.sections.last.title, contains('Governing Law'));
        expect(doc.closingStatement.isNotEmpty, isTrue);
      });
    });
  });
}
