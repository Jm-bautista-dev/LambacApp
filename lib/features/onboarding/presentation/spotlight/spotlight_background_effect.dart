import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/models/spotlight_step_model.dart';

/// Painter that fills the screen with a translucent scrim tint while carving
/// out an exact transparent hole for the spotlight target using PathFillType.evenOdd.
/// This guarantees 0% tint over the target, leaving its original colors and contrast intact.
class SpotlightHoleScrimPainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;
  final SpotlightShape shape;
  final Color scrimColor;

  const SpotlightHoleScrimPainter({
    required this.targetRect,
    required this.borderRadius,
    this.shape = SpotlightShape.roundedRect,
    required this.scrimColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Path path = Path()..fillType = PathFillType.evenOdd;
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (!targetRect.isEmpty && targetRect != Rect.zero) {
      if (shape == SpotlightShape.circle) {
        final double radius = max(targetRect.width, targetRect.height) / 2.0;
        path.addOval(Rect.fromCircle(center: targetRect.center, radius: radius));
      } else {
        path.addRRect(
          RRect.fromRectAndRadius(
            targetRect,
            Radius.circular(borderRadius),
          ),
        );
      }
    }

    final Paint paint = Paint()
      ..color = scrimColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SpotlightHoleScrimPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.shape != shape ||
        oldDelegate.scrimColor != scrimColor;
  }
}

/// High-performance, architectural spotlight background effect that guarantees
/// 100% SHARP, UNTOUCHED original content inside the spotlight target.
///
/// Architecture:
/// 1. The target region [targetRect] is a physical opening where NO BackdropFilter
///    and NO scrim pixels are rendered.
/// 2. Four peripheral bounding strips (Top, Bottom, Left, Right) sit strictly outside
///    [targetRect] and apply a frosted glass blur to the surrounding application UI.
/// 3. An even-odd Path scrim covers the full screen while subtracting the exact target shape,
///    ensuring clean dimming across the surroundings without dimming the target.
class SpotlightBackgroundEffect extends StatelessWidget {
  final Rect? targetRect;
  final double borderRadius;
  final SpotlightShape shape;
  final Color scrimColor;
  final double blurSigma;

  const SpotlightBackgroundEffect({
    super.key,
    required this.targetRect,
    required this.borderRadius,
    this.shape = SpotlightShape.roundedRect,
    required this.scrimColor,
    this.blurSigma = 4.5,
  });

  @override
  Widget build(BuildContext context) {
    final rect = targetRect;

    // While measuring or when geometry is unresolved, display only the dim scrim
    // without full-screen blur, avoiding any premature blurring of application widgets.
    if (rect == null || rect.isEmpty || rect == Rect.zero) {
      return Container(color: scrimColor);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Compute effective outer bounding box for the target shape
        final double boxLeft;
        final double boxTop;
        final double boxRight;
        final double boxBottom;

        if (shape == SpotlightShape.circle) {
          final double radius = max(rect.width, rect.height) / 2.0;
          final center = rect.center;
          boxLeft = (center.dx - radius).clamp(0.0, screenWidth);
          boxTop = (center.dy - radius).clamp(0.0, screenHeight);
          boxRight = (center.dx + radius).clamp(0.0, screenWidth);
          boxBottom = (center.dy + radius).clamp(0.0, screenHeight);
        } else {
          boxLeft = rect.left.clamp(0.0, screenWidth);
          boxTop = rect.top.clamp(0.0, screenHeight);
          boxRight = rect.right.clamp(0.0, screenWidth);
          boxBottom = rect.bottom.clamp(0.0, screenHeight);
        }

        final topHeight = boxTop;
        final bottomTop = boxBottom;
        final bottomHeight = (screenHeight - bottomTop).clamp(0.0, screenHeight);

        final midTop = topHeight;
        final midHeight = (bottomTop - topHeight).clamp(0.0, screenHeight);

        final leftWidth = boxLeft;
        final rightLeft = boxRight;
        final rightWidth = (screenWidth - rightLeft).clamp(0.0, screenWidth);

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── LAYER 1: Four Peripheral Blur Strips (ONLY outside the spotlight hole) ──
            // Notice: The central rectangle [boxLeft, boxTop, boxRight, boxBottom] contains
            // ZERO BackdropFilter elements. The live widget underneath remains 100% sharp.

            // 1. Top Strip (from y=0 down to boxTop)
            if (topHeight > 0.5)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topHeight,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

            // 2. Bottom Strip (from boxBottom down to screenHeight)
            if (bottomHeight > 0.5)
              Positioned(
                top: bottomTop,
                left: 0,
                right: 0,
                height: bottomHeight,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

            // 3. Left Strip (between boxTop and boxBottom, from x=0 to boxLeft)
            if (leftWidth > 0.5 && midHeight > 0.5)
              Positioned(
                top: midTop,
                left: 0,
                width: leftWidth,
                height: midHeight,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

            // 4. Right Strip (between boxTop and boxBottom, from boxRight to screenWidth)
            if (rightWidth > 0.5 && midHeight > 0.5)
              Positioned(
                top: midTop,
                left: rightLeft,
                width: rightWidth,
                height: midHeight,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

            // ── LAYER 2: Even-Odd Dimming Scrim ──
            // Dark translucent tint across the entire screen EXCLUDING the exact target shape.
            Positioned.fill(
              child: CustomPaint(
                painter: SpotlightHoleScrimPainter(
                  targetRect: rect,
                  borderRadius: borderRadius,
                  shape: shape,
                  scrimColor: scrimColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
