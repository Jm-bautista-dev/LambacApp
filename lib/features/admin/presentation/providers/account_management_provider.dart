import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/datasources/account_management_remote_datasource.dart';
import '../../data/datasources/firebase_account_management_remote_datasource.dart';
import '../../data/models/create_user_request.dart';
import '../../data/repositories/account_management_repository_impl.dart';
import '../../domain/repositories/account_management_repository.dart';

/// Provider for AccountManagementRemoteDataSource
final accountManagementRemoteDataSourceProvider = Provider<AccountManagementRemoteDataSource>((ref) {
  return FirebaseAccountManagementRemoteDataSource();
});

/// Provider for AccountManagementRepository
final accountManagementRepositoryProvider = Provider<AccountManagementRepository>((ref) {
  final remoteDataSource = ref.watch(accountManagementRemoteDataSourceProvider);
  return AccountManagementRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Account Management State
class AccountManagementState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final List<UserModel> users;
  final UserRole? roleFilter;
  final UserStatus? statusFilter;
  final String searchQuery;
  final String? errorMessage;

  const AccountManagementState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.users = const [],
    this.roleFilter,
    this.statusFilter,
    this.searchQuery = '',
    this.errorMessage,
  });

  AccountManagementState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<UserModel>? users,
    UserRole? roleFilter,
    bool clearRoleFilter = false,
    UserStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountManagementState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      users: users ?? this.users,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  List<UserModel> get admins => users.where((u) => u.isAdmin).toList();
  List<UserModel> get employees => users.where((u) => u.isEmployee).toList();
  int get activeCount => users.where((u) => u.isActive).length;
  int get disabledCount => users.where((u) => u.isDisabled).length;

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        users,
        roleFilter,
        statusFilter,
        searchQuery,
        errorMessage,
      ];
}

/// StateNotifier for Business Account Management
class AccountManagementNotifier extends StateNotifier<AccountManagementState> {
  final AccountManagementRepository _repository;

  AccountManagementNotifier({required AccountManagementRepository repository})
      : _repository = repository,
        super(const AccountManagementState()) {
    loadUsers();
  }

  /// Load all business users with current filters applied
  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getBusinessUsers(
      roleFilter: state.roleFilter,
      statusFilter: state.statusFilter,
      searchQuery: state.searchQuery,
    );

    result.when(
      success: (users) {
        state = state.copyWith(
          isLoading: false,
          users: users,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  void setRoleFilter(UserRole? role) {
    if (role == null) {
      state = state.copyWith(clearRoleFilter: true);
    } else {
      state = state.copyWith(roleFilter: role);
    }
    loadUsers();
  }

  void setStatusFilter(UserStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
    loadUsers();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadUsers();
  }

  /// Create a new Administrator
  Future<Result<UserModel, AppFailure>> createAdmin(CreateAdminRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repository.createAdmin(request);

    state = state.copyWith(isSubmitting: false);
    if (result.isSuccess) {
      await loadUsers();
    }
    return result;
  }

  /// Create a new Employee
  Future<Result<UserModel, AppFailure>> createEmployee(CreateEmployeeRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repository.createEmployee(request);

    state = state.copyWith(isSubmitting: false);
    if (result.isSuccess) {
      await loadUsers();
    }
    return result;
  }

  /// Update user information or permissions
  Future<Result<UserModel, AppFailure>> updateUser(String userId, UpdateUserRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repository.updateUser(userId, request);

    state = state.copyWith(isSubmitting: false);
    if (result.isSuccess) {
      await loadUsers();
    }
    return result;
  }

  /// Disable user account
  Future<Result<UserModel, AppFailure>> disableUser(String userId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repository.disableUser(userId);

    state = state.copyWith(isSubmitting: false);
    if (result.isSuccess) {
      await loadUsers();
    }
    return result;
  }

  /// Re-enable user account
  Future<Result<UserModel, AppFailure>> enableUser(String userId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repository.enableUser(userId);

    state = state.copyWith(isSubmitting: false);
    if (result.isSuccess) {
      await loadUsers();
    }
    return result;
  }

  /// Reset user password and generate temporary password
  Future<Result<String, AppFailure>> resetPassword(String userId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repository.resetUserPassword(userId);

    state = state.copyWith(isSubmitting: false);
    if (result.isSuccess) {
      await loadUsers();
    }
    return result;
  }
}

/// Riverpod Provider for AccountManagementNotifier
final accountManagementNotifierProvider =
    StateNotifierProvider<AccountManagementNotifier, AccountManagementState>((ref) {
  final repository = ref.watch(accountManagementRepositoryProvider);
  return AccountManagementNotifier(repository: repository);
});
