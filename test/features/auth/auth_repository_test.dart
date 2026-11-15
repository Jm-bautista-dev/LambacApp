import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/models/login_request.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/features/auth/data/models/request_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/models/verify_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('AuthRepository Unit Tests', () {
    late InMemoryStorageService storageService;
    late MockAuthRemoteDataSource remoteDataSource;
    late AuthRepositoryImpl authRepository;

    setUp(() {
      storageService = InMemoryStorageService();
      remoteDataSource = MockAuthRemoteDataSource();
      authRepository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
    });

    test('Login with valid credentials returns user and saves token', () async {
      final result = await authRepository.login(
        const LoginRequest(
          email: 'coffee.lover@lambac.com',
          password: 'password123',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.user.email, equals('coffee.lover@lambac.com'));
      expect(result.dataOrNull?.user.fullName, equals('Kenji Takahashi'));

      // Check secure storage
      final storedToken = await storageService.getToken();
      expect(storedToken, isNotNull);
      expect(storedToken, contains('mock_jwt_token_'));
    });

    test('Login with invalid credentials returns failure and does not save token', () async {
      final result = await authRepository.login(
        const LoginRequest(
          email: 'coffee.lover@lambac.com',
          password: 'wrongpassword',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Invalid email or password'));

      final storedToken = await storageService.getToken();
      expect(storedToken, isNull);
    });

    test('Register creates new user account and saves token via verified OTP', () async {
      const email = 'akira.tanaka@lambac.com';
      final otpRes = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Akira Tanaka',
          email: email,
          password: 'Password1234',
          phoneNumber: '09191234567',
        ),
      );
      expect(otpRes.isSuccess, isTrue);

      final otp = remoteDataSource.getPendingOtpForTesting(email)!;
      final verifyRes = await authRepository.verifyRegisterOtp(
        VerifyRegisterOtpRequest(email: email, otp: otp),
      );
      expect(verifyRes.isSuccess, isTrue);

      final result = await authRepository.register(
        RegisterRequest(
          fullName: 'Akira Tanaka',
          email: email,
          password: 'Password1234',
          phoneNumber: '09191234567',
          verificationToken: verifyRes.dataOrNull!.verificationToken,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.user.fullName, equals('Akira Tanaka'));
      expect(result.dataOrNull?.user.email, equals('akira.tanaka@lambac.com'));

      final storedToken = await storageService.getToken();
      expect(storedToken, isNotNull);
    });

    test('Logout clears session token and user data', () async {
      // Setup active login
      await authRepository.login(
        const LoginRequest(
          email: 'coffee.lover@lambac.com',
          password: 'password123',
        ),
      );
      expect(await storageService.getToken(), isNotNull);

      // Perform logout
      final logoutResult = await authRepository.logout();
      expect(logoutResult.isSuccess, isTrue);

      expect(await storageService.getToken(), isNull);
    });

    test('Restore session returns cached user if token exists', () async {
      // Log in to write token and user data to storage
      await authRepository.login(
        const LoginRequest(
          email: 'coffee.lover@lambac.com',
          password: 'password123',
        ),
      );

      // Call restoreSession
      final restoreResult = await authRepository.restoreSession();
      expect(restoreResult.isSuccess, isTrue);
      expect(restoreResult.dataOrNull?.user.email, equals('coffee.lover@lambac.com'));
    });
  });
}
