import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Minimalist Roastery Chip for Categories, Roasts, and Filter Options
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final Widget? icon;
  final Color? activeColor;
  final bool isSmall;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.icon,
    this.activeColor,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryAccent = activeColor ??
        (isDark ? AppColors.brandAmberLight : AppColors.brandAmber);

    final bgColor = isSelected
        ? primaryAccent
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);

    final fgColor = isSelected
        ? (isDark ? AppColors.darkCanvas : Colors.white)
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final borderColor = isSelected
        ? primaryAccent
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Material(
      color: bgColor,
      borderRadius: AppRadius.radiusPill,
      child: InkWell(
        onTap: onSelected != null
            ? () {
                HapticFeedback.selectionClick();
                onSelected!(!isSelected);
              }
            : null,
        borderRadius: AppRadius.radiusPill,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? AppSpacing.sm : AppSpacing.md,
            vertical: isSmall ? 4 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusPill,
            border: Border.all(color: borderColor, width: 0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: isSmall ? 14 : 16,
                    color: fgColor,
                  ),
                  child: icon!,
                ),
                SizedBox(width: isSmall ? 4 : 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? 12 : 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: fgColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
