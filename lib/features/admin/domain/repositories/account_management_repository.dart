import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/models/create_user_request.dart';

/// Domain Repository Contract for Business Account & Access Management
abstract class AccountManagementRepository {
  Future<Result<List<UserModel>, AppFailure>> getBusinessUsers({
    UserRole? roleFilter,
    UserStatus? statusFilter,
    String? searchQuery,
  });

  Future<Result<UserModel, AppFailure>> createAdmin(CreateAdminRequest request);

  Future<Result<UserModel, AppFailure>> createEmployee(CreateEmployeeRequest request);

  Future<Result<UserModel, AppFailure>> updateUser(String userId, UpdateUserRequest request);

  Future<Result<UserModel, AppFailure>> disableUser(String userId);

  Future<Result<UserModel, AppFailure>> enableUser(String userId);

  Future<Result<String, AppFailure>> resetUserPassword(String userId);
}
