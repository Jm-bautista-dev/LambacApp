import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/product_model.dart';

/// Pill Badge indicating In Stock / Limited Batch / Sold Out
class ProductAvailabilityBadge extends StatelessWidget {
  final ProductAvailability availability;
  final int stockQuantity;

  const ProductAvailabilityBadge({
    super.key,
    required this.availability,
    this.stockQuantity = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (availability) {
      case ProductAvailability.available:
        bg = isDark ? AppColors.success.withOpacity(0.18) : AppColors.success.withOpacity(0.12);
        fg = isDark ? const Color(0xFF81C784) : AppColors.success;
        label = 'In Stock';
        icon = Icons.check_circle_outline_rounded;
        break;
      case ProductAvailability.lowStock:
        bg = isDark ? AppColors.warning.withOpacity(0.2) : AppColors.warning.withOpacity(0.15);
        fg = isDark ? const Color(0xFFFFB74D) : AppColors.warning;
        label = stockQuantity <= 5 ? 'Only $stockQuantity Left in Batch' : 'Limited Allocation';
        icon = Icons.local_fire_department_rounded;
        break;
      case ProductAvailability.outOfStock:
        bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        fg = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
        label = 'Sold Out • Next Batch Soon';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusPill,
        border: Border.all(
          color: fg.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
