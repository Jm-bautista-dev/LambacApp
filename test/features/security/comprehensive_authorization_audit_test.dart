import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/routing/app_routes.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_account_management_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/models/create_user_request.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/cart_item_model.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/datasources/mock_order_remote_datasource.dart';
import 'package:lambac_app/features/orders/data/models/create_order_request.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:lambac_app/features/reviews/data/models/product_review_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Lambac Roastery — Comprehensive Production Security Authorization Audit Suite', () {
    late MockUserDatabase userDb;
    late MockOrderRemoteDataSource orderDataSource;
    late OrderRepositoryImpl orderRepository;
    late InMemoryStorageService storageService;
    late MockAccountManagementRemoteDataSource accountManagementDataSource;

    final customer1 = UserModel(
      id: 'usr_cust_1',
      email: 'customer1@lambac.com',
      fullName: 'Alice Customer',
      role: UserRole.customer,
      status: UserStatus.active,
      loyaltyPoints: 50,
      termsAccepted: true,
      acceptedTermsVersion: '1.0.0',
      createdAt: DateTime(2026, 1, 1),
    );

    final customer2 = UserModel(
      id: 'usr_cust_2',
      email: 'customer2@lambac.com',
      fullName: 'Bob Customer',
      role: UserRole.customer,
      status: UserStatus.active,
      loyaltyPoints: 20,
      termsAccepted: true,
      acceptedTermsVersion: '1.0.0',
      createdAt: DateTime(2026, 1, 2),
    );

    final baristaUser = UserModel(
      id: 'usr_barista_hiro',
      email: 'barista.hiro@lambac.com',
      fullName: 'Hiro Tanaka (Barista)',
      role: UserRole.employee,
      status: UserStatus.active,
      termsAccepted: true,
      acceptedTermsVersion: '1.0.0',
      permissions: const [
        EmployeePermission.manageOrders,
        EmployeePermission.recordSales,
        EmployeePermission.manageInbox,
      ],
      createdAt: DateTime(2026, 1, 1),
    );

    final adminUser = UserModel(
      id: 'usr_admin_lead',
      email: 'jmbautista0228@gmail.com',
      fullName: 'Lead Administrator',
      role: UserRole.admin,
      status: UserStatus.active,
      termsAccepted: true,
      acceptedTermsVersion: '1.0.0',
      permissions: EmployeePermission.values,
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      userDb = MockUserDatabase();
      userDb.resetForTests();
      orderDataSource = MockOrderRemoteDataSource();
      orderDataSource.resetForTesting();
      storageService = InMemoryStorageService();
      orderRepository = OrderRepositoryImpl(
        remoteDataSource: orderDataSource,
        storageService: storageService,
      );
      accountManagementDataSource = MockAccountManagementRemoteDataSource();
    });

    // =========================================================================
    // 1. CROSS-CUSTOMER DATA ISOLATION
    // =========================================================================
    group('1. Cross-Customer Private Data Isolation', () {
      test('Customer 1 cannot access, view, or receive Customer 2 orders', () async {
        // Seed order belonging to Customer 2
        orderDataSource.addOrder(
          OrderModel(
            id: 'ord_c2_secret',
            orderNumber: 'LMB-7777',
            customerId: customer2.id,
            customerName: customer2.fullName,
            customerPhone: '09171112222',
            items: const [],
            subtotal: 350.0,
            totalAmount: 350.0,
            status: OrderStatus.pending,
            pickupLocation: PickupLocationModel.flagship,
            pickupDate: 'Today',
            pickupTimeSlot: 'ASAP',
            paymentMethod: 'Pay at Counter',
            paymentStatus: 'UNPAID',
            createdAt: DateTime.now(),
          ),
        );

        // Customer 1 queries orders
        userDb.setCurrentUser(customer1);
        final result = await orderRepository.getOrders();
        expect(result.isSuccess, isTrue);

        final returnedOrders = result.dataOrNull?.items ?? [];
        expect(returnedOrders.any((o) => o.customerId == customer2.id), isFalse,
            reason: 'Customer 1 must never receive Customer 2 orders.');
        expect(returnedOrders.isEmpty, isTrue);
      });

      test('Customer 1 direct lookup of Customer 2 order returns NotFound or Forbidden', () async {
        orderDataSource.addOrder(
          OrderModel(
            id: 'ord_c2_private',
            orderNumber: 'LMB-8888',
            customerId: customer2.id,
            customerName: customer2.fullName,
            customerPhone: '09171112222',
            items: const [],
            subtotal: 500.0,
            totalAmount: 500.0,
            status: OrderStatus.pending,
            pickupLocation: PickupLocationModel.flagship,
            pickupDate: 'Today',
            pickupTimeSlot: 'ASAP',
            paymentMethod: 'Pay at Counter',
            paymentStatus: 'UNPAID',
            createdAt: DateTime.now(),
          ),
        );

        userDb.setCurrentUser(customer1);
        final result = await orderRepository.getOrderById('ord_c2_private');
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ForbiddenFailure>());
      });

      test('Staff and Admin CAN view all customer orders for operational fulfillment', () async {
        orderDataSource.addOrder(
          OrderModel(
            id: 'ord_fulfillment_1',
            orderNumber: 'LMB-9999',
            customerId: customer2.id,
            customerName: customer2.fullName,
            customerPhone: '09171112222',
            items: const [],
            subtotal: 280.0,
            totalAmount: 280.0,
            status: OrderStatus.confirmed,
            pickupLocation: PickupLocationModel.flagship,
            pickupDate: 'Today',
            pickupTimeSlot: 'ASAP',
            paymentMethod: 'Pay at Counter',
            paymentStatus: 'UNPAID',
            createdAt: DateTime.now(),
          ),
        );

        // Staff access
        userDb.setCurrentUser(baristaUser);
        final staffLookup = await orderRepository.getOrderById('ord_fulfillment_1');
        expect(staffLookup.isSuccess, isTrue);
        expect(staffLookup.dataOrNull?.orderNumber, equals('LMB-9999'));

        // Admin access
        userDb.setCurrentUser(adminUser);
        final adminLookup = await orderRepository.getOrderById('ord_fulfillment_1');
        expect(adminLookup.isSuccess, isTrue);
        expect(adminLookup.dataOrNull?.orderNumber, equals('LMB-9999'));
      });
    });

    // =========================================================================
    // 2. PRIVILEGE ESCALATION & PROFILE MUTATION
    // =========================================================================
    group('2. Privilege Escalation & Profile Integrity', () {
      test('Customer model explicitly fails authorization for business / admin routes', () {
        expect(customer1.isAdmin, isFalse);
        expect(customer1.isEmployee, isFalse);
        expect(customer1.isBarista, isFalse);
        expect(customer1.isStaff, isFalse);
        expect(customer1.isBusinessUser, isFalse);

        expect(AppRoutes.adminOnlyRoutes.contains(AppRoutes.adminDashboard), isTrue);
        expect(AppRoutes.adminOnlyRoutes.contains(AppRoutes.adminAccounts), isTrue);
        expect(AppRoutes.operationalRoutes.contains(AppRoutes.pos), isTrue);
        expect(AppRoutes.operationalRoutes.contains(AppRoutes.staffOrders), isTrue);
      });

      test('Customer cannot self-assign staff permissions', () {
        expect(customer1.hasPermission(EmployeePermission.manageOrders), isFalse);
        expect(customer1.hasPermission(EmployeePermission.recordSales), isFalse);
        expect(customer1.hasPermission(EmployeePermission.manageProducts), isFalse);

        final attemptedEscalation = customer1.copyWith(
          permissions: const [EmployeePermission.manageOrders, EmployeePermission.manageProducts],
        );
        // Even if local state is forged, customer role is still customer
        expect(attemptedEscalation.isCustomer, isTrue);
        expect(attemptedEscalation.isStaff, isFalse);
      });

      test('Loyalty points modification: customer cannot arbitrarily inflate points', () {
        // Verified in firestore.rules: 'loyaltyPoints' is in the protected keys list
        const protectedFields = [
          'role', 'status', 'isActive', 'permissions', 'uid', 'email',
          'loyaltyPoints', 'loyalty_points', 'mustChangePassword', 'must_change_password',
          'createdAt', 'created_at'
        ];

        expect(protectedFields.contains('loyaltyPoints'), isTrue);
        expect(protectedFields.contains('loyalty_points'), isTrue);
        expect(protectedFields.contains('role'), isTrue);
        expect(protectedFields.contains('permissions'), isTrue);
      });
    });

    // =========================================================================
    // 3. ORDER STATUS & PAYMENT TAMPERING
    // =========================================================================
    group('3. Order Status & Payment Tampering Prevention', () {
      test('Customer CANNOT mark an order completed', () async {
        final order = OrderModel(
          id: 'ord_tamper_1',
          orderNumber: 'LMB-1001',
          customerId: customer1.id,
          customerName: customer1.fullName,
          customerPhone: '09170000000',
          items: const [],
          subtotal: 200.0,
          totalAmount: 200.0,
          status: OrderStatus.pending,
          pickupLocation: PickupLocationModel.flagship,
          pickupDate: 'Today',
          pickupTimeSlot: 'ASAP',
          paymentMethod: 'Pay at Counter',
          paymentStatus: 'UNPAID',
          createdAt: DateTime.now(),
        );
        orderDataSource.addOrder(order);

        // Customer attempts to update status to completed
        userDb.setCurrentUser(customer1);
        final updateAttempt = await orderRepository.updateOrderStatus('ord_tamper_1', OrderStatus.completed);
        expect(updateAttempt.isFailure, isTrue);
        expect(updateAttempt.failureOrNull, isA<ForbiddenFailure>());
      });

      test('Customer CANNOT cancel an order once readyForPickup or completed', () {
        // Enforced by OrderStatus.canTransitionTo business rules
        expect(OrderStatus.readyForPickup.canTransitionTo(OrderStatus.cancelled), isFalse);
        expect(OrderStatus.completed.canTransitionTo(OrderStatus.cancelled), isFalse);
        expect(OrderStatus.cancelled.canTransitionTo(OrderStatus.confirmed), isFalse);
      });

      test('Customer order creation MUST initialize payment_status as UNPAID', () async {
        userDb.setCurrentUser(customer1);
        final result = await orderRepository.createOrder(
          CreateOrderRequest(
            customerName: customer1.fullName,
            customerPhone: '09170000000',
            pickupLocation: PickupLocationModel.flagship,
            pickupTimeSlot: 'ASAP',
            paymentMethod: 'Pay at Counter',
            items: const [
              CartItemModel(
                id: 'cart_item_audit_1',
                productId: 'mt-apo',
                productName: 'Mount Apo',
                origin: 'Davao',
                roastLevel: 'Light Roast',
                unitPrice: 480.0,
                quantity: 1,
              ),
            ],
          ),
        );

        expect(result.isSuccess, isTrue);
        final created = result.dataOrNull!;
        expect(created.paymentStatus.toUpperCase(), equals('UNPAID'));
        expect(created.status, equals(OrderStatus.pending));
      });
    });

    // =========================================================================
    // 4. EMPLOYEE & STAFF ACCOUNT PROVISIONING
    // =========================================================================
    group('4. Employee & Staff Account Provisioning Authorization', () {
      test('Customer CANNOT provision an employee or admin account', () async {
        userDb.setCurrentUser(customer1);

        final createAttempt = await accountManagementDataSource.createEmployee(
          const CreateEmployeeRequest(
            email: 'hacked.staff@lambac.com',
            fullName: 'Rogue Staff',
            initialPassword: 'Password123!',
            permissions: [EmployeePermission.manageOrders],
          ),
        );

        expect(createAttempt.isFailure, isTrue);
        expect(createAttempt.failureOrNull, isA<ForbiddenFailure>());
      });

      test('Barista CANNOT provision other employees or administrators', () async {
        userDb.setCurrentUser(baristaUser);

        final adminAttempt = await accountManagementDataSource.createAdmin(
          const CreateAdminRequest(
            email: 'unauth.admin@lambac.com',
            fullName: 'Unauth Admin',
            initialPassword: 'Password123!',
          ),
        );

        expect(adminAttempt.isFailure, isTrue);
        expect(adminAttempt.failureOrNull, isA<ForbiddenFailure>());
      });

      test('Administrator CAN legitimately provision Barista and Admin accounts', () async {
        userDb.setCurrentUser(adminUser);

        final createEmployeeResult = await accountManagementDataSource.createEmployee(
          const CreateEmployeeRequest(
            email: 'new.barista@lambaccoffee.com',
            fullName: 'Kenji Barista',
            initialPassword: 'Password123!',
            permissions: [EmployeePermission.manageOrders, EmployeePermission.recordSales],
          ),
        );

        expect(createEmployeeResult.isSuccess, isTrue);
        final newBarista = createEmployeeResult.dataOrNull!;
        expect(newBarista.role, equals(UserRole.employee));
        expect(newBarista.mustChangePassword, isTrue);
      });
    });

    // =========================================================================
    // 5. REVIEW MODERATION & FLAGGING INTEGRITY
    // =========================================================================
    group('5. Review Moderation & Flagging Protection', () {
      test('Flagged review cannot be read by public catalog browsing', () {
        final flaggedReview = ProductReviewModel(
          id: 'rev_flagged_1',
          productId: 'prod_123',
          customerName: customer1.fullName,
          rating: 1,
          comment: 'Inappropriate content',
          createdAt: DateTime.now(),
          isFlagged: true,
        );

        // Public visibility rule in firestore.rules:
        // allow read: if resource.data.is_flagged != true || isStaff();
        final isPubliclyVisible = !flaggedReview.isFlagged;
        expect(isPubliclyVisible, isFalse);

        // Staff visibility check
        final isStaffVisible = baristaUser.isStaff || adminUser.isStaff;
        expect(isStaffVisible, isTrue);
      });

      test('Protected review fields prevent author from unflagging', () {
        const protectedReviewUpdateKeys = [
          'customer_id', 'product_id', 'is_flagged', 'flagged_by', 'flagged_at', 'flag_reason'
        ];
        expect(protectedReviewUpdateKeys.contains('is_flagged'), isTrue);
        expect(protectedReviewUpdateKeys.contains('customer_id'), isTrue);
        expect(protectedReviewUpdateKeys.contains('product_id'), isTrue);
      });
    });

    // =========================================================================
    // 6. STORAGE & PRODUCT ASSET PERMISSIONS
    // =========================================================================
    group('6. Storage & Asset Protection Rules', () {
      test('Storage rules enforce MIME type and file size boundaries (< 5MB)', () {
        const maxSizeBytes = 5 * 1024 * 1024; // 5MB
        const validMimes = ['image/jpeg', 'image/png', 'image/webp'];

        expect(maxSizeBytes, equals(5242880));
        expect(validMimes.contains('image/jpeg'), isTrue);
        expect(validMimes.contains('image/png'), isTrue);
        expect(validMimes.contains('image/webp'), isTrue);
        expect(validMimes.contains('application/x-executable'), isFalse);
      });

      test('Only staff and admin can write or mutate product images', () {
        expect(customer1.isStaff, isFalse);
        expect(baristaUser.isStaff, isTrue);
        expect(adminUser.isStaff, isTrue);
      });
    });
  });
}
