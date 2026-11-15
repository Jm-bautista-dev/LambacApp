import 'dart:async';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../core/security/audit_logger.dart';
import '../../../../core/security/password_hasher.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/data/datasources/mock_user_database.dart';
import '../models/create_user_request.dart';
import 'account_management_remote_datasource.dart';

/// Mock and Offline implementation of AccountManagementRemoteDataSource
class MockAccountManagementRemoteDataSource implements AccountManagementRemoteDataSource {
  final MockUserDatabase _db = MockUserDatabase();
  final AuditLogger _auditLogger = AuditLogger();

  @override
  Future<Result<List<UserModel>, AppFailure>> getBusinessUsers({
    UserRole? roleFilter,
    UserStatus? statusFilter,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final caller = _db.currentUser;
    // Server-side authorization check: Only Admins can view business account management
    if (caller == null || !caller.isAdmin) {
      return const Result.failure(
        ForbiddenFailure(
          message: 'Access Denied: Only authorized administrators can view account management.',
        ),
      );
    }

    var users = _db.records.values
        .map((r) => r.user)
        .where((u) => u.role == UserRole.admin || u.role == UserRole.employee)
        .toList();

    if (roleFilter != null) {
      users = users.where((u) => u.role == roleFilter).toList();
    }

    if (statusFilter != null) {
      users = users.where((u) => u.status == statusFilter).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      users = users.where((u) {
        return u.fullName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            (u.phoneNumber?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort by role (Admins first) and then createdAt
    users.sort((a, b) {
      if (a.isAdmin && !b.isAdmin) return -1;
      if (!a.isAdmin && b.isAdmin) return 1;
      return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
    });

    return Result.success(users);
  }

  @override
  Future<Result<UserModel, AppFailure>> createAdmin(CreateAdminRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final caller = _db.currentUser;
    if (caller == null || !caller.isAdmin) {
      _auditLogger.log(
        action: AuditActionType.adminCreated,
        actorEmail: caller?.email ?? 'unauthenticated',
        actorRole: caller?.role.name ?? 'unknown',
        targetEmail: request.email,
        targetRole: 'admin',
        isSuccess: false,
        details: 'Rejected: Caller does not possess Administrator privileges.',
      );
      return const Result.failure(
        ForbiddenFailure(
          message: 'Access Denied: Only active administrators can create admin accounts.',
        ),
      );
    }

    final trimmedName = request.fullName.trim();
    if (trimmedName.length < 2) {
      return const Result.failure(
        ValidationFailure(
          message: 'Full name must be at least 2 characters.',
          fieldErrors: {'fullName': ['Full name must be at least 2 characters.']},
        ),
      );
    }

    final normalizedEmail = request.email.trim().toLowerCase();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(normalizedEmail)) {
      return const Result.failure(
        ValidationFailure(
          message: 'Please enter a valid email address.',
          fieldErrors: {'email': ['Please enter a valid email address.']},
        ),
      );
    }

    if (request.initialPassword.length < 8) {
      return const Result.failure(
        ValidationFailure(
          message: 'Initial password must be at least 8 characters long.',
          fieldErrors: {'initialPassword': ['Password must be at least 8 characters long.']},
        ),
      );
    }

    if (_db.getByEmail(normalizedEmail) != null) {
      return const Result.failure(
        ValidationFailure(
          message: 'An account with this email address already exists.',
          fieldErrors: {
            'email': ['This email address is already registered.'],
          },
        ),
      );
    }

    final newAdmin = UserModel(
      id: 'usr_admin_${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      fullName: request.fullName.trim(),
      phoneNumber: request.phoneNumber?.trim(),
      role: UserRole.admin,
      status: UserStatus.active,
      mustChangePassword: request.mustChangePassword,
      createdAt: DateTime.now(),
    );

    _db.saveRecord(UserDatabaseRecord(
      user: newAdmin,
      passwordHash: PasswordHasher.hashPassword(request.initialPassword),
    ));

    _auditLogger.log(
      action: AuditActionType.adminCreated,
      actorEmail: caller.email,
      actorRole: caller.role.name,
      targetEmail: newAdmin.email,
      targetRole: 'admin',
      isSuccess: true,
      details: 'Administrator account created with mustChangePassword=${request.mustChangePassword}',
    );

    return Result.success(newAdmin);
  }

  @override
  Future<Result<UserModel, AppFailure>> createEmployee(CreateEmployeeRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final caller = _db.currentUser;
    if (caller == null || !caller.isAdmin) {
      _auditLogger.log(
        action: AuditActionType.employeeCreated,
        actorEmail: caller?.email ?? 'unauthenticated',
        actorRole: caller?.role.name ?? 'unknown',
        targetEmail: request.email,
        targetRole: 'employee',
        isSuccess: false,
        details: 'Rejected: Caller does not possess Administrator privileges to create employees.',
      );
      return const Result.failure(
        ForbiddenFailure(
          message: 'Access Denied: Only active administrators can provision employee accounts.',
        ),
      );
    }

    final trimmedName = request.fullName.trim();
    if (trimmedName.length < 2) {
      return const Result.failure(
        ValidationFailure(
          message: 'Full name must be at least 2 characters.',
          fieldErrors: {'fullName': ['Full name must be at least 2 characters.']},
        ),
      );
    }

    final normalizedEmail = request.email.trim().toLowerCase();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(normalizedEmail)) {
      return const Result.failure(
        ValidationFailure(
          message: 'Please enter a valid email address.',
          fieldErrors: {'email': ['Please enter a valid email address.']},
        ),
      );
    }

    if (request.initialPassword.length < 8) {
      return const Result.failure(
        ValidationFailure(
          message: 'Initial password must be at least 8 characters long.',
          fieldErrors: {'initialPassword': ['Password must be at least 8 characters long.']},
        ),
      );
    }

    if (_db.getByEmail(normalizedEmail) != null) {
      return const Result.failure(
        ValidationFailure(
          message: 'An account with this email address already exists.',
          fieldErrors: {
            'email': ['This email address is already registered.'],
          },
        ),
      );
    }

    final newEmployee = UserModel(
      id: 'usr_emp_${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      fullName: request.fullName.trim(),
      phoneNumber: request.phoneNumber?.trim(),
      role: UserRole.barista,
      status: UserStatus.active,
      mustChangePassword: request.mustChangePassword,
      permissions: request.permissions,
      createdAt: DateTime.now(),
    );

    _db.saveRecord(UserDatabaseRecord(
      user: newEmployee,
      passwordHash: PasswordHasher.hashPassword(request.initialPassword),
    ));

    _auditLogger.log(
      action: AuditActionType.employeeCreated,
      actorEmail: caller.email,
      actorRole: caller.role.name,
      targetEmail: newEmployee.email,
      targetRole: 'barista',
      isSuccess: true,
      details: 'Barista account created with ${request.permissions.length} operational permissions.',
    );

    return Result.success(newEmployee);
  }

  @override
  Future<Result<UserModel, AppFailure>> updateUser(String userId, UpdateUserRequest request) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final caller = _db.currentUser;
    if (caller == null || !caller.isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Only administrators can update account permissions and details.'),
      );
    }

    final record = _db.getById(userId);
    if (record == null) {
      return const Result.failure(NotFoundFailure(message: 'User account not found.'));
    }

    final updated = record.user.copyWith(
      fullName: request.fullName ?? record.user.fullName,
      phoneNumber: request.phoneNumber ?? record.user.phoneNumber,
      permissions: request.permissions ?? record.user.permissions,
    );

    record.user = updated;
    _db.saveRecord(record);

    _auditLogger.log(
      action: AuditActionType.roleChanged,
      actorEmail: caller.email,
      actorRole: caller.role.name,
      targetEmail: updated.email,
      targetRole: updated.role.name,
      isSuccess: true,
      details: 'User details or permissions updated.',
    );

    return Result.success(updated);
  }

  @override
  Future<Result<UserModel, AppFailure>> disableUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final caller = _db.currentUser;
    if (caller == null || !caller.isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Only administrators can disable accounts.'),
      );
    }

    final record = _db.getById(userId);
    if (record == null) {
      return const Result.failure(NotFoundFailure(message: 'User account not found.'));
    }

    if (record.user.id == caller.id) {
      return const Result.failure(
        ValidationFailure(message: 'You cannot disable your own administrator account.'),
      );
    }

    final updated = record.user.copyWith(status: UserStatus.disabled);
    record.user = updated;
    _db.saveRecord(record);

    _auditLogger.log(
      action: AuditActionType.accountDisabled,
      actorEmail: caller.email,
      actorRole: caller.role.name,
      targetEmail: updated.email,
      targetRole: updated.role.name,
      isSuccess: true,
      details: 'Account successfully disabled by administrator.',
    );

    return Result.success(updated);
  }

  @override
  Future<Result<UserModel, AppFailure>> enableUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final caller = _db.currentUser;
    if (caller == null || !caller.isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Only administrators can enable accounts.'),
      );
    }

    final record = _db.getById(userId);
    if (record == null) {
      return const Result.failure(NotFoundFailure(message: 'User account not found.'));
    }

    final updated = record.user.copyWith(status: UserStatus.active);
    record.user = updated;
    _db.saveRecord(record);

    _auditLogger.log(
      action: AuditActionType.accountEnabled,
      actorEmail: caller.email,
      actorRole: caller.role.name,
      targetEmail: updated.email,
      targetRole: updated.role.name,
      isSuccess: true,
      details: 'Account successfully re-enabled by administrator.',
    );

    return Result.success(updated);
  }

  @override
  Future<Result<String, AppFailure>> resetUserPassword(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final caller = _db.currentUser;
    if (caller == null || !caller.isAdmin) {
      return const Result.failure(
        ForbiddenFailure(message: 'Only administrators can trigger password resets.'),
      );
    }

    final record = _db.getById(userId);
    if (record == null) {
      return const Result.failure(NotFoundFailure(message: 'User account not found.'));
    }

    final tempPassword = PasswordHasher.generateTemporaryPassword();
    record.passwordHash = PasswordHasher.hashPassword(tempPassword);
    record.user = record.user.copyWith(mustChangePassword: true);
    _db.saveRecord(record);

    _auditLogger.log(
      action: AuditActionType.passwordResetRequested,
      actorEmail: caller.email,
      actorRole: caller.role.name,
      targetEmail: record.user.email,
      targetRole: record.user.role.name,
      isSuccess: true,
      details: 'Administrator generated temporary password and set mustChangePassword=true',
    );

    return Result.success(tempPassword);
  }
}
