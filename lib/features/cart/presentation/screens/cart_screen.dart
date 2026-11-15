import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/buttons/app_scale_button.dart';
import '../../../../core/widgets/feedback/app_empty_states.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/guest_auth_prompt_sheet.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../../../products/presentation/widgets/app_product_image.dart';

/// Production Customer Cart Screen
/// Refactored with 4-Step Editorial Hierarchy (WHAT, WHEN, HOW YOU PAY, HOW MUCH),
/// Soft Frosted Surfaces, and Guest Authentication Protection
class CartScreen extends ConsumerWidget {
  static DateTime? _lastCheckoutTap;

  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cartState = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);

    final productsState = ref.watch(productsNotifierProvider);
    final catalogProducts = productsState.products;
    final unavailableItems = cartState.items.where((item) {
      if (catalogProducts.isEmpty) return false;
      final product = catalogProducts.where((p) => p.id == item.productId).firstOrNull;
      return product != null && (!product.isEnabled || !product.isOrderable);
    }).toList();
    final hasUnavailableItems = unavailableItems.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        showBackButton: false,
        title: 'Roastery Cart',
        subtitle: cartState.isNotEmpty
            ? '${cartState.itemCount} ${cartState.itemCount == 1 ? "Item" : "Items"} for Pickup'
            : '0 Items',
        actions: [
          if (cartState.isNotEmpty)
            TextButton(
              onPressed: () {
                cartNotifier.clearCart();
                AppToast.info(context, 'Cart cleared.');
              },
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                ),
              ),
            ),
        ],
      ),
      body: CinematicRoasteryBackground.subtle(
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 720,
            child: cartState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : cartState.isEmpty
                    ? AppEmptyCartState(
                        onBrowseMenu: () => context.go(AppRoutes.products),
                      )
                    : Column(
                        children: [
                          // Cart Content (Scrollable)
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              children: [
                                // Unavailable Items Warning Banner
                                if (hasUnavailableItems) ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.12),
                                      borderRadius: AppRadius.radiusMd,
                                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Some items are sold out / unavailable',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.error,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Please remove unavailable items before proceeding to checkout.',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            for (final u in unavailableItems) {
                                              cartNotifier.removeItem(u.id);
                                            }
                                            AppToast.info(context, 'Removed unavailable items.');
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          child: const Text('Remove', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppSpacing.vSpaceMd,
                                ],

                                // --------------------------------------------------
                                // 1. WHAT: Curated Coffee Selections
                                // --------------------------------------------------
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'WHAT',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                      ),
                                    ),
                                    Text(
                                      '${cartState.itemCount} items',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                ...cartState.items.map((item) {
                                  final matchingProduct = catalogProducts.where((p) => p.id == item.productId).firstOrNull;
                                  final isItemUnavailable = matchingProduct != null && (!matchingProduct.isEnabled || !matchingProduct.isOrderable);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: CustomerLuxuryTheme.cardDecoration(
                                        isDark: isDark,
                                        borderRadius: AppRadius.radiusLg,
                                        isElevated: true,
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, itemConstraints) {
                                          final isCompactCard = itemConstraints.maxWidth < 310;
                                          final thumbSize = isCompactCard ? 48.0 : 58.0;
                                          return Row(
                                            children: [
                                              // Product Thumbnail
                                              Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: AppRadius.radiusMd,
                                                    child: SizedBox(
                                                      width: thumbSize,
                                                      height: thumbSize,
                                                      child: AppProductImage(
                                                        imageUrl: item.imageUrl,
                                                        width: thumbSize,
                                                        height: thumbSize,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isItemUnavailable)
                                                    Positioned.fill(
                                                      child: ClipRRect(
                                                        borderRadius: AppRadius.radiusMd,
                                                        child: Container(
                                                          color: Colors.black.withOpacity(0.55),
                                                          alignment: Alignment.center,
                                                          child: const Text(
                                                            'Sold Out',
                                                            style: TextStyle(
                                                              fontSize: 8.5,
                                                              fontWeight: FontWeight.w700,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(width: isCompactCard ? 10 : 14),
                                              // Item Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.productName,
                                                      style: GoogleFonts.inter(
                                                        fontSize: isCompactCard ? 13.5 : 14.5,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: -0.2,
                                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (item.sizeVariant != null || item.grindVariant != null) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        [
                                                          if (item.sizeVariant != null) item.sizeVariant!.name,
                                                          if (item.grindVariant != null) item.grindVariant!.name,
                                                        ].join(' • '),
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11.5,
                                                          color: isDark ? CustomerLuxuryTheme.cremaBronze : CustomerLuxuryTheme.amberGold,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      CurrencyFormatter.format(item.totalPrice),
                                                      style: GoogleFonts.inter(
                                                        fontSize: isCompactCard ? 13.5 : 14.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: isDark ? AppColors.cremaGold : const Color(0xFFA35F30),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Quantity Adjuster Stepper
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                                  borderRadius: AppRadius.radiusPill,
                                                  border: Border.all(
                                                    color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                                                    width: 0.8,
                                                  ),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isCompactCard ? 2 : 4,
                                                  vertical: 2,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    AppScaleButton(
                                                      onPressed: () => cartNotifier.decrementQuantity(item.id),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(4),
                                                        child: Icon(
                                                          item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                                                          size: 16,
                                                          color: item.quantity == 1
                                                              ? AppColors.error
                                                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: isCompactCard ? 5 : 8),
                                                      child: Text(
                                                        '${item.quantity}',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w700,
                                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    AppScaleButton(
                                                      onPressed: isItemUnavailable ? null : () => cartNotifier.incrementQuantity(item.id),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(4),
                                                        child: Icon(
                                                          Icons.add_rounded,
                                                          size: 16,
                                                          color: isItemUnavailable
                                                              ? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
                                                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }),
                                AppSpacing.vSpaceMd,

                                // --------------------------------------------------
                                // 2. WHEN: Pickup Information
                                // --------------------------------------------------
                                Text(
                                  'WHEN',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: CustomerLuxuryTheme.cardDecoration(
                                    isDark: isDark,
                                    borderRadius: AppRadius.radiusLg,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? CustomerLuxuryTheme.amberGold.withOpacity(0.18)
                                              : CustomerLuxuryTheme.amberGold.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.storefront_rounded,
                                          size: 20,
                                          color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                        ),
                                      ),
                                      AppSpacing.hSpaceMd,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Flagship Roastery Counter Pickup',
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Session Road, Baguio City • Select pickup time slot at next step.',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppSpacing.vSpaceMd,

                                // --------------------------------------------------
                                // 3. HOW THEY PAY: Counter Settlement
                                // --------------------------------------------------
                                Text(
                                  'HOW YOU PAY',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: CustomerLuxuryTheme.cardDecoration(
                                    isDark: isDark,
                                    borderRadius: AppRadius.radiusLg,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? CustomerLuxuryTheme.matchaSage.withOpacity(0.2)
                                              : CustomerLuxuryTheme.matchaSage.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.payments_rounded,
                                          size: 20,
                                          color: CustomerLuxuryTheme.matchaSage,
                                        ),
                                      ),
                                      AppSpacing.hSpaceMd,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  'Pay at Counter',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: CustomerLuxuryTheme.matchaSage.withOpacity(0.18),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'No Online Prepayment',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: CustomerLuxuryTheme.matchaSage,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Pay physically when you arrive to pick up your order. Cash, GCash/Maya, & credit cards accepted at counter.',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppSpacing.vSpaceLg,
                              ],
                            ),
                          ),

                          // --------------------------------------------------------
                          // 4. HOW MUCH: Checkout Summary Footer
                          // --------------------------------------------------------
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Order Subtotal (${cartState.itemCount} items)',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(cartState.subtotal),
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Due at Counter',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(cartState.subtotal),
                                      style: GoogleFonts.inter(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.cremaGold : const Color(0xFFA35F30),
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.vSpaceMd,
                                AppButton.primary(
                                  text: hasUnavailableItems
                                      ? 'Remove Sold Out Items to Checkout'
                                      : 'Proceed to Pickup Checkout',
                                  onPressed: hasUnavailableItems
                                      ? () {
                                          AppToast.error(context, 'Please remove sold out items from your cart before proceeding.');
                                        }
                                      : () {
                                          final now = DateTime.now();
                                          if (CartScreen._lastCheckoutTap != null &&
                                              now.difference(CartScreen._lastCheckoutTap!).inMilliseconds < 1200) {
                                            return;
                                          }
                                          CartScreen._lastCheckoutTap = now;

                                          final currentUser = ref.read(currentUserProvider);
                                          final isGuest = currentUser == null || currentUser.isGuest;
                                          if (isGuest) {
                                            showGuestAuthPrompt(
                                              context: context,
                                              ref: ref,
                                              title: 'Sign In to Checkout',
                                              message: 'Sign in or create an account to complete your pickup order.',
                                              redirectPath: AppRoutes.checkout,
                                            );
                                            return;
                                          }
                                          context.push(AppRoutes.checkout);
                                        },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
