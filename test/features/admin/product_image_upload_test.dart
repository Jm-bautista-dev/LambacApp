import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/products/data/models/product_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('Secure Product Image Upload & Server Validation Pipeline Tests', () {
    late MockAdminRemoteDataSource remoteDataSource;

    const adminUser = UserModel(
      id: 'admin_test_101',
      email: 'admin@lambac.com',
      fullName: 'Master Roaster',
      role: UserRole.admin,
    );

    const customerUser = UserModel(
      id: 'cust_test_101',
      email: 'customer@lambac.com',
      fullName: 'Customer Enthusiast',
      role: UserRole.customer,
    );

    // Helpers to generate valid test bytes
    Uint8List createValidJpegBytes({int length = 64}) {
      final header = <int>[
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
        0xFF, 0xC0, 0x00, 0x11, 0x08,
        0x01, 0x90, // height: 400
        0x01, 0x90, // width: 400
        0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
      ];
      final list = Uint8List(length < header.length ? header.length : length);
      list.setRange(0, header.length, header);
      return list;
    }

    Uint8List createValidPngBytes({int length = 64}) {
      final header = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x01, 0x90,
        0x00, 0x00, 0x01, 0x90,
        0x08, 0x02, 0x00, 0x00, 0x00,
        0x6E, 0x06, 0x50, 0x40,
      ];
      final list = Uint8List(length < header.length ? header.length : length);
      list.setRange(0, header.length, header);
      return list;
    }

    Uint8List createValidWebpBytes({int length = 64}) {
      final header = <int>[
        0x52, 0x49, 0x46, 0x46,
        0x24, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50,
        0x56, 0x50, 0x38, 0x20,
        0x18, 0x00, 0x00, 0x00,
        0x30, 0x01, 0x00,
        0x9D, 0x01, 0x2A,
        0x90, 0x01,
        0x90, 0x01,
      ];
      final list = Uint8List(length < header.length ? header.length : length);
      list.setRange(0, header.length, header);
      return list;
    }

    setUp(() {
      remoteDataSource = MockAdminRemoteDataSource();
      MockUserDatabase().setCurrentUser(adminUser);
    });

    tearDown(() {
      MockUserDatabase().setCurrentUser(null);
    });

    test('Test 1 — JPG: Upload valid JPG under 5 MB returns success and secure storage URL', () async {
      final bytes = createValidJpegBytes(length: 1024 * 50); // 50 KB
      final result = await remoteDataSource.uploadProductImage(
        bytes: bytes,
        filename: 'single_origin.jpg',
      );

      expect(result.isSuccess, isTrue);
      final response = result.dataOrNull!;
      expect(response.imageUrl.startsWith('https://media.lambac.com/products/prod_img_'), isTrue);
      expect(response.imageUrl.endsWith('.jpg'), isTrue);
      expect(response.mimeType, 'image/jpeg');
      expect(response.fileSizeBytes, bytes.length);
    });

    test('Test 2 — PNG: Upload valid PNG under 5 MB returns success', () async {
      final bytes = createValidPngBytes(length: 1024 * 120); // 120 KB
      final result = await remoteDataSource.uploadProductImage(
        bytes: bytes,
        filename: 'anaerobic_lot.png',
      );

      expect(result.isSuccess, isTrue);
      final response = result.dataOrNull!;
      expect(response.imageUrl.endsWith('.png'), isTrue);
      expect(response.mimeType, 'image/png');
    });

    test('Test 3 — WebP: Upload valid WebP under 5 MB returns success', () async {
      final bytes = createValidWebpBytes(length: 1024 * 80); // 80 KB
      final result = await remoteDataSource.uploadProductImage(
        bytes: bytes,
        filename: 'cold_brew.webp',
      );

      expect(result.isSuccess, isTrue);
      final response = result.dataOrNull!;
      expect(response.imageUrl.endsWith('.webp'), isTrue);
      expect(response.mimeType, 'image/webp');
    });

    test('Test 4 — PDF: Attempt upload of PDF is REJECTED by backend', () async {
      final pdfBytes = Uint8List.fromList([
        0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, // %PDF-1.4
        0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3,
      ]);
      final result = await remoteDataSource.uploadProductImage(
        bytes: pdfBytes,
        filename: 'roast_sheet.pdf',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('Unsupported file type. Please upload a JPG, PNG, or WebP image.'));
    });

    test('Test 5 — Excel/Word: Attempt upload of Office file is REJECTED', () async {
      final xlsxBytes = Uint8List.fromList([
        0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x06, 0x00, // PK..
        0x08, 0x00, 0x00, 0x00,
      ]);
      final result = await remoteDataSource.uploadProductImage(
        bytes: xlsxBytes,
        filename: 'inventory.xlsx',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('Unsupported file type'));
    });

    test('Test 6 — Renamed PDF: Attempt upload of PDF renamed to product.jpg is REJECTED by magic bytes', () async {
      final fakeJpgBytes = Uint8List.fromList([
        0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35, // %PDF-1.5
        0x0A, 0x6D, 0x61, 0x6C, 0x69, 0x63, 0x69, 0x6F, 0x75, 0x73,
      ]);
      final result = await remoteDataSource.uploadProductImage(
        bytes: fakeJpgBytes,
        filename: 'product.jpg', // Claiming to be JPG
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('Unsupported file type'));
    });

    test('Test 7 — Oversized image: Attempt upload of file > 5 MB is REJECTED', () async {
      const oversizedLength = (5 * 1024 * 1024) + (200 * 1024); // 5.2 MB
      final oversizedBytes = createValidJpegBytes(length: oversizedLength);

      final result = await remoteDataSource.uploadProductImage(
        bytes: oversizedBytes,
        filename: 'huge_roastery_banner.jpg',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('Image is too large. Please choose an image smaller than 5 MB.'));
    });

    test('Test 8 — Role Authorization: Attempt upload with customer account returns 403 Forbidden', () async {
      MockUserDatabase().setCurrentUser(customerUser); // Switch to customer

      final bytes = createValidJpegBytes(length: 1024 * 20);
      final result = await remoteDataSource.uploadProductImage(
        bytes: bytes,
        filename: 'hack_attempt.jpg',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(result.failureOrNull?.statusCode, 403);
    });

    test('Test 9 — Product Edit Safe Replacement: Valid new image replaces existing image reference', () async {
      const existingProduct = ProductModel(
        id: 'prod_benguet_01',
        name: 'Benguet Typica',
        slug: 'benguet-typica',
        origin: 'Atok, Benguet',
        description: 'Single-origin specialty',
        basePrice: 450.0,
        imageUrl: 'https://media.lambac.com/products/old_benguet.jpg',
        categoryId: 'single-origin',
        categoryName: 'Single Origin',
        roastLevel: 'Medium Roast',
        tastingNotes: 'Brown sugar & citrus',
      );

      // 1. Upload replacement valid PNG
      final newBytes = createValidPngBytes(length: 1024 * 30);
      final uploadResult = await remoteDataSource.uploadProductImage(
        bytes: newBytes,
        filename: 'new_benguet_lot.png',
      );
      expect(uploadResult.isSuccess, isTrue);
      final newImageUrl = uploadResult.dataOrNull!.imageUrl;

      // 2. Update product
      final updatedProduct = existingProduct.copyWith(imageUrl: newImageUrl);
      final updateResult = await remoteDataSource.updateProduct(updatedProduct);

      expect(updateResult.isSuccess, isTrue);
      expect(updateResult.dataOrNull!.imageUrl, newImageUrl);
      expect(updateResult.dataOrNull!.imageUrl, isNot(existingProduct.imageUrl));
    });

    test('Test 10 — Failed Replacement Safeguard: If new image upload fails, existing product image remains intact', () async {
      const existingProduct = ProductModel(
        id: 'prod_sagada_01',
        name: 'Sagada Arabica',
        slug: 'sagada-arabica',
        origin: 'Sagada, Mountain Province',
        description: 'Dark roast specialty',
        basePrice: 420.0,
        imageUrl: 'https://media.lambac.com/products/original_sagada.jpg',
        categoryId: 'single-origin',
        categoryName: 'Single Origin',
        roastLevel: 'Dark Roast',
        tastingNotes: 'Cocoa & roasted pine',
      );

      // Attempt upload of an invalid PDF as replacement
      final invalidPdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
      final uploadResult = await remoteDataSource.uploadProductImage(
        bytes: invalidPdfBytes,
        filename: 'new_image.pdf',
      );

      expect(uploadResult.isFailure, isTrue);

      // Because upload failed, product is NOT updated with broken URL and keeps original
      expect(existingProduct.imageUrl, 'https://media.lambac.com/products/original_sagada.jpg');
    });
  });
}
