import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/app_scale_button.dart';
import '../../data/models/product_variant_model.dart';

/// Interactive Selector for Bag Size & Grind Variants
class ProductVariantSelector extends StatelessWidget {
  final String title;
  final List<ProductVariantModel> variants;
  final ProductVariantModel? selectedVariant;
  final ValueChanged<ProductVariantModel> onSelected;
  final bool showPriceDelta;

  const ProductVariantSelector({
    super.key,
    required this.title,
    required this.variants,
    required this.selectedVariant,
    required this.onSelected,
    this.showPriceDelta = false,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        AppSpacing.vSpaceSm,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variants.map((variant) {
            final isSelected = selectedVariant?.id == variant.id;

            return AppScaleButton(
              onPressed: variant.inStock ? () => onSelected(variant) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.brandAmber.withOpacity(0.25) : AppColors.brandAmber.withOpacity(0.15))
                      : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isSelected ? 1.5 : 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      variant.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    if (showPriceDelta && variant.priceDelta > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(+${CurrencyFormatter.format(variant.priceDelta)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
