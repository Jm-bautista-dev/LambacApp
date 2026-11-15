import 'package:flutter/material.dart';
import '../../presentation/spotlight/spotlight_keys.dart';
import '../models/spotlight_step_model.dart';

/// Curated Spotlight Steps for Administrator & Executive Governance Onboarding
/// Targeting actual widgets in AdminDashboardScreen, AdminShellScreen, and AdminProfileScreen.
class AdminSpotlightData {
  AdminSpotlightData._();

  static List<SpotlightStepModel> getSteps() {
    return [
      // STEP 1 — Executive Command Center & Roastery Status
      SpotlightStepModel(
        id: 'admin_dashboard_header',
        stepNumber: 1,
        categoryTitle: 'EXECUTIVE OVERVIEW',
        title: 'Executive Command Center',
        description:
            'Central headquarters for roastery operations. Monitor real-time store identity, daily throughput, operational alerts, and station velocity in one unified dashboard.',
        targetKey: SpotlightKeys.adminDashboardHeader,
        icon: Icons.dashboard_rounded,
        keyPoints: const [
          'Live roastery operations summary & store identity',
          'Central executive financial metrics and alert center',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 18,
        targetBranchIndex: 0,
      ),

      // STEP 2 — Daily Revenue & Financial KPIs
      SpotlightStepModel(
        id: 'admin_kpi_revenue',
        stepNumber: 2,
        categoryTitle: 'FINANCIAL PERFORMANCE',
        title: 'Daily Revenue & Financial KPIs',
        description:
            'Track real-time store gross sales, completed order transactions, average basket values, and hourly sales velocity.',
        targetKey: SpotlightKeys.adminRevenueCard,
        icon: Icons.payments_rounded,
        keyPoints: const [
          'Live daily revenue calculated strictly from completed orders',
          'Real-time order volume, average ticket size, and growth tracking',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.all(8),
        borderRadius: 16,
        targetBranchIndex: 0,
      ),

      // STEP 3 — Order Pipeline & Fulfillment Queue
      SpotlightStepModel(
        id: 'admin_orders_queue',
        stepNumber: 3,
        categoryTitle: 'ORDER FULFILLMENT',
        title: 'Fulfillment & Status Queue',
        description:
            'Supervise roastery order fulfillment. Advance pickup orders through the 6-stage lifecycle from Confirmed to Preparing, Prepared, and Counter Handoff.',
        targetKey: SpotlightKeys.adminOrdersQueue,
        icon: Icons.receipt_long_rounded,
        keyPoints: const [
          'Real-time 6-stage order tracking & fulfillment queues',
          'Overdue order alerts and counter pickup status coordination',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 16,
        targetBranchIndex: 1,
      ),

      // STEP 4 — Specialty Coffee Catalog & Availability
      SpotlightStepModel(
        id: 'admin_products_catalog',
        stepNumber: 4,
        categoryTitle: 'CATALOG GOVERNANCE',
        title: 'Coffee Catalog & Availability',
        description:
            'Manage active single-origin micro-lots, signature blends, grind specifications, and toggle instant item availability (Available, Sold Out, or Hidden).',
        targetKey: SpotlightKeys.adminProductsCatalog,
        icon: Icons.coffee_rounded,
        keyPoints: const [
          'One-tap toggle for bean stock availability & customer visibility',
          'Instant catalog search across single origins, roast levels & tags',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 16,
        targetBranchIndex: 2,
      ),

      // STEP 5 — New Roast Creation & Pricing
      SpotlightStepModel(
        id: 'admin_add_product',
        stepNumber: 5,
        categoryTitle: 'PRODUCT CREATION',
        title: 'New Roast Creation & Pricing',
        description:
            'Introduce new seasonal roasts and single-origin beans. Configure multi-bag pricing (250g, 500g, 1kg), sensory tasting notes, elevation, and grind options.',
        targetKey: SpotlightKeys.adminAddProductBtn,
        icon: Icons.add_circle_outline_rounded,
        keyPoints: const [
          'Custom bag size variants, pricing tiers, and whole bean/grind types',
          'Rich sensory tasting notes, farm altitude & brewing guides',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.all(8),
        borderRadius: 12,
        targetBranchIndex: 2,
      ),

      // STEP 6 — Guest Support & Concierge Inquiries
      SpotlightStepModel(
        id: 'admin_inbox_module',
        stepNumber: 6,
        categoryTitle: 'CUSTOMER RELATIONS',
        title: 'Guest Concierge & Inquiries',
        description:
            'Monitor incoming customer inquiries, roast recommendations, and order modification requests with live unread indicators.',
        targetKey: SpotlightKeys.adminInboxSummaryCard,
        icon: Icons.mark_chat_unread_rounded,
        keyPoints: const [
          'Unread badges for immediate customer inquiries needing response',
          'Bidirectional chat supervision and order resolution',
        ],
        preferredPosition: TooltipPosition.above,
        padding: const EdgeInsets.all(8),
        borderRadius: 16,
        targetBranchIndex: 0,
        scrollTargetIntoView: true,
      ),

      // STEP 7 — Business Intelligence Hub & Analytics
      SpotlightStepModel(
        id: 'admin_bi_hub',
        stepNumber: 7,
        categoryTitle: 'DATA ANALYTICS',
        title: 'Business Intelligence Hub',
        description:
            'Comprehensive data intelligence covering historical descriptive sales, product performance ranking, customer retention, and roastery data pipelines.',
        targetKey: SpotlightKeys.adminBiTabs,
        icon: Icons.auto_awesome_rounded,
        keyPoints: const [
          'Integrated descriptive, predictive, and prescriptive data views',
          'Hourly sales distribution, top-selling roasts & customer retention',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 16,
        targetBranchIndex: 3,
      ),

      // STEP 8 — AI Sales & Demand Forecasting
      SpotlightStepModel(
        id: 'admin_forecasting',
        stepNumber: 8,
        categoryTitle: 'PREDICTIVE ML',
        title: 'Sales & Demand Forecasting',
        description:
            'Predictive time-series machine learning models forecast store sales and green bean inventory demand up to 30 days ahead to eliminate bean stockouts.',
        targetKey: SpotlightKeys.adminForecastingCard,
        icon: Icons.trending_up_rounded,
        keyPoints: const [
          'Multi-horizon sales forecasts with 95% confidence intervals',
          'Bean inventory demand projections and seasonal spike anticipation',
        ],
        preferredPosition: TooltipPosition.above,
        padding: const EdgeInsets.all(10),
        borderRadius: 18,
        targetBranchIndex: 3,
        scrollTargetIntoView: true,
      ),

      // STEP 9 — Prescriptive Decisions & Batch Roast Scheduling
      SpotlightStepModel(
        id: 'admin_prescriptive',
        stepNumber: 9,
        categoryTitle: 'PRESCRIPTIVE AI',
        title: 'Prescriptive Decision Dispatch',
        description:
            'Automated prescriptive engine recommends optimal roasting batch schedules, dynamic bundle promotions, and staff allocation.',
        targetKey: SpotlightKeys.adminPrescriptiveCard,
        icon: Icons.psychology_rounded,
        keyPoints: const [
          '1-tap batch roast scheduling and production queue dispatch',
          'Auditable data quality checks and recommendation logs',
        ],
        preferredPosition: TooltipPosition.above,
        padding: const EdgeInsets.all(10),
        borderRadius: 18,
        targetBranchIndex: 3,
        scrollTargetIntoView: true,
      ),

      // STEP 10 — Administrative Governance & Shift Control
      SpotlightStepModel(
        id: 'admin_control_rbac',
        stepNumber: 10,
        categoryTitle: 'SECURITY & GOVERNANCE',
        title: 'RBAC Governance & Shift Control',
        description:
            'Provision administrator and staff credentials, enforce first-login password updates, audit the centralized sales ledger, and replay this tour anytime.',
        targetKey: SpotlightKeys.adminControlModules,
        icon: Icons.admin_panel_settings_rounded,
        keyPoints: const [
          'Role-based access control (Admin vs Staff) & security settings',
          'Centralized Sales Ledger audit and 1-tap live tour replay',
        ],
        preferredPosition: TooltipPosition.above,
        padding: const EdgeInsets.all(10),
        borderRadius: 18,
        targetBranchIndex: 4,
        scrollTargetIntoView: true,
      ),
    ];
  }
}
