import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/utils/image_validator.dart';

void main() {
  group('ImageValidator Security & Content Inspection Tests', () {
    // Helper to generate minimal valid PNG bytes (400x400)
    Uint8List createValidPngBytes({int length = 64}) {
      final header = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG magic
        0x00, 0x00, 0x00, 0x0D, // IHDR length
        0x49, 0x48, 0x44, 0x52, // IHDR
        0x00, 0x00, 0x01, 0x90, // width: 400
        0x00, 0x00, 0x01, 0x90, // height: 400
        0x08, 0x02, 0x00, 0x00, 0x00,
        0x6E, 0x06, 0x50, 0x40,
      ];
      final list = Uint8List(length < header.length ? header.length : length);
      list.setRange(0, header.length, header);
      return list;
    }

    // Helper to generate minimal valid JPEG bytes (400x400)
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

    // Helper to generate minimal valid WebP bytes
    Uint8List createValidWebpBytes({int length = 64}) {
      final header = <int>[
        0x52, 0x49, 0x46, 0x46, // 'RIFF'
        0x24, 0x00, 0x00, 0x00, // File size
        0x57, 0x45, 0x42, 0x50, // 'WEBP'
        0x56, 0x50, 0x38, 0x20, // 'VP8 '
        0x18, 0x00, 0x00, 0x00, // Chunk size
        0x30, 0x01, 0x00, // Frame tag
        0x9D, 0x01, 0x2A, // Start code
        0x90, 0x01, // width: 400
        0x90, 0x01, // height: 400
      ];
      final list = Uint8List(length < header.length ? header.length : length);
      list.setRange(0, header.length, header);
      return list;
    }

    test('1. Valid JPG: Accepts JPEG byte stream under 5 MB', () {
      final bytes = createValidJpegBytes(length: 1024 * 50); // 50 KB
      final result = ImageValidator.validateImageBytes(bytes, filename: 'coffee_bag.jpg');

      expect(result.isValid, isTrue);
      expect(result.format, SupportedImageFormat.jpeg);
      expect(result.sanitizedExtension, 'jpg');
      expect(result.errorMessage, isNull);
    });

    test('2. Valid PNG: Accepts PNG byte stream under 5 MB', () {
      final bytes = createValidPngBytes(length: 1024 * 100); // 100 KB
      final result = ImageValidator.validateImageBytes(bytes, filename: 'roastery_logo.png');

      expect(result.isValid, isTrue);
      expect(result.format, SupportedImageFormat.png);
      expect(result.sanitizedExtension, 'png');
      expect(result.errorMessage, isNull);
    });

    test('3. Valid WebP: Accepts WebP byte stream under 5 MB', () {
      final bytes = createValidWebpBytes(length: 1024 * 80); // 80 KB
      final result = ImageValidator.validateImageBytes(bytes, filename: 'cold_brew.webp');

      expect(result.isValid, isTrue);
      expect(result.format, SupportedImageFormat.webp);
      expect(result.sanitizedExtension, 'webp');
      expect(result.errorMessage, isNull);
    });

    test('4. PDF Rejection: Rejects PDF files even if presented as image', () {
      final pdfBytes = Uint8List.fromList([
        0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35, // %PDF-1.5
        0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A,
      ]);
      final result = ImageValidator.validateImageBytes(pdfBytes, filename: 'invoice.pdf');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Unsupported file type'));
    });

    test('5. Excel/Word/ZIP Rejection: Rejects PK zip headers', () {
      final zipBytes = Uint8List.fromList([
        0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x06, 0x00, // PK.. (ZIP, XLSX, DOCX)
        0x08, 0x00, 0x00, 0x00,
      ]);
      final result = ImageValidator.validateImageBytes(zipBytes, filename: 'inventory_spreadsheet.xlsx');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Unsupported file type'));
    });

    test('6. Renamed PDF Attack (document.pdf -> product.jpg): Detects PDF magic bytes and REJECTS', () {
      final renamedPdfBytes = Uint8List.fromList([
        0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37, // %PDF-1.7
        0x20, 0x6D, 0x61, 0x6C, 0x69, 0x63, 0x69, 0x6F, 0x75, 0x73,
      ]);
      // The filename has .jpg extension, but the content is PDF
      final result = ImageValidator.validateImageBytes(renamedPdfBytes, filename: 'product.jpg');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Unsupported file type'));
    });

    test('7. Executable Rejection: Rejects Windows EXE (MZ header)', () {
      final exeBytes = Uint8List.fromList([
        0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, // MZ..
      ]);
      final result = ImageValidator.validateImageBytes(exeBytes, filename: 'malware.jpg');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Unsupported file type'));
    });

    test('8. Size Limit (5 MB): Rejects file larger than 5 MB', () {
      // 5.1 MB = 5,347,737 bytes
      const oversizedLength = (5 * 1024 * 1024) + (100 * 1024);
      final oversizedBytes = createValidJpegBytes(length: oversizedLength);

      final result = ImageValidator.validateImageBytes(oversizedBytes, filename: 'huge_photo.jpg');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Image is too large. Please choose an image smaller than 5 MB.'));
    });

    test('9. Size Limit (5 MB): Accepts file near limit under 5 MB (e.g. 4.9 MB)', () {
      // 4.9 MB = 5,138,022 bytes
      const validLargeLength = (4 * 1024 * 1024) + (900 * 1024);
      final largeBytes = createValidPngBytes(length: validLargeLength);

      final result = ImageValidator.validateImageBytes(largeBytes, filename: 'high_res_roastery.png');

      expect(result.isValid, isTrue);
      expect(result.fileSizeBytes, validLargeLength);
    });

    test('10. Empty File: Rejects 0-byte file', () {
      final emptyBytes = Uint8List(0);
      final result = ImageValidator.validateImageBytes(emptyBytes, filename: 'empty.jpg');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Image file is empty.'));
    });

    test('11. Arbitrary Text / Corrupted Non-Image: Rejects plain text content', () {
      final textBytes = Uint8List.fromList('Coffee roasting profile data: batch 401'.codeUnits);
      final result = ImageValidator.validateImageBytes(textBytes, filename: 'notes.txt');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Unsupported file type'));
    });

    test('12. Dimension Boundary Check: Rejects images with dimensions < 100x100', () {
      // Create PNG with 50x50 dimensions
      final smallPng = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x32, // width: 50
        0x00, 0x00, 0x00, 0x32, // height: 50
        0x08, 0x02, 0x00, 0x00, 0x00,
        0x6E, 0x06, 0x50, 0x40,
      ];
      final result = ImageValidator.validateImageBytes(Uint8List.fromList(smallPng));

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Image dimensions too small'));
    });

    test('13. Safe Filename Generation: Generates UUID-based sanitized storage filename', () {
      final safeJpg = ImageValidator.generateSecureFilename(format: SupportedImageFormat.jpeg);
      expect(safeJpg.startsWith('prod_img_'), isTrue);
      expect(safeJpg.endsWith('.jpg'), isTrue);
      expect(safeJpg.contains('..'), isFalse);
      expect(safeJpg.contains('/'), isFalse);
      expect(safeJpg.contains(r'\'), isFalse);

      final safePng = ImageValidator.generateSecureFilename(format: SupportedImageFormat.png);
      expect(safePng.endsWith('.png'), isTrue);

      final safeWebp = ImageValidator.generateSecureFilename(format: SupportedImageFormat.webp);
      expect(safeWebp.endsWith('.webp'), isTrue);
    });

    test('14. File Size Formatting: Formats B, KB, and MB accurately', () {
      expect(ImageValidator.formatFileSize(0), '0 B');
      expect(ImageValidator.formatFileSize(512), '512 B');
      expect(ImageValidator.formatFileSize(450 * 1024), '450 KB');
      expect(ImageValidator.formatFileSize((2.3 * 1024 * 1024).round()), '2.3 MB');
      expect(ImageValidator.formatFileSize(5 * 1024 * 1024), '5.0 MB');
    });
  });
}
