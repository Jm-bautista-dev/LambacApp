import '../../../../shared/models/user_model.dart';

/// Request DTO for creating a new business Administrator
class CreateAdminRequest {
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String initialPassword;
  final bool mustChangePassword;

  const CreateAdminRequest({
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.initialPassword,
    this.mustChangePassword = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email.trim().toLowerCase(),
      if (phoneNumber != null && phoneNumber!.isNotEmpty) 'phone_number': phoneNumber,
      'initial_password': initialPassword,
      'must_change_password': mustChangePassword,
      'role': 'admin',
    };
  }
}

/// Request DTO for creating a new business Employee
class CreateEmployeeRequest {
  final String fullName;
  final String email;
  final String? phoneNumber;
  final List<EmployeePermission> permissions;
  final String initialPassword;
  final bool mustChangePassword;

  const CreateEmployeeRequest({
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.permissions = const [
      EmployeePermission.manageOrders,
      EmployeePermission.manageInbox,
    ],
    required this.initialPassword,
    this.mustChangePassword = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email.trim().toLowerCase(),
      if (phoneNumber != null && phoneNumber!.isNotEmpty) 'phone_number': phoneNumber,
      'permissions': permissions.map((p) => p.name).toList(),
      'initial_password': initialPassword,
      'must_change_password': mustChangePassword,
      'role': 'barista',
    };
  }
}

/// Request DTO for updating user profile or permissions
class UpdateUserRequest {
  final String? fullName;
  final String? phoneNumber;
  final List<EmployeePermission>? permissions;

  const UpdateUserRequest({
    this.fullName,
    this.phoneNumber,
    this.permissions,
  });

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (permissions != null) 'permissions': permissions!.map((p) => p.name).toList(),
    };
  }
}

/// Request DTO for completing forced first-login password change
class FirstLoginPasswordRequest {
  final String newPassword;

  const FirstLoginPasswordRequest({
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'new_password': newPassword,
    };
  }
}
