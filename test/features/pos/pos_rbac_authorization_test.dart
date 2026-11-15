import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/routing/app_routes.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('POS Role-Based Access Control (RBAC) Tests', () {
    const adminUser = UserModel(
      id: 'admin_1',
      fullName: 'Master Roaster Admin',
      email: 'admin@lambac.com',
      role: UserRole.admin,
    );

    const baristaUser = UserModel(
      id: 'barista_1',
      fullName: 'Barista Hiro',
      email: 'hiro.barista@lambac.com',
      role: UserRole.employee, // UserRole.employee is Barista
    );

    const customerUser = UserModel(
      id: 'customer_1',
      fullName: 'Coffee Lover',
      email: 'customer@gmail.com',
      role: UserRole.customer,
    );

    test('Both Admin and Barista are identified as authorized business users', () {
      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.isBusinessUser, isTrue);

      expect(baristaUser.isBarista, isTrue);
      expect(baristaUser.isEmployee, isTrue);
      expect(baristaUser.isBusinessUser, isTrue);
      expect(baristaUser.isAdmin, isFalse);

      expect(customerUser.isCustomer, isTrue);
      expect(customerUser.isBusinessUser, isFalse);
    });

    test('AppRoutes.pos is categorized under operationalRoutes', () {
      expect(AppRoutes.operationalRoutes.contains(AppRoutes.pos), isTrue);
      expect(AppRoutes.customerOnlyRoutes.contains(AppRoutes.pos), isFalse);
    });

    test('Customer is prohibited from operational business routes', () {
      final isCustomerAuthorizedForPos = !customerUser.isCustomer && customerUser.isBusinessUser;
      expect(isCustomerAuthorizedForPos, isFalse);
    });

    test('Barista cannot access Admin-only routes (Accounts, Forecast Benchmarking)', () {
      expect(baristaUser.isAdmin, isFalse);
      expect(AppRoutes.adminOnlyRoutes.contains(AppRoutes.adminAccounts), isTrue);
      expect(AppRoutes.adminOnlyRoutes.contains(AppRoutes.forecastBenchmarking), isTrue);
    });
  });
}
