import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Chapters grouping the comprehensive Administrator & Business Intelligence tutorial
enum AdminTutorialChapter {
  welcome,
  dashboard,
  operations,
  products,
  employees,
  pipeline,
  descriptive,
  forecasting,
  prescriptive,
  execution,
  concierge,
  notifications,
  account,
  guide;

  String get displayName {
    return switch (this) {
      AdminTutorialChapter.welcome => 'BI Hub Welcome',
      AdminTutorialChapter.dashboard => 'Admin Dashboard',
      AdminTutorialChapter.operations => 'Orders & Operations',
      AdminTutorialChapter.products => 'Product Catalog',
      AdminTutorialChapter.employees => 'Staff Management',
      AdminTutorialChapter.pipeline => 'Analytics Pipeline',
      AdminTutorialChapter.descriptive => 'Descriptive Analytics',
      AdminTutorialChapter.forecasting => 'Demand Forecasting',
      AdminTutorialChapter.prescriptive => 'Prescriptive Engine',
      AdminTutorialChapter.execution => 'Schedule & Queue',
      AdminTutorialChapter.concierge => 'Customer Concierge',
      AdminTutorialChapter.notifications => 'System Alerts',
      AdminTutorialChapter.account => 'Security & Settings',
      AdminTutorialChapter.guide => 'System Guide Hub',
    };
  }

  IconData get icon {
    return switch (this) {
      AdminTutorialChapter.welcome => Icons.auto_graph_rounded,
      AdminTutorialChapter.dashboard => Icons.dashboard_rounded,
      AdminTutorialChapter.operations => Icons.receipt_long_rounded,
      AdminTutorialChapter.products => Icons.inventory_2_rounded,
      AdminTutorialChapter.employees => Icons.people_alt_rounded,
      AdminTutorialChapter.pipeline => Icons.account_tree_rounded,
      AdminTutorialChapter.descriptive => Icons.bar_chart_rounded,
      AdminTutorialChapter.forecasting => Icons.timeline_rounded,
      AdminTutorialChapter.prescriptive => Icons.lightbulb_rounded,
      AdminTutorialChapter.execution => Icons.calendar_month_rounded,
      AdminTutorialChapter.concierge => Icons.forum_rounded,
      AdminTutorialChapter.notifications => Icons.notifications_active_rounded,
      AdminTutorialChapter.account => Icons.security_rounded,
      AdminTutorialChapter.guide => Icons.menu_book_rounded,
    };
  }
}

/// Interactive visual simulator widget type to render inside the admin tutorial card
enum AdminTutorialVisualType {
  adminWelcomeBanner,
  adminDashboardKpis,
  adminDateFiltersDemo,
  adminOrdersOperations,
  adminProductsCatalog,
  adminEmployeeManagement,
  adminSecurityGovernance,
  adminBiPipelineOverview,
  adminDescriptiveMetrics,
  adminDescriptiveDateFilters,
  adminForecastingChart,
  adminForecastingMetricsMaeMape,
  adminInsufficientDataHandling,
  adminPrescriptiveRecommendationCard,
  adminPrescriptiveActionWorkflow,
  adminPrescriptiveScheduleTimeline,
  adminPrescriptiveActionQueue,
  adminPrescriptiveActionHistory,
  adminAnalyticsTraceability,
  adminCustomerConcierge,
  adminNotificationsCenter,
  adminProfileSettings,
  adminHelpReplayAccess,
}

/// Rich Model defining a single interactive Administrator / BI tutorial step
class AdminTutorialStepModel extends Equatable {
  final String id;
  final int stepNumber;
  final AdminTutorialChapter chapter;
  final String title;
  final String subtitle;
  final String highlightArea;
  final IconData icon;
  final AdminTutorialVisualType visualType;
  final List<String> keyPoints;
  final String? operationalRule;
  final String? badgeText;
  final String? actionRoute;
  final String? actionLabel;

  const AdminTutorialStepModel({
    required this.id,
    required this.stepNumber,
    required this.chapter,
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
        chapter,
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
