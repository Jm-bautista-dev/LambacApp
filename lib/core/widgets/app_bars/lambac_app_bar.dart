import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../buttons/app_icon_button.dart';

/// Minimalist Roastery Top App Bar
class LambacAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String? fallbackRoute;
  final String backTooltip;
  final bool isCenterTitle;
  final Color? backgroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const LambacAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBack,
    this.fallbackRoute,
    this.backTooltip = 'Back',
    this.isCenterTitle = false,
    this.backgroundColor,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool canPop = false;
    try {
      canPop = context.canPop();
    } catch (_) {
      canPop = Navigator.canPop(context);
    }

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton && (canPop || onBack != null || fallbackRoute != null)) {
      leadingWidget = Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Center(
          child: AppIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 18,
            size: 40,
            tooltip: backTooltip,
            hasBorder: true,
            onPressed: () {
              if (onBack != null) {
                onBack!();
              } else if (canPop) {
                context.pop();
              } else if (fallbackRoute != null && fallbackRoute!.isNotEmpty) {
                context.go(fallbackRoute!);
              }
            },
          ),
        ),
      );
    }

    Widget? headerTitle = titleWidget;
    if (headerTitle == null && title != null) {
      headerTitle = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isCenterTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      );
    }

    return AppBar(
      title: headerTitle,
      centerTitle: isCenterTitle,
      leading: leadingWidget,
      leadingWidth: leadingWidget != null ? 52 : null,
      actions: actions != null
          ? [
              ...actions!,
              AppSpacing.hSpaceSm,
            ]
          : null,
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.darkCanvas : AppColors.lightCanvas),
      elevation: elevation,
      scrolledUnderElevation: 0,
      bottom: bottom,
    );
  }
}
