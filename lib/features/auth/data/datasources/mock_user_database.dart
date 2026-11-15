import 'dart:convert';
import '../../../../core/security/audit_logger.dart';
import '../../../../core/security/password_hasher.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/mock_ledger_store.dart';

/// User record storing user model and salted password hash
class UserDatabaseRecord {
  UserModel user;
  String passwordHash;

  UserDatabaseRecord({
    required this.user,
    required this.passwordHash,
  });

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'passwordHash': passwordHash,
    };
  }

  factory UserDatabaseRecord.fromJson(Map<String, dynamic> json) {
    return UserDatabaseRecord(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      passwordHash: (json['passwordHash'] ?? '').toString(),
    );
  }
}

/// Unified, Secure In-Memory & Persisted User Database for Lambac Platform Mock Services
class MockUserDatabase {
  static final MockUserDatabase _instance = MockUserDatabase._internal();
  factory MockUserDatabase() => _instance;

  final Map<String, UserDatabaseRecord> _records = {};
  UserModel? _currentUser;
  bool _isSeeded = false;

  MockUserDatabase._internal() {
    if (!_loadPersistedUsers()) {
      seedDefaultUsers();
      _persistUsers();
    }
  }

  /// Restores the persisted users ledger. Returns false when nothing was persisted.
  bool _loadPersistedUsers() {
    final raw = MockLedgerStore.read(MockLedgerStore.usersKey);
    if (raw == null) return false;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded.isEmpty) return false;
      _records.clear();
      decoded.forEach((key, value) {
        _records[key.trim().toLowerCase()] =
            UserDatabaseRecord.fromJson(value as Map<String, dynamic>);
      });
      const initialAdminEmail = 'jmbautista0228@gmail.com';
      if (_records.containsKey(initialAdminEmail)) {
        _currentUser = _records[initialAdminEmail]?.user;
      } else if (_records.isNotEmpty) {
        _currentUser = _records.values.first.user;
      }
      _isSeeded = true;
      return true;
    } catch (_) {
      _records.clear();
      return false;
    }
  }

  /// Writes all committed user records to durable storage
  void _persistUsers() {
    if (!MockLedgerStore.isEnabled) return;
    final map = _records.map((k, v) => MapEntry(k, v.toJson()));
    MockLedgerStore.write(
      MockLedgerStore.usersKey,
      jsonEncode(map),
    );
  }

  /// Reloads persisted user accounts from storage after MockLedgerStore.init() finishes
  void reloadPersistedUsers() {
    if (MockLedgerStore.isEnabled) {
      if (!_loadPersistedUsers()) {
        seedDefaultUsers();
        _persistUsers();
      }
    }
  }

  /// Idempotent seeding of default admin and demo accounts
  void seedDefaultUsers() {
    if (_isSeeded && _records.containsKey('jmbautista0228@gmail.com')) {
      return;
    }

    // 1. DEFAULT ADMINISTRATOR (jmbautista0228@gmail.com)
    // Secure initial password: read from environment if configured, or default to standard seed hash
    const initialAdminEmail = 'jmbautista0228@gmail.com';
    const envAdminPassword = String.fromEnvironment('DEFAULT_ADMIN_PASSWORD', defaultValue: 'LambacAdmin2026!');

    if (!_records.containsKey(initialAdminEmail)) {
      final defaultAdmin = UserModel(
        id: 'usr_admin_default',
        email: initialAdminEmail,
        fullName: 'Lead Roastery Administrator',
        phoneNumber: '09170228000',
        role: UserRole.admin,
        status: UserStatus.active,
        mustChangePassword: false,
        loyaltyPoints: 1000,
        createdAt: DateTime(2026, 1, 1),
        lastLoginAt: DateTime.now(),
      );

      _records[initialAdminEmail] = UserDatabaseRecord(
        user: defaultAdmin,
        passwordHash: PasswordHasher.hashPassword(envAdminPassword),
      );

      AuditLogger().log(
        action: AuditActionType.adminCreated,
        actorEmail: 'system.provisioning@lambaccoffee.com',
        actorRole: 'system',
        targetEmail: initialAdminEmail,
        targetRole: 'admin',
        details: 'Idempotent provisioning of initial default business administrator',
      );
    }

    // 2. Demo Customer Account
    const customerEmail = 'coffee.lover@lambac.com';
    if (!_records.containsKey(customerEmail)) {
      final demoCustomer = UserModel(
        id: 'usr_customer_demo',
        email: customerEmail,
        fullName: 'Kenji Takahashi',
        phoneNumber: '09171234567',
        role: UserRole.customer,
        status: UserStatus.active,
        isRegistrationVerified: true,
        registrationVerifiedAt: DateTime(2026, 2, 10),
        loyaltyPoints: 120,
        createdAt: DateTime(2026, 2, 10),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 3)),
        firstOrderGcashCompleted: true,
      );

      _records[customerEmail] = UserDatabaseRecord(
        user: demoCustomer,
        passwordHash: PasswordHasher.hashPassword('password123'),
      );
    }

    // 3. Demo Employee Account (Shift Barista)
    const employeeEmail = 'barista.staff@lambac.com';
    if (!_records.containsKey(employeeEmail)) {
      final demoEmployee = UserModel(
        id: 'usr_employee_demo',
        email: employeeEmail,
        fullName: 'Sora Tanaka',
        phoneNumber: '09187654321',
        role: UserRole.employee,
        status: UserStatus.active,
        mustChangePassword: false,
        permissions: const [
          EmployeePermission.manageOrders,
          EmployeePermission.manageInbox,
          EmployeePermission.recordSales,
        ],
        createdAt: DateTime(2026, 2, 15),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      _records[employeeEmail] = UserDatabaseRecord(
        user: demoEmployee,
        passwordHash: PasswordHasher.hashPassword('baristapass123'),
      );
    }

    _currentUser = _records[initialAdminEmail]?.user;
    _isSeeded = true;
    _persistUsers();
  }

  // --- Accessors ---

  UserModel? get currentUser => _currentUser;
  void setCurrentUser(UserModel? user) => _currentUser = user;

  Map<String, UserDatabaseRecord> get records => _records;

  UserDatabaseRecord? getByEmail(String email) {
    return _records[email.trim().toLowerCase()];
  }

  UserDatabaseRecord? getById(String id) {
    for (final record in _records.values) {
      if (record.user.id == id) return record;
    }
    return null;
  }

  void saveRecord(UserDatabaseRecord record) {
    _records[record.user.email.trim().toLowerCase()] = record;
    _persistUsers();
  }

  void removeByEmail(String email) {
    _records.remove(email.trim().toLowerCase());
    _persistUsers();
  }

  void resetForTests() {
    _records.clear();
    _isSeeded = false;
    seedDefaultUsers();
  }
}
