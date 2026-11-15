import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/pagination/paged_load_more_footer.dart';
import '../../../../core/pagination/pagination_scroll_listener.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/cards/app_product_card.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../../../core/widgets/feedback/app_empty_states.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/product_model.dart';
import '../providers/categories_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/products_provider.dart';

/// Production Roastery Products Catalog Screen
/// Refactored with Luxury Coffee Boutique Presentation, Responsive Grid, and Refined Filtering
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      PaginationScrollHelper.createScrollListener(
        scrollController: _scrollController,
        canLoadMore: () {
          final s = ref.read(productsNotifierProvider);
          return !s.isLoading && !s.isLoadingMore && s.hasMore;
        },
        onLoadMore: () {
          ref.read(productsNotifierProvider.notifier).loadMoreProducts();
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAddToCart(ProductModel product) {
    if (!product.isOrderable) {
      AppToast.error(context, 'This micro-lot is currently out of stock.');
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    final isGuest = currentUser == null || currentUser.isGuest;

    if (isGuest) {
      context.push(AppRoutes.productDetailPath(product.id));
      return;
    }

    ref.read(cartNotifierProvider.notifier).addItem(
      product: product,
    );

    AppToast.cartItemAdded(
      context,
      productName: product.name,
      quantity: 1,
      onViewCart: () => context.go(AppRoutes.cart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final productsState = ref.watch(productsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final favorites = ref.watch(favoritesProvider);
    final notifier = ref.read(productsNotifierProvider.notifier);
    final cartItemCount = ref.watch(cartNotifierProvider.select((s) => s.itemCount));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        showBackButton: false,
        title: 'Micro-Lot Coffee Catalog',
        subtitle: 'Freshly Roasted in Baguio City',
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                tooltip: 'Shopping Cart',
                onPressed: () => context.go(AppRoutes.cart),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkCanvas : Colors.white,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.warmDiscovery,
        showAmbientParticles: true,
        showFloatingBean: false,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: ResponsiveLayout.maxContentWidth,
            child: Column(
              children: [
                // Search Input Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    decoration: CustomerLuxuryTheme.cardDecoration(
                      isDark: isDark,
                      borderRadius: AppRadius.radiusPill,
                      isElevated: true,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (query) => notifier.setSearchQuery(query),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search micro-lots, origin, sensory notes...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),

                // Category Selector Chips
                categoriesAsync.when(
                  data: (categories) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = productsState.selectedCategoryId == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: AppChip(
                              label: cat.name,
                              isSelected: isSelected,
                              isSmall: true,
                              onSelected: (_) => notifier.selectCategory(cat.id),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 38),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 4),

                // Product Grid Content
                Expanded(
                  child: productsState.isLoading
                      ? const Center(
                          child: LambacRoasteryLoader(
                            message: 'Curating Roastery Selections...',
                          ),
                        )
                      : productsState.failure != null
                          ? AppErrorView(
                              failure: productsState.failure,
                              onRetry: () => notifier.loadProducts(),
                            )
                          : productsState.filteredProducts.isEmpty
                              ? AppEmptyProductsState(
                                  onRefresh: () => notifier.loadProducts(isRefresh: true),
                                )
                              : RefreshIndicator(
                                  onRefresh: () async => notifier.loadProducts(isRefresh: true),
                                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                  child: CustomScrollView(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      SliverLayoutBuilder(
                                        builder: (context, sliverConstraints) {
                                          final availableWidth = sliverConstraints.crossAxisExtent;
                                          final isCompact = availableWidth < 350;
                                          final horizontalPadding = isCompact ? 12.0 : 16.0;
                                          final spacing = isCompact ? 10.0 : 14.0;
                                          final columns = ResponsiveLayout.getProductGridColumnsForWidth(availableWidth);
                                          final mainAxisExtent = isCompact ? 332.0 : 348.0;

                                          return SliverPadding(
                                            padding: EdgeInsets.fromLTRB(
                                              horizontalPadding,
                                              8,
                                              horizontalPadding,
                                              16,
                                            ),
                                            sliver: SliverGrid(
                                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: columns,
                                                mainAxisExtent: mainAxisExtent,
                                                crossAxisSpacing: spacing,
                                                mainAxisSpacing: spacing,
                                              ),
                                              delegate: SliverChildBuilderDelegate(
                                                (context, index) {
                                                  final product = productsState.filteredProducts[index];
                                                  final isFav = favorites.contains(product.id);

                                                  return AppProductCard(
                                                    id: product.id,
                                                    name: product.name,
                                                    origin: product.origin,
                                                    tastingNotes: product.tastingNotes,
                                                    price: product.basePrice,
                                                    roastLevel: product.roastLevel,
                                                    imageUrl: product.imageUrl,
                                                    isAvailable: product.isOrderable,
                                                    isFavorite: isFav,
                                                    onTap: () => context.push(AppRoutes.productDetailPath(product.id)),
                                                    onFavoriteToggle: (_) => ref.read(favoritesProvider.notifier).toggleFavorite(product.id),
                                                    onAddToCart: () => _handleAddToCart(product),
                                                  );
                                                },
                                                childCount: productsState.filteredProducts.length,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      SliverToBoxAdapter(
                                        child: PagedLoadMoreFooter(
                                          isLoadingMore: productsState.isLoadingMore,
                                          hasMore: productsState.hasMore,
                                          errorMessage: productsState.loadMoreError,
                                          onRetry: () => notifier.loadMoreProducts(),
                                        ),
                                      ),
                                      const SliverToBoxAdapter(
                                        child: SizedBox(height: 24),
                                      ),
                                    ],
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
}
