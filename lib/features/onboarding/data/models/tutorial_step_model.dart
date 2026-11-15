import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'tutorial_category.dart';

/// Interactive visual widget type to render inside the tutorial card
enum TutorialVisualType {
  welcomeBanner,
  guestAuthCard,
  navigationBarSimulator,
  homeEditorialHeader,
  productCatalogCard,
  productSensoryDetails,
  sizeGrindCustomizer,
  cartManagementDemo,
  pickupOnlyModel,
  pickupSchedulerDemo,
  payAtCounterBadge,
  orderStatusTracker,
  realtimeReceiptView,
  notificationCenterAlert,
  conciergeChatDemo,
  aiAssistantDemo,
  reviewsRatingCard,
  memberLoyaltyCard,
  helpReplayCard,
}

/// Rich Model defining a single interactive customer tutorial step
class TutorialStepModel extends Equatable {
  final String id;
  final int stepNumber;
  final TutorialCategory category;
  final String title;
  final String subtitle;
  final String highlightArea;
  final IconData icon;
  final TutorialVisualType visualType;
  final List<String> keyPoints;
  final String? practicalTip;
  final String? badgeText;
  final String? actionRoute;
  final String? actionLabel;

  const TutorialStepModel({
    required this.id,
    required this.stepNumber,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.highlightArea,
    required this.icon,
    required this.visualType,
    required this.keyPoints,
    this.practicalTip,
    this.badgeText,
    this.actionRoute,
    this.actionLabel,
  });

  @override
  List<Object?> get props => [
        id,
        stepNumber,
        category,
        title,
        subtitle,
        highlightArea,
        icon,
        visualType,
        keyPoints,
        practicalTip,
        badgeText,
        actionRoute,
        actionLabel,
      ];
}
