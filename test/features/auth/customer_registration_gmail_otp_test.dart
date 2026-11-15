import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/routing/app_routes.dart';
import 'package:lambac_app/core/services/email_service.dart';
import 'package:lambac_app/core/widgets/buttons/app_button.dart';
import 'package:lambac_app/features/auth/presentation/screens/register_screen.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/models/login_request.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/features/auth/data/models/request_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/models/verify_register_otp_request.dart';
import 'package:lambac_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/auth/presentation/screens/register_otp_verification_screen.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Lambac Coffee Roastery — Customer Registration Gmail OTP Verification Suite', () {
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
      EmailService.instance.setSimulateFailure(false);
    });

    Widget buildTestableWidget(Widget child) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    // ------------------------------------------------------------------------
    // TEST 1 — Successful Customer Registration Flow
    // ------------------------------------------------------------------------
    test('Test 1: Full Registration Flow (Request OTP -> Verify OTP -> Create Account -> Login Normally with NO OTP)', () async {
      const email = 'new.customer@gmail.com';
      const password = 'StrongPassword2026!';
      const fullName = 'Juan Dela Cruz';

      // 1. Customer initiates registration
      final otpReqResult = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: fullName,
          email: email,
          password: password,
          phoneNumber: '09171234567',
        ),
      );

      expect(otpReqResult.isSuccess, isTrue);
      final otpResponse = otpReqResult.dataOrNull!;
      expect(otpResponse.email, equals(email));
      expect(otpResponse.maskedEmail, contains('@gmail.com'));
      expect(otpResponse.expiresInSeconds, equals(300));
      expect(otpResponse.resendCooldownSeconds, equals(45));

      // 2. Retrieve secure 6-digit OTP dispatched to customer inbox
      final dispatchedOtp = remoteDataSource.getPendingOtpForTesting(email);
      expect(dispatchedOtp, isNotNull);
      expect(dispatchedOtp!.length, equals(6));
      expect(RegExp(r'^\d{6}$').hasMatch(dispatchedOtp), isTrue);

      // 3. Customer submits valid OTP
      final verifyResult = await authRepository.verifyRegisterOtp(
        VerifyRegisterOtpRequest(email: email, otp: dispatchedOtp),
      );

      expect(verifyResult.isSuccess, isTrue);
      final verificationToken = verifyResult.dataOrNull!.verificationToken;
      expect(verificationToken, isNotEmpty);

      // 4. Backend creates customer account using verified token
      final registerResult = await authRepository.register(
        RegisterRequest(
          fullName: fullName,
          email: email,
          password: password,
          phoneNumber: '09171234567',
          verificationToken: verificationToken,
        ),
      );

      expect(registerResult.isSuccess, isTrue);
      final user = registerResult.dataOrNull!.user;
      expect(user.fullName, equals(fullName));
      expect(user.email, equals(email));
      expect(user.role, equals(UserRole.customer));
      expect(user.status, equals(UserStatus.active));

      // 5. Subsequent Login requires ONLY Email + Password (NO OTP on login)
      final loginResult = await authRepository.login(
        const LoginRequest(
          email: email,
          password: password,
        ),
      );

      expect(loginResult.isSuccess, isTrue);
      expect(loginResult.dataOrNull!.user.email, equals(email));
    });

    // ------------------------------------------------------------------------
    // TEST 2 — Incorrect OTP Rejection
    // ------------------------------------------------------------------------
    test('Test 2: Submitting an incorrect OTP rejects verification and prevents account creation', () async {
      const email = 'wrong.otp.user@gmail.com';

      await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Wrong OTP User',
          email: email,
          password: 'StrongPassword2026!',
        ),
      );

      final verifyResult = await authRepository.verifyRegisterOtp(
        const VerifyRegisterOtpRequest(email: email, otp: '999999'),
      );

      expect(verifyResult.isFailure, isTrue);
      expect(verifyResult.failureOrNull, isA<ValidationFailure>());
      expect(verifyResult.failureOrNull?.message, contains('verification code is incorrect'));
    });

    // ------------------------------------------------------------------------
    // TEST 3 — Expired OTP Rejection
    // ------------------------------------------------------------------------
    test('Test 3: Expired OTP code is rejected and customer is prompted to request a new code', () async {
      const email = 'expired.user@gmail.com';

      await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Expired User',
          email: email,
          password: 'StrongPassword2026!',
        ),
      );

      final realOtp = remoteDataSource.getPendingOtpForTesting(email)!;

      // Simulate expiration (past 5 minutes)
      remoteDataSource.forceExpirePendingOtpForTesting(email);

      final verifyResult = await authRepository.verifyRegisterOtp(
        VerifyRegisterOtpRequest(email: email, otp: realOtp),
      );

      expect(verifyResult.isFailure, isTrue);
      expect(verifyResult.failureOrNull?.message, contains('has expired'));
    });

    // ------------------------------------------------------------------------
    // TEST 4 — Resend OTP Invalidation & Cooldown
    // ------------------------------------------------------------------------
    test('Test 4: Resend OTP enforces cooldown, invalidates prior code, and issues fresh valid code', () async {
      const email = 'resend.user@gmail.com';

      await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Resend User',
          email: email,
          password: 'StrongPassword2026!',
        ),
      );

      final firstOtp = remoteDataSource.getPendingOtpForTesting(email)!;

      // Attempting immediate resend during 45s cooldown is blocked
      final immediateResend = await authRepository.resendRegisterOtp(email);
      expect(immediateResend.isFailure, isTrue);
      expect(immediateResend.failureOrNull?.message, contains('Please wait'));

      // Cooldown expires
      remoteDataSource.resetCooldownForTesting(email);

      final resendResult = await authRepository.resendRegisterOtp(email);
      expect(resendResult.isSuccess, isTrue);

      final secondOtp = remoteDataSource.getPendingOtpForTesting(email)!;

      // The old first OTP must no longer work
      final tryFirstOtp = await authRepository.verifyRegisterOtp(
        VerifyRegisterOtpRequest(email: email, otp: firstOtp),
      );
      expect(tryFirstOtp.isFailure, isTrue);

      // The new second OTP must succeed
      final trySecondOtp = await authRepository.verifyRegisterOtp(
        VerifyRegisterOtpRequest(email: email, otp: secondOtp),
      );
      expect(trySecondOtp.isSuccess, isTrue);
    });

    // ------------------------------------------------------------------------
    // TEST 5 — Existing Email Account Duplicate Prevention
    // ------------------------------------------------------------------------
    test('Test 5: Registering with an already registered email is blocked before OTP dispatch', () async {
      // Existing user in mock DB: coffee.lover@lambac.com
      final result = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Duplicate Account',
          email: 'coffee.lover@lambac.com',
          password: 'StrongPassword2026!',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('already exists'));
    });

    // ------------------------------------------------------------------------
    // TEST 6 — Login Continues with NO OTP Required
    // ------------------------------------------------------------------------
    test('Test 6: Customer Login and Admin Login NEVER require OTP (Email + Password only)', () async {
      // Customer Login
      final customerLogin = await authRepository.login(
        const LoginRequest(
          email: 'coffee.lover@lambac.com',
          password: 'password123',
        ),
      );
      expect(customerLogin.isSuccess, isTrue);
      expect(customerLogin.dataOrNull!.user.role, equals(UserRole.customer));

      // Admin Login
      final adminLogin = await authRepository.login(
        const LoginRequest(
          email: 'jmbautista0228@gmail.com',
          password: 'LambacAdmin2026!',
        ),
      );
      expect(adminLogin.isSuccess, isTrue);
      expect(adminLogin.dataOrNull!.user.role, equals(UserRole.admin));
    });

    // ------------------------------------------------------------------------
    // TEST 7 — Brute Force Guessing Protection
    // ------------------------------------------------------------------------
    test('Test 7: 5 consecutive failed OTP attempts locks/invalidates the registration session', () async {
      const email = 'bruteforce.user@gmail.com';

      await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Brute Force User',
          email: email,
          password: 'StrongPassword2026!',
        ),
      );

      final realOtp = remoteDataSource.getPendingOtpForTesting(email)!;

      // 4 incorrect attempts
      for (int i = 1; i <= 4; i++) {
        final res = await authRepository.verifyRegisterOtp(
          VerifyRegisterOtpRequest(email: email, otp: '00000$i'),
        );
        expect(res.isFailure, isTrue);
        expect(res.failureOrNull?.message, contains('verification code is incorrect'));
      }

      // 5th incorrect attempt triggers lockout
      final fifthAttempt = await authRepository.verifyRegisterOtp(
        const VerifyRegisterOtpRequest(email: email, otp: '000005'),
      );
      expect(fifthAttempt.isFailure, isTrue);
      expect(fifthAttempt.failureOrNull?.message, contains('Too many verification attempts'));

      // Even entering the correct OTP now is rejected because session was invalidated
      final tryRealOtp = await authRepository.verifyRegisterOtp(
        VerifyRegisterOtpRequest(email: email, otp: realOtp),
      );
      expect(tryRealOtp.isFailure, isTrue);
      expect(tryRealOtp.failureOrNull?.message, contains('Too many verification attempts'));
    });

    // ------------------------------------------------------------------------
    // TEST 8 — API Bypass Prevention
    // ------------------------------------------------------------------------
    test('Test 8: Backend strictly rejects direct register calls without a valid OTP verification token', () async {
      const email = 'bypass.attacker@gmail.com';

      // Attacker attempts to call register without OTP verification
      final bypassAttempt = await authRepository.register(
        const RegisterRequest(
          fullName: 'Bypass Attacker',
          email: email,
          password: 'StrongPassword2026!',
          verificationToken: null, // No token
        ),
      );

      expect(bypassAttempt.isFailure, isTrue);
      expect(bypassAttempt.failureOrNull?.message, contains('Email verification required'));

      // Attacker attempts with fake forged token
      final fakeTokenAttempt = await authRepository.register(
        const RegisterRequest(
          fullName: 'Bypass Attacker',
          email: email,
          password: 'StrongPassword2026!',
          verificationToken: 'fake_forged_token_12345',
        ),
      );

      expect(fakeTokenAttempt.isFailure, isTrue);
      expect(fakeTokenAttempt.failureOrNull?.message, contains('Email verification required'));
    });

    // ------------------------------------------------------------------------
    // TEST 9 — Transport / Email Failure Simulation
    // ------------------------------------------------------------------------
    test('Test 9: Simulated SMTP email transport failure returns honest error without fake success', () async {
      EmailService.instance.setSimulateFailure(true);

      final result = await authRepository.requestRegisterOtp(
        const RequestRegisterOtpRequest(
          fullName: 'Email Fail User',
          email: 'smtp.fail@gmail.com',
          password: 'StrongPassword2026!',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull?.message, contains("couldn't send the verification code"));
    });

    // ------------------------------------------------------------------------
    // TEST 10 — RegisterOtpVerificationScreen Widget & Digit UX Tests
    // ------------------------------------------------------------------------
    testWidgets('Test 10: RegisterOtpVerificationScreen renders 6-digit input boxes, masked email, and resend cooldown', (WidgetTester tester) async {
      await tester.runAsync(() async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const testArgs = RegisterOtpScreenArgs(
          fullName: 'Leah Rivera',
          email: 'leah.rivera@gmail.com',
          password: 'Password2026!',
          phoneNumber: '09170001111',
          maskedEmail: 'l••••••••a@gmail.com',
        );

        // Seed pending registration
        await authRepository.requestRegisterOtp(
          RequestRegisterOtpRequest(
            fullName: testArgs.fullName,
            email: testArgs.email,
            password: testArgs.password,
            phoneNumber: testArgs.phoneNumber,
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            const RegisterOtpVerificationScreen(
              args: testArgs,
              autoStartCooldown: false,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Verify Your Email'), findsWidgets);
        expect(find.text('l••••••••a@gmail.com'), findsOneWidget);
        expect(find.text('Enter the 6-digit code below'), findsOneWidget);

        // 6 text field digit boxes
        final digitFields = find.byType(TextField);
        expect(digitFields, findsNWidgets(6));

        // Submit button is present
        final verifyButton = find.widgetWithText(AppButton, 'Verify Email');
        expect(verifyButton, findsOneWidget);

        // Cleanly unmount
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    });

    // ------------------------------------------------------------------------
    // TEST 11 — End-to-End Registration UI Flow: RegisterScreen -> OTP Screen -> Account Creation
    // ------------------------------------------------------------------------
    testWidgets('Test 11: RegisterScreen form submission dispatches OTP and navigates to RegisterOtpVerificationScreen', (WidgetTester tester) async {
      await tester.runAsync(() async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = GoRouter(
          initialLocation: AppRoutes.register,
          routes: [
            GoRoute(
              path: AppRoutes.register,
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: AppRoutes.registerOtp,
              builder: (context, state) {
                final args = state.extra as RegisterOtpScreenArgs;
                return RegisterOtpVerificationScreen(
                  args: args,
                  autoStartCooldown: false,
                );
              },
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const Scaffold(body: Text('Customer Home Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(authRepository),
              authRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
              storageServiceProvider.overrideWithValue(storageService),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));

        // 1. Fill registration form
        final textFields = find.byType(TextField);
        expect(textFields, findsNWidgets(5)); // fullName, email, phone, password, confirmPassword

        await tester.enterText(textFields.at(0), 'Eduardo Gomez');
        await tester.enterText(textFields.at(1), 'eduardo.gomez@gmail.com');
        await tester.enterText(textFields.at(2), '09181234567');
        await tester.enterText(textFields.at(3), 'SecurePass2026!');
        await tester.enterText(textFields.at(4), 'SecurePass2026!');
        await tester.pump();

        // Verify account does NOT exist yet
        expect(remoteDataSource.getPendingOtpForTesting('eduardo.gomez@gmail.com'), isNull);

        // 2. Tap Create Account button
        final submitButton = find.widgetWithText(AppButton, 'Create Account');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 3. Verify OTP was dispatched to Gmail and navigated to RegisterOtpVerificationScreen
        expect(find.text('Verify Your Email'), findsWidgets);
        expect(find.text('Enter the 6-digit code below'), findsOneWidget);

        final pendingOtp = remoteDataSource.getPendingOtpForTesting('eduardo.gomez@gmail.com');
        expect(pendingOtp, isNotNull);
        expect(pendingOtp!.length, equals(6));

        // 4. Enter the 6-digit OTP in verification screen (triggers auto-verification on 6th digit)
        final otpDigitBoxes = find.descendant(
          of: find.byType(RegisterOtpVerificationScreen),
          matching: find.byType(TextField),
        );
        expect(otpDigitBoxes, findsNWidgets(6));
        for (int i = 0; i < 6; i++) {
          await tester.enterText(otpDigitBoxes.at(i), pendingOtp[i]);
          await tester.pump();
        }
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 5. Account creation succeeds and navigates to Home
        expect(find.text('Customer Home Screen'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    });

    // ------------------------------------------------------------------------
    // TEST 12 — Duplicate Email Registration blocks OTP and remains on RegisterScreen
    // ------------------------------------------------------------------------
    testWidgets('Test 12: Duplicate email registration error keeps user on RegisterScreen without navigating', (WidgetTester tester) async {
      await tester.runAsync(() async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = GoRouter(
          initialLocation: AppRoutes.register,
          routes: [
            GoRoute(
              path: AppRoutes.register,
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: AppRoutes.registerOtp,
              builder: (context, state) => const Scaffold(body: Text('Should Not Reach Here')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(authRepository),
              authRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
              storageServiceProvider.overrideWithValue(storageService),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Duplicate User');
        await tester.enterText(textFields.at(1), 'coffee.lover@lambac.com'); // existing user
        await tester.enterText(textFields.at(3), 'SecurePass2026!');
        await tester.enterText(textFields.at(4), 'SecurePass2026!');
        await tester.pump();

        final submitButton = find.widgetWithText(AppButton, 'Create Account');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Remains on register screen and displays error
        expect(find.text('Create Account'), findsWidgets);
        expect(find.text('Should Not Reach Here'), findsNothing);
        expect(find.textContaining('already exists'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    });
  });
}
