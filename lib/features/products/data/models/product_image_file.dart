import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/image_validator.dart';

/// Represents a validated local image file selected for product upload
class ProductImageFile extends Equatable {
  final String filename;
  final Uint8List bytes;
  final int fileSizeBytes;
  final SupportedImageFormat format;
  final int? width;
  final int? height;

  const ProductImageFile({
    required this.filename,
    required this.bytes,
    required this.fileSizeBytes,
    required this.format,
    this.width,
    this.height,
  });

  String get formattedSize => ImageValidator.formatFileSize(fileSizeBytes);
  String get mimeType => format.mimeType;

  @override
  List<Object?> get props => [filename, fileSizeBytes, format, width, height];
}

/// Server response upon successful secure product image upload
class ProductImageUploadResponse extends Equatable {
  final String imageUrl;
  final String storageKey;
  final int fileSizeBytes;
  final String mimeType;
  final int? width;
  final int? height;
  final DateTime uploadedAt;

  const ProductImageUploadResponse({
    required this.imageUrl,
    required this.storageKey,
    required this.fileSizeBytes,
    required this.mimeType,
    this.width,
    this.height,
    required this.uploadedAt,
  });

  factory ProductImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ProductImageUploadResponse(
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '').toString(),
      storageKey: (json['storage_key'] ?? json['storageKey'] ?? '').toString(),
      fileSizeBytes: (json['file_size_bytes'] ?? json['fileSizeBytes'] ?? 0) as int,
      mimeType: (json['mime_type'] ?? json['mimeType'] ?? 'image/jpeg').toString(),
      width: json['width'] as int?,
      height: json['height'] as int?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'image_url': imageUrl,
        'storage_key': storageKey,
        'file_size_bytes': fileSizeBytes,
        'mime_type': mimeType,
        'width': width,
        'height': height,
        'uploaded_at': uploadedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [imageUrl, storageKey, fileSizeBytes, mimeType, width, height, uploadedAt];
}
