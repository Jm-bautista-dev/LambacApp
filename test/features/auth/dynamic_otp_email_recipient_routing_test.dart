import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/services/email_service.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/features/auth/data/models/request_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/models/verify_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lambac_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Production Fix 02: Dynamic Customer OTP Email Recipient Routing Acceptance Suite', () {
    late EmailService emailService;
    late MockAuthRemoteDataSource remoteDataSource;
    late AuthRepository authRepository;
    late MockUserDatabase mockDb;

    const developerEmail = 'jmbautistaa0428@gmail.com';

    setUp(() {
      emailService = EmailService.instance;
      emailService.setSimulateFailure(false);
      remoteDataSource = MockAuthRemoteDataSource();
      authRepository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: InMemoryStorageService(),
      );
      mockDb = MockUserDatabase();
      MockAuthRemoteDataSource.resetLoginOtps();
    });

    // -------------------------------------------------------------------------
    // TEST A: Customer email is dynamically routed and developer email is NEVER recipient
    // -------------------------------------------------------------------------
    test('Test A: Customer registration OTP is dynamically delivered to customer email and NEVER developer address', () async {
      const customerEmail = 'patricia.reyes2026@gmail.com';
      const customerName = 'Patricia Reyes';

      expect(customerEmail, isNot(equals(developerEmail)));

      final otpResult = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: customerName,
          email: customerEmail,
          password: 'SecurePassword123!',
        ),
      );

      expect(otpResult.isSuccess, isTrue);
      final otpData = otpResult.dataOrNull!;
      expect(otpData.email, equals(customerEmail));

      // 1. Verify EmailService authoritative dispatched recipient
      expect(emailService.lastDispatchedRecipient, equals(customerEmail));
      expect(emailService.lastDispatchedRecipient, isNot(equals(developerEmail)));

      // 2. Verify pending OTP challenge belongs strictly to customer email
      final pendingOtp = remoteDataSource.getPendingOtpForTesting(customerEmail);
      expect(pendingOtp, isNotNull);
      expect(pendingOtp!.length, equals(6));

      // 3. Verify developer email has NO pending OTP challenge
      expect(remoteDataSource.getPendingOtpForTesting(developerEmail), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST B: Distinct customer accounts receive their own distinct OTPs
    // -------------------------------------------------------------------------
    test('Test B: Successive customer registration requests route to respective distinct customer inboxes', () async {
      const customer1Email = 'alice.customer@gmail.com';
      const customer2Email = 'bob.customer@gmail.com';

      // Request 1: Alice
      final aliceResult = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Alice Walker',
          email: customer1Email,
          password: 'Password123!',
        ),
      );
      expect(aliceResult.isSuccess, isTrue);
      expect(emailService.lastDispatchedRecipient, equals(customer1Email));
      final aliceOtp = remoteDataSource.getPendingOtpForTesting(customer1Email);
      expect(aliceOtp, isNotNull);

      // Request 2: Bob
      final bobResult = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Bob Martinez',
          email: customer2Email,
          password: 'Password123!',
        ),
      );
      expect(bobResult.isSuccess, isTrue);
      expect(emailService.lastDispatchedRecipient, equals(customer2Email));
      final bobOtp = remoteDataSource.getPendingOtpForTesting(customer2Email);
      expect(bobOtp, isNotNull);

      // Verify no recipient leakage or reuse between requests
      expect(emailService.lastDispatchedRecipient, isNot(equals(customer1Email)));
      expect(emailService.lastDispatchedRecipient, isNot(equals(developerEmail)));
      expect(aliceOtp, isNot(equals(bobOtp)));
    });

    // -------------------------------------------------------------------------
    // TEST C: Invalid, empty, or whitespace-only recipients are rejected without fallback
    // -------------------------------------------------------------------------
    test('Test C1: EmailService strictly rejects empty, invalid, or whitespace-only emails', () async {
      // 1. Empty email
      final emptyResult = await emailService.sendRegistrationOtpEmail(
        recipientEmail: '',
        recipientName: 'Test Name',
        otpCode: '123456',
      );
      expect(emptyResult, isFalse);

      // 2. Whitespace-only email
      final whitespaceResult = await emailService.sendRegistrationOtpEmail(
        recipientEmail: '   ',
        recipientName: 'Test Name',
        otpCode: '123456',
      );
      expect(whitespaceResult, isFalse);

      // 3. Malformed email address (missing domain, missing @)
      final malformedResult1 = await emailService.sendRegistrationOtpEmail(
        recipientEmail: 'notanemail',
        recipientName: 'Test Name',
        otpCode: '123456',
      );
      expect(malformedResult1, isFalse);

      final malformedResult2 = await emailService.sendRegistrationOtpEmail(
        recipientEmail: '@nodomain.com',
        recipientName: 'Test Name',
        otpCode: '123456',
      );
      expect(malformedResult2, isFalse);

      // 4. Invalid OTP format (non-6-digit)
      final invalidOtpResult = await emailService.sendRegistrationOtpEmail(
        recipientEmail: 'valid@example.com',
        recipientName: 'Test Name',
        otpCode: '12',
      );
      expect(invalidOtpResult, isFalse);

      // In none of these cases should the developer email have been set as last dispatched
      expect(emailService.lastDispatchedRecipient, isNot(equals(developerEmail)));
    });

    test('Test C2: Repository layer rejects invalid email inputs before dispatching', () async {
      final invalidEmailResult = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Invalid User',
          email: 'invalid-email-format',
          password: 'Password123!',
        ),
      );

      expect(invalidEmailResult.isFailure, isTrue);
      expect(invalidEmailResult.failureOrNull?.message, contains('valid email address'));
      expect(remoteDataSource.getPendingOtpForTesting('invalid-email-format'), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST D: Cross-Account OTP binding and replay prevention
    // -------------------------------------------------------------------------
    test('Test D: Customer 1 OTP cannot verify Customer 2 registration challenge', () async {
      const email1 = 'customer1@lambac.com';
      const email2 = 'customer2@lambac.com';

      // Generate OTP for Customer 1
      await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Customer One',
          email: email1,
          password: 'Password123!',
        ),
      );
      final otp1 = remoteDataSource.getPendingOtpForTesting(email1)!;

      // Generate OTP for Customer 2
      await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Customer Two',
          email: email2,
          password: 'Password123!',
        ),
      );

      // Attempt to verify Customer 2 using Customer 1's OTP
      final crossVerifyResult = await authRepository.verifyRegisterOtp(
        VerifyRegisterOtpRequest(
          email: email2,
          otp: otp1,
        ),
      );

      // Must be rejected
      expect(crossVerifyResult.isFailure, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST E: Transport Delivery Failures Report Honest Error & Prevent Account Creation
    // -------------------------------------------------------------------------
    test('Test E: Transport delivery failure halts registration without creating unverified account', () async {
      const email = 'network.failure.test@gmail.com';
      emailService.setSimulateFailure(true);

      final result = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Network Fail Customer',
          email: email,
          password: 'Password123!',
        ),
      );

      // Honest failure returned
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains("couldn't send the verification code"));

      // Account does not exist in database
      expect(mockDb.getByEmail(email), isNull);

      // Cannot bypass OTP verification to register
      final directRegisterResult = await authRepository.register(
        const RegisterRequest(
          fullName: 'Network Fail Customer',
          email: email,
          password: 'Password123!',
        ),
      );
      expect(directRegisterResult.isFailure, isTrue);
    });
  });
}
