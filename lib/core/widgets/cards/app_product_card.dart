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

/// Premium Editorial Vertical Product Card for Lambac Roastery
class AppProductCard extends StatelessWidget {
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
  final double width;

  const AppProductCard({
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
    this.width = 192.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaleButton(
      onPressed: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.hasBoundedHeight;
          final hasBoundedWidth = constraints.hasBoundedWidth;
          final double cardWidth = hasBoundedWidth ? constraints.maxWidth : width;
          final double cardHeight = hasBoundedHeight ? constraints.maxHeight : 345.0;
          final double imageHeight = hasBoundedHeight
              ? (cardHeight * 0.40).clamp(88.0, 134.0)
              : 124.0;
          final bool isTight = cardHeight < 320 || cardWidth < 155;

          final detailsContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: hasBoundedHeight ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
            mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Origin Micro-Eyebrow
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAvailable
                          ? (isDark ? AppColors.cremaGold : CustomerLuxuryTheme.amberGold)
                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      origin.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Product Name
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  height: 1.2,
                ),
                maxLines: isTight ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Tasting Notes
              Text(
                tastingNotes,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.3,
                ),
                maxLines: isTight ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!hasBoundedHeight) AppSpacing.vSpaceSm,
              // Price and Quick Add-to-Cart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.cremaGold : const Color(0xFFA35F30),
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppScaleButton(
                    onPressed: isAvailable ? onAddToCart : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? (isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        shape: BoxShape.circle,
                        boxShadow: isAvailable
                            ? [
                                BoxShadow(
                                  color: (isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.add_rounded,
                        size: 19,
                        color: isAvailable
                            ? (isDark ? AppColors.darkCanvas : Colors.white)
                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          return Container(
            width: cardWidth,
            height: hasBoundedHeight ? cardHeight : null,
            decoration: CustomerLuxuryTheme.cardDecoration(
              isDark: isDark,
              borderRadius: AppRadius.radiusLg,
              isElevated: true,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Container with Badges & Favorite Action
                Stack(
                  children: [
                    AppProductImage(
                      imageUrl: imageUrl,
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Gradient overlay for visual depth and badge contrast
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.25),
                              Colors.transparent,
                              Colors.black.withOpacity(0.20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Out of stock overlay
                    if (!isAvailable)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.48),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: AppRadius.radiusPill,
                              border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.6),
                            ),
                            child: const Text(
                              'Sold Out',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Roast Level Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.95),
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(
                            color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                            width: 0.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          roastLevel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    // Favorite Button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: AppFavoriteButton(
                        isFavorite: isFavorite,
                        onToggle: onFavoriteToggle,
                        size: 30,
                      ),
                    ),
                  ],
                ),

                // Details Container
                hasBoundedHeight
                    ? Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(11, 8, 11, 10),
                          child: detailsContent,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                        child: detailsContent,
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
