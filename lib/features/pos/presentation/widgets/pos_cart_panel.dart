import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/dialogs/app_dialog.dart';
import '../../../products/presentation/widgets/app_product_image.dart';
import '../providers/pos_cart_provider.dart';

/// POS Order / Cart Panel managing item quantities, pricing rules, stale price alerts, and checkout trigger
class PosCartPanel extends ConsumerWidget {
  final VoidCallback onProceedToCheckout;

  const PosCartPanel({
    super.key,
    required this.onProceedToCheckout,
  });

  Future<void> _confirmClearCart(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Clear Counter Order',
      message: 'Are you sure you want to remove all items from the current transaction?',
      confirmText: 'Clear Order',
      cancelText: 'Keep Items',
      isDestructive: true,
    );

    if (confirmed == true) {
      ref.read(posCartNotifierProvider.notifier).clearCart();
    }
  }

  void _showDiscountSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.read(posCartNotifierProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Apply Transaction Discount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                tileColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                leading: const Icon(Icons.elderly_rounded, color: AppColors.brandAmber),
                title: const Text('Senior Citizen / PWD (20%)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('Saves ${CurrencyFormatter.format(cartState.subtotal * 0.20)}', style: const TextStyle(fontSize: 12)),
                onTap: () {
                  ref.read(posCartNotifierProvider.notifier).applyDiscount(cartState.subtotal * 0.20, 'Senior/PWD (20%)');
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                tileColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                leading: const Icon(Icons.badge_rounded, color: AppColors.matchaSage),
                title: const Text('Staff Roastery Privilege (15%)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('Saves ${CurrencyFormatter.format(cartState.subtotal * 0.15)}', style: const TextStyle(fontSize: 12)),
                onTap: () {
                  ref.read(posCartNotifierProvider.notifier).applyDiscount(cartState.subtotal * 0.15, 'Staff (15%)');
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              if (cartState.discountAmount > 0)
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                  tileColor: AppColors.error.withValues(alpha: 0.1),
                  leading: const Icon(Icons.clear_rounded, color: AppColors.error),
                  title: const Text('Remove Discount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.error)),
                  onTap: () {
                    ref.read(posCartNotifierProvider.notifier).clearDiscount();
                    Navigator.of(ctx).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartState = ref.watch(posCartNotifierProvider);
    final notifier = ref.read(posCartNotifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 20, color: AppColors.brandAmber),
                    const SizedBox(width: 8),
                    Text(
                      'Counter Order',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        borderRadius: AppRadius.radiusPill,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        '${cartState.itemCount} items',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (cartState.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: () => _confirmClearCart(context, ref),
                  ),
              ],
            ),
          ),

          // Stale Price Alert Banner
          if (cartState.hasStalePrices)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notification_important_rounded, size: 16, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text(
                        'PRICE UPDATE DETECTED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cartState.staleItemsCount} product price(s) were updated in Firestore. Please review and accept updated canonical prices before completing sale.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                      ),
                      onPressed: () => notifier.acceptAllLivePrices(),
                      child: const Text('Accept Updated Prices', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),

          // Unavailable Product Alert Banner
          if (cartState.hasUnavailableItems)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                      SizedBox(width: 6),
                      Text(
                        'UNAVAILABLE PRODUCTS IN CART',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cartState.unavailableItemsCount} item(s) were disabled or marked sold out. Remove them to proceed to checkout.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
                      ),
                      onPressed: () => notifier.removeUnavailableItems(),
                      child: const Text('Remove Unavailable Items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),

          // Items List Area
          Expanded(
            child: cartState.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 52,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Order Cart Empty',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select items from the product catalog to begin counter sale.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cartState.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      final isStale = item.isPriceStale;
                      final isUnavail = item.isUnavailable;

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: isUnavail
                                ? AppColors.error
                                : (isStale
                                    ? AppColors.warning
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                            width: (isUnavail || isStale) ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: AppRadius.radiusSm,
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: AppProductImage(
                                      imageUrl: item.product.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Product and Variant name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.sizeVariant != null || item.grindVariant != null)
                                        Text(
                                          [
                                            if (item.sizeVariant != null) item.sizeVariant!.name,
                                            if (item.grindVariant != null) item.grindVariant!.name,
                                          ].join(' • '),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            CurrencyFormatter.format(item.capturedUnitPrice),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              decoration: isStale ? TextDecoration.lineThrough : null,
                                              color: isStale ? AppColors.lightTextTertiary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                            ),
                                          ),
                                          if (isStale) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              CurrencyFormatter.format(item.currentLiveUnitPrice),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.warning,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Line Total & Remove
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(item.lineTotal),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => notifier.removeItem(item.id),
                                      child: const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Price Discrepancy Action Banner on Item
                            if (isStale)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: InkWell(
                                  onTap: () => notifier.acceptPriceForItem(item.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.15),
                                      borderRadius: AppRadius.radiusSm,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Price changed. Tap to accept', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.warning)),
                                        Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.warning),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Unavailable Item Warning on Item
                            if (isUnavail)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  item.unavailabilityReason ?? 'Item unavailable',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error),
                                ),
                              ),

                            // Quantity Stepper Controls
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                    borderRadius: AppRadius.radiusPill,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => notifier.decrementQuantity(item.id),
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Icon(Icons.remove_rounded, size: 14),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          '${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => notifier.incrementQuantity(item.id),
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Icon(Icons.add_rounded, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Pricing Summary & Checkout Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(cartState.subtotal),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Discount line (clickable to apply discount)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _showDiscountSheet(context, ref),
                      child: Row(
                        children: [
                          Icon(
                            Icons.discount_outlined,
                            size: 14,
                            color: cartState.discountAmount > 0 ? AppColors.success : AppColors.brandAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cartState.discountAmount > 0
                                ? 'Discount (${cartState.discountType})'
                                : 'Add Discount (Senior/Staff)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cartState.discountAmount > 0 ? AppColors.success : AppColors.brandAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      cartState.discountAmount > 0
                          ? '-${CurrencyFormatter.format(cartState.discountAmount)}'
                          : '₱0.00',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cartState.discountAmount > 0 ? AppColors.success : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Divider(height: 1),
                const SizedBox(height: 10),

                // Total Charged
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(cartState.total),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Checkout CTA Button
                AppButton(
                  text: cartState.isEmpty
                      ? 'Cart is Empty'
                      : (cartState.hasUnavailableItems
                          ? 'Resolve Unavailable Items'
                          : (cartState.hasStalePrices
                              ? 'Accept Price Updates'
                              : 'Proceed to Payment • ${CurrencyFormatter.format(cartState.total)}')),
                  leadingIcon: const Icon(Icons.payments_rounded, size: 18),
                  variant: (cartState.hasUnavailableItems || cartState.hasStalePrices)
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  onPressed: cartState.isEmpty
                      ? null
                      : (cartState.hasUnavailableItems
                          ? () => notifier.removeUnavailableItems()
                          : (cartState.hasStalePrices
                              ? () => notifier.acceptAllLivePrices()
                              : onProceedToCheckout)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
