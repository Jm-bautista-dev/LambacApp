import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/buttons/app_icon_button.dart';
import '../../../../core/widgets/buttons/app_scale_button.dart';
import '../../../../core/widgets/cards/app_product_card.dart';
import '../../../../core/widgets/cards/app_product_list_card.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../../../core/widgets/feedback/app_product_skeleton.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_search_bar.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_3d_coffee_bean.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/guest_auth_prompt_sheet.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../notifications/presentation/widgets/notification_center_sheet.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/providers/categories_provider.dart';
import '../../../products/presentation/providers/favorites_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';

/// Production Customer Home Screen for Lambac Coffee Roastery
/// Elevated with Luxury Editorial Typography, Apple-Inspired Minimalism, and Warm Tactile Aesthetics
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Ohayō • Morning Harvest';
    if (hour < 17) return 'Konnichiwa • Afternoon Roast';
    return 'Konbanwa • Evening Pour';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);

    final categoriesAsync = ref.watch(categoriesProvider);
    final productsState = ref.watch(productsNotifierProvider);
    final favorites = ref.watch(favoritesProvider);
    final notifier = ref.read(productsNotifierProvider.notifier);

    final featuredProducts = productsState.products.where((p) => p.isFeatured).toList();
    final popularProducts = productsState.products.where((p) => !p.isFeatured).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.warmDiscovery,
        showAmbientParticles: true,
        child: SafeArea(
          bottom: false,
          child: ResponsiveContentContainer(
            maxWidth: ResponsiveLayout.maxContentWidth,
            child: RefreshIndicator(
              onRefresh: () => notifier.loadProducts(isRefresh: true),
              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // -----------------------------------------------------------
                  // 1. Editorial Header Bar (Brand & Greetings)
                  // -----------------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      key: SpotlightKeys.homeHeader,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: LayoutBuilder(
                        builder: (context, headerConstraints) {
                          final headerRow = Row(
                            children: [
                              // Luxury Monogram Avatar
                              GestureDetector(
                                onTap: () => context.go(AppRoutes.profile),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark ? CustomerLuxuryTheme.darkElevatedSurface : CustomerLuxuryTheme.lightCreamSurface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
                                      width: 1.2,
                                    ),
                                    boxShadow: isDark ? CustomerLuxuryTheme.luxuryShadowDark : CustomerLuxuryTheme.luxuryShadowLight,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    user?.fullName.isNotEmpty ?? false ? user!.fullName[0].toUpperCase() : 'L',
                                    style: GoogleFonts.newsreader(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? CustomerLuxuryTheme.cremaBronze : CustomerLuxuryTheme.amberGold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Welcoming Editorial Copy
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getTimeBasedGreeting(),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      user?.fullName ?? 'Coffee Enthusiast',
                                      style: GoogleFonts.newsreader(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Theme Switcher & Notification Center
                              AppIconButton(
                                key: SpotlightKeys.homeThemeToggle,
                                icon: currentThemeMode == ThemeMode.dark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 38,
                                iconSize: 18,
                                hasBorder: true,
                                tooltip: 'Switch Theme',
                                onPressed: () {
                                  ref.read(themeModeProvider.notifier).toggleTheme();
                                },
                              ),
                              const SizedBox(width: 8),
                              AppIconButton(
                                key: SpotlightKeys.homeNotifications,
                                icon: unreadNotifs > 0
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                size: 38,
                                iconSize: 19,
                                hasBorder: true,
                                badgeCount: unreadNotifs,
                                tooltip: 'Notifications',
                                onPressed: () {
                                  NotificationCenterSheet.show(context);
                                },
                              ),
                            ],
                          );

                          if (headerConstraints.maxWidth < 320) {
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 320,
                                child: headerRow,
                              ),
                            );
                          }
                          return headerRow;
                        },
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // 2. Search Input Field
                  // -----------------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      key: SpotlightKeys.homeSearch,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: AppSearchBar(
                        controller: _searchController,
                        hint: 'Search single origins, tasting notes, roasts...',
                        onSubmitted: (query) {
                          if (query.trim().isNotEmpty) {
                            notifier.setSearchQuery(query);
                            context.go(AppRoutes.products);
                          }
                        },
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // 3. Hero Visual Banner ("Your Daily Ritual, Elevated")
                  // -----------------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Container(
                        key: SpotlightKeys.homeHeroBanner,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [const Color(0xFF221A15), const Color(0xFF140F0D)]
                                : [const Color(0xFF2B1F18), const Color(0xFF1C130E)],
                          ),
                          borderRadius: AppRadius.radiusXl,
                          border: Border.all(
                            color: isDark
                                ? CustomerLuxuryTheme.borderDark
                                : CustomerLuxuryTheme.amberGold.withOpacity(0.35),
                            width: 1,
                          ),
                          boxShadow: isDark ? AppShadows.cardDark : AppShadows.elevatedLight,
                        ),
                        child: Stack(
                          children: [
                            // Ambient Floating 3D Roastery Bean
                            Positioned(
                              right: -16,
                              top: 6,
                              child: IgnorePointer(
                                child: Lambac3DCoffeeBean(
                                  size: 145,
                                  roastStyle: BeanRoastStyle.honeyGold,
                                  intensity: BeanIntensity.medium,
                                  enableFloating: true,
                                  enableRotation: true,
                                  showGlow: true,
                                  opacity: 0.45,
                                  speedMultiplier: 0.8,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: CustomerLuxuryTheme.amberGold,
                                          borderRadius: AppRadius.radiusPill,
                                        ),
                                        child: Text(
                                          'FEATURED HARVEST',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 4,
                                          children: [
                                            const Icon(Icons.verified_rounded, color: AppColors.cremaGold, size: 15),
                                            Text(
                                              'Direct Trade',
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFFD8A47F),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.vSpaceMd,
                                  Text(
                                    'Your Daily Ritual,\nElevated.',
                                    style: GoogleFonts.newsreader(
                                      color: Colors.white,
                                      fontSize: 27,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                      height: 1.14,
                                    ),
                                  ),
                                  AppSpacing.vSpaceXs,
                                  Text(
                                    'Mount Apo Anaerobic Honey Reserve • Wild raspberry, dark honey, cacao nibs & silky finish.',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFD4C8BE),
                                      fontSize: 12,
                                      height: 1.45,
                                    ),
                                  ),
                                  AppSpacing.vSpaceLg,
                                  LayoutBuilder(
                                    builder: (context, c) {
                                      if (c.maxWidth < 310) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Price (250g)',
                                                  style: GoogleFonts.inter(color: const Color(0xFFA59B90), fontSize: 11),
                                                ),
                                                Text(
                                                  CurrencyFormatter.format(480.00),
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            AppButton.primary(
                                              text: 'Explore Harvest',
                                              size: AppButtonSize.small,
                                              isFullWidth: true,
                                              onPressed: () => context.push(AppRoutes.productDetailPath('mt-apo-honey')),
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Price (250g)',
                                                  style: GoogleFonts.inter(color: const Color(0xFFA59B90), fontSize: 11),
                                                ),
                                                Text(
                                                  CurrencyFormatter.format(480.00),
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          AppButton.primary(
                                            text: 'Explore Harvest',
                                            size: AppButtonSize.small,
                                            isFullWidth: false,
                                            width: 136,
                                            onPressed: () => context.push(AppRoutes.productDetailPath('mt-apo-honey')),
                                          ),
                                        ],
                                      );
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

                  // -----------------------------------------------------------
                  // 4. Quick Action Shortcuts (Pickup, Chat, Track)
                  // -----------------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          _buildQuickAction(
                            key: SpotlightKeys.homeQuickPickup,
                            icon: Icons.takeout_dining_rounded,
                            label: 'Pickup Order',
                            onTap: () => context.go(AppRoutes.products),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 10),
                          _buildQuickAction(
                            key: SpotlightKeys.homeQuickChat,
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Barista Chat',
                            onTap: () {
                              final currentUser = ref.read(currentUserProvider);
                              if (currentUser == null || currentUser.isGuest) {
                                showGuestAuthPrompt(
                                  context: context,
                                  ref: ref,
                                  title: 'Sign In to Chat with Barista',
                                  message: 'Connect directly with our master baristas for personalized bean recommendations and brewing advice.',
                                  redirectPath: AppRoutes.chat,
                                );
                                return;
                              }
                              context.push(AppRoutes.chat);
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(width: 10),
                          _buildQuickAction(
                            key: SpotlightKeys.homeQuickTrack,
                            icon: Icons.receipt_long_outlined,
                            label: 'Track Orders',
                            onTap: () {
                              final currentUser = ref.read(currentUserProvider);
                              if (currentUser == null || currentUser.isGuest) {
                                showGuestAuthPrompt(
                                  context: context,
                                  ref: ref,
                                  title: 'Sign In to Track Orders',
                                  message: 'Sign in to monitor live roastery orders and order history.',
                                  redirectPath: AppRoutes.orders,
                                );
                                return;
                              }
                              context.go(AppRoutes.orders);
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // 5. Dynamic Category Filter Chips
                  // -----------------------------------------------------------
                  SliverToBoxAdapter(
                    child: categoriesAsync.when(
                      data: (categories) {
                        return SingleChildScrollView(
                          key: SpotlightKeys.homeCategories,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: categories.map((cat) {
                              final isSelected = productsState.selectedCategoryId == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: AppChip(
                                  label: cat.name,
                                  isSelected: isSelected,
                                  onSelected: (_) {
                                    notifier.selectCategory(cat.id);
                                    context.go(AppRoutes.products);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const SizedBox(height: 52),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // 6. Featured Roasts (Horizontal Carousel)
                  // -----------------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Featured Harvests',
                              style: GoogleFonts.newsreader(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: GestureDetector(
                              onTap: () => context.go(AppRoutes.products),
                              child: Text(
                                'See All',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      key: SpotlightKeys.homeFeaturedList,
                      child: productsState.isLoading
                          ? SizedBox(
                              height: 345,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 2,
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemBuilder: (_, __) => const AppProductCardSkeleton(),
                              ),
                            )
                          : SizedBox(
                              height: 345,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: featuredProducts.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final p = featuredProducts[index];
                                  final isFav = favorites.contains(p.id);

                                  return AppProductCard(
                                    id: p.id,
                                    name: p.name,
                                    origin: p.origin,
                                    tastingNotes: p.tastingNotes,
                                    price: p.basePrice,
                                    roastLevel: p.roastLevel,
                                    imageUrl: p.imageUrl,
                                    isAvailable: p.isOrderable,
                                    isFavorite: isFav,
                                    onTap: () => context.push(AppRoutes.productDetailPath(p.id)),
                                    onFavoriteToggle: (_) => ref.read(favoritesProvider.notifier).toggleFavorite(p.id),
                                    onAddToCart: () => _handleAddToCart(p),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),

                  // -----------------------------------------------------------
                  // 7. Popular & Staff Picks (List Showcase)
                  // -----------------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Popular & Staff Picks',
                              style: GoogleFonts.newsreader(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: GestureDetector(
                              onTap: () => context.go(AppRoutes.products),
                              child: Text(
                                'Menu Catalog',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverLayoutBuilder(
                    builder: (context, sliverConstraints) {
                      final useTwoColumns = sliverConstraints.crossAxisExtent >= 680;
                      if (useTwoColumns) {
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 142,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final p = popularProducts[index];
                                final isFav = favorites.contains(p.id);

                                return AppProductListCard(
                                  id: p.id,
                                  name: p.name,
                                  origin: p.origin,
                                  tastingNotes: p.tastingNotes,
                                  price: p.basePrice,
                                  roastLevel: p.roastLevel,
                                  imageUrl: p.imageUrl,
                                  isAvailable: p.isOrderable,
                                  isFavorite: isFav,
                                  onTap: () => context.push(AppRoutes.productDetailPath(p.id)),
                                  onFavoriteToggle: (_) => ref.read(favoritesProvider.notifier).toggleFavorite(p.id),
                                  onAddToCart: () => _handleAddToCart(p),
                                );
                              },
                              childCount: popularProducts.length,
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final p = popularProducts[index];
                              final isFav = favorites.contains(p.id);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppProductListCard(
                                  id: p.id,
                                  name: p.name,
                                  origin: p.origin,
                                  tastingNotes: p.tastingNotes,
                                  price: p.basePrice,
                                  roastLevel: p.roastLevel,
                                  imageUrl: p.imageUrl,
                                  isAvailable: p.isOrderable,
                                  isFavorite: isFav,
                                  onTap: () => context.push(AppRoutes.productDetailPath(p.id)),
                                  onFavoriteToggle: (_) => ref.read(favoritesProvider.notifier).toggleFavorite(p.id),
                                  onAddToCart: () => _handleAddToCart(p),
                                ),
                              );
                            },
                            childCount: popularProducts.length,
                          ),
                        ),
                      );
                    },
                  ),

                  // -----------------------------------------------------------
                  // 8. Roastery Craftsmanship Story Card
                  // -----------------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                                  Icons.local_fire_department_rounded,
                                  color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'The Art of Japanese Micro-Roasting',
                                    style: GoogleFonts.newsreader(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.vSpaceSm,
                            Text(
                              'At Lambac, each micro-batch is carefully roasted to honor the natural terroir of single-origin Philippine and world heritage beans. We roast weekly for peak sweetness, clarity, and balance.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: AppScaleButton(
        key: key,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          decoration: CustomerLuxuryTheme.cardDecoration(
            isDark: isDark,
            borderRadius: AppRadius.radiusMd,
            isElevated: true,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isDark ? CustomerLuxuryTheme.amberGoldLight : CustomerLuxuryTheme.amberGold,
              ),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
