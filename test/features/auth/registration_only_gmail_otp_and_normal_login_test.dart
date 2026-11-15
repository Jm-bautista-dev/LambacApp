import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/network/result.dart';
import 'package:lambac_app/core/services/email_service.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/data/models/login_request.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/features/auth/data/models/request_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/models/verify_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lambac_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Production Fix 01: Registration-Only Gmail OTP & Normal Customer Login Suite', () {
    late MockAuthRemoteDataSource remoteDataSource;
    late AuthRepository authRepository;
    late MockUserDatabase mockDb;

    setUp(() {
      remoteDataSource = MockAuthRemoteDataSource();
      authRepository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: InMemoryStorageService(),
      );
      mockDb = MockUserDatabase();
      MockAuthRemoteDataSource.resetLoginOtps();
    });

    // -------------------------------------------------------------------------
    // TEST 1: Customer Registration Requires 6-Digit OTP Before Account Creation
    // -------------------------------------------------------------------------
    test('1. Customer registration requires 6-digit OTP dispatched to Gmail before account creation', () async {
      const email = 'new.coffee.lover@lambac.com';
      const name = 'Maria Santos';
      const password = 'Password2026!';

      // A. Account does not exist yet
      expect(mockDb.getByEmail(email), isNull);

      // B. Public customer registration requests OTP
      final otpResult = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: name,
          email: email,
          password: password,
          phoneNumber: '09171112233',
        ),
      );

      expect(otpResult.isSuccess, isTrue);
      final otpData = otpResult.dataOrNull!;
      expect(otpData.email, equals(email));
      expect(otpData.resendCooldownSeconds, equals(45));
      expect(otpData.expiresInSeconds, equals(300));

      // OTP was dispatched to email
      final pendingOtp = remoteDataSource.getPendingOtpForTesting(email);
      expect(pendingOtp, isNotNull);
      expect(pendingOtp!.length, equals(6));
      expect(RegExp(r'^\d{6}$').hasMatch(pendingOtp), isTrue);

      // Account still not in user database before verification
      expect(mockDb.getByEmail(email), isNull);

      // C. Submit valid OTP to receive verification token
      final verifyOtpResult = await authRepository.verifyRegisterOtp(
        VerifyRegisterOtpRequest(
          email: email,
          otp: pendingOtp,
        ),
      );

      expect(verifyOtpResult.isSuccess, isTrue);
      final vToken = verifyOtpResult.dataOrNull?.verificationToken;
      expect(vToken, isNotNull);
      expect(vToken!.startsWith('reg_vtok_'), isTrue);

      // D. Finalize registration with verification token
      final registerResult = await authRepository.register(
        RegisterRequest(
          fullName: name,
          email: email,
          password: password,
          phoneNumber: '09171112233',
          verificationToken: vToken,
        ),
      );

      expect(registerResult.isSuccess, isTrue);
      final registeredUser = registerResult.dataOrNull!.user;
      expect(registeredUser.email, equals(email));
      expect(registeredUser.role, equals(UserRole.customer));
      expect(registeredUser.isRegistrationVerified, isTrue);
      expect(registeredUser.registrationVerifiedAt, isNotNull);

      // Persisted in mock database with verified status
      final persistedEntry = mockDb.getByEmail(email);
      expect(persistedEntry, isNotNull);
      expect(persistedEntry!.user.isRegistrationVerified, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 2: Normal Customer Login Uses Email + Password Directly (NO OTP)
    // -------------------------------------------------------------------------
    test('2. Normal customer login authenticates via email & password without dispatching any OTP', () async {
      const email = 'coffee.lover@lambac.com';
      const password = 'password123';

      // Ensure customer exists in database
      final existingEntry = mockDb.getByEmail(email);
      expect(existingEntry, isNotNull);
      expect(existingEntry!.user.role, equals(UserRole.customer));
      expect(existingEntry.user.isRegistrationVerified, isTrue);

      // Authenticate via normal login
      final loginResult = await authRepository.login(
        const LoginRequest(email: email, password: password),
      );

      expect(loginResult.isSuccess, isTrue);
      final authResponse = loginResult.dataOrNull!;
      expect(authResponse.user.email, equals(email));
      expect(authResponse.user.role, equals(UserRole.customer));
      expect(authResponse.user.isRegistrationVerified, isTrue);
      expect(authResponse.accessToken.isNotEmpty, isTrue);

      // Verify NO registration OTP was ever queued or dispatched for this email
      expect(remoteDataSource.getPendingOtpForTesting(email), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST 3: Logout and Re-Login Authenticates Immediately (NO OTP)
    // -------------------------------------------------------------------------
    test('3. Subsequent customer logins after logout authenticate immediately without OTP', () async {
      const email = 'coffee.lover@lambac.com';
      const password = 'password123';

      // 1. Initial Login
      final firstLogin = await authRepository.login(
        const LoginRequest(email: email, password: password),
      );
      expect(firstLogin.isSuccess, isTrue);

      // 2. User logs out
      final logoutResult = await authRepository.logout();
      expect(logoutResult.isSuccess, isTrue);

      // 3. User logs back in
      final secondLogin = await authRepository.login(
        const LoginRequest(email: email, password: password),
      );
      expect(secondLogin.isSuccess, isTrue);
      expect(secondLogin.dataOrNull?.user.email, equals(email));
      expect(secondLogin.dataOrNull?.user.role, equals(UserRole.customer));

      // Still no OTP queued or sent
      expect(remoteDataSource.getPendingOtpForTesting(email), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST 4: App Restart / Session Restoration Restores Customer Directly
    // -------------------------------------------------------------------------
    test('4. App restart / session restoration restores authenticated customer session with no OTP', () async {
      const email = 'coffee.lover@lambac.com';
      const password = 'password123';

      // Login to persist session into storage
      final loginResult = await authRepository.login(
        const LoginRequest(email: email, password: password),
      );
      expect(loginResult.isSuccess, isTrue);

      // Simulate App Restart by retrieving profile from repository
      final restoredProfileResult = await authRepository.getProfile();
      expect(restoredProfileResult.isSuccess, isTrue);
      final restoredUser = restoredProfileResult.dataOrNull!;
      expect(restoredUser.email, equals(email));
      expect(restoredUser.role, equals(UserRole.customer));
      expect(restoredUser.isRegistrationVerified, isTrue);

      // Session restoration did not require or trigger OTP
      expect(remoteDataSource.getPendingOtpForTesting(email), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST 5: Unverified Customer Account is Rejected
    // -------------------------------------------------------------------------
    test('5. Unverified customer account attempt to log in is rejected with verification failure', () async {
      const unverifiedEmail = 'unverified.customer@lambac.com';
      const password = 'password123';

      // Directly seed an unverified customer with no legacy proof
      final unverifiedUser = UserModel(
        id: 'usr_unverified_999',
        email: unverifiedEmail,
        fullName: 'Unverified Customer',
        role: UserRole.customer,
        status: UserStatus.active,
        mustChangePassword: false,
        loyaltyPoints: 0,
        termsAccepted: false,
        isRegistrationVerified: false,
        createdAt: DateTime.now(),
      );

      mockDb.saveRecord(UserDatabaseRecord(
        user: unverifiedUser,
        passwordHash: mockDb.getByEmail('coffee.lover@lambac.com')!.passwordHash,
      ));

      final loginResult = await authRepository.login(
        const LoginRequest(email: unverifiedEmail, password: password),
      );

      expect(loginResult.isFailure, isTrue);
      expect(loginResult.failureOrNull?.message, contains('Account registration has not been verified'));
    });

    // -------------------------------------------------------------------------
    // TEST 6: Legacy Customer Accounts with Proof are Migrated
    // -------------------------------------------------------------------------
    test('6. Legacy customer accounts with existing activity/terms are migrated and allowed to log in', () async {
      const legacyEmail = 'legacy.customer@lambac.com';
      const password = 'password123';

      // Seed a legacy customer with loyalty points & accepted terms, but isRegistrationVerified=false
      final legacyUser = UserModel(
        id: 'usr_legacy_101',
        email: legacyEmail,
        fullName: 'Legacy Loyal Customer',
        role: UserRole.customer,
        status: UserStatus.active,
        mustChangePassword: false,
        loyaltyPoints: 120, // Evidence of past legitimate activity
        termsAccepted: true, // Evidence of past accepted terms
        isRegistrationVerified: false,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      );

      mockDb.saveRecord(UserDatabaseRecord(
        user: legacyUser,
        passwordHash: mockDb.getByEmail('coffee.lover@lambac.com')!.passwordHash,
      ));

      // Attempt login
      final loginResult = await authRepository.login(
        const LoginRequest(email: legacyEmail, password: password),
      );

      // Controlled migration should allow login and update verification status
      expect(loginResult.isSuccess, isTrue);
      final user = loginResult.dataOrNull!.user;
      expect(user.isRegistrationVerified, isTrue);

      // Persisted record is now verified
      final updatedDbRecord = mockDb.getByEmail(legacyEmail);
      expect(updatedDbRecord!.user.isRegistrationVerified, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 7: Privileged Logins (Admin and Barista) Authenticate Directly (NO OTP)
    // -------------------------------------------------------------------------
    test('7. Privileged roles (Admin, Barista) log in via email and password with zero OTP requirements', () async {
      // Admin Login
      final adminLogin = await authRepository.login(
        const LoginRequest(email: 'jmbautista0228@gmail.com', password: 'LambacAdmin2026!'),
      );
      expect(adminLogin.isSuccess, isTrue);
      expect(adminLogin.dataOrNull?.user.role, equals(UserRole.admin));
      expect(adminLogin.dataOrNull?.user.isAdmin, isTrue);

      // Barista Login
      final baristaLogin = await authRepository.login(
        const LoginRequest(email: 'barista.staff@lambac.com', password: 'baristapass123'),
      );
      expect(baristaLogin.isSuccess, isTrue);
      expect(baristaLogin.dataOrNull?.user.role, equals(UserRole.employee));
      expect(baristaLogin.dataOrNull?.user.isStaff, isTrue);

      // Neither triggered any OTP
      expect(remoteDataSource.getPendingOtpForTesting('jmbautista0228@gmail.com'), isNull);
      expect(remoteDataSource.getPendingOtpForTesting('barista.staff@lambac.com'), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST 8: UserModel Deserialization Sets isRegistrationVerified Accurately
    // -------------------------------------------------------------------------
    test('8. UserModel.fromJson correctly resolves verification fields across schema versions', () {
      // Privileged roles are always verified
      final adminUser = UserModel.fromJson(const {
        'id': 'adm_1',
        'email': 'admin@lambac.com',
        'role': 'admin',
      });
      expect(adminUser.isRegistrationVerified, isTrue);

      final baristaUser = UserModel.fromJson(const {
        'id': 'bar_1',
        'email': 'barista@lambac.com',
        'role': 'barista',
      });
      expect(baristaUser.isRegistrationVerified, isTrue);

      // Customer with is_registration_verified=true
      final verifiedCustomer = UserModel.fromJson(const {
        'id': 'cust_1',
        'email': 'c1@lambac.com',
        'role': 'customer',
        'is_registration_verified': true,
      });
      expect(verifiedCustomer.isRegistrationVerified, isTrue);

      // Customer with legacy termsAccepted=true
      final legacyCustomer = UserModel.fromJson(const {
        'id': 'cust_2',
        'email': 'c2@lambac.com',
        'role': 'customer',
        'terms_accepted': true,
      });
      expect(legacyCustomer.isRegistrationVerified, isTrue);

      // Unverified customer without any evidence
      final unverifiedCustomer = UserModel.fromJson(const {
        'id': 'cust_3',
        'email': 'c3@lambac.com',
        'role': 'customer',
      });
      expect(unverifiedCustomer.isRegistrationVerified, isFalse);
    });
  });
}
