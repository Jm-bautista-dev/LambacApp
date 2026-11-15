import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../buttons/app_button.dart';
import '../visuals/lambac_3d_coffee_bean.dart';

/// Spacious Elegant Empty State View
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customIllustration;
  final bool use3DBean;
  final BeanRoastStyle beanRoastStyle;

  const AppEmptyState({
    super.key,
    this.icon = Icons.coffee_outlined,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.customIllustration,
    this.use3DBean = false,
    this.beanRoastStyle = BeanRoastStyle.mediumRoast,
  });

  const AppEmptyState.roastery({
    super.key,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.customIllustration,
    this.beanRoastStyle = BeanRoastStyle.mediumRoast,
  })  : icon = Icons.coffee_rounded,
        use3DBean = true;

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
            if (customIllustration != null)
              customIllustration!
            else if (use3DBean)
              Lambac3DCoffeeBean(
                size: 84,
                intensity: BeanIntensity.medium,
                roastStyle: beanRoastStyle,
              )
            else
              Container(
                width: 80,
                height: 80,
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
                  size: 36,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                ),
              ),
            AppSpacing.vSpaceXl,
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
                  fontSize: 14,
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
