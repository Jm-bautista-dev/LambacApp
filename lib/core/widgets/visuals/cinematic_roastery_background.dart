import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'lambac_3d_coffee_bean.dart';

/// Background visual mood preset
enum RoasteryAtmosphereMode {
  heroCinematic,    // Full luxury lighting + ambient glow + subtle floating particles
  warmDiscovery,    // Subtle warm roastery aura + delicate particles
  subtleOperations, // High-contrast clean workspace with subtle warm ambient depth
  subtleClean,      // Ultra-minimal warm ambient gradient (for Analytics / Forms)
  minimal,          // Flat luxury background with subtle corner radiance
}

/// Production-ready Cinematic Roastery Background Atmosphere
/// Provides Apple-like depth, warm radial roastery lighting, floating coffee dust embers,
/// and optional ambient miniature floating beans while strictly remaining non-intrusive.
class CinematicRoasteryBackground extends StatefulWidget {
  final Widget child;
  final RoasteryAtmosphereMode mode;
  final bool showFloatingBean;
  final bool showAmbientParticles;
  final double beanOpacity;
  final Alignment beanAlignment;
  final double beanSize;

  const CinematicRoasteryBackground({
    super.key,
    required this.child,
    this.mode = RoasteryAtmosphereMode.warmDiscovery,
    this.showFloatingBean = false,
    this.showAmbientParticles = true,
    this.beanOpacity = 0.12,
    this.beanAlignment = const Alignment(0.85, -0.65),
    this.beanSize = 160,
  });

  const CinematicRoasteryBackground.hero({
    super.key,
    required this.child,
    this.showFloatingBean = true,
    this.showAmbientParticles = true,
    this.beanOpacity = 0.22,
    this.beanAlignment = const Alignment(0.75, -0.55),
    this.beanSize = 190,
  }) : mode = RoasteryAtmosphereMode.heroCinematic;

  const CinematicRoasteryBackground.subtle({
    super.key,
    required this.child,
    this.showFloatingBean = false,
    this.showAmbientParticles = true,
    this.beanOpacity = 0.08,
    this.beanAlignment = const Alignment(0.9, -0.7),
    this.beanSize = 140,
  }) : mode = RoasteryAtmosphereMode.subtleClean;

  @override
  State<CinematicRoasteryBackground> createState() => _CinematicRoasteryBackgroundState();
}

class _CinematicRoasteryBackgroundState extends State<CinematicRoasteryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleController;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    if (!_isTestEnvironment) {
      _particleController.repeat();
    } else {
      _particleController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    final baseCanvas = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ---------------------------------------------------------------------
        // Layer 1: Base Canvas & Warm Ambient Radial Roastery Light
        // ---------------------------------------------------------------------
        Positioned.fill(
          child: Container(
            color: baseCanvas,
            child: CustomPaint(
              painter: _AmbientGlowPainter(
                isDark: isDark,
                mode: widget.mode,
              ),
            ),
          ),
        ),

        // ---------------------------------------------------------------------
        // Layer 2: Subtle Drifting Micro-Particles (Non-blocking)
        // ---------------------------------------------------------------------
        if (widget.showAmbientParticles && !isReducedMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _AtmosphericParticlesPainter(
                      progress: _particleController.value,
                      isDark: isDark,
                      particleCount: widget.mode == RoasteryAtmosphereMode.heroCinematic ? 18 : 10,
                    ),
                  );
                },
              ),
            ),
          ),

        // ---------------------------------------------------------------------
        // Layer 3: Floating 3D Ambient Watermark Bean (Behind Content)
        // ---------------------------------------------------------------------
        if (widget.showFloatingBean)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: widget.beanAlignment,
                child: Lambac3DCoffeeBean(
                  size: widget.beanSize,
                  roastStyle: isDark ? BeanRoastStyle.mediumRoast : BeanRoastStyle.honeyGold,
                  intensity: BeanIntensity.subtle,
                  showGlow: false,
                  opacity: widget.beanOpacity,
                  enableFloating: true,
                  enableRotation: true,
                  speedMultiplier: 0.6,
                ),
              ),
            ),
          ),

        // ---------------------------------------------------------------------
        // Layer 4: Interactive Foreground Content Hierarchy
        // ---------------------------------------------------------------------
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}

/// Paints delicate ambient gradients resembling warm roastery light & steam reflections
class _AmbientGlowPainter extends CustomPainter {
  final bool isDark;
  final RoasteryAtmosphereMode mode;

  _AmbientGlowPainter({
    required this.isDark,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top-Right Crema Highlight
    final topGlowCenter = Offset(w * 0.85, h * 0.12);
    final topGlowRadius = w * 0.75;
    final topGlowColor = isDark
        ? AppColors.brandAmberDark.withValues(alpha: mode == RoasteryAtmosphereMode.heroCinematic ? 0.16 : 0.08)
        : AppColors.cremaGold.withValues(alpha: mode == RoasteryAtmosphereMode.heroCinematic ? 0.20 : 0.10);

    final topPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          topGlowColor,
          topGlowColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: topGlowCenter, radius: topGlowRadius));

    canvas.drawCircle(topGlowCenter, topGlowRadius, topPaint);

    // Bottom-Left Warm Grounding Haze
    if (mode == RoasteryAtmosphereMode.heroCinematic || mode == RoasteryAtmosphereMode.warmDiscovery) {
      final bottomGlowCenter = Offset(w * 0.10, h * 0.88);
      final bottomGlowRadius = w * 0.65;
      final bottomGlowColor = isDark
          ? const Color(0xFF2E1C12).withValues(alpha: 0.22)
          : const Color(0xFFEFE8DC).withValues(alpha: 0.40);

      final bottomPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            bottomGlowColor,
            bottomGlowColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: bottomGlowCenter, radius: bottomGlowRadius));

      canvas.drawCircle(bottomGlowCenter, bottomGlowRadius, bottomPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.mode != mode;
  }
}

/// Paints subtle, slow-drifting micro-particles (warm amber coffee dust)
class _AtmosphericParticlesPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final int particleCount;

  _AtmosphericParticlesPainter({
    required this.progress,
    required this.isDark,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42); // Deterministic seed for stable particle positions

    for (int i = 0; i < particleCount; i++) {
      final baseX = rand.nextDouble();
      final baseY = rand.nextDouble();
      final particleSize = 1.0 + rand.nextDouble() * 2.4;
      final driftSpeed = 0.5 + rand.nextDouble() * 0.8;
      final horizontalWobble = math.sin((progress * 2 * math.pi) + (i * 1.5)) * 14.0;

      // Vertical drift calculation
      final currentY = ((baseY - (progress * driftSpeed)) % 1.0) * size.height;
      final currentX = (baseX * size.width) + horizontalWobble;

      final baseColor = isDark ? AppColors.cremaGoldLight : AppColors.brandAmber;
      final particleOpacity = (0.08 + (rand.nextDouble() * 0.16)) *
          math.sin((currentY / size.height) * math.pi); // Fade in & out near borders

      final particlePaint = Paint()
        ..color = baseColor.withValues(alpha: particleOpacity.clamp(0.0, 0.28))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particleSize * 0.6);

      canvas.drawCircle(Offset(currentX, currentY), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmosphericParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
