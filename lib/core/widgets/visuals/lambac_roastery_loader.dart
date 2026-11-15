import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'lambac_3d_coffee_bean.dart';

/// Production Branded Roastery Loading Experience
class LambacRoasteryLoader extends StatelessWidget {
  final String? message;
  final double size;
  final bool isFullScreen;

  const LambacRoasteryLoader({
    super.key,
    this.message = 'Brewing with intention...',
    this.size = 54,
    this.isFullScreen = false,
  });

  const LambacRoasteryLoader.fullScreen({
    super.key,
    this.message = 'Preparing Lambac Roastery Experience...',
    this.size = 72,
  }) : isFullScreen = true;

  const LambacRoasteryLoader.compact({
    super.key,
    this.message = 'Loading...',
    this.size = 36,
  }) : isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulsing Crema Ring
              SizedBox(
                width: size * 1.35,
                height: size * 1.35,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.brandAmberLight.withValues(alpha: 0.5) : AppColors.brandAmber.withValues(alpha: 0.5),
                  ),
                ),
              ),
              // Rotating 3D Bean Anchor
              Lambac3DCoffeeBean(
                size: size,
                roastStyle: BeanRoastStyle.mediumRoast,
                intensity: BeanIntensity.medium,
                enableFloating: true,
                enableRotation: true,
                showGlow: true,
                speedMultiplier: 1.4,
              ),
            ],
          ),
          if (message != null) ...[
            AppSpacing.vSpaceLg,
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        body: SafeArea(child: content),
      );
    }

    return content;
  }
}
