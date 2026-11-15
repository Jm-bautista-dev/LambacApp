import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('Admin RBAC Unit Tests', () {
    test('Admin user role has full business & owner permissions', () {
      const adminUser = UserModel(
        id: 'usr_admin',
        email: 'admin@lambac.com',
        fullName: 'Master Roaster',
        role: UserRole.admin,
      );

      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.isStaff, isTrue);
      expect(adminUser.isBusinessUser, isTrue);
      expect(adminUser.isGuest, isFalse);
    });

    test('Staff user role has operational business permissions but not full admin', () {
      const staffUser = UserModel(
        id: 'usr_staff',
        email: 'staff@lambac.com',
        fullName: 'Shift Barista',
        role: UserRole.staff,
      );

      expect(staffUser.isAdmin, isFalse);
      expect(staffUser.isStaff, isTrue);
      expect(staffUser.isBusinessUser, isTrue);
    });

    test('Customer role does not have business permissions', () {
      const customerUser = UserModel(
        id: 'usr_customer',
        email: 'kenji@example.com',
        fullName: 'Kenji Takahashi',
        role: UserRole.customer,
      );

      expect(customerUser.isAdmin, isFalse);
      expect(customerUser.isStaff, isFalse);
      expect(customerUser.isBusinessUser, isFalse);
    });
  });
}
