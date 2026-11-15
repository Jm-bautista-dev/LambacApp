import 'dart:typed_data';
import 'package:uuid/uuid.dart';

/// Supported image formats for Lambac product catalog
enum SupportedImageFormat {
  jpeg(mimeType: 'image/jpeg', extension: 'jpg', displayName: 'JPEG / JPG'),
  png(mimeType: 'image/png', extension: 'png', displayName: 'PNG'),
  webp(mimeType: 'image/webp', extension: 'webp', displayName: 'WebP');

  final String mimeType;
  final String extension;
  final String displayName;

  const SupportedImageFormat({
    required this.mimeType,
    required this.extension,
    required this.displayName,
  });
}

/// Result of an image validation check
class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;
  final SupportedImageFormat? format;
  final int? width;
  final int? height;
  final int fileSizeBytes;
  final String? sanitizedExtension;

  const ImageValidationResult({
    required this.isValid,
    this.errorMessage,
    this.format,
    this.width,
    this.height,
    required this.fileSizeBytes,
    this.sanitizedExtension,
  });

  ImageValidationResult.valid({
    required SupportedImageFormat format,
    required int fileSizeBytes,
    int? width,
    int? height,
  }) : this(
          isValid: true,
          format: format,
          fileSizeBytes: fileSizeBytes,
          width: width,
          height: height,
          sanitizedExtension: format.extension,
        );

  const ImageValidationResult.invalid({
    required String errorMessage,
    required int fileSizeBytes,
  }) : this(
          isValid: false,
          errorMessage: errorMessage,
          fileSizeBytes: fileSizeBytes,
        );
}

/// Comprehensive Image Security and Content Validator
/// Enforces: Images Only (JPG, PNG, WebP), Max 5 MB, Magic-Byte Signature Verification, Dimension Bounds, and Safe Filenames.
class ImageValidator {
  ImageValidator._();

  /// Maximum allowed product image file size (5 MB = 5,242,880 bytes)
  static const int maxProductImageSizeBytes = 5 * 1024 * 1024;

  /// Minimum acceptable image dimensions for product catalog (100x100 pixels)
  static const int minImageDimension = 100;

  /// Maximum acceptable image dimension to prevent decompression memory bombs (8000x8000 pixels)
  static const int maxImageDimension = 8000;

  /// Allowed image MIME types
  static const Set<String> allowedMimeTypes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  /// Allowed file extensions
  static const Set<String> allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  // ---------------------------------------------------------------------------
  // Magic Byte Signatures
  // ---------------------------------------------------------------------------
  static const List<int> _jpegHeader = [0xFF, 0xD8, 0xFF];
  static const List<int> _pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  static const List<int> _riffHeader = [0x52, 0x49, 0x46, 0x46]; // 'RIFF'
  static const List<int> _webpHeader = [0x57, 0x45, 0x42, 0x50]; // 'WEBP'
  static const List<int> _pdfHeader = [0x25, 0x50, 0x44, 0x46]; // '%PDF'
  static const List<int> _zipOfficeHeader = [0x50, 0x4B, 0x03, 0x04]; // 'PK..' (XLSX, DOCX, ZIP)
  static const List<int> _legacyOfficeHeader = [0xD0, 0xCF, 0x11, 0xE0]; // Legacy DOC, XLS
  static const List<int> _dosExeHeader = [0x4D, 0x5A]; // 'MZ' (Windows EXE)
  static const List<int> _elfHeader = [0x7F, 0x45, 0x4C, 0x46]; // ELF Binary
  static const List<int> _gifHeader = [0x47, 0x49, 0x46, 0x38]; // 'GIF8'

  /// Validate image bytes for production security
  static ImageValidationResult validateImageBytes(
    Uint8List bytes, {
    String? filename,
  }) {
    final size = bytes.length;

    // 1. File existence / non-empty check
    if (size == 0) {
      return const ImageValidationResult.invalid(
        errorMessage: 'Image file is empty.',
        fileSizeBytes: 0,
      );
    }

    // 2. Strict 5 MB Size Limit
    if (size > maxProductImageSizeBytes) {
      return ImageValidationResult.invalid(
        errorMessage: 'Image is too large. Please choose an image smaller than 5 MB.',
        fileSizeBytes: size,
      );
    }

    // 3. Reject Known Forbidden Non-Image Formats by Header
    if (_matchesHeader(bytes, _pdfHeader) ||
        _matchesHeader(bytes, _zipOfficeHeader) ||
        _matchesHeader(bytes, _legacyOfficeHeader) ||
        _matchesHeader(bytes, _dosExeHeader) ||
        _matchesHeader(bytes, _elfHeader)) {
      return ImageValidationResult.invalid(
        errorMessage: 'Unsupported file type. Please upload a JPG, PNG, or WebP image.',
        fileSizeBytes: size,
      );
    }

    // 4. Magic-Byte Inspection for Supported Image Formats
    SupportedImageFormat? detectedFormat;

    if (_isJpeg(bytes)) {
      detectedFormat = SupportedImageFormat.jpeg;
    } else if (_isPng(bytes)) {
      detectedFormat = SupportedImageFormat.png;
    } else if (_isWebP(bytes)) {
      detectedFormat = SupportedImageFormat.webp;
    }

    if (detectedFormat == null) {
      return ImageValidationResult.invalid(
        errorMessage: 'Unsupported file type. Please upload a JPG, PNG, or WebP image.',
        fileSizeBytes: size,
      );
    }

    // 5. Header Dimension Decoding & Safe Boundary Verification
    final dimensions = _extractDimensions(bytes, detectedFormat);
    if (dimensions != null) {
      final (width, height) = dimensions;

      if (width < minImageDimension || height < minImageDimension) {
        return ImageValidationResult.invalid(
          errorMessage: 'Image dimensions too small. Minimum required is ${minImageDimension}x${minImageDimension}px.',
          fileSizeBytes: size,
        );
      }

      if (width > maxImageDimension || height > maxImageDimension) {
        return ImageValidationResult.invalid(
          errorMessage: 'Image dimensions too large. Maximum supported is ${maxImageDimension}x${maxImageDimension}px.',
          fileSizeBytes: size,
        );
      }

      return ImageValidationResult.valid(
        format: detectedFormat,
        fileSizeBytes: size,
        width: width,
        height: height,
      );
    }

    return ImageValidationResult.valid(
      format: detectedFormat,
      fileSizeBytes: size,
    );
  }

  /// Format raw byte count into human-readable representation (e.g. "2.4 MB", "450 KB")
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024.0;
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    }
    final mb = bytes / (1024.0 * 1024.0);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Generate safe, randomized, injection-resistant storage filename
  static String generateSecureFilename({
    required SupportedImageFormat format,
    String? prefix = 'prod_img',
  }) {
    final uuid = const Uuid().v4().replaceAll('-', '');
    final p = prefix ?? 'prod_img';
    return '${p}_$uuid.${format.extension}';
  }

  // ---------------------------------------------------------------------------
  // Internal Magic-Byte Detection Helpers
  // ---------------------------------------------------------------------------

  static bool _matchesHeader(Uint8List bytes, List<int> header) {
    if (bytes.length < header.length) return false;
    for (int i = 0; i < header.length; i++) {
      if (bytes[i] != header[i]) return false;
    }
    return true;
  }

  static bool _isJpeg(Uint8List bytes) {
    if (bytes.length < 3) return false;
    return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  }

  static bool _isPng(Uint8List bytes) {
    return _matchesHeader(bytes, _pngHeader);
  }

  static bool _isWebP(Uint8List bytes) {
    if (bytes.length < 12) return false;
    final isRiff = _matchesHeader(bytes, _riffHeader);
    if (!isRiff) return false;
    return bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50; // WEBP
  }

  // ---------------------------------------------------------------------------
  // Internal Header Dimension Parsing
  // ---------------------------------------------------------------------------

  static (int, int)? _extractDimensions(Uint8List bytes, SupportedImageFormat format) {
    try {
      return switch (format) {
        SupportedImageFormat.png => _extractPngDimensions(bytes),
        SupportedImageFormat.jpeg => _extractJpegDimensions(bytes),
        SupportedImageFormat.webp => _extractWebpDimensions(bytes),
      };
    } catch (_) {
      return null;
    }
  }

  static (int, int)? _extractPngDimensions(Uint8List bytes) {
    if (bytes.length < 24) return null;
    final byteData = ByteData.sublistView(bytes);
    final width = byteData.getUint32(16, Endian.big);
    final height = byteData.getUint32(20, Endian.big);
    if (width > 0 && height > 0) return (width, height);
    return null;
  }

  static (int, int)? _extractJpegDimensions(Uint8List bytes) {
    int offset = 2; // Skip SOI (0xFFD8)
    final length = bytes.length;

    while (offset < length - 8) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }

      final marker = bytes[offset + 1];
      // Check SOF markers (SOF0 = 0xC0, SOF1 = 0xC1, SOF2 = 0xC2, SOF3 = 0xC3)
      if ((marker >= 0xC0 && marker <= 0xC3) || (marker >= 0xC5 && marker <= 0xC7) || (marker >= 0xC9 && marker <= 0xCB)) {
        if (offset + 8 < length) {
          final byteData = ByteData.sublistView(bytes);
          final height = byteData.getUint16(offset + 5, Endian.big);
          final width = byteData.getUint16(offset + 7, Endian.big);
          if (width > 0 && height > 0) return (width, height);
        }
      }

      // Read chunk length to advance
      if (offset + 3 < length) {
        final byteData = ByteData.sublistView(bytes);
        final chunkLength = byteData.getUint16(offset + 2, Endian.big);
        offset += chunkLength + 2;
      } else {
        break;
      }
    }
    return null;
  }

  static (int, int)? _extractWebpDimensions(Uint8List bytes) {
    if (bytes.length < 30) return null;
    final byteData = ByteData.sublistView(bytes);

    // Check for VP8X (Extended WebP)
    if (bytes[12] == 0x56 && bytes[13] == 0x50 && bytes[14] == 0x38 && bytes[15] == 0x58) {
      final width = 1 + (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16));
      final height = 1 + (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16));
      return (width, height);
    }

    // Check for VP8 (Lossy WebP)
    if (bytes[12] == 0x56 && bytes[13] == 0x50 && bytes[14] == 0x38 && bytes[15] == 0x20) {
      if (bytes.length >= 30) {
        final width = byteData.getUint16(26, Endian.little) & 0x3FFF;
        final height = byteData.getUint16(28, Endian.little) & 0x3FFF;
        if (width > 0 && height > 0) return (width, height);
      }
    }

    return null;
  }
}
