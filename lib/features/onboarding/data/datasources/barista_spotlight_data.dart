import 'package:flutter/material.dart';
import '../../presentation/spotlight/spotlight_keys.dart';
import '../models/spotlight_step_model.dart';

/// Curated Spotlight Steps for Barista / Staff Operations Onboarding
/// Targeting actual widgets in StaffOperationsScreen, StaffShellScreen, and StaffProfileScreen.
class BaristaSpotlightData {
  BaristaSpotlightData._();

  static List<SpotlightStepModel> getSteps() {
    return [
      // STEP 1 — Barista Dashboard & Operational Workspace
      SpotlightStepModel(
        id: 'barista_dashboard_header',
        stepNumber: 1,
        categoryTitle: 'OPERATIONAL OVERVIEW',
        title: 'Barista Station & Daily Queue',
        description:
            'Welcome to the Barista Operations Workspace. Monitor live store status, station throughput, and quickly synchronize the live active pickup queue.',
        targetKey: SpotlightKeys.staffQueueHeader,
        icon: Icons.coffee_maker_rounded,
        keyPoints: const [
          'High-visibility station queue header and live total order count',
          'Fast access to live order queue management and manual queue synchronization',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        borderRadius: 14,
        targetBranchIndex: 0,
      ),

      // STEP 2 — Active Orders & Live Pipeline Status
      SpotlightStepModel(
        id: 'barista_metrics_pipeline',
        stepNumber: 2,
        categoryTitle: 'QUEUE PIPELINE',
        title: 'Real-Time Operational Metrics',
        description:
            'Track counts across brewing milestones: Active Queue, Preparing, Ready, and Due/Overdue alerts to maintain counter throughput.',
        targetKey: SpotlightKeys.staffMetricsBar,
        icon: Icons.tune_rounded,
        keyPoints: const [
          'Instant status breakdown color-coded by urgency',
          'Monitor station throughput in real time during peak hours',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        borderRadius: 12,
        targetBranchIndex: 0,
      ),

      // STEP 3 — Order Details & Recipe Specifications
      SpotlightStepModel(
        id: 'barista_order_ticket',
        stepNumber: 3,
        categoryTitle: 'RECIPE SPECIFICATIONS',
        title: 'Order Ticket & Item Composition',
        description:
            'Inspect incoming pickup orders with clear drink sizing, grind specifications, roast origins, and customer preparation notes.',
        targetKey: SpotlightKeys.staffFirstOrderCard,
        icon: Icons.receipt_long_rounded,
        keyPoints: const [
          'High-contrast item multipliers (e.g. 2 × Single-Origin Pour Over)',
          'Clear customer details and special brewing instructions',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.all(8),
        borderRadius: 16,
        targetBranchIndex: 0,
        scrollTargetIntoView: true,
      ),

      // STEP 4 — Preparing Status Advancement
      SpotlightStepModel(
        id: 'barista_status_preparing',
        stepNumber: 4,
        categoryTitle: 'BREWING ADVANCEMENT',
        title: 'Start Brewing & Status Control',
        description:
            'Tap "Start Preparing" when you begin brewing. This immediately updates customer-facing live order tracking to stage 3.',
        targetKey: SpotlightKeys.staffOrderActionBtn,
        icon: Icons.local_cafe_rounded,
        keyPoints: const [
          'Advances workflow from Confirmed to Preparing',
          'Prevents duplicate brewing across multiple baristas',
        ],
        preferredPosition: TooltipPosition.above,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        borderRadius: 12,
        targetBranchIndex: 0,
        scrollTargetIntoView: true,
      ),

      // STEP 5 — Ready for Pickup & Counter Handoff
      SpotlightStepModel(
        id: 'barista_status_ready',
        stepNumber: 5,
        categoryTitle: 'COUNTER HANDOFF',
        title: 'Mark Ready & Order Completion',
        description:
            'Mark orders ready when packaged on the pickup counter. When customer arrives, verify counter payment and complete the order handoff.',
        targetKey: SpotlightKeys.staffOrderActionBtn,
        icon: Icons.check_circle_rounded,
        keyPoints: const [
          'Sends instant push alert to customer that order is ready for pickup',
          'Supports counter payment collection and final order completion handoff',
        ],
        preferredPosition: TooltipPosition.above,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        borderRadius: 12,
        targetBranchIndex: 0,
        scrollTargetIntoView: true,
      ),

      // STEP 6 — Scheduled Pickup Slots & Time Windows
      SpotlightStepModel(
        id: 'barista_pickup_time_slot',
        stepNumber: 6,
        categoryTitle: 'TIMING PRECISION',
        title: 'Scheduled Pickup Time Slots',
        description:
            'Prioritize preparation based on promised pickup windows (1h, 3h, 5h, or custom customer time slots) to ensure optimal beverage temperature.',
        targetKey: SpotlightKeys.staffOrderPickupBadge,
        icon: Icons.access_time_filled_rounded,
        keyPoints: const [
          'Promised pickup window clearly highlighted on every ticket',
          'Coordinates brewing time with customer arrival schedule',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        borderRadius: 10,
        targetBranchIndex: 0,
        scrollTargetIntoView: true,
      ),

      // STEP 7 — Customer Concierge & Live Chat
      SpotlightStepModel(
        id: 'barista_nav_concierge',
        stepNumber: 7,
        categoryTitle: 'GUEST SUPPORT',
        title: 'Customer Concierge Inbox',
        description:
            'Direct communication channel with customers for inquiries, bean recommendations, brewing adjustments, and pickup timing updates.',
        targetKey: SpotlightKeys.staffInboxBanner,
        icon: Icons.chat_bubble_rounded,
        keyPoints: const [
          'Direct customer-to-barista chat with live unread badge',
          'Resolve customer requests without leaving the bar station',
        ],
        preferredPosition: TooltipPosition.below,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 12,
        targetBranchIndex: 1,
      ),

      // STEP 8 — Barista Shift Profile & Help Guide
      SpotlightStepModel(
        id: 'barista_nav_shift',
        stepNumber: 8,
        categoryTitle: 'SHIFT & OPERATIONS',
        title: 'My Shift & Station Controls',
        description:
            'Access your shift profile, assigned station permissions, operations SOP manual, and replay this interactive tutorial at any time.',
        targetKey: SpotlightKeys.staffShiftControls,
        icon: Icons.badge_rounded,
        keyPoints: const [
          'Shift status, station themes, and operations guide',
          'One-tap replay of this 8-step Barista Spotlight Tour',
        ],
        preferredPosition: TooltipPosition.above,
        padding: const EdgeInsets.all(8),
        borderRadius: 16,
        targetBranchIndex: 2,
        scrollTargetIntoView: true,
      ),
    ];
  }
}
