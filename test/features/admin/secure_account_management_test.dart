import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/security/audit_logger.dart';
import 'package:lambac_app/core/security/password_hasher.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_account_management_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/models/create_user_request.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/data/models/login_request.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/features/auth/data/models/request_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/models/verify_register_otp_request.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  late MockUserDatabase userDb;
  late MockAuthRemoteDataSource authDataSource;
  late MockAccountManagementRemoteDataSource accountDataSource;
  late AuditLogger auditLogger;

  setUp(() {
    userDb = MockUserDatabase();
    userDb.resetForTests();
    authDataSource = MockAuthRemoteDataSource();
    accountDataSource = MockAccountManagementRemoteDataSource();
    auditLogger = AuditLogger();
  });

  group('1. Default Administrator Account & Idempotency', () {
    test('Default admin jmbautista0228@gmail.com is provisioned with hashed password and Admin role', () {
      final defaultAdminRecord = userDb.getByEmail('jmbautista0228@gmail.com');

      expect(defaultAdminRecord, isNotNull);
      expect(defaultAdminRecord!.user.email, equals('jmbautista0228@gmail.com'));
      expect(defaultAdminRecord.user.role, equals(UserRole.admin));
      expect(defaultAdminRecord.user.isAdmin, isTrue);
      expect(defaultAdminRecord.user.status, equals(UserStatus.active));

      // Verify password is NOT stored as plaintext
      expect(defaultAdminRecord.passwordHash, isNot(equals('LambacAdmin2026!')));
      expect(defaultAdminRecord.passwordHash.contains(':'), isTrue); // salt:hash format

      // Verify cryptographic verification works
      expect(
        PasswordHasher.verifyPassword('LambacAdmin2026!', defaultAdminRecord.passwordHash),
        isTrue,
      );
      expect(
        PasswordHasher.verifyPassword('WrongPassword', defaultAdminRecord.passwordHash),
        isFalse,
      );
    });

    test('Default admin provisioning is idempotent and does not overwrite existing admin on re-seed', () {
      final initialRecord = userDb.getByEmail('jmbautista0228@gmail.com');
      final originalHash = initialRecord!.passwordHash;

      // Re-trigger seed
      userDb.seedDefaultUsers();

      final secondRecord = userDb.getByEmail('jmbautista0228@gmail.com');
      expect(secondRecord!.passwordHash, equals(originalHash));
    });
  });

  group('2. Customer Registration Mass-Assignment Security', () {
    test('Customer registration strictly creates Customer role and rejects privilege escalation', () async {
      const email = 'newcustomer@example.com';
      const password = 'SecurePassword123!';

      final otpRes = await authDataSource.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Test Customer',
          email: email,
          password: password,
        ),
      );
      expect(otpRes.isSuccess, isTrue);

      final otp = authDataSource.getPendingOtpForTesting(email)!;
      final verifyRes = await authDataSource.verifyRegisterOtp(
        VerifyRegisterOtpRequest(email: email, otp: otp),
      );
      expect(verifyRes.isSuccess, isTrue);

      final result = await authDataSource.register(
        RegisterRequest(
          fullName: 'Test Customer',
          email: email,
          password: password,
          verificationToken: verifyRes.dataOrNull!.verificationToken,
        ),
      );

      expect(result.isSuccess, isTrue);
      final registeredUser = result.dataOrNull!.user;

      expect(registeredUser.role, equals(UserRole.customer));
      expect(registeredUser.isAdmin, isFalse);
      expect(registeredUser.isBusinessUser, isFalse);

      final record = userDb.getByEmail(email);
      expect(record!.user.role, equals(UserRole.customer));
      expect(PasswordHasher.verifyPassword(password, record.passwordHash), isTrue);
    });

    test('Duplicate customer registration returns ValidationFailure', () async {
      final result = await authDataSource.register(
        const RegisterRequest(
          fullName: 'Duplicate Tester',
          email: 'coffee.lover@lambac.com', // Existing demo email
          password: 'password123',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('3. Server-Side RBAC Enforcement on Privileged Endpoints', () {
    test('Admin user can create another Administrator', () async {
      // Set caller to default Admin
      userDb.setCurrentUser(userDb.getByEmail('jmbautista0228@gmail.com')!.user);

      final result = await accountDataSource.createAdmin(
        const CreateAdminRequest(
          fullName: 'Secondary Admin',
          email: 'admin2@lambaccoffee.com',
          initialPassword: 'TempPassword123!',
          mustChangePassword: true,
        ),
      );

      expect(result.isSuccess, isTrue);
      final newAdmin = result.dataOrNull!;
      expect(newAdmin.role, equals(UserRole.admin));
      expect(newAdmin.mustChangePassword, isTrue);
    });

    test('Employee or Customer attempting to create Administrator is rejected with 403 Forbidden', () async {
      // Set caller to Employee
      userDb.setCurrentUser(userDb.getByEmail('barista.staff@lambac.com')!.user);

      final result = await accountDataSource.createAdmin(
        const CreateAdminRequest(
          fullName: 'Malicious Admin',
          email: 'hacker@lambaccoffee.com',
          initialPassword: 'TempPassword123!',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(userDb.getByEmail('hacker@lambaccoffee.com'), isNull);
    });

    test('Employee attempting to access getBusinessUsers is rejected with 403 Forbidden', () async {
      userDb.setCurrentUser(userDb.getByEmail('barista.staff@lambac.com')!.user);

      final result = await accountDataSource.getBusinessUsers();
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });
  });

  group('4. Account Disablement & Authentication Rejection', () {
    test('Disabled account is rejected during login attempts', () async {
      // Admin disables employee account
      userDb.setCurrentUser(userDb.getByEmail('jmbautista0228@gmail.com')!.user);
      final employeeRecord = userDb.getByEmail('barista.staff@lambac.com')!;

      final disableResult = await accountDataSource.disableUser(employeeRecord.user.id);
      expect(disableResult.isSuccess, isTrue);
      expect(disableResult.dataOrNull!.status, equals(UserStatus.disabled));

      // Attempt to log in with correct password
      final loginResult = await authDataSource.login(
        const LoginRequest(
          email: 'barista.staff@lambac.com',
          password: 'baristapass123',
        ),
      );

      expect(loginResult.isFailure, isTrue);
      expect(loginResult.failureOrNull, isA<UnauthorizedFailure>());
      expect(loginResult.failureOrNull!.message, contains('disabled'));
    });

    test('Admin cannot disable their own account', () async {
      final adminUser = userDb.getByEmail('jmbautista0228@gmail.com')!.user;
      userDb.setCurrentUser(adminUser);

      final result = await accountDataSource.disableUser(adminUser.id);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('5. Mandatory First-Login Password Setup', () {
    test('Newly provisioned user with mustChangePassword must complete first login password change', () async {
      userDb.setCurrentUser(userDb.getByEmail('jmbautista0228@gmail.com')!.user);

      // Create new employee
      final createResult = await accountDataSource.createEmployee(
        const CreateEmployeeRequest(
          fullName: 'New Barista',
          email: 'newbarista@lambaccoffee.com',
          initialPassword: 'TempPassword123!',
          mustChangePassword: true,
        ),
      );

      expect(createResult.isSuccess, isTrue);
      expect(createResult.dataOrNull!.mustChangePassword, isTrue);

      // User logs in
      final loginResult = await authDataSource.login(
        const LoginRequest(
          email: 'newbarista@lambaccoffee.com',
          password: 'TempPassword123!',
        ),
      );
      expect(loginResult.isSuccess, isTrue);
      expect(loginResult.dataOrNull!.user.mustChangePassword, isTrue);

      // User submits new permanent password
      final changeResult = await authDataSource.completeFirstLoginPassword(
        const FirstLoginPasswordRequest(newPassword: 'MyNewPermanentPassword2026!'),
      );

      expect(changeResult.isSuccess, isTrue);
      expect(changeResult.dataOrNull!.mustChangePassword, isFalse);

      // Verify old temporary password is no longer valid and new password works
      final reLoginOld = await authDataSource.login(
        const LoginRequest(
          email: 'newbarista@lambaccoffee.com',
          password: 'TempPassword123!',
        ),
      );
      expect(reLoginOld.isFailure, isTrue);

      final reLoginNew = await authDataSource.login(
        const LoginRequest(
          email: 'newbarista@lambaccoffee.com',
          password: 'MyNewPermanentPassword2026!',
        ),
      );
      expect(reLoginNew.isSuccess, isTrue);
      expect(reLoginNew.dataOrNull!.user.mustChangePassword, isFalse);
    });
  });

  group('6. Security Audit Trail', () {
    test('Audit events are properly recorded for administrative actions', () {
      final logs = auditLogger.getLogs();
      expect(logs.isNotEmpty, isTrue);

      // Check for admin provisioning log
      final adminCreatedLogs = logs.where((l) => l.action == AuditActionType.adminCreated);
      expect(adminCreatedLogs.isNotEmpty, isTrue);
    });
  });
}
