import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/network/result.dart';
import 'package:lambac_app/core/routing/app_routes.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/models/forgot_password_request.dart';
import 'package:lambac_app/features/auth/data/models/reset_password_request.dart';
import 'package:lambac_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:lambac_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:lambac_app/core/widgets/buttons/app_button.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Lambac Coffee Roastery — Forgot Password & Reset Password Verification', () {
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

    test('1. Repository forgotPassword returns success for registered user email', () async {
      final result = await authRepository.forgotPassword(
        const ForgotPasswordRequest(email: 'coffee.lover@lambac.com'),
      );
      expect(result.isSuccess, isTrue);
    });

    test('2. Repository forgotPassword returns failure for non-existent email', () async {
      final result = await authRepository.forgotPassword(
        const ForgotPasswordRequest(email: 'unknown.user@lambac.com'),
      );
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('3. Repository resetPassword successfully updates user credentials with token', () async {
      final result = await authRepository.resetPassword(
        const ResetPasswordRequest(
          email: 'coffee.lover@lambac.com',
          resetToken: '123456',
          newPassword: 'NewRoastPass2026',
        ),
      );
      expect(result.isSuccess, isTrue);
    });

    testWidgets('4. ForgotPasswordScreen displays error on empty or invalid email submit', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Tap Send Verification Code without entering email
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
    });

    testWidgets('5. ForgotPasswordScreen dispatches reset and navigates to reset password screen on valid email', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: AppRoutes.resetPassword,
            builder: (context, state) {
              final email = state.uri.queryParameters['email'];
              return ResetPasswordScreen(email: email);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'coffee.lover@lambac.com');
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Enter Verification'), findsOneWidget);
      expect(find.textContaining('We have sent a verification code to coffee.lover@lambac.com'), findsOneWidget);
    });
  });
}
