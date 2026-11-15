import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:lambac_app/features/auth/presentation/screens/login_screen.dart';
import 'package:lambac_app/features/auth/presentation/screens/register_screen.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
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

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Auth Screens Widget Tests', () {
    testWidgets('LoginScreen renders form inputs and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders all input fields and validators', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const RegisterScreen()));

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Mobile Number (Optional)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen renders email field and send button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const ForgotPasswordScreen()));

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });
  });
}
