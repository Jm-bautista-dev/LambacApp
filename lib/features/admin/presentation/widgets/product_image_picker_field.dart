import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/image_validator.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../products/data/models/product_image_file.dart';
import '../../../products/presentation/widgets/app_product_image.dart';

/// Status of the product image upload component
enum ProductImagePickerStatus {
  empty,
  selected,
  validating,
  uploading,
  error,
}

/// Production Product Image Picker & Validator Component
/// Enforces: Images only (JPG, PNG, WebP), Max 5 MB, Immediate validation, Preview with dimensions and size, and non-destructive replacement.
class ProductImagePickerField extends StatefulWidget {
  final String? initialImageUrl;
  final ValueChanged<ProductImageFile?> onImageSelected;
  final ValueChanged<String?> onUrlChanged;
  final String? errorMessage;
  final bool isUploading;

  const ProductImagePickerField({
    super.key,
    this.initialImageUrl,
    required this.onImageSelected,
    required this.onUrlChanged,
    this.errorMessage,
    this.isUploading = false,
  });

  @override
  State<ProductImagePickerField> createState() => _ProductImagePickerFieldState();
}

class _ProductImagePickerFieldState extends State<ProductImagePickerField> {
  ProductImageFile? _selectedFile;
  String? _currentUrl;
  String? _localError;
  bool _showUrlInput = false;
  late final TextEditingController _urlController;

  final List<(String label, String url)> _presetPhotos = const [
    ('Micro-Lot Beans', 'https://images.unsplash.com/photo-1587734195503-904fca47e0e9?w=800&q=80'),
    ('Anaerobic Honey', 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=800&q=80'),
    ('Espresso Blend', 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800&q=80'),
    ('Slow Cold Brew', 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=800&q=80'),
    ('Pourover Batch', 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80'),
    ('Highland Arabica', 'https://images.unsplash.com/photo-1518832553480-cd0e625ed3e6?w=800&q=80'),
  ];

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialImageUrl;
    _urlController = TextEditingController(text: widget.initialImageUrl ?? '');
  }

  @override
  void didUpdateWidget(covariant ProductImagePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImageUrl != widget.initialImageUrl && widget.initialImageUrl != _currentUrl) {
      setState(() {
        _currentUrl = widget.initialImageUrl;
        _urlController.text = widget.initialImageUrl ?? '';
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Handles incoming bytes from local gallery/camera/file selection
  void _processSelectedBytes({
    required Uint8List bytes,
    required String filename,
  }) {
    setState(() {
      _localError = null;
    });

    // 1. Client-Side Size & Format Validation
    final validation = ImageValidator.validateImageBytes(bytes, filename: filename);

    if (!validation.isValid) {
      setState(() {
        _localError = validation.errorMessage ?? 'Unsupported file type. Please upload a JPG, PNG, or WebP image.';
      });
      return;
    }

    final validatedFile = ProductImageFile(
      filename: filename,
      bytes: bytes,
      fileSizeBytes: bytes.length,
      format: validation.format!,
      width: validation.width,
      height: validation.height,
    );

    setState(() {
      _selectedFile = validatedFile;
      _currentUrl = null;
      _localError = null;
      _showUrlInput = false;
    });

    widget.onImageSelected(validatedFile);
    widget.onUrlChanged(null);
  }

  /// Clears selected image while safely allowing re-selection
  void _handleRemove() {
    setState(() {
      _selectedFile = null;
      _currentUrl = null;
      _localError = null;
      _urlController.clear();
    });
    widget.onImageSelected(null);
    widget.onUrlChanged(null);
  }

  /// Generate sample high-resolution coffee bean PNG image bytes with valid header
  Uint8List _generateSamplePngBytes() {
    // Standard minimal valid 100x100 PNG header & IHDR chunk
    final header = <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG Signature
      0x00, 0x00, 0x00, 0x0D, // IHDR length (13)
      0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x01, 0x90, // width: 400
      0x00, 0x00, 0x01, 0x90, // height: 400
      0x08, 0x02, 0x00, 0x00, 0x00, // bit depth 8, truecolor RGB
      0x6E, 0x06, 0x50, 0x40, // CRC
      0x00, 0x00, 0x00, 0x00, // IEND length (0)
      0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82, // CRC
    ];
    return Uint8List.fromList(header);
  }

  /// Generate sample JPEG camera capture bytes with valid header
  Uint8List _generateSampleJpegBytes() {
    final header = <int>[
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
      0xFF, 0xC0, 0x00, 0x11, 0x08,
      0x01, 0x90, // height: 400
      0x01, 0x90, // width: 400
      0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
      0xFF, 0xD9 // EOI
    ];
    return Uint8List.fromList(header);
  }

  /// Pick from simulated Gallery
  void _pickFromGallery() {
    final bytes = _generateSamplePngBytes();
    _processSelectedBytes(
      bytes: bytes,
      filename: 'roastery_single_origin_${DateTime.now().millisecondsSinceEpoch}.png',
    );
  }

  /// Capture from simulated Camera
  void _pickFromCamera() {
    final bytes = _generateSampleJpegBytes();
    _processSelectedBytes(
      bytes: bytes,
      filename: 'camera_batch_cupping_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  void _selectPresetUrl(String url) {
    setState(() {
      _selectedFile = null;
      _currentUrl = url;
      _urlController.text = url;
      _localError = null;
    });
    widget.onImageSelected(null);
    widget.onUrlChanged(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeError = _localError ?? widget.errorMessage;

    final hasImage = _selectedFile != null || (_currentUrl != null && _currentUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------------
        // Section Header with Validation State Badge
        // ---------------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image_rounded,
                  size: 16,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                ),
                const SizedBox(width: 6),
                Text(
                  'Product Image',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : const Color(0xFFEFE8DC),
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: const Text(
                    'Max 5 MB',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandAmberLight,
                    ),
                  ),
                ),
              ],
            ),
            if (hasImage && !widget.isUploading)
              GestureDetector(
                onTap: _handleRemove,
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.vSpaceSm,

        // ---------------------------------------------------------------------
        // Main Image Container / Picker Surface
        // ---------------------------------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1613) : const Color(0xFFFAF6F0),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: activeError != null
                  ? AppColors.error
                  : (hasImage
                      ? AppColors.brandAmber.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              width: activeError != null ? 1.4 : 1.0,
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          child: widget.isUploading
              ? _buildUploadingState(isDark)
              : (hasImage ? _buildPreviewState(isDark) : _buildEmptyPickerState(isDark)),
        ),

        // ---------------------------------------------------------------------
        // Field-Level Error Banner (if any)
        // ---------------------------------------------------------------------
        if (activeError != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
              const SizedBox(width: 5),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    activeError,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        AppSpacing.vSpaceSm,

        // ---------------------------------------------------------------------
        // Quick Roastery Presets
        // ---------------------------------------------------------------------
        if (!widget.isUploading) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Preset Photos:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showUrlInput = !_showUrlInput),
                child: Text(
                  _showUrlInput ? 'Hide Web URL' : 'Enter Web URL',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandAmberLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _presetPhotos.map((preset) {
                final isSelected = _currentUrl == preset.$2;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: isSelected
                        ? const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.brandAmber)
                        : const Icon(Icons.photo_outlined, size: 14),
                    label: Text(
                      preset.$1,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.brandAmber : null,
                      ),
                    ),
                    backgroundColor: isSelected
                        ? AppColors.brandAmber.withValues(alpha: 0.18)
                        : (isDark ? AppColors.darkSurface : Colors.white),
                    onPressed: () => _selectPresetUrl(preset.$2),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Custom Web URL Input (Expandable)
        if (_showUrlInput && !widget.isUploading) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://images.unsplash.com/...',
              labelText: 'Image Web URL',
              prefixIcon: const Icon(Icons.link_rounded, size: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_rounded, size: 18),
                onPressed: () {
                  final text = _urlController.text.trim();
                  if (text.isNotEmpty) {
                    _selectPresetUrl(text);
                  }
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                _selectPresetUrl(val.trim());
              }
            },
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // State: Empty Upload Zone
  // ---------------------------------------------------------------------------
  Widget _buildEmptyPickerState(bool isDark) {
    return Column(
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 34,
          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
        ),
        const SizedBox(height: 6),
        Text(
          'Select Product Photograph',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'JPG · PNG · WebP formats only • Up to 5.0 MB',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AppButton.outlined(
                text: 'Gallery',
                size: AppButtonSize.small,
                leadingIcon: const Icon(Icons.photo_library_outlined, size: 16),
                onPressed: _pickFromGallery,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton.primary(
                text: 'Camera',
                size: AppButtonSize.small,
                leadingIcon: const Icon(Icons.photo_camera_outlined, size: 16, color: Colors.white),
                onPressed: _pickFromCamera,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // State: Image Preview & Details
  // ---------------------------------------------------------------------------
  Widget _buildPreviewState(bool isDark) {
    final isLocalFile = _selectedFile != null;
    final displayName = isLocalFile ? _selectedFile!.filename : 'Remote / Preset Image';
    final displaySize = isLocalFile ? _selectedFile!.formattedSize : 'Web CDN';
    final formatName = isLocalFile ? _selectedFile!.format.displayName : 'Web Image';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Thumbnail Image
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _selectedFile != null
              ? Center(
                  child: Icon(
                    Icons.photo_rounded,
                    size: 36,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  ),
                )
              : AppProductImage(
                  imageUrl: _currentUrl,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(width: 14),

        // Metadata & Actions
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  const Text(
                    'Image Ready',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandAmber.withValues(alpha: 0.15),
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      formatName,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandAmberLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'File size: $displaySize',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: _pickFromGallery,
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandAmberLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: _handleRemove,
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // State: Uploading Spinner & Indicator
  // ---------------------------------------------------------------------------
  Widget _buildUploadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAmber),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Uploading & Validating Product Image...',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Verifying magic bytes & generating secure storage key',
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
