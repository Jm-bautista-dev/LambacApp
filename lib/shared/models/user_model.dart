import 'package:equatable/equatable.dart';

/// Role enum for Lambac Platform users
enum UserRole {
  customer,
  employee,
  admin;

  /// Backwards-compatible alias for employee / barista
  static const UserRole staff = UserRole.employee;
  static const UserRole barista = UserRole.employee;
  static const UserRole manager = UserRole.employee;

  static UserRole? tryParse(String? role) {
    if (role == null) return null;
    return switch (role.trim().toLowerCase()) {
      'admin' || 'administrator' || 'super_admin' || 'superadmin' => UserRole.admin,
      'employee' || 'staff' || 'barista' || 'manager' => UserRole.employee,
      'customer' => UserRole.customer,
      _ => null,
    };
  }

  static UserRole fromString(String? role) {
    return tryParse(role) ?? UserRole.customer;
  }

  String toFormattedString() {
    return switch (this) {
      UserRole.admin => 'Administrator',
      UserRole.employee => 'Barista / Operations Staff',
      UserRole.customer => 'Customer',
    };
  }
}

/// Account operational and security status
enum UserStatus {
  active,
  disabled,
  pendingActivation;

  static UserStatus fromString(String? status) {
    return switch (status?.toLowerCase()) {
      'disabled' || 'inactive' || 'suspended' => UserStatus.disabled,
      'pending' || 'pending_activation' || 'pendingactivation' => UserStatus.pendingActivation,
      _ => UserStatus.active,
    };
  }

  String toFormattedString() {
    return switch (this) {
      UserStatus.active => 'Active',
      UserStatus.disabled => 'Disabled',
      UserStatus.pendingActivation => 'Pending Setup',
    };
  }
}

/// Granular operational permissions for business employees
enum EmployeePermission {
  manageOrders,
  manageProducts,
  recordSales,
  manageInbox,
  viewBasicMetrics;

  static EmployeePermission fromString(String? perm) {
    return switch (perm?.toLowerCase()) {
      'manage_orders' || 'manageorders' => EmployeePermission.manageOrders,
      'manage_products' || 'manageproducts' => EmployeePermission.manageProducts,
      'record_sales' || 'recordsales' => EmployeePermission.recordSales,
      'manage_inbox' || 'manageinbox' => EmployeePermission.manageInbox,
      'view_basic_metrics' || 'viewbasicmetrics' => EmployeePermission.viewBasicMetrics,
      _ => EmployeePermission.manageOrders,
    };
  }

  String toFormattedString() {
    return switch (this) {
      EmployeePermission.manageOrders => 'Process Orders',
      EmployeePermission.manageProducts => 'Manage Products & Stock',
      EmployeePermission.recordSales => 'Record Walk-in Sales',
      EmployeePermission.manageInbox => 'Concierge Chat Support',
      EmployeePermission.viewBasicMetrics => 'View Basic Metrics',
    };
  }
}

/// Core User entity representing authenticated accounts
class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final UserRole role;
  final UserStatus status;
  final bool mustChangePassword;
  final bool isRegistrationVerified;
  final DateTime? registrationVerifiedAt;
  final List<EmployeePermission> permissions;
  final String? avatarUrl;
  final int loyaltyPoints;
  final bool termsAccepted;
  final String? acceptedTermsVersion;
  final DateTime? termsAcceptedAt;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool firstOrderGcashCompleted;
  final String? firstOrderCompletedOrderId;
  final DateTime? firstOrderCompletedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.role = UserRole.customer,
    this.status = UserStatus.active,
    this.mustChangePassword = false,
    this.isRegistrationVerified = true,
    this.registrationVerifiedAt,
    this.permissions = const [],
    this.avatarUrl,
    this.loyaltyPoints = 0,
    this.termsAccepted = false,
    this.acceptedTermsVersion,
    this.termsAcceptedAt,
    this.createdAt,
    this.lastLoginAt,
    this.firstOrderGcashCompleted = false,
    this.firstOrderCompletedOrderId,
    this.firstOrderCompletedAt,
  });

  /// Anonymous / Guest fallback user
  factory UserModel.guest() {
    return const UserModel(
      id: 'guest',
      email: '',
      fullName: 'Guest Coffee Enthusiast',
      role: UserRole.customer,
      status: UserStatus.active,
      isRegistrationVerified: true,
      termsAccepted: true,
      acceptedTermsVersion: '1.0.0',
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<EmployeePermission> perms = [];
    if (json['permissions'] != null && json['permissions'] is List) {
      perms = (json['permissions'] as List)
          .map((p) => EmployeePermission.fromString(p.toString()))
          .toList();
    }

    final role = UserRole.fromString(json['role']?.toString());
    final isPrivileged = role == UserRole.admin || role == UserRole.employee;

    final rawVerified = json['is_registration_verified'] ??
        json['isRegistrationVerified'] ??
        json['registration_verified'] ??
        json['email_verified'] ??
        json['emailVerified'] ??
        json['is_verified'] ??
        json['isVerified'];

    final bool verified;
    if (isPrivileged) {
      verified = true;
    } else if (rawVerified != null) {
      verified = rawVerified == true || rawVerified.toString().toLowerCase() == 'true';
    } else {
      // Defensive legacy account check:
      // Customers created prior to OTP integration with accepted terms, loyalty points, or established record
      final hasTerms = (json['terms_accepted'] ?? json['termsAccepted'] ?? false) as bool;
      final points = (json['loyalty_points'] ?? json['points'] ?? 0) as int;
      final hasCreatedDate = json['created_at'] != null || json['createdAt'] != null;
      verified = hasTerms || points > 50 || hasCreatedDate;
    }

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['fullName'] ?? json['name'] ?? '').toString(),
      phoneNumber: json['phone_number']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['phone']?.toString(),
      role: role,
      status: UserStatus.fromString(json['status']?.toString()),
      mustChangePassword: (json['must_change_password'] ?? json['mustChangePassword'] ?? false) as bool,
      isRegistrationVerified: verified,
      registrationVerifiedAt: json['registration_verified_at'] != null
          ? DateTime.tryParse(json['registration_verified_at'].toString())
          : (json['registrationVerifiedAt'] != null
              ? DateTime.tryParse(json['registrationVerifiedAt'].toString())
              : null),
      permissions: perms,
      avatarUrl: json['avatar_url']?.toString() ?? json['avatar']?.toString(),
      loyaltyPoints: (json['loyalty_points'] ?? json['points'] ?? 0) as int,
      termsAccepted: (json['terms_accepted'] ?? json['termsAccepted'] ?? false) as bool,
      acceptedTermsVersion: json['accepted_terms_version']?.toString() ?? json['acceptedTermsVersion']?.toString(),
      termsAcceptedAt: json['terms_accepted_at'] != null
          ? DateTime.tryParse(json['terms_accepted_at'].toString())
          : (json['termsAcceptedAt'] != null ? DateTime.tryParse(json['termsAcceptedAt'].toString()) : null),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      lastLoginAt: json['last_login_at'] != null ? DateTime.tryParse(json['last_login_at'].toString()) : null,
      firstOrderGcashCompleted: (json['first_order_gcash_completed'] ?? json['firstOrderGcashCompleted'] ?? false) == true,
      firstOrderCompletedOrderId: (json['first_order_completed_order_id'] ?? json['firstOrderCompletedOrderId'])?.toString(),
      firstOrderCompletedAt: (json['first_order_completed_at'] ?? json['firstOrderCompletedAt']) != null
          ? DateTime.tryParse((json['first_order_completed_at'] ?? json['firstOrderCompletedAt']).toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      'role': role.name,
      'status': status.name,
      'must_change_password': mustChangePassword,
      'is_registration_verified': isRegistrationVerified,
      if (registrationVerifiedAt != null) 'registration_verified_at': registrationVerifiedAt?.toIso8601String(),
      'permissions': permissions.map((p) => p.name).toList(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'loyalty_points': loyaltyPoints,
      'terms_accepted': termsAccepted,
      if (acceptedTermsVersion != null) 'accepted_terms_version': acceptedTermsVersion,
      if (termsAcceptedAt != null) 'terms_accepted_at': termsAcceptedAt?.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (lastLoginAt != null) 'last_login_at': lastLoginAt?.toIso8601String(),
      'first_order_gcash_completed': firstOrderGcashCompleted,
      if (firstOrderCompletedOrderId != null) 'first_order_completed_order_id': firstOrderCompletedOrderId,
      if (firstOrderCompletedAt != null) 'first_order_completed_at': firstOrderCompletedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    UserStatus? status,
    bool? mustChangePassword,
    bool? isRegistrationVerified,
    DateTime? registrationVerifiedAt,
    List<EmployeePermission>? permissions,
    String? avatarUrl,
    int? loyaltyPoints,
    bool? termsAccepted,
    String? acceptedTermsVersion,
    DateTime? termsAcceptedAt,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? firstOrderGcashCompleted,
    String? firstOrderCompletedOrderId,
    DateTime? firstOrderCompletedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      isRegistrationVerified: isRegistrationVerified ?? this.isRegistrationVerified,
      registrationVerifiedAt: registrationVerifiedAt ?? this.registrationVerifiedAt,
      permissions: permissions ?? this.permissions,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      acceptedTermsVersion: acceptedTermsVersion ?? this.acceptedTermsVersion,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      firstOrderGcashCompleted: firstOrderGcashCompleted ?? this.firstOrderGcashCompleted,
      firstOrderCompletedOrderId: firstOrderCompletedOrderId ?? this.firstOrderCompletedOrderId,
      firstOrderCompletedAt: firstOrderCompletedAt ?? this.firstOrderCompletedAt,
    );
  }

  bool get isGuest => id == 'guest' || email.isEmpty;
  bool get isAdmin => role == UserRole.admin;
  bool get isEmployee => role == UserRole.employee;
  bool get isBarista => role == UserRole.employee;
  bool get isStaff => role == UserRole.admin || role == UserRole.employee;
  bool get isBusinessUser => isStaff;
  bool get isCustomer => role == UserRole.customer;
  bool get isActive => status == UserStatus.active;
  bool get isDisabled => status == UserStatus.disabled;
  bool get isPendingActivation => status == UserStatus.pendingActivation;

  /// Check whether the account has accepted the current required terms version
  bool hasAcceptedTerms(String requiredVersion) {
    if (isGuest) return true;
    return termsAccepted && acceptedTermsVersion == requiredVersion;
  }

  bool hasPermission(EmployeePermission permission) {
    if (isAdmin) return true;
    return permissions.contains(permission);
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phoneNumber,
        role,
        status,
        mustChangePassword,
        isRegistrationVerified,
        registrationVerifiedAt,
        permissions,
        avatarUrl,
        loyaltyPoints,
        termsAccepted,
        acceptedTermsVersion,
        termsAcceptedAt,
        createdAt,
        lastLoginAt,
        firstOrderGcashCompleted,
        firstOrderCompletedOrderId,
        firstOrderCompletedAt,
      ];
}
