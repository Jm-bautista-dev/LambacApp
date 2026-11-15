import 'package:flutter/material.dart';
import '../../../../core/routing/app_routes.dart';
import '../models/admin_tutorial_step_model.dart';

/// Comprehensive Administrator & Business Intelligence system tutorial catalog
/// built specifically for Executive Administrators of Lambac Coffee Roastery.
class AdminTutorialData {
  AdminTutorialData._();

  static const List<AdminTutorialStepModel> steps = [
    // -------------------------------------------------------------------------
    // 1. Welcome to Lambac Business Intelligence Hub
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_welcome',
      stepNumber: 1,
      chapter: AdminTutorialChapter.welcome,
      title: 'Welcome to Lambac BI Hub',
      subtitle: "Let's walk through the tools you use to manage operations, understand business performance, and make data-driven decisions.",
      highlightArea: 'Executive Governance Hub',
      icon: Icons.auto_graph_rounded,
      visualType: AdminTutorialVisualType.adminWelcomeBanner,
      badgeText: 'ADMIN EXECUTIVE',
      keyPoints: [
        'Central command center integrating store operations, staff governance, and BI analytics',
        'Direct access to 4-tier BI pipeline: Descriptive, Forecasting, Prescriptive, and Execution',
        'Complete administrative authority across product catalog, pricing, accounts, and live queues',
      ],
      operationalRule: 'You can replay this complete guide anytime from Admin Profile → Help & Guide.',
    ),

    // -------------------------------------------------------------------------
    // 2. Admin Dashboard & Executive KPIs
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_dashboard_kpis',
      stepNumber: 2,
      chapter: AdminTutorialChapter.dashboard,
      title: 'Executive Governance Dashboard',
      subtitle: 'Monitor high-level revenue, total order volume, active products, and station capacity in real-time.',
      highlightArea: 'Top Metric Cards & Status Counters',
      icon: Icons.dashboard_rounded,
      visualType: AdminTutorialVisualType.adminDashboardKpis,
      badgeText: 'EXECUTIVE KPIS',
      keyPoints: [
        'Total Revenue: Real-time gross earnings from online pickups and walk-in counter POS',
        'Order Velocity: Total orders placed today across all operational stages',
        'Active Catalog: Count of currently available single-origin beans and signature items',
        'Active Shift Staff: Number of on-duty baristas logged into the operations console',
      ],
      operationalRule: 'Review morning revenue velocity to determine if extra roasting capacity is needed for afternoon pickup peaks.',
      actionRoute: AppRoutes.adminDashboard,
      actionLabel: 'Open Dashboard',
    ),

    // -------------------------------------------------------------------------
    // 3. Multi-Period Dashboard Filters
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_dashboard_filters',
      stepNumber: 3,
      chapter: AdminTutorialChapter.dashboard,
      title: 'Multi-Period Date Filters',
      subtitle: 'Filter real-time executive metrics by Today, Last 7 Days, Last 15 Days, and Last 30 Days.',
      highlightArea: 'Dashboard Timeframe Selector',
      icon: Icons.date_range_rounded,
      visualType: AdminTutorialVisualType.adminDateFiltersDemo,
      badgeText: 'DATE FILTERS',
      keyPoints: [
        'Today: Live operational data for the current business cycle',
        '7 Days: Highlights weekly sales velocity and peak day patterns',
        '15 Days: Mid-month operational checkpoint for bean supply reordering',
        '30 Days: Full monthly aggregate for executive reporting and accounting settlement',
      ],
      operationalRule: 'Changing timeframe filters updates all underlying charts, cards, and ranking summaries simultaneously.',
    ),

    // -------------------------------------------------------------------------
    // 4. Operational Oversight & Orders Queue
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_operations_queue',
      stepNumber: 4,
      chapter: AdminTutorialChapter.operations,
      title: 'Operations & Order Queue Access',
      subtitle: 'Administrators possess complete access to view, triage, prepare, and advance live pickup orders.',
      highlightArea: 'Admin Orders & Queue Dispatch',
      icon: Icons.receipt_long_rounded,
      visualType: AdminTutorialVisualType.adminOrdersOperations,
      badgeText: 'FULL OPERATIONS',
      keyPoints: [
        'Admin can perform every barista action: Accept, Prepare, Package, and Hand Off',
        'Inspect order metadata: Customer name, pickup time, grind variant, and roast batch',
        'Verify Pay-at-Counter collection before marking orders as Completed',
        'Intervene in high-volume rushes to reassign batches or expedite VIP orders',
      ],
      operationalRule: 'Administrative operational actions are synchronized in real-time with customer apps.',
      actionRoute: AppRoutes.adminOrders,
      actionLabel: 'View Orders',
    ),

    // -------------------------------------------------------------------------
    // 5. Product Catalog & Bean Management
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_product_catalog',
      stepNumber: 5,
      chapter: AdminTutorialChapter.products,
      title: 'Bean Catalog & Stock Control',
      subtitle: 'Create single-origin lots, adjust prices, edit sensory notes, and toggle instant stock availability.',
      highlightArea: 'Catalog Management Screen',
      icon: Icons.inventory_2_rounded,
      visualType: AdminTutorialVisualType.adminProductsCatalog,
      badgeText: 'CATALOG CONTROL',
      keyPoints: [
        'Add New Products: Upload imagery, origin details, elevation, and flavor notes',
        'Size & Pricing: Configure 250g, 500g, and 1kg pouch prices and discount tiers',
        'Grind Configurations: Set allowed grind types (Whole Bean, Espresso, V60, Cold Brew)',
        'Live Availability: Toggle stock status to immediately reflect in customer store',
      ],
      operationalRule: 'Keep sensory tasting notes updated to reflect current harvest batch cupping scores.',
      actionRoute: AppRoutes.adminProducts,
      actionLabel: 'Manage Products',
    ),

    // -------------------------------------------------------------------------
    // 6. Employee Management & Staff Accounts
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_employee_management',
      stepNumber: 6,
      chapter: AdminTutorialChapter.employees,
      title: 'Staff & Employee Management',
      subtitle: 'Provision staff accounts, configure granular permissions, enforce security, and manage activations.',
      highlightArea: 'Account Management Screen',
      icon: Icons.people_alt_rounded,
      visualType: AdminTutorialVisualType.adminEmployeeManagement,
      badgeText: 'STAFF ACCOUNTS',
      keyPoints: [
        'Provision Accounts: Create certified barista and floor staff login credentials',
        'Granular Permissions: Assign Process Orders, Walk-In POS, Concierge Inbox, or Basic Metrics',
        'First-Login Setup: System enforces mandatory password creation upon initial staff sign-in',
        'Account Status: Toggle Active or Disabled to immediately revoke station access',
      ],
      operationalRule: 'Never share administrative accounts; provision dedicated staff logins for individual baristas.',
      actionRoute: AppRoutes.adminAccounts,
      actionLabel: 'Manage Accounts',
    ),

    // -------------------------------------------------------------------------
    // 7. Security & Role Governance
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_security_roles',
      stepNumber: 7,
      chapter: AdminTutorialChapter.employees,
      title: 'Role-Based Security Architecture',
      subtitle: 'Understand the strict three-tier role hierarchy: Customer vs Staff / Barista vs Administrator.',
      highlightArea: 'Role Governance Matrix',
      icon: Icons.security_rounded,
      visualType: AdminTutorialVisualType.adminSecurityGovernance,
      badgeText: 'ROLE ISOLATION',
      keyPoints: [
        'Customer: Shopping, cart, checkout, order tracking, and concierge chat',
        'Staff / Barista: Order processing queue, Walk-In POS, shared inbox, and shift profile',
        'Administrator: Full executive oversight, BI Hub, account provisioning, and catalog control',
        'Backend Authoritative: Access control is strictly enforced on the server, not just in UI',
      ],
      operationalRule: 'Administrative permissions are controlled by backend authenticated role tokens.',
    ),

    // -------------------------------------------------------------------------
    // 8. Business Intelligence Pipeline Architecture
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_bi_pipeline',
      stepNumber: 8,
      chapter: AdminTutorialChapter.pipeline,
      title: '4-Tier Business Intelligence Pipeline',
      subtitle: 'How Lambac transforms raw point-of-sale records into predictive demand and prescriptive recommendations.',
      highlightArea: 'BI Architecture Diagram',
      icon: Icons.account_tree_rounded,
      visualType: AdminTutorialVisualType.adminBiPipelineOverview,
      badgeText: 'BI PIPELINE',
      keyPoints: [
        'Tier 1 (Sales Ingestion): Logs every pickup and counter transaction securely',
        'Tier 2 (Descriptive Analytics): Calculates revenue trends, top beans, and order velocity',
        'Tier 3 (Demand Forecasting): Projects future consumption curves using historical patterns',
        'Tier 4 (Prescriptive Actions): Formulates high-impact roasting and scheduling recommendations',
      ],
      operationalRule: 'The BI Hub updates continuously as new transactions settle throughout the day.',
      actionRoute: AppRoutes.businessIntelligence,
      actionLabel: 'Open BI Hub',
    ),

    // -------------------------------------------------------------------------
    // 9. Descriptive Analytics & Sales Trends
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_descriptive_analytics',
      stepNumber: 9,
      chapter: AdminTutorialChapter.descriptive,
      title: 'Descriptive Analytics: Historical Truth',
      subtitle: 'Examine what has already occurred across gross revenue, transaction counts, and Average Order Value.',
      highlightArea: 'Descriptive Analytics Dashboard',
      icon: Icons.bar_chart_rounded,
      visualType: AdminTutorialVisualType.adminDescriptiveMetrics,
      badgeText: 'HISTORICAL DATA',
      keyPoints: [
        'Gross Revenue: Total sales volume with period-over-period percentage growth',
        'Average Order Value (AOV): Average basket size across single-origin and beverage items',
        'Top Performing Beans: Ranking beans by volume sold and revenue generated',
        'Channel Breakdown: Proportional split between App Scheduled Pickups and Walk-In POS',
      ],
      operationalRule: 'Use AOV metrics to evaluate the effectiveness of bean bundle promotions.',
    ),

    // -------------------------------------------------------------------------
    // 10. Descriptive Date Filtering Semantics
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_descriptive_date_ranges',
      stepNumber: 10,
      chapter: AdminTutorialChapter.descriptive,
      title: 'Descriptive Date Range Semantics',
      subtitle: 'Understand the exact boundaries of Today, Last 7 Days, Last 15 Days, and Last 30 Days data ranges.',
      highlightArea: 'Analytics Date Range Picker',
      icon: Icons.calendar_view_day_rounded,
      visualType: AdminTutorialVisualType.adminDescriptiveDateFilters,
      badgeText: 'TIMEFRAME LOGIC',
      keyPoints: [
        'Today: Midnight to current moment of the active business day',
        'Last 7 Days: Current day plus preceding six days (rolling 7-day window)',
        'Last 15 Days: Current day plus preceding fourteen days (bi-weekly trend analysis)',
        'Last 30 Days: Current day plus preceding twenty-nine days (monthly baseline)',
      ],
      operationalRule: 'Compare 7-day vs 30-day performance to identify emerging demand shifts.',
    ),

    // -------------------------------------------------------------------------
    // 11. Demand Forecasting Engine
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_forecasting_engine',
      stepNumber: 11,
      chapter: AdminTutorialChapter.forecasting,
      title: 'Demand Forecasting & Projection',
      subtitle: 'Project future single-origin micro-lot consumption using historical sales velocity and trends.',
      highlightArea: 'Forecasting Chart & Curves',
      icon: Icons.timeline_rounded,
      visualType: AdminTutorialVisualType.adminForecastingChart,
      badgeText: 'DEMAND ESTIMATE',
      keyPoints: [
        'Historical vs Projected: Displays historical sales curve alongside forward-looking forecast',
        'Horizon Forecast: Estimates bean bag demand for the upcoming 7 to 14 days',
        'Product-Level Curves: Select specific micro-lots (e.g. Mount Apo, Sagada, Benguet)',
        'Estimates, Not Guarantees: Forecasts provide mathematical predictions based on trend patterns',
      ],
      operationalRule: 'Always review product-specific forecasts before ordering green coffee bean shipments.',
      actionRoute: AppRoutes.forecasting,
      actionLabel: 'View Forecasts',
    ),

    // -------------------------------------------------------------------------
    // 12. Forecasting Statistical Error Metrics (MAE, RMSE, MAPE)
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_forecasting_metrics',
      stepNumber: 12,
      chapter: AdminTutorialChapter.forecasting,
      title: 'Evaluating Forecast Error Metrics',
      subtitle: 'Evaluate model performance. Note: MAPE represents forecast error rather than a direct accuracy score.',
      highlightArea: 'Statistical Evaluation Cards (MAE, RMSE, MAPE)',
      icon: Icons.query_stats_rounded,
      visualType: AdminTutorialVisualType.adminForecastingMetricsMaeMape,
      badgeText: 'ERROR EVALUATION',
      keyPoints: [
        'MAE (Mean Absolute Error): Average magnitude of forecast errors in raw units/bags',
        'RMSE (Root Mean Squared Error): Penalizes larger outliers more heavily for volatility checks',
        'MAPE (Mean Absolute Percentage Error): Expresses average percentage error relative to actuals',
        'Interpretation: Lower MAPE represents tighter model fit and lower forecasting error',
      ],
      operationalRule: 'Do not interpret MAPE as accuracy; a MAPE of 8.2% means the forecast deviates by ~8.2% on average.',
    ),

    // -------------------------------------------------------------------------
    // 13. Data Quality & Insufficient History Handling
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_insufficient_data',
      stepNumber: 13,
      chapter: AdminTutorialChapter.forecasting,
      title: 'Handling Insufficient Historical Data',
      subtitle: 'How the engine handles new bean offerings and protects decision-making from unreliable projections.',
      highlightArea: 'Data Confidence & Warning Badges',
      icon: Icons.data_usage_rounded,
      visualType: AdminTutorialVisualType.adminInsufficientDataHandling,
      badgeText: 'DATA INTEGRITY',
      keyPoints: [
        'Minimum Data Threshold: Statistical projections require sufficient historical transactions',
        'Insufficient Data Banner: System alerts when a newly introduced bean has limited sales history',
        'No Synthetic Guesswork: The system refuses to generate arbitrary or fake forecasts',
        'Confidence Scoring: Confidence ratings scale upward as seasonal history accumulates',
      ],
      operationalRule: 'For newly launched micro-lots, use conservative manual roasting batches until data matures.',
    ),

    // -------------------------------------------------------------------------
    // 14. Prescriptive Recommendation Engine
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_prescriptive_recommendations',
      stepNumber: 14,
      chapter: AdminTutorialChapter.prescriptive,
      title: 'Prescriptive Recommendations Engine',
      subtitle: 'Evidence-based decision guidance that recommends concrete roasting, inventory, and marketing actions.',
      highlightArea: 'Prescriptive Action Recommendations',
      icon: Icons.lightbulb_rounded,
      visualType: AdminTutorialVisualType.adminPrescriptiveRecommendationCard,
      badgeText: 'ACTIONABLE AI',
      keyPoints: [
        'Synthesizes historical sales, upcoming pickup reservations, and forecast projections',
        'Prioritizes operational actions: High (Urgent), Medium (Optimization), Low (Exploratory)',
        'Identifies supply bottlenecks before store shelves run out of popular roast profiles',
        'Formulates exact quantities (e.g. "Roast 12kg of Benguet Typica for Weekend Rush")',
      ],
      operationalRule: 'Prescriptive recommendations provide the evidence; the administrator makes the final decision.',
    ),

    // -------------------------------------------------------------------------
    // 15. Prescriptive Recommendation Card Anatomy
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_prescriptive_card_anatomy',
      stepNumber: 15,
      chapter: AdminTutorialChapter.prescriptive,
      title: 'Recommendation Card Breakdown',
      subtitle: 'Understand Category, Priority, Supporting Metrics, Data-Driven Rationale, and Recommended Action.',
      highlightArea: 'Recommendation Card Structure',
      icon: Icons.fact_check_rounded,
      visualType: AdminTutorialVisualType.adminPrescriptiveRecommendationCard,
      badgeText: 'CARD ANATOMY',
      keyPoints: [
        'Category Pill: Classifies action type (Roast Prep, Inventory Restock, Promotion, Capacity)',
        'Priority Indicator: Color-coded badge (High/Medium/Low) establishing urgency',
        'Data-Driven Rationale: Explains the exact mathematical evidence driving the suggestion',
        'Supporting Metric: Highlights key projection data (e.g. Projected Weekend Spike: +34%)',
      ],
      operationalRule: 'Always review the Rationale and Supporting Metric before accepting or scheduling an action.',
    ),

    // -------------------------------------------------------------------------
    // 16. Decision-to-Action 4-Stage Lifecycle
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_decision_lifecycle',
      stepNumber: 16,
      chapter: AdminTutorialChapter.execution,
      title: 'Decision-to-Action 4-Stage Lifecycle',
      subtitle: 'Recommendations are suggestions until reviewed, configured, scheduled, and handed over to floor staff.',
      highlightArea: 'Decision Lifecycle Workflow',
      icon: Icons.published_with_changes_rounded,
      visualType: AdminTutorialVisualType.adminPrescriptiveActionWorkflow,
      badgeText: 'DECISION LIFECYCLE',
      keyPoints: [
        'Step 1 (Recommendation): Engine identifies operational optimization opportunity',
        'Step 2 (Admin Review): Administrator reviews evidence and configures parameters',
        'Step 3 (Schedule & Queue): Action is calendarized and added to barista task board',
        'Step 4 (Execution & Audit): Staff completes physical action, logged into history',
      ],
      operationalRule: 'Closing the loop from analysis to physical execution is the primary goal of the BI Hub.',
    ),

    // -------------------------------------------------------------------------
    // 17. Prescriptive Schedule Management
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_prescriptive_schedule',
      stepNumber: 17,
      chapter: AdminTutorialChapter.execution,
      title: 'Prescriptive Production Schedule',
      subtitle: 'Plan and calendarize batch roasting, cold brew steeping, and inventory replenishment sessions.',
      highlightArea: 'Schedule Timeline Tab',
      icon: Icons.calendar_month_rounded,
      visualType: AdminTutorialVisualType.adminPrescriptiveScheduleTimeline,
      badgeText: 'PRODUCTION SCHEDULE',
      keyPoints: [
        'Schedule Definition: Schedule = WHEN an action is planned to occur',
        'Batch Timing: Assign specific dates and times (e.g. Friday 6:00 AM Roast Session)',
        'Reschedule & Adjust: Easily shift roasting times when supply delivery dates change',
        'Staff Assignment: Assign specific roast batches to certified lead baristas',
      ],
      operationalRule: 'Maintain scheduled roast sessions at least 24 hours in advance to allow green bean preparation.',
    ),

    // -------------------------------------------------------------------------
    // 18. Action Queue & Execution Audit History
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_prescriptive_queue_history',
      stepNumber: 18,
      chapter: AdminTutorialChapter.execution,
      title: 'Action Queue & Audit Ledger',
      subtitle: 'Track active operational tickets and review completed decisions in the historical audit ledger.',
      highlightArea: 'Action Queue & History Sub-Tabs',
      icon: Icons.history_edu_rounded,
      visualType: AdminTutorialVisualType.adminPrescriptiveActionQueue,
      badgeText: 'ACTION QUEUE',
      keyPoints: [
        'Queue Definition: Queue = OPERATIONAL ACTIONS requiring active floor execution',
        'Status Progression: Pending -> Scheduled -> In Progress -> Completed -> Cancelled',
        'Execution History: Permanent audit trail documenting completed roast batches',
        'Traceability: Every historical record links back to the original recommendation trigger',
      ],
      operationalRule: 'Review History at end of week to evaluate how recommendations improved product availability.',
    ),

    // -------------------------------------------------------------------------
    // 19. Customer Concierge & AI Collaboration
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_customer_concierge',
      stepNumber: 19,
      chapter: AdminTutorialChapter.concierge,
      title: 'Customer Concierge & AI Governance',
      subtitle: 'Oversee customer inquiries, review AI assistant interactions, and send direct administrative messages.',
      highlightArea: 'Concierge Chat Hub',
      icon: Icons.forum_rounded,
      visualType: AdminTutorialVisualType.adminCustomerConcierge,
      badgeText: 'CONCIERGE & AI',
      keyPoints: [
        'Unified Threads: View all customer inquiries across the flagship roastery',
        'AI Assistant Monitoring: Review automated answers regarding brewing guides and store info',
        'Administrative Intervention: Step into any conversation to resolve complex customer inquiries',
        'Persistent Records: All customer preferences and grind notes are saved to customer profile',
      ],
      operationalRule: 'Ensure prompt response to high-value wholesale or custom cupping event inquiries.',
      actionRoute: AppRoutes.staffInbox,
      actionLabel: 'Open Inbox',
    ),

    // -------------------------------------------------------------------------
    // 20. Operational & Business Notifications
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_notifications_center',
      stepNumber: 20,
      chapter: AdminTutorialChapter.notifications,
      title: 'Operational & Analytics Alerts',
      subtitle: 'Receive proactive alerts for low bean stock, high queue surges, and scheduled batch reminders.',
      highlightArea: 'Notification System & Alert Badges',
      icon: Icons.notifications_active_rounded,
      visualType: AdminTutorialVisualType.adminNotificationsCenter,
      badgeText: 'PROACTIVE ALERTS',
      keyPoints: [
        'Stock Threshold Alerts: Notifies when green bean or packaged bag inventory runs low',
        'High Queue Surges: Alerts administrator when active preparation orders exceed station capacity',
        'Scheduled Action Reminders: Chimes when a scheduled roast batch is approaching execution time',
        'Customer Messages: Unread badge counters on the Concierge icon',
      ],
      operationalRule: 'Configure notifications to maintain rapid operational awareness during peak morning rushes.',
    ),

    // -------------------------------------------------------------------------
    // 21. Admin Profile, Security & Preferences
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_security_settings',
      stepNumber: 21,
      chapter: AdminTutorialChapter.account,
      title: 'Admin Profile, Security & Settings',
      subtitle: 'Manage administrator credentials, toggle high-contrast Tokyo Night Dark mode, and access system logs.',
      highlightArea: 'Admin Profile & System Settings',
      icon: Icons.admin_panel_settings_rounded,
      visualType: AdminTutorialVisualType.adminProfileSettings,
      badgeText: 'SECURITY & CONTROL',
      keyPoints: [
        'Administrator Identity: Displays executive credentials and authorized permissions',
        'Appearance Theme: Toggle Tokyo Night Cafe Dark mode or Warm Parchment Light mode',
        'Session Governance: Secure sign-out terminating active administrative session tokens',
        'Help & Guide Access: Launch the full 22-step interactive guide or browse specific BI chapters',
      ],
      operationalRule: 'Always log out from shared terminal tablets when leaving the roastery office.',
      actionRoute: AppRoutes.adminProfile,
      actionLabel: 'View Profile',
    ),

    // -------------------------------------------------------------------------
    // 22. System Guide Hub & Interactive Replay
    // -------------------------------------------------------------------------
    AdminTutorialStepModel(
      id: 'admin_guide_hub_replay',
      stepNumber: 22,
      chapter: AdminTutorialChapter.guide,
      title: 'You are Ready to Manage Lambac',
      subtitle: 'You now know how to operate the system, understand business performance, interpret forecasts, and turn recommendations into actions.',
      highlightArea: 'Admin Guide Hub & Launch',
      icon: Icons.menu_book_rounded,
      visualType: AdminTutorialVisualType.adminHelpReplayAccess,
      badgeText: 'GOVERNANCE READY',
      keyPoints: [
        'You understand Dashboard KPIs, multi-period filters, and operational order triage',
        'You master the 4-Tier BI Pipeline: Descriptive, Forecasting, Prescriptive, and Execution',
        'You can provision staff accounts, manage bean catalogs, and oversee customer inquiries',
        'You can replay this complete Admin tutorial anytime from Profile → Help & Guide',
      ],
      operationalRule: 'Tap "Open Dashboard" to begin your executive session in the Lambac BI Hub.',
      actionRoute: AppRoutes.adminDashboard,
      actionLabel: 'Open Dashboard',
    ),
  ];
}
