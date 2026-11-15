import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../../domain/repositories/account_management_repository.dart';
import '../datasources/account_management_remote_datasource.dart';
import '../models/create_user_request.dart';

/// Concrete AccountManagementRepository implementation
class AccountManagementRepositoryImpl implements AccountManagementRepository {
  final AccountManagementRemoteDataSource _remoteDataSource;

  AccountManagementRepositoryImpl({
    required AccountManagementRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<List<UserModel>, AppFailure>> getBusinessUsers({
    UserRole? roleFilter,
    UserStatus? statusFilter,
    String? searchQuery,
  }) {
    return _remoteDataSource.getBusinessUsers(
      roleFilter: roleFilter,
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<Result<UserModel, AppFailure>> createAdmin(CreateAdminRequest request) {
    return _remoteDataSource.createAdmin(request);
  }

  @override
  Future<Result<UserModel, AppFailure>> createEmployee(CreateEmployeeRequest request) {
    return _remoteDataSource.createEmployee(request);
  }

  @override
  Future<Result<UserModel, AppFailure>> updateUser(String userId, UpdateUserRequest request) {
    return _remoteDataSource.updateUser(userId, request);
  }

  @override
  Future<Result<UserModel, AppFailure>> disableUser(String userId) {
    return _remoteDataSource.disableUser(userId);
  }

  @override
  Future<Result<UserModel, AppFailure>> enableUser(String userId) {
    return _remoteDataSource.enableUser(userId);
  }

  @override
  Future<Result<String, AppFailure>> resetUserPassword(String userId) {
    return _remoteDataSource.resetUserPassword(userId);
  }
}
