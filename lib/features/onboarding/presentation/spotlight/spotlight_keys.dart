import 'package:flutter/material.dart';

/// Central registry of GlobalKeys for customer UI widgets targeted by the
/// Spotlight Coach-Mark Guided Product Tour.
class SpotlightKeys {
  SpotlightKeys._();

  // Home Screen Target Keys
  static final GlobalKey homeHeader = GlobalKey(debugLabel: 'spotlight_home_header');
  static final GlobalKey homeNotifications = GlobalKey(debugLabel: 'spotlight_home_notifications');
  static final GlobalKey homeThemeToggle = GlobalKey(debugLabel: 'spotlight_home_theme_toggle');
  static final GlobalKey homeSearch = GlobalKey(debugLabel: 'spotlight_home_search');
  static final GlobalKey homeHeroBanner = GlobalKey(debugLabel: 'spotlight_home_hero_banner');
  static final GlobalKey homeCategories = GlobalKey(debugLabel: 'spotlight_home_categories');
  static final GlobalKey homeQuickPickup = GlobalKey(debugLabel: 'spotlight_home_quick_pickup');
  static final GlobalKey homeQuickChat = GlobalKey(debugLabel: 'spotlight_home_quick_chat');
  static final GlobalKey homeQuickTrack = GlobalKey(debugLabel: 'spotlight_home_quick_track');
  static final GlobalKey homeFeaturedList = GlobalKey(debugLabel: 'spotlight_home_featured_list');
  static final GlobalKey homeFirstProductCard = GlobalKey(debugLabel: 'spotlight_home_first_product_card');

  // Bottom Navigation Target Keys
  static final GlobalKey navHome = GlobalKey(debugLabel: 'spotlight_nav_home');
  static final GlobalKey navRoastery = GlobalKey(debugLabel: 'spotlight_nav_roastery');
  static final GlobalKey navCart = GlobalKey(debugLabel: 'spotlight_nav_cart');
  static final GlobalKey navOrders = GlobalKey(debugLabel: 'spotlight_nav_orders');
  static final GlobalKey navProfile = GlobalKey(debugLabel: 'spotlight_nav_profile');

  // Barista / Staff Operations Target Keys
  static final GlobalKey staffQueueHeader = GlobalKey(debugLabel: 'spotlight_staff_queue_header');
  static final GlobalKey staffMetricsBar = GlobalKey(debugLabel: 'spotlight_staff_metrics_bar');
  static final GlobalKey staffStatusTabs = GlobalKey(debugLabel: 'spotlight_staff_status_tabs');
  static final GlobalKey staffFirstOrderCard = GlobalKey(debugLabel: 'spotlight_staff_first_order_card');
  static final GlobalKey staffOrderPickupBadge = GlobalKey(debugLabel: 'spotlight_staff_order_pickup_badge');
  static final GlobalKey staffOrderActionBtn = GlobalKey(debugLabel: 'spotlight_staff_order_action_btn');
  static final GlobalKey staffEmptyQueueCard = GlobalKey(debugLabel: 'spotlight_staff_empty_queue_card');
  static final GlobalKey staffInboxBanner = GlobalKey(debugLabel: 'spotlight_staff_inbox_banner');
  static final GlobalKey staffShiftControls = GlobalKey(debugLabel: 'spotlight_staff_shift_controls');

  // Barista / Staff Bottom Navigation Keys
  static final GlobalKey staffNavQueue = GlobalKey(debugLabel: 'spotlight_staff_nav_queue');
  static final GlobalKey staffNavPos = GlobalKey(debugLabel: 'spotlight_staff_nav_pos');
  static final GlobalKey staffNavConcierge = GlobalKey(debugLabel: 'spotlight_staff_nav_concierge');
  static final GlobalKey staffNavShift = GlobalKey(debugLabel: 'spotlight_staff_nav_shift');

  // Administrator Operations Target Keys
  static final GlobalKey adminDashboardHeader = GlobalKey(debugLabel: 'spotlight_admin_dashboard_header');
  static final GlobalKey adminRevenueCard = GlobalKey(debugLabel: 'spotlight_admin_revenue_card');
  static final GlobalKey adminOrdersMetric = GlobalKey(debugLabel: 'spotlight_admin_orders_metric');
  static final GlobalKey adminAddProductBtn = GlobalKey(debugLabel: 'spotlight_admin_add_product_btn');
  static final GlobalKey adminModulesList = GlobalKey(debugLabel: 'spotlight_admin_modules_list');
  static final GlobalKey adminOrdersQueue = GlobalKey(debugLabel: 'spotlight_admin_orders_queue');
  static final GlobalKey adminProductsCatalog = GlobalKey(debugLabel: 'spotlight_admin_products_catalog');
  static final GlobalKey adminInboxSummaryCard = GlobalKey(debugLabel: 'spotlight_admin_inbox_summary_card');
  static final GlobalKey adminBiTabs = GlobalKey(debugLabel: 'spotlight_admin_bi_tabs');
  static final GlobalKey adminForecastingCard = GlobalKey(debugLabel: 'spotlight_admin_forecasting_card');
  static final GlobalKey adminPrescriptiveCard = GlobalKey(debugLabel: 'spotlight_admin_prescriptive_card');
  static final GlobalKey adminControlModules = GlobalKey(debugLabel: 'spotlight_admin_control_modules');

  // Administrator Bottom Navigation Keys
  static final GlobalKey adminNavDashboard = GlobalKey(debugLabel: 'spotlight_admin_nav_dashboard');
  static final GlobalKey adminNavOrders = GlobalKey(debugLabel: 'spotlight_admin_nav_orders');
  static final GlobalKey adminNavProducts = GlobalKey(debugLabel: 'spotlight_admin_nav_products');
  static final GlobalKey adminNavIntelligence = GlobalKey(debugLabel: 'spotlight_admin_nav_intelligence');
  static final GlobalKey adminNavControl = GlobalKey(debugLabel: 'spotlight_admin_nav_control');
}
