import 'package:flutter/material.dart';
import '../../../../core/routing/app_routes.dart';
import '../models/staff_tutorial_step_model.dart';

/// Comprehensive operational tutorial catalog built specifically for
/// Baristas and Staff members operating the Lambac Coffee Roastery system.
class StaffTutorialData {
  StaffTutorialData._();

  static const List<StaffTutorialStepModel> steps = [
    // -------------------------------------------------------------------------
    // 1. Welcome to Lambac Operations
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_welcome',
      stepNumber: 1,
      category: StaffTutorialCategory.welcome,
      title: 'Welcome to Lambac Operations',
      subtitle: 'Your dedicated Barista operations console for managing pickup queues, walk-in sales, and customer concierge.',
      highlightArea: 'Operations Hub & Station Overview',
      icon: Icons.storefront_rounded,
      visualType: StaffTutorialVisualType.operationsWelcomeBanner,
      badgeText: 'BARISTA CONSOLE',
      keyPoints: [
        'Purpose-built for roastery floor staff, baristas, and counter managers',
        'Streamlined for fast order triage, status advancement, and inventory hand-off',
        'Direct connection to customer apps for real-time pickup synchronization',
      ],
      operationalRule: 'Maintain strict attention to pickup time slots to ensure single-origin beans are brewed or packaged at peak freshness.',
    ),

    // -------------------------------------------------------------------------
    // 2. Staff Station Navigation
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_navigation',
      stepNumber: 2,
      category: StaffTutorialCategory.navigation,
      title: 'Station Navigation Structure',
      subtitle: 'Four dedicated operational tabs designed for quick one-thumb switching during busy roastery shifts.',
      highlightArea: 'Bottom Navigation Bar (4 Operations Tabs)',
      icon: Icons.tab_rounded,
      visualType: StaffTutorialVisualType.staffNavigationBarSimulator,
      badgeText: '4 CORE TABS',
      keyPoints: [
        'Queue: Live order dispatch board, preparation queue & status progression',
        'Walk-In POS: Register walk-in customers and log over-the-counter coffee sales',
        'Concierge: Shared customer messaging inbox with real-time AI handoff',
        'My Shift: Barista profile, station timer, assigned permissions & Help Guide',
      ],
      operationalRule: 'The Queue tab displays a live badge counter showing how many incoming orders require staff action.',
    ),

    // -------------------------------------------------------------------------
    // 3. Barista Operations Dashboard & Metrics
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_kpi_metrics',
      stepNumber: 3,
      category: StaffTutorialCategory.queue,
      title: 'Live Operational Queue Metrics',
      subtitle: 'Monitor workload across five operational states in real-time right at the top of the Queue screen.',
      highlightArea: 'Top Metric Chips (New, Preparing, Prepared, Ready, Handed Off)',
      icon: Icons.analytics_outlined,
      visualType: StaffTutorialVisualType.operationsKpiMetrics,
      badgeText: 'QUEUE METRICS',
      keyPoints: [
        'New (Warning): Placed or confirmed orders waiting for roasting/brewing to start',
        'Preparing (Amber): Orders currently being ground, roasted, or extracted',
        'Prepared (Amber Dark): Items packaged and labeled with roast date stamps',
        'Ready (Sage Green): Customer notified and waiting at the roastery counter',
        'Handed Off (Muted): Completed pickups settled during current shift',
      ],
      operationalRule: 'Aim to keep the "New" count below 3 by promptly claiming orders as soon as they arrive.',
      actionRoute: AppRoutes.staffOrders,
      actionLabel: 'View Queue',
    ),

    // -------------------------------------------------------------------------
    // 4. Status Filter Tabs & Queue Navigation
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_queue_filtering',
      stepNumber: 4,
      category: StaffTutorialCategory.queue,
      title: 'Filtering Orders by Status',
      subtitle: 'Use quick filter chips to isolate specific orders needing your attention right now.',
      highlightArea: 'Horizontal Status Filter Bar',
      icon: Icons.filter_list_rounded,
      visualType: StaffTutorialVisualType.statusFilterTabsDemo,
      badgeText: 'STATUS FILTERING',
      keyPoints: [
        'All: Shows the full ledger of roastery orders for the current business day',
        'New Tab: Shows only incoming orders requiring initial barista acceptance',
        'Preparing Tab: Focus purely on active brewing and bean weighing tasks',
        'Ready Tab: Rapidly check names and order numbers when customers arrive at the counter',
      ],
      operationalRule: 'Filter by "Ready" during rush hours to quickly match arriving pickup customers.',
    ),

    // -------------------------------------------------------------------------
    // 5. Order Card Inspection & Specifications
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_order_card_anatomy',
      stepNumber: 5,
      category: StaffTutorialCategory.queue,
      title: 'Order Card Anatomy & Details',
      subtitle: 'Each card displays vital pickup metadata, custom grind specifications, and special notes.',
      highlightArea: 'Order List Item & Specification Badges',
      icon: Icons.receipt_long_rounded,
      visualType: StaffTutorialVisualType.orderCardInspection,
      badgeText: 'ORDER ANATOMY',
      keyPoints: [
        'Order Number: Prominent reference (e.g. #LMB-8921) shown for customer matching',
        'Pickup Time Badge: Highlights scheduled pickup date and time slot (e.g. 3:30 PM)',
        'Item & Grind Variant: Displays selected bean size (250g/500g/1kg) and grind setting',
        'Special Notes: Customer brew preferences or packaging requests highlighted in gold',
        'Payment Badge: Clearly indicates whether the order is UNPAID or PAID at counter',
      ],
      operationalRule: 'Always verify the grind setting (Whole Bean vs V60 vs Espresso) before adjusting your commercial grinder.',
    ),

    // -------------------------------------------------------------------------
    // 6. Stage 1 — Accepting New Orders
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_stage_accept',
      stepNumber: 6,
      category: StaffTutorialCategory.preparation,
      title: 'Stage 1: Accepting & Queuing Orders',
      subtitle: 'Claim incoming orders and begin the preparation process when you are ready to roast or brew.',
      highlightArea: 'Action Button: "Start Preparing / Roasting"',
      icon: Icons.check_circle_outline_rounded,
      visualType: StaffTutorialVisualType.acceptOrderStep,
      badgeText: 'STAGE 1: ACCEPT',
      keyPoints: [
        'When an order arrives, it sits in "Order Placed" or "Confirmed" status',
        'Review the scheduled pickup time slot to prioritize urgent orders',
        'Tap "Start Preparing / Roasting" to claim the batch and transition status to Preparing',
        'The customer immediately sees that their micro-lot is being prepared',
      ],
      operationalRule: 'Do not accept more orders into "Preparing" than your current station capacity allows.',
    ),

    // -------------------------------------------------------------------------
    // 7. Stage 2 — Roasting & Grinding Calibration
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_stage_preparing',
      stepNumber: 7,
      category: StaffTutorialCategory.preparation,
      title: 'Stage 2: Precision Preparation & Grind',
      subtitle: 'Calibrate grinders, weigh micro-lots, and execute extraction according to recipe guidelines.',
      highlightArea: 'Preparation Active State',
      icon: Icons.local_fire_department_rounded,
      visualType: StaffTutorialVisualType.preparingRoastingStep,
      badgeText: 'STAGE 2: PREPARE',
      keyPoints: [
        'Weigh single-origin beans to the exact gram requested (250g, 500g, or 1kg)',
        'Set the Mahlkönig grinder: Fine (Espresso), Medium-Fine (V60), Coarse (French Press)',
        'For Whole Bean orders, inspect bean surface integrity and check degassing valve',
        'For brewed beverage orders, ensure brew water temperature is 92°C–94°C',
      ],
      operationalRule: 'Always purge 5g of beans when switching grind settings to avoid particulate contamination.',
    ),

    // -------------------------------------------------------------------------
    // 8. Stage 3 — Marking Prepared & Packaged
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_stage_prepared',
      stepNumber: 8,
      category: StaffTutorialCategory.preparation,
      title: 'Stage 3: Packaging & Roast Stamping',
      subtitle: 'Seal bags with freshness valves, stamp roast dates, and advance the order to Prepared.',
      highlightArea: 'Action Button: "Mark Prepared & Packaged"',
      icon: Icons.inventory_2_rounded,
      visualType: StaffTutorialVisualType.markPreparedStep,
      badgeText: 'STAGE 3: PACKAGE',
      keyPoints: [
        'Place sealed bean pouches or packaged items into official Lambac kraft bags',
        'Affix the roast batch tag and write the Order Number clearly on the bag label',
        'Tap "Mark Prepared & Packaged" to move the order into Prepared status',
        'Place the bag into the designated preparation holding rack',
      ],
      operationalRule: 'Never mark an order as "Prepared" before the bag is physically sealed and labeled.',
    ),

    // -------------------------------------------------------------------------
    // 9. Stage 4 — Ready for Pickup Notification
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_stage_ready',
      stepNumber: 9,
      category: StaffTutorialCategory.preparation,
      title: 'Stage 4: Ready for Pickup Notification',
      subtitle: 'Move completed items to the front counter and trigger the customer pickup notification.',
      highlightArea: 'Action Button: "Mark Ready for Pickup"',
      icon: Icons.notifications_active_rounded,
      visualType: StaffTutorialVisualType.readyForPickupStep,
      badgeText: 'STAGE 4: READY',
      keyPoints: [
        'Transfer the packaged order to the front Pickup Staging Counter',
        'Tap "Mark Ready for Pickup" — this instantly sends a notification to the customer',
        'The customer app updates with a bright green "Ready for Pickup" status banner',
        'The order is now queued for quick counter hand-off and payment verification',
      ],
      operationalRule: 'Only tap "Ready for Pickup" when the item is physically on the front pickup counter.',
    ),

    // -------------------------------------------------------------------------
    // 10. Stage 5 — Customer Hand-Off & Completion
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_stage_completed',
      stepNumber: 10,
      category: StaffTutorialCategory.preparation,
      title: 'Stage 5: Counter Hand-Off & Completed',
      subtitle: 'Verify customer identity, collect payment at counter, and mark the order as Completed.',
      highlightArea: 'Action Button: "Hand Off & Mark Completed"',
      icon: Icons.task_alt_rounded,
      visualType: StaffTutorialVisualType.handOffCompletedStep,
      badgeText: 'STAGE 5: COMPLETE',
      keyPoints: [
        'When customer arrives, ask for their Order Number (e.g. #LMB-8921) or Name',
        'Check payment status: If UNPAID, collect payment via Cash, GCash, or POS card',
        'Hand over the order and offer tasting notes advice',
        'Tap "Hand Off & Mark Completed" to finalize the transaction in the ledger',
      ],
      operationalRule: 'Never release an unpaid order without collecting counter payment first.',
    ),

    // -------------------------------------------------------------------------
    // 11. Real-Time Customer Synchronization
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_realtime_sync',
      stepNumber: 11,
      category: StaffTutorialCategory.pickup,
      title: 'Real-Time Sync & System Integrity',
      subtitle: 'Understand how every button tap instantly reflects across the customer app and backend.',
      highlightArea: 'Real-Time Dispatch Architecture',
      icon: Icons.sync_rounded,
      visualType: StaffTutorialVisualType.realtimeSyncExplanation,
      badgeText: 'INSTANT SYNC',
      keyPoints: [
        'Staff tap -> Server updates -> Customer phone updates immediately without delay',
        'Customers rely on status accuracy to plan their walk or drive to the flagship store',
        'Falsely marking orders ready results in customer arriving to unready coffee',
        'All status transitions are audited with staff timestamp records',
      ],
      operationalRule: 'Treat each status advance button as a verified factual statement of physical reality.',
    ),

    // -------------------------------------------------------------------------
    // 12. Pay-at-Counter Policy & Verification
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_pay_at_counter',
      stepNumber: 12,
      category: StaffTutorialCategory.pickup,
      title: 'Pay-at-Counter Workflow & Settlement',
      subtitle: 'Orders placed in the app are unpaid pickup orders. Payment is collected in-person.',
      highlightArea: 'Payment Status & POS Collection',
      icon: Icons.point_of_sale_rounded,
      visualType: StaffTutorialVisualType.payAtCounterSettlement,
      badgeText: 'PAY AT COUNTER',
      keyPoints: [
        'App orders are NOT prepaid online — they are placed for preparation and paid upon pickup',
        'Order Card shows "UNPAID (Pay at Counter)" until payment is received',
        'Accept payment via Roastery Cash Register, GCash / Maya QR, or Credit/Debit POS terminal',
        'Once payment is verified, complete the handoff and digital receipt confirmation',
      ],
      operationalRule: 'Placing an order is an intent to purchase. Always verify payment before letting the customer leave.',
    ),

    // -------------------------------------------------------------------------
    // 13. Walk-In Sales POS Ledger
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_walk_in_pos',
      stepNumber: 13,
      category: StaffTutorialCategory.pos,
      title: 'Walk-In Sales POS System',
      subtitle: 'Record over-the-counter walk-in sales for customers visiting the roastery in person.',
      highlightArea: 'Walk-In POS Tab & Record Sale Sheet',
      icon: Icons.shopping_cart_checkout_rounded,
      visualType: StaffTutorialVisualType.walkInPosDemo,
      badgeText: 'WALK-IN POS',
      keyPoints: [
        'Tap the "Walk-In POS" tab or the POS icon in the top bar to open the sales ledger',
        'Tap "Record Walk-In Sale" to open the item entry modal',
        'Select bean bag sizes (250g, 500g, 1kg), grind variants, and enter customer name',
        'Select payment method (Cash, GCash, Card) and submit to record the transaction',
      ],
      operationalRule: 'All walk-in transactions instantly log into the unified roastery revenue ledger.',
      actionRoute: AppRoutes.staffSales,
      actionLabel: 'Open Walk-In POS',
    ),

    // -------------------------------------------------------------------------
    // 14. Customer Concierge Shared Inbox
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_concierge_inbox',
      stepNumber: 14,
      category: StaffTutorialCategory.concierge,
      title: 'Customer Concierge Shared Inbox',
      subtitle: 'Answer customer brewing questions, grind inquiries, and pickup status checks in real-time.',
      highlightArea: 'Concierge Tab & Conversation Threads',
      icon: Icons.forum_rounded,
      visualType: StaffTutorialVisualType.conciergeSharedInbox,
      badgeText: 'SHARED INBOX',
      keyPoints: [
        'Shared Inbox: All baristas and managers have visibility into active customer threads',
        'Unread Badge: Green dot indicator shows when a customer sent a new question',
        'Customer Context: View customer name and active order number right in the chat header',
        'Persistent History: All advice and conversations are preserved for future reference',
      ],
      operationalRule: 'Maintain warm, respectful, Japanese-inspired hospitality in all customer chat interactions.',
      actionRoute: AppRoutes.staffInboxRoute,
      actionLabel: 'Open Concierge Inbox',
    ),

    // -------------------------------------------------------------------------
    // 15. AI Assistant Collaboration & Human Handoff
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_ai_handoff',
      stepNumber: 15,
      category: StaffTutorialCategory.concierge,
      title: 'AI Collaboration & Barista Takeover',
      subtitle: 'Our AI Assistant handles basic menu inquiries, freeing you to handle complex order requests.',
      highlightArea: 'AI + Human Hybrid Chat Model',
      icon: Icons.psychology_rounded,
      visualType: StaffTutorialVisualType.aiBaristaHandoffDemo,
      badgeText: 'AI + HUMAN',
      keyPoints: [
        'AI Assistant automatically answers questions about roast profiles, elevation, and store hours',
        'When a customer needs human barista assistance, the AI gracefully introduces the barista team',
        'You can seamlessly step in and send a message in the same conversation thread',
        'Your replies appear clearly marked as "Master Barista" with your authenticated staff name',
      ],
      operationalRule: 'Check the Concierge tab periodically for threads where the AI requested barista assistance.',
    ),

    // -------------------------------------------------------------------------
    // 16. Operational Alerts & Notifications
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_notifications',
      stepNumber: 16,
      category: StaffTutorialCategory.shift,
      title: 'Operational Alerts & Audio Notices',
      subtitle: 'Stay alerted to new orders, upcoming pickups, and customer messages during your shift.',
      highlightArea: 'Operational Sound & In-App Alerts',
      icon: Icons.notifications_active_rounded,
      visualType: StaffTutorialVisualType.operationalNotifications,
      badgeText: 'ACTIVE ALERTS',
      keyPoints: [
        'New Order Alert: Instant banner and sound chime when an online pickup order is placed',
        'Pickup Approaching: Reminder when an order scheduled for pickup is within 30 minutes',
        'Concierge Inquiries: Notification when a customer messages the roastery inbox',
        'Queue Refresh: Pull down anytime on the Queue screen to force-refresh order status',
      ],
      operationalRule: 'Keep your device volume audible on the barista bar to never miss a new order chime.',
    ),

    // -------------------------------------------------------------------------
    // 17. Staff Station Profile & Shift Control
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_profile_shift',
      stepNumber: 17,
      category: StaffTutorialCategory.shift,
      title: 'My Shift Station & Profile',
      subtitle: 'Review assigned operational permissions, toggle dark/light theme, and manage shift sign-out.',
      highlightArea: 'My Shift Screen',
      icon: Icons.badge_rounded,
      visualType: StaffTutorialVisualType.staffProfileStation,
      badgeText: 'MY SHIFT',
      keyPoints: [
        'Station Status: Shows active shift status and Flagship Roastery assignment',
        'Permissions: Lists your operational authorizations (Orders, POS, Concierge, Inventory)',
        'Appearance: Toggle Tokyo Night Dark or Linen Light mode for optimal ambient visibility',
        'End Shift: Secure sign-out when handing over the barista bar to the next shift',
      ],
      operationalRule: 'Always sign out at the end of your shift so the next barista logs in with their credentials.',
      actionRoute: AppRoutes.staffProfile,
      actionLabel: 'View My Shift',
    ),

    // -------------------------------------------------------------------------
    // 18. Replaying Staff Tutorial Anytime
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_help_replay',
      stepNumber: 18,
      category: StaffTutorialCategory.shift,
      title: 'Accessing Staff Help & Replaying Guide',
      subtitle: 'Need a refresher on order advancement or POS steps? Replay this guide anytime from My Shift.',
      highlightArea: 'My Shift → Help & Operations Guide',
      icon: Icons.help_outline_rounded,
      visualType: StaffTutorialVisualType.staffHelpReplayCard,
      badgeText: 'ALWAYS AVAILABLE',
      keyPoints: [
        'Navigate to My Shift → Help & Operations Guide anytime to review full workflows',
        'Browse topic-specific reference sheets for Queue, Preparation, POS, and Concierge',
        'Access Barista Standard Operating Procedure (SOP) quick reference guidelines',
        'Tutorial controls in this walkthrough are 100% sandboxed and will not execute real orders',
      ],
      operationalRule: 'New team members can review this interactive guide during onboarding training.',
    ),

    // -------------------------------------------------------------------------
    // 19. Barista Operational Safety Rules
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_safety_rules',
      stepNumber: 19,
      category: StaffTutorialCategory.shift,
      title: 'Standard Operating Quality Rules',
      subtitle: 'Core operational standards that maintain Lambac Coffee Roastery artisan excellence.',
      highlightArea: 'Barista Quality Standards',
      icon: Icons.verified_user_rounded,
      visualType: StaffTutorialVisualType.operationalSafetyRules,
      badgeText: 'QUALITY RULES',
      keyPoints: [
        '1. Grind Accuracy: Double-check bag grind selection before touching the Mahlkönig dial',
        '2. Roast Tagging: Ensure roast batch date label is clearly stamped on every bag',
        '3. Payment Before Hand-off: Confirm counter payment is settled for unpaid app orders',
        '4. Truth in Status: Only mark "Ready" when the coffee is physically at the counter',
      ],
      operationalRule: 'Our reputation rests on cup clarity and impeccable service timing.',
    ),

    // -------------------------------------------------------------------------
    // 20. Ready for Service Completion
    // -------------------------------------------------------------------------
    StaffTutorialStepModel(
      id: 'staff_completion',
      stepNumber: 20,
      category: StaffTutorialCategory.shift,
      title: 'You are Ready for Service',
      subtitle: 'You now know the complete Lambac Barista workflow. Have a fantastic shift!',
      highlightArea: 'Shift Launch & Queue Dispatch',
      icon: Icons.coffee_rounded,
      visualType: StaffTutorialVisualType.operationsWelcomeBanner,
      badgeText: 'SHIFT READY',
      keyPoints: [
        'You understand queue management, 5-stage order progression, and counter pickup',
        'You can record walk-in sales on the POS and answer concierge messages',
        'You can replay this tutorial anytime from My Shift → Help & Operations Guide',
      ],
      operationalRule: 'Tap "Start Working" to jump straight into the live Barista Operations Queue.',
    ),
  ];
}
