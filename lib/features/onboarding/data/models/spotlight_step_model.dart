import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Shape of the spotlight cutout
enum SpotlightShape {
  roundedRect,
  circle,
}

/// Preferred vertical position of the tooltip card relative to the target
enum TooltipPosition {
  auto,
  above,
  below,
}

/// Model representing a single customer spotlight coach-mark tour step
class SpotlightStepModel extends Equatable {
  final String id;
  final int stepNumber;
  final String categoryTitle;
  final String title;
  final String description;
  final GlobalKey targetKey;
  final IconData icon;
  final List<String> keyPoints;
  final SpotlightShape shape;
  final double borderRadius;
  final EdgeInsets padding;
  final TooltipPosition preferredPosition;
  final int? targetBranchIndex;
  final bool scrollTargetIntoView;

  const SpotlightStepModel({
    required this.id,
    required this.stepNumber,
    required this.categoryTitle,
    required this.title,
    required this.description,
    required this.targetKey,
    required this.icon,
    this.keyPoints = const [],
    this.shape = SpotlightShape.roundedRect,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(8.0),
    this.preferredPosition = TooltipPosition.auto,
    this.targetBranchIndex,
    this.scrollTargetIntoView = true,
  });

  @override
  List<Object?> get props => [
        id,
        stepNumber,
        categoryTitle,
        title,
        description,
        targetKey,
        icon,
        keyPoints,
        shape,
        borderRadius,
        padding,
        preferredPosition,
        targetBranchIndex,
        scrollTargetIntoView,
      ];
}
