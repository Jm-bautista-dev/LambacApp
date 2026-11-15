import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';

/// Bottom Navigation Item Model
class LambacNavItem {
  final Key? key;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const LambacNavItem({
    this.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// Frosted Glassmorphic Bottom Navigation Bar
class LambacBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LambacNavItem> items;
  final Color? accentColor;
  final Color? accentColorLight;

  const LambacBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.accentColor,
    this.accentColorLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final barBgColor = isDark
        ? AppColors.darkSurface.withOpacity(0.88)
        : Colors.white.withOpacity(0.92);

    final borderColor = isDark
        ? AppColors.darkBorder.withOpacity(0.8)
        : AppColors.lightBorder.withOpacity(0.8);

    final primaryAccent = accentColor ?? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber);
    final primaryAccentLight = accentColorLight ?? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber);
    final activeColor = isDark ? primaryAccentLight : primaryAccent;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: barBgColor,
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: 0.8,
              ),
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          padding: EdgeInsets.only(
            top: 6,
            bottom: bottomInset > 0 ? bottomInset : 8,
            left: MediaQuery.sizeOf(context).width < 360 ? 4 : 10,
            right: MediaQuery.sizeOf(context).width < 360 ? 4 : 10,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 340;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  final inactiveColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

                  return Expanded(
                    child: GestureDetector(
                      key: item.key,
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!isSelected) {
                          HapticFeedback.selectionClick();
                          onTap(index);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedContainer(
                                  duration: AppAnimations.fast,
                                  curve: AppAnimations.easeInOutCubic,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 10 : 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? activeColor.withOpacity(isDark ? 0.18 : 0.12)
                                        : Colors.transparent,
                                    borderRadius: AppRadius.radiusPill,
                                  ),
                                  child: AnimatedScale(
                                    duration: AppAnimations.fast,
                                    scale: isSelected ? 1.05 : 1.0,
                                    curve: AppAnimations.spring,
                                    child: Icon(
                                      isSelected ? item.activeIcon : item.icon,
                                      size: isCompact ? 20 : 22,
                                      color: isSelected ? activeColor : inactiveColor,
                                    ),
                                  ),
                                ),
                                if (item.badgeCount != null && item.badgeCount! > 0)
                                  Positioned(
                                    top: -2,
                                    right: isCompact ? 2 : 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
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
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: AppAnimations.fast,
                              curve: AppAnimations.easeInOutCubic,
                              style: TextStyle(
                                fontSize: isCompact ? 9.5 : 10,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? activeColor : inactiveColor,
                                letterSpacing: 0.1,
                              ),
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
