import 'package:flutter/material.dart';
import '../models/spotlight_step_model.dart';
import '../../presentation/spotlight/spotlight_keys.dart';

/// Curated, production-ready Customer Spotlight steps built strictly around
/// the actual implemented customer interface widgets in the Lambac Coffee Roastery app.
class CustomerSpotlightData {
  CustomerSpotlightData._();

  static List<SpotlightStepModel> get steps => [
        // ---------------------------------------------------------------------
        // STEP 1 — Home & Daily Dashboard
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_home_header',
          stepNumber: 1,
          categoryTitle: 'HOME & DASHBOARD',
          title: 'Home & Daily Roastery Greeting',
          description:
              'Your everyday coffee ritual starts here. Enjoy personalized morning and evening greetings, track member status, and toggle dark/light roastery aesthetics.',
          targetKey: SpotlightKeys.homeHeader,
          icon: Icons.wb_sunny_outlined,
          shape: SpotlightShape.roundedRect,
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          preferredPosition: TooltipPosition.below,
          targetBranchIndex: 0,
          keyPoints: [
            'Time-based Japanese greetings (Ohayō, Konnichiwa, Konbanwa)',
            'Quick one-tap access to your member profile and theme switch',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 2 — Roastery Notifications
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_notifications',
          stepNumber: 2,
          categoryTitle: 'NOTIFICATIONS',
          title: 'Roastery Alerts & Readiness',
          description:
              'Stay up to date with real-time push alerts the moment your beans or pourovers are ready at the counter, plus announcements for limited micro-lot drops.',
          targetKey: SpotlightKeys.homeNotifications,
          icon: Icons.notifications_active_rounded,
          shape: SpotlightShape.circle,
          borderRadius: 22,
          padding: const EdgeInsets.all(6),
          preferredPosition: TooltipPosition.below,
          targetBranchIndex: 0,
          keyPoints: [
            'Red badge indicator displays unread order updates and announcements',
            'Tap anytime to open the Notification Center Sheet',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 3 — Search Bar
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_search',
          stepNumber: 3,
          categoryTitle: 'SEARCH & DISCOVERY',
          title: 'Terroir Search & Flavor Finder',
          description:
              'Instantly find your ideal cup by searching single-origin farms, processing methods (washed, honey, anaerobic), elevation, or cupping notes.',
          targetKey: SpotlightKeys.homeSearch,
          icon: Icons.search_rounded,
          shape: SpotlightShape.roundedRect,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          preferredPosition: TooltipPosition.below,
          targetBranchIndex: 0,
          keyPoints: [
            'Type tasting notes like "raspberry", "cacao", or "honey"',
            'Search origins from Mount Apo to Ethiopian heirloom estates',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 4 — Roast & Origin Category Filters
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_categories',
          stepNumber: 4,
          categoryTitle: 'CATEGORY FILTERS',
          title: 'Origin & Roast Category Filters',
          description:
              'Filter our specialty selections by harvest category and roast profile. Switch seamlessly between Light-Medium Roasts, Espresso Blends, and Single-Origin micro-lots.',
          targetKey: SpotlightKeys.homeCategories,
          icon: Icons.coffee_rounded,
          shape: SpotlightShape.roundedRect,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          preferredPosition: TooltipPosition.below,
          targetBranchIndex: 0,
          keyPoints: [
            'Instant horizontal filter chips for fast menu navigation',
            'Highlights active harvests with live origin badges',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 5 — Roastery Craftsmanship Hero Banner
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_hero_banner',
          stepNumber: 5,
          categoryTitle: 'ARTISAN ROASTERY',
          title: 'Artisan Roasting Philosophy',
          description:
              'Lambac roasts in weekly micro-batches in Baguio City, honoring direct-trade relationships and preserving peak natural sweetness in every bean.',
          targetKey: SpotlightKeys.homeHeroBanner,
          icon: Icons.local_fire_department_rounded,
          shape: SpotlightShape.roundedRect,
          borderRadius: 22,
          padding: const EdgeInsets.all(8),
          preferredPosition: TooltipPosition.below,
          targetBranchIndex: 0,
          keyPoints: [
            'Ethically sourced Philippine highland and international origins',
            'Roasted to order for peak floral clarity and cupping score',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 6 — Counter Pickup & Rapid Scheduling
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_quick_pickup',
          stepNumber: 6,
          categoryTitle: 'PICKUP ORDERING',
          title: 'Counter Pickup & Scheduling',
          description:
              'Lambac is 100% focused on freshly prepared roastery counter pickup with zero delivery fees. Select rapid 1h/3h/5h prep presets and pay in-person upon collection.',
          targetKey: SpotlightKeys.homeQuickPickup,
          icon: Icons.takeout_dining_rounded,
          shape: SpotlightShape.roundedRect,
          borderRadius: 18,
          padding: const EdgeInsets.all(8),
          preferredPosition: TooltipPosition.below,
          targetBranchIndex: 0,
          keyPoints: [
            'Select rapid presets (+1h, +3h, +5h) or pick a scheduled date/time',
            'Zero delivery markups; pay at counter via Cash, GCash/Maya, or Card',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 7 — Barista Concierge & AI Assistant
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_barista_chat',
          stepNumber: 7,
          categoryTitle: '1-ON-1 CONCIERGE',
          title: 'Barista Concierge & AI Assistant',
          description:
              'Chat directly with our master baristas for custom grind recommendations, brewing water ratios, and roast dates, or ask the AI assistant store FAQs.',
          targetKey: SpotlightKeys.homeQuickChat,
          icon: Icons.chat_bubble_outline_rounded,
          shape: SpotlightShape.roundedRect,
          borderRadius: 18,
          padding: const EdgeInsets.all(8),
          preferredPosition: TooltipPosition.below,
          targetBranchIndex: 0,
          keyPoints: [
            'Direct messaging with roastery baristas during store hours',
            'Instant 24/7 AI answers for store hours, origin info, and policies',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 8 — Live 6-Stage Order Tracker
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_order_tracking',
          stepNumber: 8,
          categoryTitle: '6-STAGE TRACKER',
          title: 'Live 6-Stage Order Tracking',
          description:
              'Follow your order in real-time as it advances through Placed, Confirmed, Preparing, Prepared, Ready for Pickup, and Completed with digital thermal receipts.',
          targetKey: SpotlightKeys.homeQuickTrack,
          icon: Icons.receipt_long_outlined,
          shape: SpotlightShape.roundedRect,
          borderRadius: 18,
          padding: const EdgeInsets.all(8),
          preferredPosition: TooltipPosition.below,
          targetBranchIndex: 0,
          keyPoints: [
            'Live status updates with estimated counter readiness time',
            'Review itemized digital receipts with full roast and grind specs',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 9 — Featured Harvests, Grind Options & Favorites
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_featured_harvests',
          stepNumber: 9,
          categoryTitle: 'SENSORY DETAILS',
          title: 'Sensory Profiles & Custom Grind',
          description:
              'Tap any micro-lot to inspect deep tasting notes and MASL elevation. Choose Whole Bean or calibrated grinds (Espresso, V60, French Press) and tap the heart to save favorites.',
          targetKey: SpotlightKeys.homeFirstProductCard,
          icon: Icons.auto_awesome_rounded,
          shape: SpotlightShape.roundedRect,
          borderRadius: 20,
          padding: const EdgeInsets.all(6),
          preferredPosition: TooltipPosition.above,
          scrollTargetIntoView: true,
          targetBranchIndex: 0,
          keyPoints: [
            'Select precision grind styles calibrated for your home brew setup',
            'Tap the heart icon to save favorite roasts to your member profile',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 10 — Pickup Cart & Guest Checkout
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_cart',
          stepNumber: 10,
          categoryTitle: 'PICKUP CART',
          title: 'Your Pickup Cart & Checkout',
          description:
              'Review your selected bags, adjust grind variants, and check order subtotals. Feel free to explore as a guest; simple sign-in is prompted when placing an order.',
          targetKey: SpotlightKeys.navCart,
          icon: Icons.shopping_bag_outlined,
          shape: SpotlightShape.roundedRect,
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          preferredPosition: TooltipPosition.above,
          targetBranchIndex: 0,
          keyPoints: [
            'Live badge counter displays items waiting in your pickup cart',
            'Guest browsing is 100% free; sign in only when you are ready to order',
          ],
        ),

        // ---------------------------------------------------------------------
        // STEP 11 — Member Profile, Loyalty & Reviews
        // ---------------------------------------------------------------------
        SpotlightStepModel(
          id: 'spotlight_profile',
          stepNumber: 11,
          categoryTitle: 'MEMBER ACCOUNT',
          title: 'Profile, Loyalty Beans & Reviews',
          description:
              'Earn Coffee Beans reward points on pickups, review your past orders, submit 5-star ratings and reviews on tasted coffees, and replay this guide anytime.',
          targetKey: SpotlightKeys.navProfile,
          icon: Icons.person_rounded,
          shape: SpotlightShape.roundedRect,
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          preferredPosition: TooltipPosition.above,
          targetBranchIndex: 0,
          keyPoints: [
            'Earn loyalty points towards exclusive micro-lot roasts',
            'Rate and review tried beans, or replay this tour from Help & Guide',
          ],
        ),
      ];
}
