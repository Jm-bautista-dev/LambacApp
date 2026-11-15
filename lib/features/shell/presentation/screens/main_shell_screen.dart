import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../../core/widgets/navigation/lambac_bottom_nav_bar.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../onboarding/presentation/spotlight/customer_spotlight_overlay.dart';
import '../../../onboarding/presentation/spotlight/customer_spotlight_provider.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';

/// Main Application Shell Screen supporting GoRouter Stateful Shell Navigation
/// Adapts between Bottom Navigation Bar (Mobile < 600px), Compact Navigation Rail
/// (Tablet 600-1023px), and Extended Luxury Roastery Sidebar (Desktop >= 1024px).
class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onSelectTab(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemCount = ref.watch(cartNotifierProvider.select((state) => state.itemCount));
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < ResponsiveLayout.tabletBreakpoint;
    final isDesktop = screenWidth >= ResponsiveLayout.desktopBreakpoint;

    // Listen to spotlight step changes to switch branch when a step specifically targets another tab
    ref.listen(customerSpotlightProvider, (prev, next) {
      if (next.isActive && next.currentStep != null) {
        final targetBranch = next.currentStep!.targetBranchIndex;
        if (targetBranch != null && targetBranch != navigationShell.currentIndex) {
          navigationShell.goBranch(targetBranch);
        }
      }
    });

    final navItems = [
      LambacNavItem(
        key: SpotlightKeys.navHome,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      LambacNavItem(
        key: SpotlightKeys.navRoastery,
        icon: Icons.coffee_outlined,
        activeIcon: Icons.coffee_rounded,
        label: 'Roastery',
      ),
      LambacNavItem(
        key: SpotlightKeys.navCart,
        icon: Icons.shopping_bag_outlined,
        activeIcon: Icons.shopping_bag_rounded,
        label: 'Cart',
        badgeCount: cartItemCount > 0 ? cartItemCount : null,
      ),
      LambacNavItem(
        key: SpotlightKeys.navOrders,
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Orders',
      ),
      LambacNavItem(
        key: SpotlightKeys.navProfile,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    if (isMobile) {
      return ExitConfirmationScope(
        child: CustomerSpotlightOverlay(
          child: Scaffold(
            body: navigationShell,
            bottomNavigationBar: LambacBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _onSelectTab,
              items: navItems,
            ),
          ),
        ),
      );
    }

    return ExitConfirmationScope(
      child: CustomerSpotlightOverlay(
        child: Scaffold(
          body: Row(
            children: [
              _LambacAdaptiveSideNav(
                currentIndex: navigationShell.currentIndex,
                onTap: _onSelectTab,
                items: navItems,
                isExtended: isDesktop,
              ),
              Expanded(
                child: navigationShell,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Luxury Adaptive Side Navigation for Tablet (compact rail) & Desktop (extended sidebar)
class _LambacAdaptiveSideNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LambacNavItem> items;
  final bool isExtended;

  const _LambacAdaptiveSideNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.isExtended,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.brandAmberLight : AppColors.brandAmber;
    final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      width: isExtended ? 236 : 84,
      decoration: BoxDecoration(
        color: isDark ? CustomerLuxuryTheme.darkElevatedSurface : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: isExtended ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [
            // Brand Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                isExtended ? 20 : 12,
                20,
                isExtended ? 20 : 12,
                16,
              ),
              child: isExtended
                  ? Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: activeColor.withOpacity(0.15),
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(
                              color: activeColor.withOpacity(0.35),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.local_cafe_rounded,
                            size: 20,
                            color: activeColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LAMBAC',
                                style: GoogleFonts.newsreader(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Coffee Roastery',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: activeColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.15),
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: activeColor.withOpacity(0.35),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.local_cafe_rounded,
                        size: 20,
                        color: activeColor,
                      ),
                    ),
            ),
            Divider(
              height: 1,
              color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
            ),
            const SizedBox(height: 12),
            // Navigation Items (scrollable in short landscape viewports)
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: isExtended ? 12 : 8,
                  vertical: 4,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;

                  return GestureDetector(
                    key: item.key,
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!isSelected) {
                        HapticFeedback.selectionClick();
                        onTap(index);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: isExtended ? 14 : 8,
                        vertical: isExtended ? 12 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withOpacity(isDark ? 0.18 : 0.12)
                            : Colors.transparent,
                        borderRadius: AppRadius.radiusMd,
                        border: isSelected
                            ? Border.all(
                                color: activeColor.withOpacity(0.35),
                                width: 0.9,
                              )
                            : null,
                      ),
                      child: isExtended
                          ? Row(
                              children: [
                                Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  size: 21,
                                  color: isSelected ? activeColor : inactiveColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                          : inactiveColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (item.badgeCount != null && item.badgeCount! > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: activeColor,
                                      borderRadius: AppRadius.radiusPill,
                                    ),
                                    child: Text(
                                      item.badgeCount! > 99 ? '99+' : item.badgeCount.toString(),
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkCanvas : Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      isSelected ? item.activeIcon : item.icon,
                                      size: 22,
                                      color: isSelected ? activeColor : inactiveColor,
                                    ),
                                    if (item.badgeCount != null && item.badgeCount! > 0)
                                      Positioned(
                                        top: -4,
                                        right: -8,
                                        child: Container(
                                          padding: const EdgeInsets.all(3.5),
                                          decoration: BoxDecoration(
                                            color: activeColor,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 15,
                                            minHeight: 15,
                                          ),
                                          child: Text(
                                            item.badgeCount! > 99 ? '99+' : item.badgeCount.toString(),
                                            style: TextStyle(
                                              color: isDark ? AppColors.darkCanvas : Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              height: 1,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? activeColor : inactiveColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

