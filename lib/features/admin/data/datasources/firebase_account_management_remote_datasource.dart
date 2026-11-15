import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../models/create_user_request.dart';
import 'account_management_remote_datasource.dart';

/// Production Cloud Firestore-backed Account Management Data Source
class FirebaseAccountManagementRemoteDataSource implements AccountManagementRemoteDataSource {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  FirebaseAccountManagementRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _customFirestore = firestore,
        _customAuth = auth;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  Future<bool> _isCallerAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      final role = UserRole.fromString(doc.data()?['role']?.toString());
      return role == UserRole.admin;
    } catch (_) {
      return false;
    }
  }

  /// Securely provisions the user in Firebase Authentication using the Firebase Identity Toolkit REST API
  /// without disrupting, altering, or signing out the currently logged-in administrator.
  Future<String> _provisionAuthAccount({
    required String email,
    required String password,
  }) async {
    if (password.isEmpty) {
      throw const ValidationFailure(message: 'Initial password cannot be empty.');
    }

    final apiKey = Firebase.app().options.apiKey;
    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Content-Type': 'application/json'},
    ));

    try {
      final response = await dio.post<Map<String, dynamic>>(
        url,
        data: {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        },
      );

      final data = response.data;
      final localId = data?['localId']?.toString();
      if (localId != null && localId.isNotEmpty) {
        return localId;
      }
      throw const ServerFailure(message: 'Failed to obtain user identity from authentication provider.');
    } on DioException catch (de) {
      final errorData = de.response?.data;
      String errorCode = '';
      if (errorData is Map) {
        final err = errorData['error'];
        if (err is Map) {
          errorCode = err['message']?.toString() ?? '';
        }
      }

      if (errorCode.contains('EMAIL_EXISTS')) {
        throw const ConflictFailure(
          message: 'An account with this email address already exists in the system. Please use a unique email or reset the existing account\'s password.',
        );
      } else if (errorCode.contains('WEAK_PASSWORD')) {
        throw const ValidationFailure(message: 'The initial password is too weak. Must be at least 6 characters.');
      } else if (errorCode.contains('INVALID_EMAIL')) {
        throw const ValidationFailure(message: 'The email address is improperly formatted.');
      } else if (errorCode.contains('OPERATION_NOT_ALLOWED')) {
        throw const ServerFailure(message: 'Email/Password sign-in is disabled in Firebase.');
      } else if (errorCode.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
        throw const RateLimitFailure(message: 'Too many authentication attempts. Please try again later.');
      }

      throw ServerFailure(
        message: errorCode.isNotEmpty
            ? 'Authentication provisioning failed: $errorCode'
            : (de.message ?? 'Authentication service unreachable.'),
      );
    }
  }

  @override
  Future<Result<List<UserModel>, AppFailure>> getBusinessUsers({
    UserRole? roleFilter,
    UserStatus? statusFilter,
    String? searchQuery,
  }) async {
    final isAdmin = await _isCallerAdmin();
    if (!isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Admin privilege required to manage accounts.'),
      );
    }

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('users');

      if (roleFilter != null) {
        query = query.where('role', isEqualTo: roleFilter.name);
      } else {
        query = query.where('role', whereIn: ['admin', 'employee', 'barista']);
      }

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      query = query.limit(50);

      final snap = await query.get();
      var users = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return UserModel.fromJson(data);
      }).where((u) => u.isAdmin || u.isEmployee).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        users = users.where((u) =>
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.phoneNumber?.toLowerCase().contains(q) ?? false)
        ).toList();
      }

      users.sort((a, b) => a.fullName.compareTo(b.fullName));
      return Result.success(users);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to fetch business users: ${e.message}'));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<UserModel, AppFailure>> createAdmin(CreateAdminRequest request) async {
    final isAdmin = await _isCallerAdmin();
    if (!isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Only administrators can create other admins.'),
      );
    }

    final trimmedName = request.fullName.trim();
    if (trimmedName.length < 2) {
      return const Result.failure(
        ValidationFailure(message: 'Full name must be at least 2 characters.'),
      );
    }

    final normalizedEmail = request.email.trim().toLowerCase();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(normalizedEmail)) {
      return const Result.failure(
        ValidationFailure(message: 'Please enter a valid email address.'),
      );
    }

    if (request.initialPassword.length < 8) {
      return const Result.failure(
        ValidationFailure(message: 'Initial password must be at least 8 characters long.'),
      );
    }

    try {
      // Check existing email in Firestore to prevent orphaned auth accounts
      final existingDocs = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (existingDocs.docs.isNotEmpty) {
        return const Result.failure(
          ConflictFailure(message: 'An account with this email address already exists.'),
        );
      }

      final authUid = await _provisionAuthAccount(
        email: normalizedEmail,
        password: request.initialPassword,
      );

      final now = DateTime.now();

      final adminUser = UserModel(
        id: authUid,
        email: normalizedEmail,
        fullName: trimmedName,
        phoneNumber: request.phoneNumber?.trim(),
        role: UserRole.admin,
        status: UserStatus.active,
        permissions: EmployeePermission.values,
        mustChangePassword: request.mustChangePassword,
        createdAt: now,
        lastLoginAt: null,
      );

      final data = adminUser.toJson();
      data['uid'] = authUid;

      await _firestore.collection('users').doc(authUid).set(data);
      return Result.success(adminUser);
    } on AppFailure catch (af) {
      return Result.failure(af);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to create administrator: ${e.message}'));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<UserModel, AppFailure>> createEmployee(CreateEmployeeRequest request) async {
    final isAdmin = await _isCallerAdmin();
    if (!isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Only administrators can create employees.'),
      );
    }

    final trimmedName = request.fullName.trim();
    if (trimmedName.length < 2) {
      return const Result.failure(
        ValidationFailure(message: 'Full name must be at least 2 characters.'),
      );
    }

    final normalizedEmail = request.email.trim().toLowerCase();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(normalizedEmail)) {
      return const Result.failure(
        ValidationFailure(message: 'Please enter a valid email address.'),
      );
    }

    if (request.initialPassword.length < 8) {
      return const Result.failure(
        ValidationFailure(message: 'Initial password must be at least 8 characters long.'),
      );
    }

    try {
      // Check existing email in Firestore to prevent orphaned auth accounts
      final existingDocs = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (existingDocs.docs.isNotEmpty) {
        return const Result.failure(
          ConflictFailure(message: 'An account with this email address already exists.'),
        );
      }

      final authUid = await _provisionAuthAccount(
        email: normalizedEmail,
        password: request.initialPassword,
      );

      final now = DateTime.now();

      final employeeUser = UserModel(
        id: authUid,
        email: normalizedEmail,
        fullName: trimmedName,
        phoneNumber: request.phoneNumber?.trim(),
        role: UserRole.employee,
        status: UserStatus.active,
        permissions: request.permissions,
        mustChangePassword: request.mustChangePassword,
        createdAt: now,
        lastLoginAt: null,
      );

      final data = employeeUser.toJson();
      data['uid'] = authUid;
      data['role'] = 'barista'; // Canonical Barista role identifier

      await _firestore.collection('users').doc(authUid).set(data);
      return Result.success(employeeUser.copyWith(role: UserRole.barista));
    } on AppFailure catch (af) {
      return Result.failure(af);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to create employee: ${e.message}'));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<UserModel, AppFailure>> updateUser(String userId, UpdateUserRequest request) async {
    final isAdmin = await _isCallerAdmin();
    if (!isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Admin access required to update user accounts.'),
      );
    }

    try {
      final docRef = _firestore.collection('users').doc(userId);
      final snap = await docRef.get();
      if (!snap.exists) {
        return const Result.failure(NotFoundFailure(message: 'User account not found.'));
      }

      final existing = UserModel.fromJson({...snap.data()!, 'id': snap.id});
      final updated = existing.copyWith(
        fullName: request.fullName ?? existing.fullName,
        phoneNumber: request.phoneNumber ?? existing.phoneNumber,
        permissions: request.permissions ?? existing.permissions,
      );

      await docRef.update(updated.toJson());
      return Result.success(updated);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to update user: ${e.message}'));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<UserModel, AppFailure>> disableUser(String userId) async {
    final isAdmin = await _isCallerAdmin();
    if (!isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Admin access required to disable accounts.'),
      );
    }

    try {
      final docRef = _firestore.collection('users').doc(userId);
      final snap = await docRef.get();
      if (!snap.exists) {
        return const Result.failure(NotFoundFailure(message: 'User account not found.'));
      }

      final existing = UserModel.fromJson({...snap.data()!, 'id': snap.id});
      final updated = existing.copyWith(
        status: UserStatus.disabled,
      );

      await docRef.update({
        'status': 'disabled',
      });

      return Result.success(updated);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to disable user: ${e.message}'));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<UserModel, AppFailure>> enableUser(String userId) async {
    final isAdmin = await _isCallerAdmin();
    if (!isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Admin access required to enable accounts.'),
      );
    }

    try {
      final docRef = _firestore.collection('users').doc(userId);
      final snap = await docRef.get();
      if (!snap.exists) {
        return const Result.failure(NotFoundFailure(message: 'User account not found.'));
      }

      final existing = UserModel.fromJson({...snap.data()!, 'id': snap.id});
      final updated = existing.copyWith(
        status: UserStatus.active,
      );

      await docRef.update({
        'status': 'active',
      });

      return Result.success(updated);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to enable user: ${e.message}'));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<String, AppFailure>> resetUserPassword(String userId) async {
    final isAdmin = await _isCallerAdmin();
    if (!isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Admin access required to reset passwords.'),
      );
    }

    try {
      final docRef = _firestore.collection('users').doc(userId);
      final snap = await docRef.get();
      if (!snap.exists) {
        return const Result.failure(NotFoundFailure(message: 'User account not found.'));
      }

      // Generate a temporary one-time password
      final tempPassword = 'TempPass_${Random().nextInt(900000) + 100000}!';

      await docRef.update({
        'must_change_password': true,
        'password_reset_pending': true,
      });

      return Result.success(tempPassword);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to reset password: ${e.message}'));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}
