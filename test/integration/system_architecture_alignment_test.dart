import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/routing/app_routes.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_account_management_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/models/create_walk_in_sale_request.dart';
import 'package:lambac_app/features/sales/data/models/sales_channel.dart';
import 'package:lambac_app/features/sales/data/models/sales_record_item_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('Official Lambac System Architecture Alignment Tests', () {
    late MockUserDatabase userDb;
    late MockSalesRemoteDataSource salesDataSource;
    late MockAdminRemoteDataSource adminDataSource;
    late MockAccountManagementRemoteDataSource accountDataSource;

    final defaultAdmin = UserModel(
      id: 'usr_admin_owner',
      email: 'jmbautista0228@gmail.com',
      fullName: 'JM Bautista',
      role: UserRole.admin,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    final staffEmployee = UserModel(
      id: 'usr_staff_1',
      email: 'barista.hiro@lambac.com',
      fullName: 'Hiro Takahashi',
      role: UserRole.employee,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 2),
    );

    final customer = UserModel(
      id: 'usr_cust_alice',
      email: 'alice@customer.com',
      fullName: 'Alice Walker',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 3),
    );

    setUp(() {
      userDb = MockUserDatabase();
      userDb.seedDefaultUsers();
      salesDataSource = MockSalesRemoteDataSource();
      adminDataSource = MockAdminRemoteDataSource();
      accountDataSource = MockAccountManagementRemoteDataSource();
    });

    test('1. Role-based entry destination routing: Admin -> Business Platform, Customer -> Customer Experience', () {
      // Helper function matching login and splash redirection logic
      String resolveRoleDestination(UserModel? user, {String? redirectPath}) {
        if (redirectPath != null) return redirectPath;
        if (user != null && !user.isGuest && user.isBusinessUser) {
          return AppRoutes.adminDashboard;
        }
        return AppRoutes.home;
      }

      expect(resolveRoleDestination(defaultAdmin), equals(AppRoutes.adminDashboard));
      expect(resolveRoleDestination(staffEmployee), equals(AppRoutes.adminDashboard));
      expect(resolveRoleDestination(customer), equals(AppRoutes.home));
      expect(resolveRoleDestination(null), equals(AppRoutes.home));
    });

    test('2. Backend Security: Customer calling Centralized Sales Ledger is rejected with 403 Forbidden', () async {
      userDb.setCurrentUser(customer);

      // Attempt to access sales ledger
      final ledgerResult = await salesDataSource.getSalesRecords();
      expect(ledgerResult.isFailure, isTrue);
      expect(ledgerResult.failureOrNull, isA<ForbiddenFailure>());
    });

    test('3. Backend Security: Customer calling Business Metrics is rejected with 403 Forbidden', () async {
      userDb.setCurrentUser(customer);

      final metricsResult = await adminDataSource.getBusinessMetrics();
      expect(metricsResult.isFailure, isTrue);
      expect(metricsResult.failureOrNull, isA<ForbiddenFailure>());
    });

    test('4. Backend Security: Customer or Employee calling Account Management is rejected', () async {
      // Customer attempt
      userDb.setCurrentUser(customer);
      final custAttempt = await accountDataSource.getBusinessUsers();
      expect(custAttempt.isFailure, isTrue);
      expect(custAttempt.failureOrNull, isA<ForbiddenFailure>());

      // Employee attempt
      userDb.setCurrentUser(staffEmployee);
      final staffAttempt = await accountDataSource.getBusinessUsers();
      expect(staffAttempt.isFailure, isTrue);
      expect(staffAttempt.failureOrNull, isA<ForbiddenFailure>());

      // Admin attempt -> Allowed
      userDb.setCurrentUser(defaultAdmin);
      final adminAttempt = await accountDataSource.getBusinessUsers();
      expect(adminAttempt.isSuccess, isTrue);
    });

    test('5. Business Platform: Admin and Staff can successfully access Centralized Sales Ledger', () async {
      userDb.setCurrentUser(staffEmployee);

      final ledgerResult = await salesDataSource.getSalesRecords();
      expect(ledgerResult.isSuccess, isTrue);
      final sales = ledgerResult.dataOrNull!;
      expect(sales.isNotEmpty, isTrue);
      expect(sales.every((s) => s.channel == SalesChannel.mobileApp), isTrue);
    });
  });
}
