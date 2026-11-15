import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Segmented Header Switcher connecting Overview, Descriptive, Forecasting, Prescriptive & Data Quality
class UnifiedBiTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const UnifiedBiTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tabs = [
      (label: 'Overview & Pipeline', icon: Icons.schema_rounded),
      (label: '1. Descriptive', icon: Icons.bar_chart_rounded),
      (label: '2. Forecasting', icon: Icons.trending_up_rounded),
      (label: '3. Prescriptive', icon: Icons.lightbulb_rounded),
      (label: '4. Data Quality', icon: Icons.verified_user_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(tabs.length, (idx) {
            final isSelected = selectedIndex == idx;
            final item = tabs[idx];

            return GestureDetector(
              onTap: () => onTabSelected(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                      : Colors.transparent,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: isSelected
                          ? (isDark ? AppColors.darkCanvas : Colors.white)
                          : (isDark ? AppColors.brandAmberLight : AppColors.brandAmber),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? AppColors.darkCanvas : Colors.white)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
