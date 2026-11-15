import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../../core/widgets/navigation/lambac_bottom_nav_bar.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../onboarding/presentation/spotlight/barista_spotlight_overlay.dart';
import '../../../onboarding/presentation/spotlight/barista_spotlight_provider.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

/// Production Staff & Bartender Operations Shell Screen supporting Stateful GoRouter Navigation
class StaffShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const StaffShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to spotlight step changes to switch branch when a step specifically targets another tab
    ref.listen(baristaSpotlightProvider, (prev, next) {
      if (next.isActive && next.currentStep != null) {
        final targetBranch = next.currentStep!.targetBranchIndex;
        if (targetBranch != null && targetBranch != navigationShell.currentIndex) {
          navigationShell.goBranch(targetBranch);
        }
      }
    });

    // Live, dynamic count of active pickup orders requiring staff attention
    final activeOrdersCount = ref.watch(
      ordersNotifierProvider.select(
        (state) => state.orders.where((o) => o.status.isActive).length,
      ),
    );

    // Live unread inbox count
    final metricsAsync = ref.watch(businessMetricsProvider);
    final int unreadInboxCount = metricsAsync.maybeWhen(
      data: (m) => m.unreadInboxCount,
      orElse: () => 0,
    );

    final navItems = [
      LambacNavItem(
        key: SpotlightKeys.staffNavQueue,
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Queue',
        badgeCount: activeOrdersCount > 0 ? activeOrdersCount : null,
      ),
      LambacNavItem(
        key: SpotlightKeys.staffNavConcierge,
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Concierge',
        badgeCount: unreadInboxCount > 0 ? unreadInboxCount : null,
      ),
      LambacNavItem(
        key: SpotlightKeys.staffNavShift,
        icon: Icons.badge_outlined,
        activeIcon: Icons.badge_rounded,
        label: 'My Shift',
      ),
    ];

    return ExitConfirmationScope(
      child: BaristaSpotlightOverlay(
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
            accentColor: AppColors.matchaSage,
            accentColorLight: AppColors.matchaSage,
          ),
        ),
      ),
    );
  }
}
