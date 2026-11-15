import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/spotlight_step_model.dart';

/// Inverted clipper that excludes the target spotlight shape from the canvas.
/// Guarantees that BackdropFilter and dimming scrim ONLY run outside the target,
/// keeping the targeted widget 100% crisp, unblurred, and readable.
class InvertedSpotlightClipper extends CustomClipper<Path> {
  final Rect targetRect;
  final double borderRadius;
  final SpotlightShape shape;

  const InvertedSpotlightClipper({
    required this.targetRect,
    required this.borderRadius,
    this.shape = SpotlightShape.roundedRect,
  });

  @override
  Path getClip(Size size) {
    final Path fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect.isEmpty || targetRect == Rect.zero) {
      return fullScreenPath;
    }

    final Path holePath = Path();
    if (shape == SpotlightShape.circle) {
      final double radius = max(targetRect.width, targetRect.height) / 2.0;
      holePath.addOval(Rect.fromCircle(center: targetRect.center, radius: radius));
    } else {
      holePath.addRRect(
        RRect.fromRectAndRadius(
          targetRect,
          Radius.circular(borderRadius),
        ),
      );
    }

    return Path.combine(PathOperation.difference, fullScreenPath, holePath);
  }

  @override
  bool shouldReclip(covariant InvertedSpotlightClipper oldClipper) {
    return oldClipper.targetRect != targetRect ||
        oldClipper.borderRadius != borderRadius ||
        oldClipper.shape != shape;
  }
}
