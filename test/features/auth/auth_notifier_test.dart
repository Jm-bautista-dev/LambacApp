import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lambac_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lambac_app/shared/models/auth_state.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('AuthNotifier State Transitions Test', () {
    late InMemoryStorageService storageService;
    late MockAuthRemoteDataSource remoteDataSource;
    late AuthRepositoryImpl authRepository;
    late AuthNotifier authNotifier;

    setUp(() {
      storageService = InMemoryStorageService();
      remoteDataSource = MockAuthRemoteDataSource();
      authRepository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        storageService: storageService,
      );
      authNotifier = AuthNotifier(repository: authRepository);
    });

    test('Initial state transitions to unauthenticated when storage is empty', () async {
      await authNotifier.restoreSession();
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
      expect(authNotifier.state.isAuthenticated, isFalse);
    });

    test('Login success updates AuthNotifier state to authenticated', () async {
      final result = await authNotifier.login(
        email: 'coffee.lover@lambac.com',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      expect(authNotifier.state.user?.email, equals('coffee.lover@lambac.com'));
      expect(authNotifier.state.isAuthenticated, isTrue);
    });

    test('Login failure updates AuthNotifier state to failure', () async {
      final result = await authNotifier.login(
        email: 'coffee.lover@lambac.com',
        password: 'wrongpassword',
      );

      expect(result.isFailure, isTrue);
      expect(authNotifier.state.status, equals(AuthStatus.failure));
      expect(authNotifier.state.isAuthenticated, isFalse);
    });

    test('Guest mode updates AuthNotifier state to guest user', () {
      authNotifier.continueAsGuest();
      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      expect(authNotifier.state.user?.isGuest, isTrue);
    });

    test('Session expired state helper updates status to sessionExpired', () {
      authNotifier.handleSessionExpired();
      expect(authNotifier.state.status, equals(AuthStatus.sessionExpired));
      expect(authNotifier.state.isSessionExpired, isTrue);
    });
  });
}
