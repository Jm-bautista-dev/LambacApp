import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/errors/error_handler.dart';
import 'package:lambac_app/core/utils/validators.dart';
import 'package:lambac_app/features/auth/data/datasources/firebase_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/models/login_request.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/firebase_options.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Auth 400 Error Investigation & Fix Verification', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUserCredential mockUserCredential;
    late MockUser mockFirebaseUser;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockUserDoc;
    late MockDocumentSnapshot mockDocSnapshot;
    late FirebaseAuthRemoteDataSourceImpl dataSource;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUserCredential = MockUserCredential();
      mockFirebaseUser = MockUser();
      mockUsersCollection = MockCollectionReference();
      mockUserDoc = MockDocumentReference();
      mockDocSnapshot = MockDocumentSnapshot();

      when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);

      dataSource = FirebaseAuthRemoteDataSourceImpl(
        auth: mockAuth,
        firestore: mockFirestore,
      );
    });

    test('DefaultFirebaseOptions.web targets lambac-coffee-roastery Firebase project', () {
      expect(DefaultFirebaseOptions.web.projectId, equals('lambac-coffee-roastery'));
      expect(DefaultFirebaseOptions.web.authDomain, equals('lambac-coffee-roastery.firebaseapp.com'));
      expect(DefaultFirebaseOptions.web.apiKey, isNotEmpty);
    });

    test('Valid customer login succeeds and normalizes email while preserving password verbatim', () async {
      const rawEmail = '  Customer.Test@Gmail.com  ';
      const normalizedEmail = 'customer.test@gmail.com';
      const passwordWithSpaces = '  RoastPass123!  ';
      const uid = 'cust_uid_1';

      when(() => mockAuth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: passwordWithSpaces,
          )).thenAnswer((_) async => mockUserCredential);

      when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
      when(() => mockFirebaseUser.uid).thenReturn(uid);
      when(() => mockFirebaseUser.email).thenReturn(normalizedEmail);
      when(() => mockFirebaseUser.displayName).thenReturn('Test Customer');
      when(() => mockFirebaseUser.refreshToken).thenReturn('refresh_tok');
      when(() => mockFirebaseUser.getIdToken()).thenAnswer((_) async => 'id_tok_123');

      when(() => mockUserDoc.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.data()).thenReturn({
        'uid': uid,
        'id': uid,
        'email': normalizedEmail,
        'full_name': 'Test Customer',
        'role': 'customer',
        'status': 'active',
        'isActive': true,
        'is_registration_verified': true,
      });
      when(() => mockUserDoc.update(any())).thenAnswer((_) async {});

      final result = await dataSource.login(
        const LoginRequest(email: rawEmail, password: passwordWithSpaces),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.user.email, equals(normalizedEmail));
      expect(result.dataOrNull!.user.role, equals(UserRole.customer));

      verify(() => mockAuth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: passwordWithSpaces,
          )).called(1);
    });

    test('Empty email or empty password is rejected client-side before hitting Firebase Auth', () async {
      final emptyEmailResult = await dataSource.login(
        const LoginRequest(email: '   ', password: 'Password123!'),
      );
      expect(emptyEmailResult.isFailure, isTrue);
      expect(emptyEmailResult.failureOrNull, isA<ValidationFailure>());

      final emptyPassResult = await dataSource.login(
        const LoginRequest(email: 'customer@gmail.com', password: ''),
      );
      expect(emptyPassResult.isFailure, isTrue);
      expect(emptyPassResult.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('Validators.email accepts surrounding whitespace and rejects invalid format; Validators.loginPassword does not trim', () {
      expect(Validators.email('  user@example.com  '), isNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.loginPassword('   '), isNull);
      expect(Validators.loginPassword(''), isNotNull);
    });

    test('Incorrect password and nonexistent email map cleanly from invalid-credential / invalid-login-credentials', () async {
      for (final code in const ['invalid-credential', 'invalid-login-credentials', 'wrong-password', 'user-not-found']) {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: 'nobody@gmail.com',
              password: 'WrongPassword1!',
            )).thenThrow(FirebaseAuthException(code: code));

        final res = await dataSource.login(
          const LoginRequest(email: 'nobody@gmail.com', password: 'WrongPassword1!'),
        );

        expect(res.isFailure, isTrue);
        expect(res.failureOrNull, isA<UnauthorizedFailure>());
        expect(res.failureOrNull!.message, equals('Email or password is incorrect.'));
        expect(res.failureOrNull!.canRetry, isFalse);
      }
    });

    test('Network failure, disabled account, too-many-requests, and operation-not-allowed map accurately', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'user@gmail.com',
            password: 'Password123!',
          )).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final netRes = await dataSource.login(
        const LoginRequest(email: 'user@gmail.com', password: 'Password123!'),
      );
      expect(netRes.failureOrNull, isA<NetworkFailure>());

      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'user@gmail.com',
            password: 'Password123!',
          )).thenThrow(FirebaseAuthException(code: 'user-disabled'));

      final disabledRes = await dataSource.login(
        const LoginRequest(email: 'user@gmail.com', password: 'Password123!'),
      );
      expect(disabledRes.failureOrNull, isA<UnauthorizedFailure>());
      expect(disabledRes.failureOrNull!.isRecoverable, isFalse);

      final opNotAllowed = ErrorHandler.handleException(
        FirebaseAuthException(code: 'operation-not-allowed'),
      );
      expect(opNotAllowed, isA<ServerFailure>());

      final rateLimit = ErrorHandler.handleException(
        FirebaseAuthException(code: 'too-many-requests'),
      );
      expect(rateLimit, isA<RateLimitFailure>());
    });

    test('Customer registration, sign-out, and subsequent sign-in preserve credentials consistently', () async {
      const email = 'fresh.customer@gmail.com';
      const passwordWithLeadingSpace = ' Roast123!';
      const uid = 'fresh_uid_99';

      dataSource.setPendingRegistrationForTesting(email, verificationToken: 'tok_verified');

      when(() => mockAuth.createUserWithEmailAndPassword(
            email: email,
            password: passwordWithLeadingSpace,
          )).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
      when(() => mockFirebaseUser.uid).thenReturn(uid);
      when(() => mockFirebaseUser.email).thenReturn(email);
      when(() => mockFirebaseUser.displayName).thenReturn('Fresh Customer');
      when(() => mockFirebaseUser.refreshToken).thenReturn('ref_1');
      when(() => mockFirebaseUser.getIdToken()).thenAnswer((_) async => 'id_1');
      when(() => mockFirebaseUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockUserDoc.set(any())).thenAnswer((_) async {});

      final regRes = await dataSource.register(
        const RegisterRequest(
          fullName: 'Fresh Customer',
          email: email,
          password: passwordWithLeadingSpace,
          verificationToken: 'tok_verified',
        ),
      );
      expect(regRes.isSuccess, isTrue);

      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      final outRes = await dataSource.logout();
      expect(outRes.isSuccess, isTrue);

      when(() => mockAuth.signInWithEmailAndPassword(
            email: email,
            password: passwordWithLeadingSpace,
          )).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserDoc.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.data()).thenReturn({
        'uid': uid,
        'id': uid,
        'email': email,
        'full_name': 'Fresh Customer',
        'role': 'customer',
        'status': 'active',
        'isActive': true,
        'is_registration_verified': true,
      });
      when(() => mockUserDoc.update(any())).thenAnswer((_) async {});

      final loginRes = await dataSource.login(
        const LoginRequest(email: '  $email  ', password: passwordWithLeadingSpace),
      );
      expect(loginRes.isSuccess, isTrue);
      verify(() => mockAuth.signInWithEmailAndPassword(
            email: email,
            password: passwordWithLeadingSpace,
          )).called(1);
    });
  });
}
