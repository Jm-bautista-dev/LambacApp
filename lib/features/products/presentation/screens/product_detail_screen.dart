import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/buttons/app_favorite_button.dart';
import '../../../../core/widgets/buttons/app_scale_button.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_3d_coffee_bean.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/guest_auth_prompt_sheet.dart';
import '../../../cart/domain/models/pending_add_to_cart_action.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../reviews/presentation/widgets/product_reviews_list.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_variant_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/product_detail_provider.dart';
import '../widgets/app_product_image.dart';
import '../widgets/product_availability_badge.dart';
import '../widgets/product_variant_selector.dart';

/// Production Product Detail Screen
/// Editorial Coffee Presentation, Sensory Highlight, Terroir Specifications & Verified Reviews
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductVariantModel? _selectedSize;
  ProductVariantModel? _selectedGrind;
  int _quantity = 1;

  double _calculateUnitPrice(ProductModel product) {
    final base = product.basePrice;
    final sizeDelta = _selectedSize?.priceDelta ?? 0.0;
    final grindDelta = _selectedGrind?.priceDelta ?? 0.0;
    return base + sizeDelta + grindDelta;
  }

  double _calculateTotalPrice(ProductModel product) {
    return _calculateUnitPrice(product) * _quantity;
  }

  void _handleAddToCart(ProductModel product) {
    if (!product.isOrderable) {
      AppToast.error(context, 'This micro-lot is currently out of stock.');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    final isGuest = currentUser == null || currentUser.isGuest;

    if (isGuest) {
      final action = PendingAddToCartAction(
        product: product,
        sizeVariant: _selectedSize,
        grindVariant: _selectedGrind,
        quantity: _quantity,
      );
      showGuestAuthPrompt(
        context: context,
        ref: ref,
        title: 'Sign In to Add to Cart',
        message: 'Sign in to add items to your cart and place an order.',
        pendingAction: action,
        redirectPath: AppRoutes.productDetailPath(product.id),
      );
      return;
    }

    ref.read(cartNotifierProvider.notifier).addItem(
      product: product,
      sizeVariant: _selectedSize,
      grindVariant: _selectedGrind,
      quantity: _quantity,
    );

    final sizeName = _selectedSize?.name ?? '250g Bag';
    final grindName = _selectedGrind?.name ?? 'Whole Bean';

    AppToast.cartItemAdded(
      context,
      productName: product.name,
      quantity: _quantity,
      variantDescription: '$sizeName, $grindName',
      onViewCart: () => context.go(AppRoutes.cart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(widget.productId);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        title: 'Micro-Lot Details',
        fallbackRoute: AppRoutes.products,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppFavoriteButton(
              isFavorite: isFavorite,
              size: 38,
              onToggle: (_) => ref.read(favoritesProvider.notifier).toggleFavorite(widget.productId),
            ),
          ),
        ],
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.warmDiscovery,
        showAmbientParticles: true,
        child: productAsync.when(
          data: (product) {
            // Initialize default variants if null
            _selectedSize ??= product.sizeVariants.isNotEmpty
                ? product.sizeVariants.firstWhere((s) => s.isDefault, orElse: () => product.sizeVariants.first)
                : null;

            _selectedGrind ??= product.grindVariants.isNotEmpty
                ? product.grindVariants.firstWhere((g) => g.isDefault, orElse: () => product.grindVariants.first)
                : null;

            final unitPrice = _calculateUnitPrice(product);
            final totalPrice = _calculateTotalPrice(product);

            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: ResponsiveContentContainer(
                      maxWidth: 720,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          // ---------------------------------------------------
                          // 1. Hero Imagery with Aspect Ratio & Ambient Bean
                          // ---------------------------------------------------
                          Container(
                            height: 250,
                            decoration: CustomerLuxuryTheme.cardDecoration(
                              isDark: isDark,
                              borderRadius: AppRadius.radiusXl,
                              isElevated: true,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AppProductImage(
                                  imageUrl: product.imageUrl,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                // Gradient for badge contrast
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.35),
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.55),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Availability Badge (Top-left)
                                Positioned(
                                  top: 14,
                                  left: 14,
                                  child: ProductAvailabilityBadge(
                                    availability: product.availability,
                                    stockQuantity: product.stockQuantity,
                                  ),
                                ),
                                // Single Origin Badge (Top-right)
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.92),
                                      borderRadius: AppRadius.radiusPill,
                                      border: Border.all(
                                        color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Lambac3DCoffeeBean(
                                          size: 14,
                                          intensity: BeanIntensity.subtle,
                                          roastStyle: BeanRoastStyle.honeyGold,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Single Origin',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                            color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vSpaceLg,

                          // ---------------------------------------------------
                          // 2. Origin & Roast Eyebrow
                          // ---------------------------------------------------
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isDark ? CustomerLuxuryTheme.darkElevatedSurface : CustomerLuxuryTheme.lightCreamSurface,
                                  borderRadius: AppRadius.radiusPill,
                                  border: Border.all(
                                    color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                                  ),
                                ),
                                child: Text(
                                  product.roastLevel,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.cremaGold : CustomerLuxuryTheme.amberGold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  product.origin.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.9,
                                    color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vSpaceSm,

                          // ---------------------------------------------------
                          // 3. Editorial Product Title
                          // ---------------------------------------------------
                          Text(
                            product.name,
                            style: GoogleFonts.newsreader(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              height: 1.18,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          AppSpacing.vSpaceMd,

                          // ---------------------------------------------------
                          // 4. Roastery Terroir Description
                          // ---------------------------------------------------
                          Text(
                            'Roastery Terroir & Craft',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          AppSpacing.vSpaceXs,
                          Text(
                            product.description,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.5,
                            ),
                          ),
                          AppSpacing.vSpaceLg,

                          // ---------------------------------------------------
                          // 5. Sensory Tasting Notes Card
                          // ---------------------------------------------------
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: CustomerLuxuryTheme.cardDecoration(
                              isDark: isDark,
                              borderRadius: AppRadius.radiusLg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 16,
                                      color: isDark ? AppColors.cremaGold : CustomerLuxuryTheme.amberGold,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sensory Tasting Notes',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  product.tastingNotes,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vSpaceLg,

                          // ---------------------------------------------------
                          // 6. Terroir Specifications (Elevation, Process, Varietal)
                          // ---------------------------------------------------
                          if (product.elevation != null || product.process != null || product.varietal != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: CustomerLuxuryTheme.cardDecoration(
                                isDark: isDark,
                                borderRadius: AppRadius.radiusLg,
                              ),
                              child: Row(
                                children: [
                                  if (product.elevation != null)
                                    Expanded(
                                      child: _buildSpecItem('Elevation', product.elevation!, isDark),
                                    ),
                                  if (product.process != null)
                                    Expanded(
                                      child: _buildSpecItem('Process', product.process!, isDark),
                                    ),
                                  if (product.varietal != null)
                                    Expanded(
                                      child: _buildSpecItem('Varietal', product.varietal!, isDark),
                                    ),
                                ],
                              ),
                            ),
                            AppSpacing.vSpaceLg,
                          ],

                          // ---------------------------------------------------
                          // 7. Unit Price Banner
                          // ---------------------------------------------------
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            decoration: CustomerLuxuryTheme.cardDecoration(
                              isDark: isDark,
                              borderRadius: AppRadius.radiusMd,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unit Price',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.format(unitPrice),
                                      style: GoogleFonts.inter(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.cremaGold : const Color(0xFFA35F30),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? CustomerLuxuryTheme.darkElevatedSurface : Colors.white,
                                    borderRadius: AppRadius.radiusPill,
                                    border: Border.all(
                                      color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                                    ),
                                  ),
                                  child: Text(
                                    _selectedSize?.name ?? 'Base 250g',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vSpaceLg,

                          // ---------------------------------------------------
                          // 8. Customizations: Size & Grind Variant Selectors
                          // ---------------------------------------------------
                          if (product.sizeVariants.isNotEmpty) ...[
                            ProductVariantSelector(
                              title: 'Select Bag Size',
                              variants: product.sizeVariants,
                              selectedVariant: _selectedSize,
                              showPriceDelta: true,
                              onSelected: (size) => setState(() => _selectedSize = size),
                            ),
                            AppSpacing.vSpaceLg,
                          ],

                          if (product.grindVariants.isNotEmpty) ...[
                            ProductVariantSelector(
                              title: 'Select Grind Size',
                              variants: product.grindVariants,
                              selectedVariant: _selectedGrind,
                              onSelected: (grind) => setState(() => _selectedGrind = grind),
                            ),
                            AppSpacing.vSpaceLg,
                          ],

                          // ---------------------------------------------------
                          // 9. Verified Customer Reviews & Moderation
                          // ---------------------------------------------------
                          AppSpacing.vSpaceMd,
                          ProductReviewsList(
                            productId: product.id,
                            productName: product.name,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // 10. Bottom Purchase Floating Bar (Quantity + Add to Cart)
                  // -----------------------------------------------------------
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.sizeOf(context).width < 360 ? 12 : 20,
                      14,
                      MediaQuery.sizeOf(context).width < 360 ? 12 : 20,
                      20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? CustomerLuxuryTheme.darkElevatedSurface : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                          width: 1,
                        ),
                      ),
                      boxShadow: isDark ? CustomerLuxuryTheme.luxuryShadowDark : CustomerLuxuryTheme.luxuryShadowLight,
                    ),
                    child: SafeArea(
                      top: false,
                      child: ResponsiveContentContainer(
                        maxWidth: 720,
                        child: LayoutBuilder(
                          builder: (context, barConstraints) {
                            final isCompactBar = barConstraints.maxWidth < 320;
                            return Row(
                              children: [
                                // Quantity Stepper
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                    borderRadius: AppRadius.radiusPill,
                                    border: Border.all(
                                      color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppScaleButton(
                                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompactBar ? 8 : 10,
                                            vertical: 8,
                                          ),
                                          child: Icon(
                                            Icons.remove_rounded,
                                            size: 18,
                                            color: _quantity > 1
                                                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                                : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          '$_quantity',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ),
                                      AppScaleButton(
                                        onPressed: product.isOrderable ? () => setState(() => _quantity++) : null,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompactBar ? 8 : 10,
                                            vertical: 8,
                                          ),
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 18,
                                            color: product.isOrderable
                                                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                                : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: isCompactBar ? 8 : 14),
                                // Add to Cart Button
                                Expanded(
                                  child: AppButton.primary(
                                    text: product.isOrderable
                                        ? 'Add • ${CurrencyFormatter.format(totalPrice)}'
                                        : 'Sold Out',
                                    onPressed: product.isOrderable ? () => _handleAddToCart(product) : null,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: LambacRoasteryLoader(
              message: 'Preparing Roastery Terroir...',
            ),
          ),
          error: (err, stackTrace) {
            final failure = ErrorHandler.handle(
              err,
              stackTrace: stackTrace,
              operation: 'product',
              domain: FailureDomain.firestoreAccess,
              recordId: widget.productId,
            );
            return AppErrorView(
              failure: failure,
              onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
