import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../../../core/widgets/feedback/app_empty_states.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/widgets/app_product_image.dart';
import '../providers/admin_provider.dart';
import '../widgets/add_edit_product_sheet.dart';
import '../widgets/product_availability_dialogs.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';

/// Business Product Catalog Management Screen
/// Provides real-time governance of product availability, sold-out states, and catalog visibility.
class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDisableProduct(ProductModel product) async {
    final visibilityChoice = await DisableProductDialog.show(context, product: product);
    if (visibilityChoice == null || !mounted) return;

    final controller = ref.read(adminProductNotifierProvider);
    final result = await controller.setProductAvailabilityAndVisibility(
      productId: product.id,
      isEnabled: false,
      customerVisibility: visibilityChoice,
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        if (visibilityChoice == ProductVisibility.visible) {
          AppToast.info(context, '${product.name} marked as sold out.');
        } else {
          AppToast.info(context, '${product.name} hidden from customers.');
        }
      },
      failure: (failure) {
        AppToast.error(context, failure.userFriendlyMessage);
      },
    );
  }

  Future<void> _handleEnableProduct(ProductModel product) async {
    final confirmed = await EnableProductDialog.show(context, product: product);
    if (confirmed != true || !mounted) return;

    final controller = ref.read(adminProductNotifierProvider);
    final result = await controller.setProductAvailabilityAndVisibility(
      productId: product.id,
      isEnabled: true,
      customerVisibility: ProductVisibility.visible,
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        AppToast.success(context, '${product.name} enabled successfully.');
      },
      failure: (failure) {
        AppToast.error(context, failure.userFriendlyMessage);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    final adminProductsState = ref.watch(adminProductsNotifierProvider);
    final notifier = ref.read(adminProductsNotifierProvider.notifier);
    final isOwnerAdmin = user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        showBackButton: false,
        title: 'Product Management',
        subtitle: '${adminProductsState.products.length} Total Roastery Products',
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: InkWell(
              onTap: () => context.push(AppRoutes.pos),
              borderRadius: AppRadius.radiusPill,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.brandAmber.withValues(alpha: 0.22) : AppColors.brandAmber.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(
                    color: AppColors.brandAmber.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.point_of_sale_rounded, size: 16, color: AppColors.brandAmber),
                    const SizedBox(width: 5),
                    Text(
                      'POS Register',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOwnerAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                key: SpotlightKeys.adminAddProductBtn,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                tooltip: 'Add Roast',
                onPressed: () => AddEditProductSheet.show(context),
              ),
            ),
        ],
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.subtleOperations,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 760,
            child: Column(
              children: [
                // Search and Filters Header Section
                Container(
                  key: SpotlightKeys.adminProductsCatalog,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search Input Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (query) => notifier.setSearchQuery(query),
                          decoration: InputDecoration(
                            hintText: 'Search products by name, origin, roast...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      notifier.setSearchQuery('');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),

                      // Status Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AppChip(
                                label: 'All (${adminProductsState.products.length})',
                                isSelected: adminProductsState.filter == AdminProductFilter.all,
                                isSmall: true,
                                onSelected: (_) => notifier.setFilter(AdminProductFilter.all),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AppChip(
                                label: 'Available (${adminProductsState.availableCount})',
                                isSelected: adminProductsState.filter == AdminProductFilter.available,
                                isSmall: true,
                                onSelected: (_) => notifier.setFilter(AdminProductFilter.available),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AppChip(
                                label: 'Sold Out (${adminProductsState.soldOutCount})',
                                isSelected: adminProductsState.filter == AdminProductFilter.soldOut,
                                isSmall: true,
                                onSelected: (_) => notifier.setFilter(AdminProductFilter.soldOut),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AppChip(
                                label: 'Hidden (${adminProductsState.hiddenCount})',
                                isSelected: adminProductsState.filter == AdminProductFilter.hidden,
                                isSmall: true,
                                onSelected: (_) => notifier.setFilter(AdminProductFilter.hidden),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Products List
                Expanded(
                  child: adminProductsState.isLoading && adminProductsState.products.isEmpty
                      ? const Center(
                          child: LambacRoasteryLoader(message: 'Loading product catalog...'),
                        )
                      : adminProductsState.failure != null && adminProductsState.products.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: AppErrorView(
                                failure: adminProductsState.failure!,
                                onRetry: () => notifier.loadProducts(isRefresh: true),
                              ),
                            )
                          : adminProductsState.filteredProducts.isEmpty
                              ? AppEmptyProductsState(
                                  onRefresh: () => notifier.loadProducts(isRefresh: true),
                                )
                          : RefreshIndicator(
                              onRefresh: () async => notifier.loadProducts(isRefresh: true),
                              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                              child: ListView.separated(
                                padding: AppSpacing.screenPadding,
                                itemCount: adminProductsState.filteredProducts.length,
                                separatorBuilder: (_, __) => AppSpacing.vSpaceMd,
                                itemBuilder: (context, index) {
                                  final product = adminProductsState.filteredProducts[index];
                                  return _buildProductManagementCard(
                                    context: context,
                                    product: product,
                                    isOwnerAdmin: isOwnerAdmin,
                                    isDark: isDark,
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductManagementCard({
    required BuildContext context,
    required ProductModel product,
    required bool isOwnerAdmin,
    required bool isDark,
  }) {
    final isAvailable = product.isEnabled;
    final isSoldOut = !product.isEnabled && product.customerVisibility == ProductVisibility.visible;
    final isHidden = product.customerVisibility == ProductVisibility.hidden;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: AppProductImage(
                  imageUrl: product.imageUrl,
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(10),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.origin} • ${product.roastLevel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status Badge
                    _buildStatusBadge(
                      isAvailable: isAvailable,
                      isSoldOut: isSoldOut,
                      isHidden: isHidden,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dynamic Action Button (Disable / Enable)
              if (isAvailable)
                OutlinedButton.icon(
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 15),
                  label: const Text('Disable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 34),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _handleDisableProduct(product),
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 15),
                  label: const Text('Enable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 34),
                    visualDensity: VisualDensity.compact,
                    elevation: 0,
                  ),
                  onPressed: () => _handleEnableProduct(product),
                ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Price: ${CurrencyFormatter.format(product.basePrice)} • Stock: ${product.stockQuantity} bags',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isOwnerAdmin)
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit Specs', style: TextStyle(fontSize: 12)),
                  onPressed: () => AddEditProductSheet.show(context, product: product),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isAvailable,
    required bool isSoldOut,
    required bool isHidden,
    required bool isDark,
  }) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (isAvailable) {
      bg = isDark ? AppColors.success.withOpacity(0.18) : AppColors.success.withOpacity(0.12);
      fg = isDark ? const Color(0xFF81C784) : AppColors.success;
      label = 'Available';
      icon = Icons.check_circle_rounded;
    } else if (isSoldOut) {
      bg = isDark ? AppColors.warning.withOpacity(0.2) : AppColors.warning.withOpacity(0.15);
      fg = isDark ? const Color(0xFFFFB74D) : AppColors.warning;
      label = 'Sold Out';
      icon = Icons.do_not_disturb_on_rounded;
    } else {
      bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
      fg = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
      label = 'Hidden';
      icon = Icons.visibility_off_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusPill,
        border: Border.all(color: fg.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
