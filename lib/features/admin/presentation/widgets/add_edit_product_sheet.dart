import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../../products/data/models/product_image_file.dart';
import '../../../products/data/models/product_model.dart';
import '../providers/admin_provider.dart';
import 'product_image_picker_field.dart';

/// Modal Bottom Sheet to Add or Edit a Roastery Product with Secure Image Upload & Validation
class AddEditProductSheet extends ConsumerStatefulWidget {
  final ProductModel? product;

  const AddEditProductSheet({
    super.key,
    this.product,
  });

  static Future<ProductModel?> show(BuildContext context, {ProductModel? product}) {
    return AppBottomSheet.show<ProductModel>(
      context,
      title: product == null ? 'Add New Roast Product' : 'Edit Roast Specifications',
      child: AddEditProductSheet(product: product),
    );
  }

  @override
  ConsumerState<AddEditProductSheet> createState() => _AddEditProductSheetState();
}

class _AddEditProductSheetState extends ConsumerState<AddEditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _originController;
  late final TextEditingController _priceController;
  late final TextEditingController _tastingNotesController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;

  ProductImageFile? _selectedLocalImageFile;
  String? _selectedImageUrl;
  String? _imageFieldError;

  String _roastLevel = 'Light-Medium Roast';
  String _categoryId = 'single-origin';
  String _categoryName = 'Single Origin';
  bool _isLoading = false;
  bool _isUploadingImage = false;

  final List<String> _roastLevels = [
    'Light Roast',
    'Light-Medium Roast',
    'Medium-Light Roast',
    'Medium Roast',
    'Medium-Dark Roast',
    'Dark Roast',
    'Dark Roast (French)',
    'Ready to Drink',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _originController = TextEditingController(text: p?.origin ?? '');
    _priceController = TextEditingController(text: p != null ? p.basePrice.toStringAsFixed(2) : '450.00');
    _tastingNotesController = TextEditingController(text: p?.tastingNotes ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _stockController = TextEditingController(text: p != null ? p.stockQuantity.toString() : '20');
    _selectedImageUrl = p?.imageUrl;

    if (p != null) {
      if (p.roastLevel.isNotEmpty && !_roastLevels.contains(p.roastLevel)) {
        _roastLevels.add(p.roastLevel);
      }
      _roastLevel = p.roastLevel.isNotEmpty ? p.roastLevel : 'Light-Medium Roast';
      _categoryId = p.categoryId;
      _categoryName = p.categoryName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _priceController.dispose();
    _tastingNotesController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isLoading || _isUploadingImage) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _imageFieldError = null;
    });

    final controller = ref.read(adminProductNotifierProvider);
    String? finalImageUrl = _selectedImageUrl;

    // 1. Secure Image Upload Pipeline (if a new local image was chosen)
    if (_selectedLocalImageFile != null) {
      setState(() => _isUploadingImage = true);

      final uploadResult = await controller.uploadProductImage(
        bytes: _selectedLocalImageFile!.bytes,
        filename: _selectedLocalImageFile!.filename,
        contentType: _selectedLocalImageFile!.mimeType,
      );

      setState(() => _isUploadingImage = false);

      if (uploadResult.isFailure) {
        setState(() {
          _isLoading = false;
          _imageFieldError = uploadResult.failureOrNull?.userFriendlyMessage ??
              'Unsupported file type. Please upload a JPG, PNG, or WebP image under 5 MB.';
        });
        if (mounted) {
          AppToast.error(
            context,
            uploadResult.failureOrNull?.userFriendlyMessage ?? 'Image upload failed. Please try again.',
          );
        }
        return;
      }

      finalImageUrl = uploadResult.dataOrNull?.imageUrl;
    }

    final isEdit = widget.product != null;
    final price = double.tryParse(_priceController.text.trim()) ?? 450.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 20;

    final productData = ProductModel(
      id: widget.product?.id ?? 'temp_id',
      name: _nameController.text.trim(),
      slug: _nameController.text.trim().toLowerCase().replaceAll(' ', '-'),
      origin: _originController.text.trim(),
      description: _descriptionController.text.trim(),
      basePrice: price,
      imageUrl: finalImageUrl,
      categoryId: _categoryId,
      categoryName: _categoryName,
      roastLevel: _roastLevel,
      tastingNotes: _tastingNotesController.text.trim(),
      availability: stock > 0 ? ProductAvailability.available : ProductAvailability.outOfStock,
      stockQuantity: stock,
      isFeatured: widget.product?.isFeatured ?? false,
    );

    final result = isEdit
        ? await controller.updateProduct(productData)
        : await controller.addProduct(productData);

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (savedProduct) {
        AppToast.success(context, isEdit ? 'Product updated.' : 'New roast product created.');
        Navigator.of(context).pop(savedProduct);
      },
      failure: (failure) {
        AppToast.error(context, failure.userFriendlyMessage);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = _isLoading || _isUploadingImage;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ------------------------------------------------------------------
          // 1. Luxury Product Image Picker & Security Validator Field
          // ------------------------------------------------------------------
          ProductImagePickerField(
            initialImageUrl: _selectedImageUrl,
            errorMessage: _imageFieldError,
            isUploading: _isUploadingImage,
            onImageSelected: (file) {
              setState(() {
                _selectedLocalImageFile = file;
                _imageFieldError = null;
                if (file != null) _selectedImageUrl = null;
              });
            },
            onUrlChanged: (url) {
              setState(() {
                _selectedImageUrl = url;
                _selectedLocalImageFile = null;
                _imageFieldError = null;
              });
            },
          ),
          AppSpacing.vSpaceLg,

          // ------------------------------------------------------------------
          // 2. Product Details Form
          // ------------------------------------------------------------------
          AppTextField(
            label: 'Roast Product Name',
            hint: 'e.g. Benguet Typica Heirloom',
            controller: _nameController,
            validator: Validators.productName,
          ),
          AppSpacing.vSpaceLg,

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Origin & Terroir',
                  hint: 'Atok, Benguet',
                  controller: _originController,
                  validator: (v) {
                    final req = Validators.required(v, 'Please enter origin');
                    if (req != null) return req;
                    if (v!.trim().length > 100) return 'Origin cannot exceed 100 characters';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Base Price (250g ₱)',
                  hint: '450.00',
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => Validators.price(v, fieldName: 'Base price'),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceLg,

          AppTextField(
            label: 'Sensory Tasting Notes',
            hint: 'Wild raspberry, forest honey, cacao nibs...',
            controller: _tastingNotesController,
            validator: (v) {
              final req = Validators.required(v, 'Enter tasting notes');
              if (req != null) return req;
              if (v!.trim().length > 200) return 'Tasting notes cannot exceed 200 characters';
              return null;
            },
          ),
          AppSpacing.vSpaceLg,

          AppTextField(
            label: 'Full Description & Craft Notes',
            hint: 'Describe fermentation, farm background...',
            controller: _descriptionController,
            maxLines: 3,
            validator: (v) {
              final req = Validators.required(v, 'Enter description');
              if (req != null) return req;
              if (v!.trim().length > 2000) return 'Description cannot exceed 2000 characters';
              return null;
            },
          ),
          AppSpacing.vSpaceLg,

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _roastLevels.contains(_roastLevel) ? _roastLevel : _roastLevels.first,
                  decoration: const InputDecoration(labelText: 'Roast Level'),
                  items: _roastLevels.map((lvl) {
                    return DropdownMenuItem(value: lvl, child: Text(lvl, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _roastLevel = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Stock Quantity',
                  hint: '20',
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.stock(v, fieldName: 'Stock quantity'),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceXxl,

          AppButton.primary(
            text: widget.product == null ? 'Save New Roast' : 'Update Product',
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : _handleSave,
          ),
          AppSpacing.vSpaceMd,
        ],
      ),
    );
  }
}
