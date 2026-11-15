import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'app_skeleton.dart';

/// Skeleton Loader for Vertical Product Cards
class AppProductCardSkeleton extends StatelessWidget {
  final double width;

  const AppProductCardSkeleton({
    super.key,
    this.width = 190.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.9,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSkeleton(
            height: 130,
            width: double.infinity,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton(width: 60, height: 10),
                AppSpacing.vSpaceXs,
                const AppSkeleton(width: 140, height: 14),
                AppSpacing.vSpaceXs,
                const AppSkeleton(width: 100, height: 12),
                AppSpacing.vSpaceMd,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    AppSkeleton(width: 50, height: 16),
                    AppSkeleton.circle(size: 32),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton Loader for Horizontal Product List Cards
class AppProductListCardSkeleton extends StatelessWidget {
  const AppProductListCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.9,
        ),
      ),
      child: Row(
        children: [
          const AppSkeleton(width: 80, height: 80),
          AppSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton(width: 50, height: 10),
                AppSpacing.vSpaceXs,
                const AppSkeleton(width: 150, height: 14),
                AppSpacing.vSpaceXs,
                const AppSkeleton(width: 110, height: 12),
                AppSpacing.vSpaceSm,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    AppSkeleton(width: 60, height: 16),
                    AppSkeleton(width: 55, height: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
