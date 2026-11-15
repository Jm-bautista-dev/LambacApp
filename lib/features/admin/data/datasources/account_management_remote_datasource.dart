import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../models/create_user_request.dart';

/// Contract for Business Account Management API calls
abstract class AccountManagementRemoteDataSource {
  /// Fetch all business users (Admins & Employees)
  Future<Result<List<UserModel>, AppFailure>> getBusinessUsers({
    UserRole? roleFilter,
    UserStatus? statusFilter,
    String? searchQuery,
  });

  /// Create a new Administrator (Admin-only privilege)
  Future<Result<UserModel, AppFailure>> createAdmin(CreateAdminRequest request);

  /// Create a new Employee with assigned permissions (Admin-only privilege)
  Future<Result<UserModel, AppFailure>> createEmployee(CreateEmployeeRequest request);

  /// Update an existing user's information or permissions
  Future<Result<UserModel, AppFailure>> updateUser(String userId, UpdateUserRequest request);

  /// Disable an account (prevents login and access)
  Future<Result<UserModel, AppFailure>> disableUser(String userId);

  /// Re-enable an account
  Future<Result<UserModel, AppFailure>> enableUser(String userId);

  /// Reset an account's password to a temporary password
  Future<Result<String, AppFailure>> resetUserPassword(String userId);
}
