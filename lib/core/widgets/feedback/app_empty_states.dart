import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../buttons/app_button.dart';
import '../visuals/lambac_3d_coffee_bean.dart';

/// Reusable Empty Cart State
class AppEmptyCartState extends StatelessWidget {
  final VoidCallback? onBrowseMenu;

  const AppEmptyCartState({
    super.key,
    this.onBrowseMenu,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseEmptyState(
      icon: Icons.shopping_bag_outlined,
      title: 'Your Cart is Waiting',
      description: 'Discover something worth brewing.',
      actionText: 'Explore Menu',
      onAction: onBrowseMenu,
      use3DBean: true,
    );
  }
}

/// Reusable No Orders State
class AppEmptyOrdersState extends StatelessWidget {
  final VoidCallback? onOrderNow;

  const AppEmptyOrdersState({
    super.key,
    this.onOrderNow,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseEmptyState(
      icon: Icons.coffee_maker_outlined,
      title: 'Your next coffee is waiting.',
      description: 'You have not placed any pickup orders yet. Discover our artisanal single-origin lots and fresh counter brews.',
      actionText: 'Browse Roastery',
      onAction: onOrderNow,
    );
  }
}

/// Reusable No Products State
class AppEmptyProductsState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const AppEmptyProductsState({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseEmptyState(
      icon: Icons.coffee_rounded,
      title: 'Nothing is available right now.',
      description: 'Our master roasters are curating the next single-origin harvest batches. Check back shortly for newly roasted arrivals.',
      actionText: onRefresh != null ? 'Refresh Roastery' : null,
      onAction: onRefresh,
    );
  }
}

/// Reusable No Messages State
class AppEmptyChatState extends StatelessWidget {
  final VoidCallback? onStartChat;

  const AppEmptyChatState({
    super.key,
    this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Direct Concierge Chat',
      description: 'Have questions regarding roast dates, grind sizes, or brewing methods? Message our master barista.',
      actionText: 'Start Consultation',
      onAction: onStartChat,
    );
  }
}

/// Reusable No Search Results State
class AppEmptySearchState extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;

  const AppEmptySearchState({
    super.key,
    required this.query,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No Matches Found',
      description: 'We could not find any roast or product matching "$query". Try searching by origin (e.g. Benguet, Apo) or roast type.',
      actionText: 'Clear Search',
      onAction: onClearSearch,
    );
  }
}

/// Internal Base Container for Standardized Empty States
class _BaseEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;
  final bool use3DBean;

  const _BaseEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.use3DBean = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (use3DBean)
              Lambac3DCoffeeBean(
                size: 80,
                intensity: BeanIntensity.medium,
                roastStyle: BeanRoastStyle.mediumRoast,
              )
            else
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 34,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                ),
              ),
            AppSpacing.vSpaceXl,
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vSpaceSm,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              AppSpacing.vSpaceXxl,
              AppButton.primary(
                text: actionText!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
