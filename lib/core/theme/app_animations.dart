import 'package:flutter/material.dart';

/// Centralized Animation Durations & Curves for Micro-Interactions
class AppAnimations {
  AppAnimations._();

  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration pageTransition = Duration(milliseconds: 350);

  // Curves (Apple-inspired fluid easing)
  static const Curve easeInQuart = Cubic(0.5, 0.0, 0.75, 0.0);
  static const Curve easeOutQuart = Cubic(0.25, 1.0, 0.5, 1.0);
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve spring = SpringCurve();
  static const Curve bounce = Curves.elasticOut;
}

/// Custom Spring Curve for Tactile Taps
class SpringCurve extends Curve {
  const SpringCurve();

  @override
  double transformInternal(double t) {
    return -1 * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1;
  }
}
