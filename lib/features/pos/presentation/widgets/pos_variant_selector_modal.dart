import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';
import '../../../products/presentation/widgets/app_product_image.dart';

/// Luxury Variant Selection Modal for POS Ordering
class PosVariantSelectorModal extends StatefulWidget {
  final ProductModel product;
  final void Function({
    required ProductModel product,
    ProductVariantModel? sizeVariant,
    ProductVariantModel? grindVariant,
    required int quantity,
  }) onAddToCart;

  const PosVariantSelectorModal({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductModel product,
    required void Function({
      required ProductModel product,
      ProductVariantModel? sizeVariant,
      ProductVariantModel? grindVariant,
      required int quantity,
    }) onAddToCart,
  }) {
    return AppBottomSheet.show<void>(
      context,
      title: 'Select Options • ${product.name}',
      child: PosVariantSelectorModal(
        product: product,
        onAddToCart: onAddToCart,
      ),
    );
  }

  @override
  State<PosVariantSelectorModal> createState() => _PosVariantSelectorModalState();
}

class _PosVariantSelectorModalState extends State<PosVariantSelectorModal> {
  ProductVariantModel? _selectedSize;
  ProductVariantModel? _selectedGrind;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.sizeVariants.isNotEmpty) {
      _selectedSize = widget.product.sizeVariants.firstWhere(
        (s) => s.isDefault,
        orElse: () => widget.product.sizeVariants.first,
      );
    }
    if (widget.product.grindVariants.isNotEmpty) {
      _selectedGrind = widget.product.grindVariants.firstWhere(
        (g) => g.isDefault,
        orElse: () => widget.product.grindVariants.first,
      );
    }
  }

  double get _currentUnitPrice {
    final sizeDelta = _selectedSize?.priceDelta ?? 0.0;
    final grindDelta = _selectedGrind?.priceDelta ?? 0.0;
    return widget.product.basePrice + sizeDelta + grindDelta;
  }

  double get _totalPrice => _currentUnitPrice * _quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Product Summary Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.radiusMd,
              child: SizedBox(
                width: 72,
                height: 72,
                child: AppProductImage(
                  imageUrl: widget.product.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.product.origin} • ${widget.product.roastLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(_currentUnitPrice),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandAmber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Size Selection (if available)
        if (widget.product.sizeVariants.isNotEmpty) ...[
          Text(
            'PACKAGE SIZE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.product.sizeVariants.map((size) {
              final isSelected = _selectedSize?.id == size.id;
              final deltaText = size.priceDelta > 0
                  ? ' (+${CurrencyFormatter.format(size.priceDelta)})'
                  : (size.priceDelta < 0
                      ? ' (-${CurrencyFormatter.format(size.priceDelta.abs())})'
                      : '');
              return AppChip(
                label: '${size.name}$deltaText',
                isSelected: isSelected,
                onSelected: (_) => setState(() => _selectedSize = size),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Grind Selection (if available)
        if (widget.product.grindVariants.isNotEmpty) ...[
          Text(
            'GRIND PROFILE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.product.grindVariants.map((grind) {
              final isSelected = _selectedGrind?.id == grind.id;
              return AppChip(
                label: grind.name,
                isSelected: isSelected,
                onSelected: (_) => setState(() => _selectedGrind = grind),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Quantity Stepper
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QUANTITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppRadius.radiusPill,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '$_quantity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Add to Cart CTA Button
        AppButton(
          text: 'Add to Order • ${CurrencyFormatter.format(_totalPrice)}',
          leadingIcon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
          variant: AppButtonVariant.primary,
          onPressed: () {
            widget.onAddToCart(
              product: widget.product,
              sizeVariant: _selectedSize,
              grindVariant: _selectedGrind,
              quantity: _quantity,
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
