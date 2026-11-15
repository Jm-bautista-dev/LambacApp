import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/routing/app_routes.dart';
import 'package:lambac_app/core/routing/route_guards.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/features/admin/data/models/create_user_request.dart';

void main() {
  group('Barista Role Normalization, Authentication & Routing Suite', () {
    test('1. UserRole.tryParse accurately recognizes all case and alias variations of Barista', () {
      expect(UserRole.tryParse('barista'), equals(UserRole.employee));
      expect(UserRole.tryParse('BARISTA'), equals(UserRole.employee));
      expect(UserRole.tryParse('Barista'), equals(UserRole.employee));
      expect(UserRole.tryParse('  barista  '), equals(UserRole.employee));
      expect(UserRole.tryParse('employee'), equals(UserRole.employee));
      expect(UserRole.tryParse('EMPLOYEE'), equals(UserRole.employee));
      expect(UserRole.tryParse('staff'), equals(UserRole.employee));
      expect(UserRole.tryParse('admin'), equals(UserRole.admin));
      expect(UserRole.tryParse('ADMIN'), equals(UserRole.admin));
      expect(UserRole.tryParse('super_admin'), equals(UserRole.admin));
      expect(UserRole.tryParse('customer'), equals(UserRole.customer));
      expect(UserRole.tryParse('CUSTOMER'), equals(UserRole.customer));
      
      // Invalid or unassigned roles return null (preventing silent fallback to customer)
      expect(UserRole.tryParse(null), isNull);
      expect(UserRole.tryParse(''), isNull);
      expect(UserRole.tryParse('unknown_role'), isNull);
      expect(UserRole.tryParse('hacker'), isNull);
    });

    test('2. UserModel flags correctly identify Barista vs Customer vs Admin', () {
      const barista = UserModel(
        id: 'usr_barista_01',
        email: 'barista@lambac.com',
        fullName: 'Barista Brent',
        role: UserRole.barista,
      );

      expect(barista.isBarista, isTrue);
      expect(barista.isEmployee, isTrue);
      expect(barista.isStaff, isTrue);
      expect(barista.isCustomer, isFalse);
      expect(barista.isAdmin, isFalse);
      expect(barista.role.toFormattedString(), equals('Barista / Operations Staff'));

      const customer = UserModel(
        id: 'usr_cust_01',
        email: 'customer@gmail.com',
        fullName: 'Coffee Lover',
        role: UserRole.customer,
      );

      expect(customer.isBarista, isFalse);
      expect(customer.isCustomer, isTrue);
      expect(customer.isAdmin, isFalse);
    });

    test('3. getRoleHomeRoute routes Barista to dedicated Staff Orders Station, never Customer Home', () {
      const barista = UserModel(
        id: 'usr_barista_01',
        email: 'barista@lambac.com',
        fullName: 'Barista Brent',
        role: UserRole.barista,
      );

      const admin = UserModel(
        id: 'usr_admin_01',
        email: 'admin@lambac.com',
        fullName: 'Admin JM',
        role: UserRole.admin,
      );

      const customer = UserModel(
        id: 'usr_cust_01',
        email: 'customer@gmail.com',
        fullName: 'Customer Carlo',
        role: UserRole.customer,
      );

      // Dedicated route verification
      expect(getRoleHomeRoute(barista), equals(AppRoutes.staffOrders));
      expect(getRoleHomeRoute(admin), equals(AppRoutes.adminDashboard));
      expect(getRoleHomeRoute(customer), equals(AppRoutes.home));
      expect(getRoleHomeRoute(null), equals(AppRoutes.home));
    });

    test('4. CreateEmployeeRequest serializes canonical barista role for Firestore', () {
      const request = CreateEmployeeRequest(
        fullName: 'Barista Jordan',
        email: 'jordan@lambac.com',
        initialPassword: 'TempPassword2026!',
        permissions: [EmployeePermission.manageOrders, EmployeePermission.manageInbox],
      );

      final json = request.toJson();
      expect(json['role'], equals('barista'));
      expect(json['email'], equals('jordan@lambac.com'));
      expect(json['full_name'], equals('Barista Jordan'));
      expect(json['must_change_password'], isTrue);
    });
  });
}
