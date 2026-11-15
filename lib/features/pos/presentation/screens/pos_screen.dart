import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/pos_cart_provider.dart';
import '../widgets/pos_cart_panel.dart';
import '../widgets/pos_checkout_dialog.dart';
import '../widgets/pos_header.dart';
import '../widgets/pos_product_grid.dart';

/// Dedicated Point of Sale (POS) Counter Operations Screen
/// Responsive 2-panel architecture on tablets and desktop;
/// Streamlined catalog + accessible bottom drawer cart on mobile devices.
class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  void _openMobileCartSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: PosCartPanel(
              onProceedToCheckout: () {
                Navigator.of(sheetContext).pop();
                PosCheckoutDialog.show(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = context.isMediumOrLarger;
    final cartState = ref.watch(posCartNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      body: CinematicRoasteryBackground.subtle(
        child: SafeArea(
          child: Column(
            children: [
              // Top POS Header
              PosHeader(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    final user = ref.read(currentUserProvider);
                    context.go(
                      user?.isAdmin == true
                          ? AppRoutes.adminDashboard
                          : AppRoutes.staffOrders,
                    );
                  }
                },
              ),

              // Main Body Area
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Panel: Catalog Grid (Flex 5)
                          const Expanded(
                            flex: 5,
                            child: PosProductGrid(),
                          ),
                          // Right Panel: Persistent Order & Cart (Flex 3, bounded)
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 360,
                              maxWidth: 420,
                            ),
                            child: PosCartPanel(
                              onProceedToCheckout: () => PosCheckoutDialog.show(context),
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          // Mobile Catalog Grid
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: cartState.isNotEmpty ? 76.0 : 0.0,
                              ),
                              child: const PosProductGrid(),
                            ),
                          ),

                          // Mobile Floating Cart Summary Bar
                          if (cartState.isNotEmpty)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 14,
                              child: InkWell(
                                onTap: () => _openMobileCartSheet(context),
                                borderRadius: AppRadius.radiusLg,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandAmberDark,
                                    borderRadius: AppRadius.radiusLg,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Item count bubble
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${cartState.itemCount}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Label
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              cartState.hasStalePrices
                                                  ? 'Price updates pending'
                                                  : (cartState.hasUnavailableItems
                                                      ? 'Items unavailable'
                                                      : 'View Order Cart'),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'Total: ${CurrencyFormatter.format(cartState.total)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white.withValues(alpha: 0.85),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Open CTA
                                      const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'OPEN CART',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 20),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
