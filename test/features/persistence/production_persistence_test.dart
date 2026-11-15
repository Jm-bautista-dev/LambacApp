import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_account_management_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/models/create_user_request.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/auth/data/models/login_request.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/mock_ledger_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MockLedgerStore.init();
    MockUserDatabase().resetForTests();
    MockOrderRemoteDataSource().resetForTesting();
    MockSalesRemoteDataSource().resetForTesting();
  });

  group('Production Persistence Audit & Lifecycle Tests', () {
    test('TEST A: Admin account creation survives app restart and authenticates properly', () async {
      final accountDataSource = MockAccountManagementRemoteDataSource();
      final authDataSource = MockAuthRemoteDataSource();

      // 1. Initial caller is the default seeded admin
      expect(MockUserDatabase().currentUser?.isAdmin, isTrue);

      // 2. Create a new Admin account
      const newAdminEmail = 'partner.admin@lambaccoffee.com';
      const newAdminPassword = 'StrongAdmin2026!';
      final createRes = await accountDataSource.createAdmin(
        const CreateAdminRequest(
          fullName: 'Partner Roastery Executive',
          email: newAdminEmail,
          initialPassword: newAdminPassword,
          mustChangePassword: false,
        ),
      );

      expect(createRes.isSuccess, isTrue);
      final createdAdmin = createRes.dataOrNull!;
      expect(createdAdmin.email, equals(newAdminEmail));
      expect(createdAdmin.role, equals(UserRole.admin));

      // 3. Log out
      await authDataSource.logout();
      expect(MockUserDatabase().currentUser, isNull);

      // 4. Log back in with newly created Admin account
      final loginRes1 = await authDataSource.login(
        const LoginRequest(email: newAdminEmail, password: newAdminPassword),
      );
      expect(loginRes1.isSuccess, isTrue);
      expect(loginRes1.dataOrNull!.user.role, equals(UserRole.admin));

      // 5. Terminate and simulate app restart
      // Re-initialize ledger store and reload datasources
      MockUserDatabase().setCurrentUser(null);
      MockUserDatabase().reloadPersistedUsers();

      // 6. Log in after restart using the newly created Admin account
      final loginRes2 = await authDataSource.login(
        const LoginRequest(email: newAdminEmail, password: newAdminPassword),
      );
      expect(loginRes2.isSuccess, isTrue);
      final sessionUser = loginRes2.dataOrNull!.user;
      expect(sessionUser.email, equals(newAdminEmail));
      expect(sessionUser.role, equals(UserRole.admin));
      expect(sessionUser.isAdmin, isTrue);
    });

    test('TEST B: Order status transitions (PREPARING -> READY -> COMPLETED) persist across restart', () async {
      final orderDataSource = MockOrderRemoteDataSource();
      final salesDataSource = MockSalesRemoteDataSource();
      final adminDataSource = MockAdminRemoteDataSource();

      // Ensure authenticated business user
      MockUserDatabase().setCurrentUser(
        MockUserDatabase().getByEmail('jmbautista0228@gmail.com')?.user,
      );

      // 1. Pick an order currently in preparing status (e.g. ord_lmb_1082)
      final initialOrderRes = await orderDataSource.getOrderById('ord_lmb_1082');
      expect(initialOrderRes.isSuccess, isTrue);
      final initialOrder = initialOrderRes.dataOrNull!;
      expect(initialOrder.status, equals(OrderStatus.preparing));

      // 2. Advance to readyForPickup
      final readyRes = await orderDataSource.updateOrderStatus('ord_lmb_1082', OrderStatus.readyForPickup);
      expect(readyRes.isSuccess, isTrue);
      expect(readyRes.dataOrNull!.status, equals(OrderStatus.readyForPickup));

      // 3. Advance to completed
      final completedRes = await orderDataSource.updateOrderStatus('ord_lmb_1082', OrderStatus.completed);
      expect(completedRes.isSuccess, isTrue);
      expect(completedRes.dataOrNull!.status, equals(OrderStatus.completed));
      expect(completedRes.dataOrNull!.paymentStatus, equals('PAID'));

      // 4. Verify sales ledger recorded the completed sale
      expect(salesDataSource.hasSaleForOrder('ord_lmb_1082'), isTrue);

      // 5. Simulate Flutter process termination and application restart
      MockOrderRemoteDataSource().reloadPersistedOrders();
      MockSalesRemoteDataSource().reloadPersistedSales();

      // 6. Query order after restart
      final postRestartOrderRes = await orderDataSource.getOrderById('ord_lmb_1082');
      expect(postRestartOrderRes.isSuccess, isTrue);
      final postRestartOrder = postRestartOrderRes.dataOrNull!;
      expect(postRestartOrder.status, equals(OrderStatus.completed));
      expect(postRestartOrder.paymentStatus, equals('PAID'));
      expect(postRestartOrder.status, isNot(equals(OrderStatus.preparing)));

      // 7. Verify Dashboard Analytics metrics are updated and persisted
      final metricsRes = await adminDataSource.getBusinessMetrics();
      expect(metricsRes.isSuccess, isTrue);
      final metrics = metricsRes.dataOrNull!;
      expect(metrics.todaySales, greaterThan(0));
      expect(metrics.completedOrdersCount, greaterThanOrEqualTo(1));
    });
  });
}
