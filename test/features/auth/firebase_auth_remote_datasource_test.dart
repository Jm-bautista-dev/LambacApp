import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/auth/data/datasources/firebase_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/models/login_request.dart';
import 'package:lambac_app/features/auth/data/models/register_request.dart';
import 'package:lambac_app/features/auth/data/models/update_profile_request.dart';
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

  group('FirebaseAuthRemoteDataSourceImpl Tests', () {
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

    test('Register creates user in Firebase Auth and profile in Firestore with customer role', () async {
      const email = 'new.customer@lambac.com';
      const password = 'Password123!';
      const uid = 'fb_uid_test_123';

      when(() => mockAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockUserCredential);

      when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
      when(() => mockFirebaseUser.uid).thenReturn(uid);
      when(() => mockFirebaseUser.email).thenReturn(email);
      when(() => mockFirebaseUser.displayName).thenReturn('New Customer');
      when(() => mockFirebaseUser.refreshToken).thenReturn('mock_refresh_token');
      when(() => mockFirebaseUser.getIdToken(any())).thenAnswer((_) async => 'fb_id_token_123');
      when(() => mockFirebaseUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockUserDoc.set(any())).thenAnswer((_) async {});

      // Verify bypass without token is rejected
      final bypassResult = await dataSource.register(
        const RegisterRequest(
          fullName: 'New Customer',
          email: email,
          password: password,
          phoneNumber: '09171234567',
        ),
      );
      expect(bypassResult.isFailure, isTrue);
      expect(bypassResult.failureOrNull?.message, contains('Email verification required'));

      // Verify registration with valid verification token succeeds
      const vToken = 'fb_reg_vtok_test_123';
      dataSource.setPendingRegistrationForTesting(email, verificationToken: vToken);

      final result = await dataSource.register(
        const RegisterRequest(
          fullName: 'New Customer',
          email: email,
          password: password,
          phoneNumber: '09171234567',
          verificationToken: vToken,
        ),
      );

      expect(result.isSuccess, isTrue);
      final authData = result.dataOrNull!;
      expect(authData.user.id, equals(uid));
      expect(authData.user.email, equals(email));
      expect(authData.user.role, equals(UserRole.customer));
      expect(authData.user.status, equals(UserStatus.active));

      // Verify Firestore set call
      verify(() => mockUserDoc.set(any(that: predicate<Map<String, dynamic>>((map) {
            return map['role'] == 'customer' && map['uid'] == uid && map['isActive'] == true;
          })))).called(1);
    });

    test('Login authenticates with FirebaseAuth and resolves role from Firestore', () async {
      const email = 'lead.admin@lambac.com';
      const password = 'AdminPassword123!';
      const uid = 'admin_uid_789';

      when(() => mockAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockUserCredential);

      when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
      when(() => mockFirebaseUser.uid).thenReturn(uid);
      when(() => mockFirebaseUser.email).thenReturn(email);
      when(() => mockFirebaseUser.displayName).thenReturn('Lead Administrator');
      when(() => mockFirebaseUser.refreshToken).thenReturn('mock_admin_refresh');
      when(() => mockFirebaseUser.getIdToken(any())).thenAnswer((_) async => 'admin_id_token');
      when(() => mockUserDoc.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.data()).thenReturn({
        'uid': uid,
        'email': email,
        'full_name': 'Lead Administrator',
        'role': 'admin',
        'status': 'active',
        'isActive': true,
        'permissions': ['manageOrders', 'manageProducts', 'recordSales', 'manageInbox', 'viewBasicMetrics'],
      });
      when(() => mockUserDoc.update(any())).thenAnswer((_) async {});

      final result = await dataSource.login(
        const LoginRequest(
          email: email,
          password: password,
        ),
      );

      expect(result.isSuccess, isTrue);
      final authData = result.dataOrNull!;
      expect(authData.user.id, equals(uid));
      expect(authData.user.role, equals(UserRole.admin));
      expect(authData.user.isAdmin, isTrue);
      expect(authData.user.isActive, isTrue);
    });

    test('Login rejects disabled accounts even if credentials are valid in FirebaseAuth', () async {
      const email = 'disabled.user@lambac.com';
      const password = 'Password123!';
      const uid = 'disabled_uid_456';

      when(() => mockAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockUserCredential);

      when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
      when(() => mockFirebaseUser.uid).thenReturn(uid);
      when(() => mockFirebaseUser.email).thenReturn(email);
      when(() => mockUserDoc.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.data()).thenReturn({
        'uid': uid,
        'email': email,
        'role': 'customer',
        'status': 'disabled',
        'isActive': false,
      });
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      final result = await dataSource.login(
        const LoginRequest(
          email: email,
          password: password,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(result.failureOrNull?.message, contains('disabled'));
      verify(() => mockAuth.signOut()).called(1);
    });

    test('Update profile modifies allowed fields and retrieves updated profile', () async {
      const uid = 'cust_uid_update';

      when(() => mockAuth.currentUser).thenReturn(mockFirebaseUser);
      when(() => mockFirebaseUser.uid).thenReturn(uid);
      when(() => mockFirebaseUser.email).thenReturn('cust@lambac.com');
      when(() => mockFirebaseUser.displayName).thenReturn('Original Name');
      when(() => mockFirebaseUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockUserDoc.update(any())).thenAnswer((_) async {});

      when(() => mockUserDoc.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.data()).thenReturn({
        'uid': uid,
        'email': 'cust@lambac.com',
        'full_name': 'Updated Name',
        'role': 'customer',
        'status': 'active',
        'isActive': true,
        'is_registration_verified': true,
        'phoneNumber': '09198765432',
      });

      final result = await dataSource.updateProfile(
        const UpdateProfileRequest(
          fullName: 'Updated Name',
          phoneNumber: '09198765432',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.fullName, equals('Updated Name'));
      expect(result.dataOrNull?.phoneNumber, equals('09198765432'));

      // Verify update payload doesn't contain forbidden role field
      verify(() => mockUserDoc.update(any(that: predicate<Map<String, dynamic>>((map) {
            return !map.containsKey('role') && !map.containsKey('status');
          })))).called(1);
    });

    test('Logout signs out from Firebase Authentication', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      final result = await dataSource.logout();

      expect(result.isSuccess, isTrue);
      verify(() => mockAuth.signOut()).called(1);
    });

    test('Maps FirebaseAuthException user-not-found to UnauthorizedFailure', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'notfound@lambac.com',
            password: 'Password123!',
          )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final result = await dataSource.login(
        const LoginRequest(
          email: 'notfound@lambac.com',
          password: 'Password123!',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(result.failureOrNull?.message.toLowerCase(), contains('password is incorrect'));
    });
  });
}
