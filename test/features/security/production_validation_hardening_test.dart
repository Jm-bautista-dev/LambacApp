import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/utils/image_validator.dart';
import 'package:lambac_app/core/utils/validators.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_account_management_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/admin/data/models/create_user_request.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/domain/services/pickup_scheduling_service.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('Production Validation Hardening Acceptance Suite', () {
    late MockUserDatabase userDb;
    late MockAdminRemoteDataSource adminDataSource;
    late MockAccountManagementRemoteDataSource accountManagementDataSource;

    final customerUser = UserModel(
      id: 'usr_cust_val',
      email: 'customer.val@lambac.com',
      fullName: 'Val Customer',
      role: UserRole.customer,
      status: UserStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    final adminUser = UserModel(
      id: 'usr_admin_val',
      email: 'admin.val@lambaccoffee.com',
      fullName: 'Lead Roaster Admin',
      role: UserRole.admin,
      status: UserStatus.active,
      permissions: EmployeePermission.values,
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      userDb = MockUserDatabase();
      userDb.resetForTests();
      adminDataSource = MockAdminRemoteDataSource();
      accountManagementDataSource = MockAccountManagementRemoteDataSource();
    });

    // =========================================================================
    // 1. EMPTY INPUTS VALIDATION
    // =========================================================================
    group('1. Empty Inputs Rejection', () {
      test('Rejects null or empty user profile fields (name, email, password, phone)', () {
        expect(Validators.fullName(''), equals('Please enter your full name'));
        expect(Validators.fullName('   '), equals('Please enter your full name'));
        expect(Validators.fullName(null), equals('Please enter your full name'));

        expect(Validators.email(''), equals('Please enter your email address'));
        expect(Validators.email('   '), equals('Please enter your email address'));
        expect(Validators.email(null), equals('Please enter your email address'));

        expect(Validators.password(''), equals('Please enter a password'));
        expect(Validators.password(null), equals('Please enter a password'));

        expect(Validators.phone(''), equals('Please enter your mobile number'));
        expect(Validators.phone(null), equals('Please enter your mobile number'));
      });

      test('Rejects empty product fields (name, price, stock)', () {
        expect(Validators.productName(''), equals('Please enter product name'));
        expect(Validators.productName('   '), equals('Please enter product name'));
        expect(Validators.productName(null), equals('Please enter product name'));

        expect(Validators.price(''), equals('Please enter Price'));
        expect(Validators.price(null), equals('Please enter Price'));

        expect(Validators.stock(''), equals('Please enter Stock quantity'));
        expect(Validators.stock(null), equals('Please enter Stock quantity'));
      });

      test('Rejects empty review comments and empty chat messages', () {
        expect(Validators.reviewComment(''), equals('Please share your tasting feedback'));
        expect(Validators.reviewComment('   '), equals('Please share your tasting feedback'));
        expect(Validators.reviewComment(null), equals('Please share your tasting feedback'));

        expect(Validators.chatMessage(''), equals('Cannot send an empty message'));
        expect(Validators.chatMessage('   '), equals('Cannot send an empty message'));
        expect(Validators.chatMessage(null), equals('Cannot send an empty message'));
      });
    });

    // =========================================================================
    // 2. OVERSIZED STRINGS & RANGE BOUNDARIES
    // =========================================================================
    group('2. Oversized Strings & Field Boundary Limits', () {
      test('Full name boundary: min 2, max 100 characters', () {
        expect(Validators.fullName('A'), equals('Full name must be at least 2 characters'));
        expect(Validators.fullName('A' * 101), equals('Full name cannot exceed 100 characters'));
        expect(Validators.fullName('Hiro Tanaka'), isNull);
      });

      test('Email address boundary: max 254 characters', () {
        final oversizedEmail = '${"a" * 250}@lambac.com';
        expect(Validators.email(oversizedEmail), equals('Email address cannot exceed 254 characters'));
        expect(Validators.email('guest@lambaccoffee.com'), isNull);
      });

      test('Product name boundary: min 2, max 120 characters', () {
        expect(Validators.productName('C'), equals('Product name must be at least 2 characters'));
        expect(Validators.productName('X' * 121), equals('Product name cannot exceed 120 characters'));
        expect(Validators.productName('Benguet Honey Arabica'), isNull);
      });

      test('Product price boundary: 0.01 to 50,000.00', () {
        expect(Validators.price('-10.00'), contains('cannot be negative'));
        expect(Validators.price('0.00'), contains('must be at least'));
        expect(Validators.price('50000.01'), contains('cannot exceed'));
        expect(Validators.price('abc'), equals('Price must be a valid number'));
        expect(Validators.price('450.00'), isNull);
      });

      test('Stock quantity boundary: 0 to 1,000,000 whole units', () {
        expect(Validators.stock('-5'), contains('cannot be negative'));
        expect(Validators.stock('1000001'), contains('cannot exceed 1000000'));
        expect(Validators.stock('12.5'), equals('Stock quantity must be a valid whole number'));
        expect(Validators.stock('25'), isNull);
      });

      test('Review comment boundary: min 3, max 1000 characters', () {
        expect(Validators.reviewComment('Hi'), equals('Review comment must be at least 3 characters'));
        expect(Validators.reviewComment('A' * 1001), equals('Review comment cannot exceed 1000 characters'));
        expect(Validators.reviewComment('Excellent balance of fruit acidity and chocolate sweetness.'), isNull);
      });

      test('Chat message boundary: max 2000 characters', () {
        expect(Validators.chatMessage('A' * 2001), equals('Message cannot exceed 2000 characters'));
        expect(Validators.chatMessage('Could you please recommend a pour-over recipe for Benguet Typica?'), isNull);
      });

      test('Order notes boundary: max 500 characters', () {
        expect(Validators.orderNotes('N' * 501), equals('Order notes cannot exceed 500 characters'));
        expect(Validators.orderNotes('Please grind for V60 filter brew.'), isNull);
        expect(Validators.orderNotes(null), isNull);
      });
    });

    // =========================================================================
    // 3. OPERATING HOURS & PICKUP DATES
    // =========================================================================
    group('3. Pickup Date/Time & Business Operating Hours Enforcement', () {
      final scheduler = PickupSchedulingService();

      test('Rejects pickup date in the past', () {
        final fixedNow = DateTime(2026, 9, 25, 12, 0);
        final result = scheduler.validateSchedule(
          dateStr: '2026-09-20',
          timeSlotStr: '12:00 PM',
          now: fixedNow,
        );
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull?.message, contains('cannot be in the past'));
      });

      test('Rejects pickup date exceeding max booking window (7 days)', () {
        final fixedNow = DateTime(2026, 9, 25, 12, 0);
        final result = scheduler.validateSchedule(
          dateStr: '2026-10-10',
          timeSlotStr: '12:00 PM',
          now: fixedNow,
        );
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull?.message, contains('cannot exceed 7 days in advance'));
      });

      test('Rejects pickup time slot outside roastery operating hours', () {
        final fixedNow = DateTime(2026, 9, 25, 12, 0);

        // Before flagship opening (7:00 AM)
        final earlyResult = scheduler.validateSchedule(
          dateStr: 'Tomorrow',
          timeSlotStr: '5:30 AM',
          now: fixedNow,
        );
        expect(earlyResult.isFailure, isTrue);
        expect(earlyResult.failureOrNull?.message, contains('within roastery hours'));

        // After flagship closing (9:00 PM)
        final lateResult = scheduler.validateSchedule(
          dateStr: 'Tomorrow',
          timeSlotStr: '9:45 PM',
          now: fixedNow,
        );
        expect(lateResult.isFailure, isTrue);
        expect(lateResult.failureOrNull?.message, contains('within roastery hours'));
      });

      test('Rejects pickup time with insufficient preparation buffer for today', () {
        final fixedNow = DateTime(2026, 9, 25, 14, 0); // 2:00 PM
        final result = scheduler.validateSchedule(
          dateStr: 'Today',
          timeSlotStr: '2:15 PM', // Only 15 mins buffer, location requires 60 mins
          now: fixedNow,
        );
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull?.message, contains('Minimum preparation buffer is'));
      });

      test('Accepts valid pickup schedule within business hours and buffer', () {
        final fixedNow = DateTime(2026, 9, 25, 12, 0);
        final result = scheduler.validateSchedule(
          dateStr: 'Today',
          timeSlotStr: '2:30 PM',
          now: fixedNow,
        );
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.timeSlot, equals('2:30 PM'));
      });
    });

    // =========================================================================
    // 4. PRODUCT IMAGES & STORAGE SECURITY
    // =========================================================================
    group('4. Product Images Content Inspection & Storage Boundary Rules', () {
      test('Rejects 0-byte empty file', () {
        final emptyBytes = Uint8List(0);
        final result = ImageValidator.validateImageBytes(emptyBytes);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('empty'));
      });

      test('Rejects oversized image (> 5 MB)', () {
        final oversized = Uint8List(5 * 1024 * 1024 + 1);
        final result = ImageValidator.validateImageBytes(oversized);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('smaller than 5 MB'));
      });

      test('Rejects disallowed formats by magic bytes: PDF, ZIP, EXE', () {
        // PDF header (%PDF)
        final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35]);
        expect(ImageValidator.validateImageBytes(pdfBytes).isValid, isFalse);

        // ZIP header (PK..)
        final zipBytes = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 0x14, 0x00]);
        expect(ImageValidator.validateImageBytes(zipBytes).isValid, isFalse);

        // Windows EXE header (MZ)
        final exeBytes = Uint8List.fromList([0x4D, 0x5A, 0x90, 0x00, 0x03]);
        expect(ImageValidator.validateImageBytes(exeBytes).isValid, isFalse);
      });

      test('Rejects GIF image because product catalog strictly accepts JPEG, PNG, and WebP', () {
        final gifBytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x20, 0x00]);
        final result = ImageValidator.validateImageBytes(gifBytes);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('JPG, PNG, or WebP'));
      });

      test('Generates secure, randomized storage filename preventing path traversal', () {
        final filename = ImageValidator.generateSecureFilename(
          format: SupportedImageFormat.jpeg,
          prefix: 'prod_img',
        );
        expect(filename.startsWith('prod_img_'), isTrue);
        expect(filename.endsWith('.jpg'), isTrue);
        expect(filename.contains('..'), isFalse);
        expect(filename.contains('/'), isFalse);
        expect(filename.contains(r'\'), isFalse);
      });
    });

    // =========================================================================
    // 5. AUTHORIZATION BOUNDARY & BYPASS PREVENTION
    // =========================================================================
    group('5. Authorization Boundary & Client Bypass Rejections', () {
      test('Customer cannot add or update catalog products at backend datasource', () async {
        userDb.setCurrentUser(customerUser);

        final attempt = await adminDataSource.addProduct(
          const ProductModel(
            id: 'hacked_prod',
            name: 'Rogue Coffee',
            slug: 'rogue-coffee',
            origin: 'Unknown',
            description: 'Tampered product',
            basePrice: 1.0,
            categoryId: 'beans',
            categoryName: 'Whole Bean',
            roastLevel: 'Dark Roast',
            tastingNotes: 'Bitter',
            availability: ProductAvailability.available,
            stockQuantity: 100,
          ),
        );

        expect(attempt.isFailure, isTrue);
        expect(attempt.failureOrNull, isA<ForbiddenFailure>());
      });

      test('Administrator product creation validates boundaries (price, stock, name)', () async {
        userDb.setCurrentUser(adminUser);

        // Invalid negative price
        final badPriceAttempt = await adminDataSource.addProduct(
          const ProductModel(
            id: 'bad_price_prod',
            name: 'Invalid Price Bean',
            slug: 'invalid-price-bean',
            origin: 'Sagada',
            description: 'Notes',
            basePrice: -50.0,
            categoryId: 'beans',
            categoryName: 'Whole Bean',
            roastLevel: 'Medium',
            tastingNotes: 'Vanilla',
            availability: ProductAvailability.available,
            stockQuantity: 50,
          ),
        );
        expect(badPriceAttempt.isFailure, isTrue);
        expect(badPriceAttempt.failureOrNull, isA<ValidationFailure>());

        // Valid product succeeds
        final validAttempt = await adminDataSource.addProduct(
          const ProductModel(
            id: 'valid_prod_1',
            name: 'Benguet Bourbon Anaerobic',
            slug: 'benguet-bourbon-anaerobic',
            origin: 'Atok, Benguet',
            description: 'Micro-lot natural processed high-altitude coffee.',
            basePrice: 520.0,
            categoryId: 'single-origin',
            categoryName: 'Single Origin',
            roastLevel: 'Medium-Light Roast',
            tastingNotes: 'Blackberry, lavender, panela sweetness',
            availability: ProductAvailability.available,
            stockQuantity: 40,
          ),
        );
        expect(validAttempt.isSuccess, isTrue);
      });

      test('Customer cannot provision an employee account or escalate privileges', () async {
        userDb.setCurrentUser(customerUser);

        final attempt = await accountManagementDataSource.createEmployee(
          const CreateEmployeeRequest(
            email: 'fake.barista@lambac.com',
            fullName: 'Rogue Barista',
            initialPassword: 'Password123!',
            permissions: [EmployeePermission.manageOrders],
          ),
        );

        expect(attempt.isFailure, isTrue);
        expect(attempt.failureOrNull, isA<ForbiddenFailure>());
      });
    });
  });
}