import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Categories grouping the Barista / Staff operational tutorial steps
enum StaffTutorialCategory {
  welcome,
  navigation,
  queue,
  preparation,
  pickup,
  pos,
  concierge,
  shift;

  String get displayName {
    return switch (this) {
      StaffTutorialCategory.welcome => 'Getting Started',
      StaffTutorialCategory.navigation => 'Station Navigation',
      StaffTutorialCategory.queue => 'Queue & Metrics',
      StaffTutorialCategory.preparation => 'Order Preparation',
      StaffTutorialCategory.pickup => 'Pickup & Payment',
      StaffTutorialCategory.pos => 'Walk-In POS',
      StaffTutorialCategory.concierge => 'Concierge & AI',
      StaffTutorialCategory.shift => 'Shift & Safety',
    };
  }

  IconData get icon {
    return switch (this) {
      StaffTutorialCategory.welcome => Icons.storefront_rounded,
      StaffTutorialCategory.navigation => Icons.tab_rounded,
      StaffTutorialCategory.queue => Icons.receipt_long_rounded,
      StaffTutorialCategory.preparation => Icons.local_fire_department_rounded,
      StaffTutorialCategory.pickup => Icons.point_of_sale_rounded,
      StaffTutorialCategory.pos => Icons.shopping_cart_checkout_rounded,
      StaffTutorialCategory.concierge => Icons.forum_rounded,
      StaffTutorialCategory.shift => Icons.badge_rounded,
    };
  }
}

/// Interactive visual widget type to render inside the staff tutorial card
enum StaffTutorialVisualType {
  operationsWelcomeBanner,
  staffNavigationBarSimulator,
  operationsKpiMetrics,
  statusFilterTabsDemo,
  orderCardInspection,
  acceptOrderStep,
  preparingRoastingStep,
  markPreparedStep,
  readyForPickupStep,
  handOffCompletedStep,
  realtimeSyncExplanation,
  payAtCounterSettlement,
  walkInPosDemo,
  conciergeSharedInbox,
  aiBaristaHandoffDemo,
  operationalNotifications,
  staffProfileStation,
  staffHelpReplayCard,
  operationalSafetyRules,
}

/// Rich Model defining a single interactive Barista / Staff tutorial step
class StaffTutorialStepModel extends Equatable {
  final String id;
  final int stepNumber;
  final StaffTutorialCategory category;
  final String title;
  final String subtitle;
  final String highlightArea;
  final IconData icon;
  final StaffTutorialVisualType visualType;
  final List<String> keyPoints;
  final String? operationalRule;
  final String? badgeText;
  final String? actionRoute;
  final String? actionLabel;

  const StaffTutorialStepModel({
    required this.id,
    required this.stepNumber,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.highlightArea,
    required this.icon,
    required this.visualType,
    required this.keyPoints,
    this.operationalRule,
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
        operationalRule,
        badgeText,
        actionRoute,
        actionLabel,
      ];
}
