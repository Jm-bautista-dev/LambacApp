import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../../core/widgets/navigation/lambac_bottom_nav_bar.dart';
import '../../../onboarding/presentation/spotlight/admin_spotlight_overlay.dart';
import '../../../onboarding/presentation/spotlight/admin_spotlight_provider.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

/// Production Business Administrator Shell Screen supporting Stateful GoRouter Navigation
class AdminShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to spotlight step changes to switch branch when a step specifically targets another tab
    ref.listen(adminSpotlightProvider, (prev, next) {
      if (next.isActive && next.currentStep != null) {
        final targetBranch = next.currentStep!.targetBranchIndex;
        if (targetBranch != null && targetBranch != navigationShell.currentIndex) {
          navigationShell.goBranch(targetBranch);
        }
      }
    });

    // Live, dynamic count of active pickup orders requiring business/staff attention
    final activeOrdersCount = ref.watch(
      ordersNotifierProvider.select(
        (state) => state.orders.where((o) => o.status.isActive).length,
      ),
    );

    final navItems = [
      LambacNavItem(
        key: SpotlightKeys.adminNavDashboard,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
      LambacNavItem(
        key: SpotlightKeys.adminNavOrders,
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Orders',
        badgeCount: activeOrdersCount > 0 ? activeOrdersCount : null,
      ),
      LambacNavItem(
        key: SpotlightKeys.adminNavProducts,
        icon: Icons.coffee_outlined,
        activeIcon: Icons.coffee_rounded,
        label: 'Products',
      ),
      LambacNavItem(
        key: SpotlightKeys.adminNavIntelligence,
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome_rounded,
        label: 'Intelligence',
      ),
      LambacNavItem(
        key: SpotlightKeys.adminNavControl,
        icon: Icons.admin_panel_settings_outlined,
        activeIcon: Icons.admin_panel_settings_rounded,
        label: 'Control',
      ),
    ];

    return ExitConfirmationScope(
      child: AdminSpotlightOverlay(
        child: Scaffold(
          body: navigationShell,
          bottomNavigationBar: LambacBottomNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            items: navItems,
            accentColor: AppColors.brandAmber,
            accentColorLight: AppColors.brandAmberLight,
          ),
        ),
      ),
    );
  }
}
