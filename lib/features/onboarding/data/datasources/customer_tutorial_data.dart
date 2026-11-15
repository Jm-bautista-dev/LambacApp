import 'package:flutter/material.dart';
import '../../../../core/routing/app_routes.dart';
import '../models/tutorial_category.dart';
import '../models/tutorial_step_model.dart';

/// Curated, production-ready tutorial catalog built exclusively around
/// actual implemented customer features in the Lambac Coffee Roastery app.
class CustomerTutorialData {
  CustomerTutorialData._();

  static const List<TutorialStepModel> steps = [
    // -------------------------------------------------------------------------
    // 1. Welcome & Roastery Identity
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'welcome_identity',
      stepNumber: 1,
      category: TutorialCategory.welcome,
      title: 'Welcome to Lambac Coffee Roastery',
      subtitle: 'Experience ethically sourced single-origin micro-lots roasted with precision and Japanese craftsmanship.',
      highlightArea: 'Welcome & Roastery Philosophy',
      icon: Icons.local_fire_department_rounded,
      visualType: TutorialVisualType.welcomeBanner,
      badgeText: 'ARTISAN ROASTERY',
      keyPoints: [
        'Direct-trade single-origin specialty beans from Mount Apo and world heritage farms',
        'Weekly small-batch roasting to honor natural terroir and peak sweetness',
        'Crafted for coffee enthusiasts who appreciate fine cup profiles and mindful brewing',
      ],
      practicalTip: 'Take a moment with this interactive guide to discover everything you can do in the Lambac app.',
    ),

    // -------------------------------------------------------------------------
    // 2. Guest Browsing vs Customer Account
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'guest_auth_model',
      stepNumber: 2,
      category: TutorialCategory.welcome,
      title: 'Guest Browsing & Member Accounts',
      subtitle: 'You can freely explore our roastery catalog as a guest without creating an account first.',
      highlightArea: 'Authentication & Guest Mode',
      icon: Icons.person_pin_circle_outlined,
      visualType: TutorialVisualType.guestAuthCard,
      badgeText: 'GUEST FRIENDLY',
      keyPoints: [
        'Explore menu, tasting notes, roast profiles, and prices without signing in',
        'An account is required only when you are ready to add to cart, schedule pickup, or chat',
        'Members earn Coffee Beans reward points and save their custom brewing preferences',
      ],
      practicalTip: 'If you browse as a guest and tap Add to Cart, we will gently prompt you to sign in or register in seconds.',
      actionRoute: AppRoutes.login,
      actionLabel: 'Sign In / Register',
    ),

    // -------------------------------------------------------------------------
    // 3. Customer Navigation Structure
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'app_navigation',
      stepNumber: 3,
      category: TutorialCategory.navigation,
      title: 'Customer Navigation Structure',
      subtitle: 'Effortlessly switch between your coffee home, catalog, pickup cart, live orders, and profile.',
      highlightArea: 'Bottom Navigation Bar (5 Core Tabs)',
      icon: Icons.tab_rounded,
      visualType: TutorialVisualType.navigationBarSimulator,
      badgeText: '5 CORE TABS',
      keyPoints: [
        'Home: Daily roastery greeting, featured harvest, quick shortcuts & stories',
        'Roastery: Full specialty coffee catalog, category filters & origin search',
        'Cart: Curated pickup items, custom grind settings & checkout',
        'Orders: Active pickup tracking, live status progression & receipts',
        'Profile: Member tier, loyalty beans points, preferences & Help Center',
      ],
      practicalTip: 'The Cart icon displays a live badge counter whenever items are waiting in your pickup cart.',
    ),

    // -------------------------------------------------------------------------
    // 4. Home Screen & Daily Editorial
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'home_experience',
      stepNumber: 4,
      category: TutorialCategory.navigation,
      title: 'Home Experience & Shortcuts',
      subtitle: 'Your daily coffee dashboard with time-based greetings, theme switching, and quick actions.',
      highlightArea: 'Home Screen Top Bar & Quick Actions',
      icon: Icons.home_rounded,
      visualType: TutorialVisualType.homeEditorialHeader,
      badgeText: 'DAILY DASHBOARD',
      keyPoints: [
        'Greeting: Time-of-day greetings (Ohayō, Konnichiwa, Konbanwa) personalized to you',
        'Theme Switcher: One-tap toggle between Warm Linen Light and Tokyo Night Dark mode',
        'Notification Bell: Instant alerts for order progress and fresh roast drops',
        'Quick Shortcuts: 1-tap buttons for Pickup Order, Barista Chat, and Track Orders',
      ],
      practicalTip: 'Tap the circular avatar in the top-left anytime to jump straight to your member profile.',
      actionRoute: AppRoutes.home,
      actionLabel: 'View Home Screen',
    ),

    // -------------------------------------------------------------------------
    // 5. Menu & Micro-Lot Catalog
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'menu_catalog',
      stepNumber: 5,
      category: TutorialCategory.menu,
      title: 'Browse Menu & Micro-Lots',
      subtitle: 'Filter our current roastery catalog by coffee origin, harvest categories, and roast profiles.',
      highlightArea: 'Roastery Menu & Category Filter Chips',
      icon: Icons.coffee_rounded,
      visualType: TutorialVisualType.productCatalogCard,
      badgeText: 'SPECIALTY CATALOG',
      keyPoints: [
        'Categories: Filter between Single-Origin Micro-Lots, Espresso Blends, and Pour-over Beans',
        'Search Bar: Search instantly by origin (e.g., Mount Apo, Ethiopia), roast level, or flavor note',
        'Live Badges: See Roast Level (Light, Medium, Dark) and real-time stock availability badges',
        'Favorites: Tap the heart icon on any card to save your favorite roasts for quick reordering',
      ],
      practicalTip: 'All product details and stock statuses reflect the active Lambac roastery inventory.',
      actionRoute: AppRoutes.products,
      actionLabel: 'Browse Roastery Menu',
    ),

    // -------------------------------------------------------------------------
    // 6. Product Details & Sensory Terroir
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'product_details',
      stepNumber: 6,
      category: TutorialCategory.menu,
      title: 'Sensory Terroir & Coffee Details',
      subtitle: 'Explore deep technical specifications and tasting notes for every single micro-batch.',
      highlightArea: 'Product Detail Screen',
      icon: Icons.auto_awesome_rounded,
      visualType: TutorialVisualType.productSensoryDetails,
      badgeText: 'SENSORY PROFILE',
      keyPoints: [
        'Tasting Notes: Curated cup notes like wild raspberry, dark honey, cacao nibs, or jasmine',
        'Farm Terroir: View exact Elevation (e.g., 1,500 MASL), Process (Anaerobic Honey, Washed), and Varietals',
        'Roastery Terroir Story: Discover the heritage and craftsmanship behind each micro-lot',
        'Verified Ratings: Community reviews and customer feedback from verified brew lovers',
      ],
      practicalTip: 'Knowing the processing method (e.g. Anaerobic Honey) helps predict the natural sweetness and body.',
    ),

    // -------------------------------------------------------------------------
    // 7. Customizations & Grind Settings
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'customizations_grind',
      stepNumber: 7,
      category: TutorialCategory.ordering,
      title: 'Bag Size & Grind Customization',
      subtitle: 'Tailor each coffee bean order with your preferred bag size and brewing grind size.',
      highlightArea: 'Product Detail Customizer',
      icon: Icons.tune_rounded,
      visualType: TutorialVisualType.sizeGrindCustomizer,
      badgeText: 'PRECISION BREWING',
      keyPoints: [
        'Bag Sizes: Choose from 250g Standard Bag, 500g Value Pack, or 1kg Roastery Reserve',
        'Transparent Pricing: Size upgrades show the exact price delta (+₱0, +₱420, +₱900)',
        'Grind Settings: Whole Bean (recommended for fresh grinding), Espresso, V60 Pourover, French Press, or Cold Brew',
        'Barista Calibration: Our commercial Mahlkönig grinders ensure uniform particle distribution',
      ],
      practicalTip: 'If in doubt about your brew method, choose Whole Bean or ask our Barista Concierge in chat.',
    ),

    // -------------------------------------------------------------------------
    // 8. Adding to Cart & Guest Auth Flow
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'add_to_cart_flow',
      stepNumber: 8,
      category: TutorialCategory.ordering,
      title: 'Adding Products to Cart',
      subtitle: 'Adjust your quantity and add items with instant feedback and smart session memory.',
      highlightArea: 'Bottom Sticky Action Bar',
      icon: Icons.add_shopping_cart_rounded,
      visualType: TutorialVisualType.cartManagementDemo,
      badgeText: 'SMART CART',
      keyPoints: [
        'Quantity Selector: Increment or decrement bags with one tap before adding',
        'Dynamic Total: The bottom bar updates the exact total price including size deltas in real-time',
        'Instant Toast Feedback: Confirmation alert with a direct 1-tap link to "View Cart"',
        'Guest Seamless Flow: If browsing as a guest, we save your selected item and resume right after login',
      ],
      practicalTip: 'You can adjust quantities or remove items anytime before finalizing pickup checkout.',
    ),

    // -------------------------------------------------------------------------
    // 9. Shopping Cart Management
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'cart_management',
      stepNumber: 9,
      category: TutorialCategory.ordering,
      title: 'Managing Your Cart',
      subtitle: 'Review your selected micro-lots, verify grind variants, and check order subtotals.',
      highlightArea: 'Cart Screen',
      icon: Icons.shopping_bag_outlined,
      visualType: TutorialVisualType.cartManagementDemo,
      badgeText: 'REVIEW & EDIT',
      keyPoints: [
        'Item Breakdown: See item thumbnail, roast name, selected bag size, and grind option',
        'Quantity Controls: Increase or decrease items directly within the cart list',
        'Item Removal: Swipe or tap delete to remove any unneeded items',
        'Clear Cart: Convenient top button to start fresh whenever desired',
      ],
      practicalTip: 'Check that your grind selection matches your home brewing equipment before continuing to checkout.',
      actionRoute: AppRoutes.cart,
      actionLabel: 'Open Cart',
    ),

    // -------------------------------------------------------------------------
    // 10. Pickup-Only Coffee Model
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'pickup_only_model',
      stepNumber: 10,
      category: TutorialCategory.pickup,
      title: 'Pickup-Only Ordering Model',
      subtitle: 'Lambac orders are crafted exclusively for roastery counter pickup with zero wait time.',
      highlightArea: 'Pickup Notice & Flagship Roastery',
      icon: Icons.storefront_rounded,
      visualType: TutorialVisualType.pickupOnlyModel,
      badgeText: 'FRESH PICKUP',
      keyPoints: [
        'No Third-Party Couriers: Orders are packaged or brewed on-demand for maximum bean freshness',
        'Flagship Location: Collect your order at Lambac Coffee Roastery Flagship, BGC / Makati',
        'Zero Waiting: Arrive at your scheduled time and your order will be bagged and ready',
        'Barista Interaction: Meet the roasters, discuss tasting notes, and inspect roast dates',
      ],
      practicalTip: 'Because coffee stales quickly after brewing, scheduling your exact pickup ensures peak flavor.',
    ),

    // -------------------------------------------------------------------------
    // 11. Smart Pickup Scheduling
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'pickup_scheduling',
      stepNumber: 11,
      category: TutorialCategory.pickup,
      title: 'Scheduling Your Pickup Time',
      subtitle: 'Choose convenient preset prep intervals or customize your specific pickup date and time.',
      highlightArea: 'Checkout Pickup Scheduler Widget',
      icon: Icons.schedule_rounded,
      visualType: TutorialVisualType.pickupSchedulerDemo,
      badgeText: 'SMART PRESETS',
      keyPoints: [
        'Quick Presets: +1 Hour (Quick Prep), +3 Hours (Afternoon Slot), +5 Hours (Evening Slot)',
        'Custom Date & Time: Select upcoming days and choose 30-minute time slots',
        'Operating Hours: Validated against store hours (7:00 AM – 9:00 PM daily)',
        'Preparation Buffer: The app enforces a minimum 45-minute preparation lead time for quality',
      ],
      practicalTip: 'Closed hours and past time slots are automatically disabled so your order is never late.',
    ),

    // -------------------------------------------------------------------------
    // 12. Pay at Counter Policy
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'pay_at_counter',
      stepNumber: 12,
      category: TutorialCategory.pickup,
      title: 'Payment at Roastery Counter',
      subtitle: 'No online payment required. Place your order and pay in-person upon pickup collection.',
      highlightArea: 'Checkout Payment Section',
      icon: Icons.point_of_sale_rounded,
      visualType: TutorialVisualType.payAtCounterBadge,
      badgeText: 'PAY AT COUNTER',
      keyPoints: [
        'Zero Online Charges: Placed orders are prepared for pickup without upfront digital payment',
        'Payment Methods: Cash, GCash / Maya QR, Debit, or Credit cards accepted at the counter',
        'Unpaid vs Paid Status: Orders remain marked as "UNPAID" until settled with staff upon collection',
        'Inspection First: You can verify your roasted beans and bag seals before making payment',
      ],
      practicalTip: 'Submitting an order confirms your preparation slot. Simply pay when you arrive to claim it.',
    ),

    // -------------------------------------------------------------------------
    // 13. Order Lifecycle: 6 Status Stages
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'order_lifecycle',
      stepNumber: 13,
      category: TutorialCategory.tracking,
      title: 'Order Status Lifecycle',
      subtitle: 'Follow your coffee through every step from order placement to barista packing and pickup.',
      highlightArea: 'Order Tracking Screen & Status Stepper',
      icon: Icons.timeline_rounded,
      visualType: TutorialVisualType.orderStatusTracker,
      badgeText: '6-STEP TRACKER',
      keyPoints: [
        '1. Order Placed: Received by roastery dispatch system',
        '2. Confirmed: Barista accepted order and queued batch',
        '3. Preparing: Micro-lot beans being weighed, ground, or brewed',
        '4. Prepared: Order packaged and sealed with roast date label',
        '5. Ready for Pickup: Waiting for you at the counter — arrive now!',
        '6. Completed: Picked up and paid at the counter',
      ],
      practicalTip: 'You will receive a notification the moment your status advances to "Ready for Pickup".',
      actionRoute: AppRoutes.orders,
      actionLabel: 'View Orders',
    ),

    // -------------------------------------------------------------------------
    // 14. Real-Time Order Tracking & Receipts
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'order_tracking_receipts',
      stepNumber: 14,
      category: TutorialCategory.tracking,
      title: 'Live Tracking & Digital Receipts',
      subtitle: 'Monitor preparation progress in real-time and access itemized thermal receipts anytime.',
      highlightArea: 'Order Detail Screen & Thermal Receipt View',
      icon: Icons.receipt_long_rounded,
      visualType: TutorialVisualType.realtimeReceiptView,
      badgeText: 'LIVE PROGRESS',
      keyPoints: [
        'Live Animated Progress Bar: Clear visual stepper showing current preparation phase',
        'Pickup Schedule Badge: Highlights your scheduled date, time slot, and roastery address',
        'Special Notes: Shows any custom instructions you provided during checkout',
        'Thermal Receipt: View and download your official Lambac coffee receipt with QR code',
      ],
      practicalTip: 'Show your Order Number (e.g., #LMB-8921) to our counter staff for instant pickup.',
    ),

    // -------------------------------------------------------------------------
    // 15. Notification Center & Alerts
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'notification_center',
      stepNumber: 15,
      category: TutorialCategory.tracking,
      title: 'Roastery Notifications & Alerts',
      subtitle: 'Stay informed with order status changes, pickup readiness reminders, and fresh roast alerts.',
      highlightArea: 'Notification Center Sheet (Bell Icon)',
      icon: Icons.notifications_active_rounded,
      visualType: TutorialVisualType.notificationCenterAlert,
      badgeText: 'STAY INFORMED',
      keyPoints: [
        'Header Badge: Red dot indicator on the home bell icon shows unread roastery updates',
        'Order Alerts: Real-time notices when your order is accepted, prepared, and ready',
        'Pickup Reminders: Gentle notification 30 minutes before your scheduled pickup window',
        'Preferences: Customize which alerts you receive in Notification Preferences',
      ],
      practicalTip: 'Tap any notification in the sheet to jump straight to the relevant order or conversation.',
    ),

    // -------------------------------------------------------------------------
    // 16. Roastery Concierge 1-on-1 Chat
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'barista_concierge_chat',
      stepNumber: 16,
      category: TutorialCategory.concierge,
      title: 'Direct Roastery Concierge Chat',
      subtitle: 'Connect 1-on-1 with our master baristas for custom brewing advice, roast dates, and orders.',
      highlightArea: 'Concierge Chat Screen',
      icon: Icons.forum_rounded,
      visualType: TutorialVisualType.conciergeChatDemo,
      badgeText: '1-ON-1 CONCIERGE',
      keyPoints: [
        'Direct Messaging: Talk directly with knowledgeable roastery staff and baristas',
        'Brewing Advice: Ask for recommended water temperature, grind size, or pour-over ratios',
        'Quick Inquiry Chips: 1-tap prompts for grind advice, roast dates, and single-origin pairings',
        'Persistent History: Your conversation thread is saved securely and never vanishes',
      ],
      practicalTip: 'Feel free to ask our baristas what fresh micro-lots just arrived from Mount Apo this week.',
      actionRoute: AppRoutes.chat,
      actionLabel: 'Open Concierge Chat',
    ),

    // -------------------------------------------------------------------------
    // 17. AI Customer Service Assistant
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'ai_customer_assistant',
      stepNumber: 17,
      category: TutorialCategory.concierge,
      title: 'Lambac AI Coffee Assistant',
      subtitle: 'Get instant, verified answers to questions about our menu, roast profiles, and store policies.',
      highlightArea: 'Chat AI Integration & Guardrails',
      icon: Icons.psychology_rounded,
      visualType: TutorialVisualType.aiAssistantDemo,
      badgeText: 'AI COFFEE GUIDE',
      keyPoints: [
        'Instant Answers: Ask about flavor notes, varietal origins, decaf options, and brewing tips',
        'Pickup & Store Info: Quickly check roastery hours, pickup guidelines, and order policies',
        'Strict Guardrails: The AI is specialized strictly for Lambac Coffee and avoids hallucinations',
        'Human Barista Handoff: For complex order changes, the AI seamlessly routes to our barista team',
      ],
      practicalTip: 'The AI assistant is designed specifically for Lambac Coffee questions.',
    ),

    // -------------------------------------------------------------------------
    // 18. Customer Reviews & Ratings
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'reviews_and_ratings',
      stepNumber: 18,
      category: TutorialCategory.account,
      title: 'Micro-Lot Reviews & Ratings',
      subtitle: 'Share your brewing experience and read honest tasting notes from fellow coffee enthusiasts.',
      highlightArea: 'Product Reviews Section & Review Sheet',
      icon: Icons.star_rate_rounded,
      visualType: TutorialVisualType.reviewsRatingCard,
      badgeText: 'COMMUNITY TASTING',
      keyPoints: [
        'Star Ratings: Rate any micro-lot from 1 to 5 stars based on cup clarity and sweetness',
        'Brewing Method: Tag the equipment you used (e.g., V60, Aeropress, Espresso, French Press)',
        'Tasting Impressions: Describe the aroma, acidity, body, and finish you experienced',
        'Community Transparency: Browse genuine ratings from other Lambac coffee members',
      ],
      practicalTip: 'Reviews help fellow coffee lovers find the ideal micro-lot for their morning ritual.',
    ),

    // -------------------------------------------------------------------------
    // 19. Member Profile & Loyalty Beans
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'member_profile_rewards',
      stepNumber: 19,
      category: TutorialCategory.account,
      title: 'Member Profile & Loyalty Beans',
      subtitle: 'Track your Coffee Beans rewards, customize brewing preferences, and manage security.',
      highlightArea: 'Profile Screen',
      icon: Icons.workspace_premium_rounded,
      visualType: TutorialVisualType.memberLoyaltyCard,
      badgeText: 'REWARDS & TIER',
      keyPoints: [
        'Coffee Beans Points: Earn beans points with every pickup order to unlock tier rewards',
        'Taste Preferences: Select your preferred roast (Light, Medium) and brew styles (V60, Pourover)',
        'Edit Profile & Security: Update your name, mobile phone number, and account password',
        'Theme & Settings: Toggle dark/light appearance and review terms and build information',
      ],
      practicalTip: 'Keep your mobile number updated in profile so baristas can SMS you if a pickup is ready.',
      actionRoute: AppRoutes.profile,
      actionLabel: 'View Member Profile',
    ),

    // -------------------------------------------------------------------------
    // 20. Replaying & Help Center Access
    // -------------------------------------------------------------------------
    TutorialStepModel(
      id: 'help_replay_access',
      stepNumber: 20,
      category: TutorialCategory.account,
      title: 'Access Help & Replay Guide Anytime',
      subtitle: 'Need a refresher later? You can replay this interactive tutorial anytime from your profile.',
      highlightArea: 'Profile → Help & Guide Hub',
      icon: Icons.help_outline_rounded,
      visualType: TutorialVisualType.helpReplayCard,
      badgeText: 'ALWAYS AVAILABLE',
      keyPoints: [
        'Profile Access: Navigate to Profile → Help & Guide to reopen this complete walkthrough',
        'Settings Access: Also accessible from Settings → Customer Guide & Tutorial',
        'Feature Guides: Browse quick reference sheets for Pickup, Customizations, and Chat',
        'Concierge Support: Tap the chat icon in Help & Guide to speak with our roastery team',
      ],
      practicalTip: 'You now know your way around Lambac! Tap "Start Exploring" to browse fresh roasts.',
    ),
  ];
}
