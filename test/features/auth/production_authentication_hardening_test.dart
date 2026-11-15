import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/constants/app_constants.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/network/result.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_account_management_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/models/create_user_request.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/data/models/forgot_password_request.dart';
import 'package:lambac_app/features/auth/data/models/login_request.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/features/auth/data/models/request_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/models/reset_password_request.dart';
import 'package:lambac_app/features/auth/data/models/verify_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:lambac_app/features/products/presentation/providers/favorites_provider.dart';
import 'package:lambac_app/shared/models/auth_state.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Production Authentication Hardening Acceptance Suite — Lambac Coffee Roastery', () {
    late InMemoryStorageService storageService;
    late MockAuthRemoteDataSource authRemoteDataSource;
    late AuthRepositoryImpl authRepository;
    late MockUserDatabase userDb;
    late MockAccountManagementRemoteDataSource accountDataSource;

    setUp(() {
      storageService = InMemoryStorageService();
      authRemoteDataSource = MockAuthRemoteDataSource();
      authRepository = AuthRepositoryImpl(
        remoteDataSource: authRemoteDataSource,
        storageService: storageService,
      );
      userDb = MockUserDatabase();
      userDb.resetForTests();
      accountDataSource = MockAccountManagementRemoteDataSource();
      authRemoteDataSource.resetPasswordResetCooldownForTesting();
    });

    // -------------------------------------------------------------------------
    // CRITERION 1: Customer Registration with OTP & Email Verification
    // -------------------------------------------------------------------------
    test('1. Customer registration requires OTP issuance and verification before account creation', () async {
      const email = 'harden.customer@lambac.com';

      // Step 1: Request OTP
      final otpRes = await authRemoteDataSource.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Harden Customer',
          email: email,
          password: 'SecurePassword123',
        ),
      );
      expect(otpRes.isSuccess, isTrue);
      final rawOtp = authRemoteDataSource.getPendingOtpForTesting(email);
      expect(rawOtp, isNotNull);
      expect(rawOtp!.length, equals(6));

      // Step 2: Verify OTP
      final verifyRes = await authRemoteDataSource.verifyRegisterOtp(
        VerifyRegisterOtpRequest(
          email: email,
          otp: rawOtp,
        ),
      );
      expect(verifyRes.isSuccess, isTrue);
      final token = verifyRes.dataOrNull!.verificationToken;
      expect(token, isNotEmpty);

      // Step 3: Complete registration with token
      final regRes = await authRemoteDataSource.register(
        RegisterRequest(
          fullName: 'Harden Customer',
          email: email,
          password: 'SecurePassword123',
          verificationToken: token,
        ),
      );
      expect(regRes.isSuccess, isTrue);
      final createdUser = regRes.dataOrNull!.user;
      expect(createdUser.role, equals(UserRole.customer));
      expect(createdUser.status, equals(UserStatus.active));
      expect(createdUser.email, equals(email));
    });

    // -------------------------------------------------------------------------
    // CRITERION 2: Duplicate Email Protection
    // -------------------------------------------------------------------------
    test('2. Registration with duplicate email is strictly rejected before OTP issuance', () async {
      // coffee.lover@lambac.com is pre-seeded in MockUserDatabase
      final dupRes = await authRemoteDataSource.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Imposter User',
          email: 'coffee.lover@lambac.com',
          password: 'Password123',
        ),
      );
      expect(dupRes.isFailure, isTrue);
      expect(dupRes.failureOrNull, isA<ValidationFailure>());
      expect(dupRes.failureOrNull!.message, contains('already exists'));
    });

    // -------------------------------------------------------------------------
    // CRITERION 3: Login strictly requires Email + Password (NO OTP)
    // -------------------------------------------------------------------------
    test('3. Login strictly validates email and password with zero OTP requirements', () async {
      final loginRes = await authRemoteDataSource.login(
        const LoginRequest(
          email: 'coffee.lover@lambac.com',
          password: 'password123',
        ),
      );
      expect(loginRes.isSuccess, isTrue);
      final session = loginRes.dataOrNull!;
      expect(session.user.email, equals('coffee.lover@lambac.com'));
      expect(session.accessToken, isNotEmpty);
      expect(session.refreshToken, isNotEmpty);
    });

    // -------------------------------------------------------------------------
    // CRITERION 4: Email-Enumeration Protection in Password Reset
    // -------------------------------------------------------------------------
    test('4. Email-enumeration protection prevents probing non-existent accounts', () async {
      authRemoteDataSource.emailEnumerationProtection = true;

      // An unknown email returns success without leaking account existence
      final resetRes = await authRemoteDataSource.forgotPassword(
        const ForgotPasswordRequest(email: 'does_not_exist_99@lambac.com'),
      );
      expect(resetRes.isSuccess, isTrue);
    });

    // -------------------------------------------------------------------------
    // CRITERION 5: Password Reset Rate Limiting (Cooldown)
    // -------------------------------------------------------------------------
    test('5. Password reset requests enforce rate-limiting cooldown per email address', () async {
      const email = 'coffee.lover@lambac.com';

      // First request succeeds
      final res1 = await authRemoteDataSource.forgotPassword(
        const ForgotPasswordRequest(email: email),
      );
      expect(res1.isSuccess, isTrue);

      // Immediate second request triggers RateLimitFailure
      final res2 = await authRemoteDataSource.forgotPassword(
        const ForgotPasswordRequest(email: email),
      );
      expect(res2.isFailure, isTrue);
      expect(res2.failureOrNull, isA<RateLimitFailure>());
      expect(res2.failureOrNull!.message, contains('limit reached'));
    });

    // -------------------------------------------------------------------------
    // CRITERION 6: Password Reset Token Brute-Force Lockout
    // -------------------------------------------------------------------------
    test('6. 5 consecutive incorrect reset codes lock out the reset attempt', () async {
      const email = 'coffee.lover@lambac.com';

      // 4 incorrect attempts return ValidationFailure with remaining attempts
      for (int i = 0; i < 4; i++) {
        final failRes = await authRemoteDataSource.resetPassword(
          const ResetPasswordRequest(
            email: email,
            resetToken: '999999',
            newPassword: 'NewPassword123',
          ),
        );
        expect(failRes.isFailure, isTrue);
        expect(failRes.failureOrNull, isA<ValidationFailure>());
      }

      // 5th incorrect attempt
      final attempt5 = await authRemoteDataSource.resetPassword(
        const ResetPasswordRequest(
          email: email,
          resetToken: '999999',
          newPassword: 'NewPassword123',
        ),
      );
      expect(attempt5.isFailure, isTrue);

      // 6th attempt is hard-locked with RateLimitFailure
      final attempt6 = await authRemoteDataSource.resetPassword(
        const ResetPasswordRequest(
          email: email,
          resetToken: '123456', // Even with the valid code!
          newPassword: 'NewPassword123',
        ),
      );
      expect(attempt6.isFailure, isTrue);
      expect(attempt6.failureOrNull, isA<RateLimitFailure>());
      expect(attempt6.failureOrNull!.message, contains('Maximum password reset verification attempts exceeded'));
    });

    // -------------------------------------------------------------------------
    // CRITERION 7: Password Complexity Policy Enforcement
    // -------------------------------------------------------------------------
    test('7. Password reset rejects weak passwords violating complexity policy', () async {
      const email = 'coffee.lover@lambac.com';

      // Missing numbers
      final noNumber = await authRemoteDataSource.resetPassword(
        const ResetPasswordRequest(
          email: email,
          resetToken: '123456',
          newPassword: 'NoNumberPass',
        ),
      );
      expect(noNumber.isFailure, isTrue);
      expect(noNumber.failureOrNull, isA<ValidationFailure>());
      expect(noNumber.failureOrNull!.message, contains('and one number'));

      // Missing uppercase
      final noUpper = await authRemoteDataSource.resetPassword(
        const ResetPasswordRequest(
          email: email,
          resetToken: '123456',
          newPassword: 'nouppercase123',
        ),
      );
      expect(noUpper.isFailure, isTrue);
      expect(noUpper.failureOrNull, isA<ValidationFailure>());

      // Too short (< 8 chars)
      final tooShort = await authRemoteDataSource.resetPassword(
        const ResetPasswordRequest(
          email: email,
          resetToken: '123456',
          newPassword: 'Sh1',
        ),
      );
      expect(tooShort.isFailure, isTrue);
      expect(tooShort.failureOrNull, isA<ValidationFailure>());

      // Compliant password succeeds
      final compliant = await authRemoteDataSource.resetPassword(
        const ResetPasswordRequest(
          email: email,
          resetToken: '123456',
          newPassword: 'ValidHardenedPass2026',
        ),
      );
      expect(compliant.isSuccess, isTrue);
    });

    // -------------------------------------------------------------------------
    // CRITERION 8: Secure Barista Provisioning with Initial Password Setup
    // -------------------------------------------------------------------------
    test('8. Admin provisions Barista account with UserRole.barista and mustChangePassword=true', () async {
      final adminUser = userDb.getByEmail('jmbautista0228@gmail.com')!.user;
      userDb.setCurrentUser(adminUser);

      final result = await accountDataSource.createEmployee(
        const CreateEmployeeRequest(
          fullName: 'Barista Elena Santos',
          email: 'elena.santos@lambac.com',
          initialPassword: 'TempBaristaPass2026',
          permissions: [
            EmployeePermission.manageOrders,
            EmployeePermission.manageInbox,
            EmployeePermission.recordSales,
          ],
          mustChangePassword: true,
        ),
      );

      expect(result.isSuccess, isTrue);
      final barista = result.dataOrNull!;
      expect(barista.role, equals(UserRole.barista));
      expect(barista.status, equals(UserStatus.active));
      expect(barista.mustChangePassword, isTrue);
      expect(barista.permissions, contains(EmployeePermission.recordSales));
    });

    // -------------------------------------------------------------------------
    // CRITERION 9: Secure Admin Provisioning with Initial Password Setup
    // -------------------------------------------------------------------------
    test('9. Admin provisions another Admin with UserRole.admin and mustChangePassword=true', () async {
      final adminUser = userDb.getByEmail('jmbautista0228@gmail.com')!.user;
      userDb.setCurrentUser(adminUser);

      final result = await accountDataSource.createAdmin(
        const CreateAdminRequest(
          fullName: 'Operations Manager Diaz',
          email: 'ops.diaz@lambac.com',
          initialPassword: 'TempAdminPass2026',
          mustChangePassword: true,
        ),
      );

      expect(result.isSuccess, isTrue);
      final admin = result.dataOrNull!;
      expect(admin.role, equals(UserRole.admin));
      expect(admin.status, equals(UserStatus.active));
      expect(admin.mustChangePassword, isTrue);
    });

    // -------------------------------------------------------------------------
    // CRITERION 10: Non-Admin Caller Cannot Provision Staff (Forbidden)
    // -------------------------------------------------------------------------
    test('10. Non-admin caller is rejected with ForbiddenFailure when attempting to provision accounts', () async {
      final customer = userDb.getByEmail('coffee.lover@lambac.com')!.user;
      userDb.setCurrentUser(customer);

      final adminAttempt = await accountDataSource.createAdmin(
        const CreateAdminRequest(
          fullName: 'Rogue Admin',
          email: 'rogue.admin@lambac.com',
          initialPassword: 'RoguePassword123',
        ),
      );
      expect(adminAttempt.isFailure, isTrue);
      expect(adminAttempt.failureOrNull, isA<ForbiddenFailure>());

      final employeeAttempt = await accountDataSource.createEmployee(
        const CreateEmployeeRequest(
          fullName: 'Rogue Employee',
          email: 'rogue.emp@lambac.com',
          initialPassword: 'RoguePassword123',
        ),
      );
      expect(employeeAttempt.isFailure, isTrue);
      expect(employeeAttempt.failureOrNull, isA<ForbiddenFailure>());
    });

    // -------------------------------------------------------------------------
    // CRITERION 11: Disabled Account Rejection
    // -------------------------------------------------------------------------
    test('11. Disabled account is rejected on login and profile retrieval', () async {
      // Disable customer account
      final customerRecord = userDb.getByEmail('coffee.lover@lambac.com')!;
      customerRecord.user = customerRecord.user.copyWith(status: UserStatus.disabled);
      userDb.saveRecord(customerRecord);

      // Login is rejected
      final loginRes = await authRemoteDataSource.login(
        const LoginRequest(
          email: 'coffee.lover@lambac.com',
          password: 'password123',
        ),
      );
      expect(loginRes.isFailure, isTrue);
      expect(loginRes.failureOrNull, isA<UnauthorizedFailure>());
      expect(loginRes.failureOrNull!.message, contains('disabled'));

      // Session restoration / getProfile is also rejected
      userDb.setCurrentUser(customerRecord.user);
      final profileRes = await authRemoteDataSource.getProfile();
      expect(profileRes.isFailure, isTrue);
      expect(profileRes.failureOrNull, isA<UnauthorizedFailure>());
      expect(profileRes.failureOrNull!.message, contains('disabled'));
    });

    // -------------------------------------------------------------------------
    // CRITERION 12: Missing Profile Handling
    // -------------------------------------------------------------------------
    test('12. Missing profile in database returns NotFoundFailure and signs out session', () async {
      final ghostUser = UserModel(
        id: 'usr_ghost_999',
        email: 'ghost@lambac.com',
        fullName: 'Ghost User',
        role: UserRole.customer,
      );
      userDb.setCurrentUser(ghostUser);

      final profileRes = await authRemoteDataSource.getProfile();
      expect(profileRes.isFailure, isTrue);
      expect(profileRes.failureOrNull, isA<NotFoundFailure>());
      expect(userDb.currentUser, isNull);
    });

    // -------------------------------------------------------------------------
    // CRITERION 13: Role Restoration After App Restart
    // -------------------------------------------------------------------------
    test('13. Session restoration restores authentic user role and permissions from storage', () async {
      final customerUser = userDb.getByEmail('coffee.lover@lambac.com')!.user;
      userDb.setCurrentUser(customerUser);

      // Save credentials in storage service
      await storageService.setToken('jwt_persistent_token');
      await storageService.setRefreshToken('jwt_refresh_token');
      await storageService.setString(AppConstants.userDataKey, jsonEncode(customerUser.toJson()));

      // Simulate app restart with a fresh container
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          authRemoteDataSourceProvider.overrideWithValue(authRemoteDataSource),
        ],
      );

      // Wait for restoreSession() to finish
      await container.read(authNotifierProvider.notifier).restoreSession();

      final restoredUser = container.read(currentUserProvider);
      expect(restoredUser, isNotNull);
      expect(restoredUser!.email, equals('coffee.lover@lambac.com'));
      expect(restoredUser.role, equals(UserRole.customer));
      expect(container.read(isAuthenticatedProvider), isTrue);

      container.dispose();
    });

    // -------------------------------------------------------------------------
    // CRITERION 14: Comprehensive Logout In-Memory Teardown
    // -------------------------------------------------------------------------
    test('14. Logout cleanly flushes user state, cart items, favorites, and repository sessions', () async {
      final customerUser = userDb.getByEmail('coffee.lover@lambac.com')!.user;
      userDb.setCurrentUser(customerUser);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          authRemoteDataSourceProvider.overrideWithValue(authRemoteDataSource),
        ],
      );

      // Set authenticated user
      container.read(authNotifierProvider.notifier).state = AuthState.authenticated(
        user: customerUser,
        token: 'active_token',
      );

      // Keep favorites & cart alive
      final favSub = container.listen(favoritesProvider, (_, __) {});
      final cartSub = container.listen(cartNotifierProvider, (_, __) {});

      expect(container.read(currentUserProvider), isNotNull);

      // Perform logout
      await container.read(authNotifierProvider.notifier).logout();

      // Verify complete teardown
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(container.read(cartNotifierProvider).items, isEmpty);
      expect(container.read(favoritesProvider), isEmpty);

      favSub.close();
      cartSub.close();
      container.dispose();
    });
  });
}
