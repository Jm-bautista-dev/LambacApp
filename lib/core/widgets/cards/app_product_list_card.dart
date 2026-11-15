import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/customer_luxury_theme.dart';
import '../../utils/currency_formatter.dart';
import '../buttons/app_favorite_button.dart';
import '../buttons/app_scale_button.dart';
import '../../../features/products/presentation/widgets/app_product_image.dart';

/// Premium Horizontal Product List Card for Lambac Roastery
class AppProductListCard extends StatelessWidget {
  final String id;
  final String name;
  final String origin;
  final String tastingNotes;
  final double price;
  final String roastLevel;
  final String? imageUrl;
  final bool isAvailable;
  final bool isFavorite;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFavoriteToggle;
  final VoidCallback? onAddToCart;

  const AppProductListCard({
    super.key,
    required this.id,
    required this.name,
    required this.origin,
    required this.tastingNotes,
    required this.price,
    required this.roastLevel,
    this.imageUrl,
    this.isAvailable = true,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaleButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: CustomerLuxuryTheme.cardDecoration(
          isDark: isDark,
          borderRadius: AppRadius.radiusLg,
          isElevated: true,
        ),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            final rowContent = Row(
              children: [
                // Image Box with Real Product Image & Sold Out Scrim
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.radiusMd,
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: AppProductImage(
                          imageUrl: imageUrl,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (!isAvailable)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: AppRadius.radiusMd,
                          child: Container(
                            color: Colors.black.withOpacity(0.55),
                            alignment: Alignment.center,
                            child: const Text(
                              'Sold Out',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.hSpaceMd,
                // Info Column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF231E1A) : const Color(0xFFEFE9DF),
                                borderRadius: AppRadius.radiusPill,
                                border: Border.all(
                                  color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                roastLevel,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.cremaGold : CustomerLuxuryTheme.amberGold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppFavoriteButton(
                            isFavorite: isFavorite,
                            onToggle: onFavoriteToggle,
                            size: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tastingNotes,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(price),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.cremaGold : const Color(0xFFA35F30),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          if (onAddToCart != null) ...[
                            const SizedBox(width: 8),
                            AppScaleButton(
                              onPressed: isAvailable ? onAddToCart : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? (isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold)
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  borderRadius: AppRadius.radiusPill,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 15,
                                      color: isAvailable
                                          ? (isDark ? AppColors.darkCanvas : Colors.white)
                                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isAvailable
                                            ? (isDark ? AppColors.darkCanvas : Colors.white)
                                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (cardConstraints.maxWidth < 320) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 320,
                  child: rowContent,
                ),
              );
            }
            return rowContent;
          },
        ),
      ),
    );
  }
}
