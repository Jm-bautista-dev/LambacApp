import 'package:flutter/material.dart';

/// Categories grouping the customer tutorial steps
enum TutorialCategory {
  welcome,
  navigation,
  menu,
  ordering,
  pickup,
  tracking,
  concierge,
  account;

  String get displayName {
    return switch (this) {
      TutorialCategory.welcome => 'Getting Started',
      TutorialCategory.navigation => 'App Navigation',
      TutorialCategory.menu => 'Menu & Roasts',
      TutorialCategory.ordering => 'Cart & Customization',
      TutorialCategory.pickup => 'Pickup & Payment',
      TutorialCategory.tracking => 'Order Lifecycle',
      TutorialCategory.concierge => 'Concierge & AI',
      TutorialCategory.account => 'Account & Rewards',
    };
  }

  IconData get icon {
    return switch (this) {
      TutorialCategory.welcome => Icons.auto_awesome_rounded,
      TutorialCategory.navigation => Icons.explore_outlined,
      TutorialCategory.menu => Icons.coffee_rounded,
      TutorialCategory.ordering => Icons.shopping_bag_outlined,
      TutorialCategory.pickup => Icons.storefront_rounded,
      TutorialCategory.tracking => Icons.receipt_long_rounded,
      TutorialCategory.concierge => Icons.forum_rounded,
      TutorialCategory.account => Icons.person_rounded,
    };
  }
}
