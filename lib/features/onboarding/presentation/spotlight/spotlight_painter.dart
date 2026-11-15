import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/spotlight_step_model.dart';

/// CustomPainter that renders a frosted dark dimming scrim with a smooth spotlight
/// cutout and an animated glowing golden roastery aura around the target element.
class SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;
  final SpotlightShape shape;
  final Color scrimColor;
  final Color glowColor;
  final double pulseValue;
  final bool isDark;

  SpotlightPainter({
    required this.targetRect,
    this.borderRadius = 16.0,
    this.shape = SpotlightShape.roundedRect,
    required this.scrimColor,
    required this.glowColor,
    this.pulseValue = 0.0,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Calculate Cutout Path
    final Path cutoutPath = Path();
    if (shape == SpotlightShape.circle) {
      final double radius = max(targetRect.width, targetRect.height) / 2.0;
      cutoutPath.addOval(Rect.fromCircle(center: targetRect.center, radius: radius));
    } else {
      final rrect = RRect.fromRectAndRadius(
        targetRect,
        Radius.circular(borderRadius),
      );
      cutoutPath.addRRect(rrect);
    }

    // 2. Full Screen Path
    final Path fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 3. Difference Path (Full Screen minus Cutout)
    final Path scrimPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      cutoutPath,
    );

    // 4. Paint Scrim
    final Paint scrimPaint = Paint()
      ..color = scrimColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(scrimPath, scrimPaint);

    // 5. Paint Outer Glowing Aura (Pulsing breath effect)
    final double glowSpread = 8.0 + (6.0 * pulseValue);
    final double glowAlpha = 0.28 + (0.16 * pulseValue);

    final Paint glowPaint = Paint()
      ..color = glowColor.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + (2.0 * pulseValue)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSpread);

    if (shape == SpotlightShape.circle) {
      final double radius = max(targetRect.width, targetRect.height) / 2.0;
      canvas.drawCircle(targetRect.center, radius + 1.0, glowPaint);
    } else {
      final rrect = RRect.fromRectAndRadius(
        targetRect,
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(rrect, glowPaint);
    }

    // 6. Paint Sharp Golden Accent Stroke
    final Paint strokePaint = Paint()
      ..color = glowColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    if (shape == SpotlightShape.circle) {
      final double radius = max(targetRect.width, targetRect.height) / 2.0;
      canvas.drawCircle(targetRect.center, radius, strokePaint);
    } else {
      final rrect = RRect.fromRectAndRadius(
        targetRect,
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(rrect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.shape != shape ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isDark != isDark;
  }
}
