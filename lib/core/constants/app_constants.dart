/// Global Application Constants
class AppConstants {
  AppConstants._();

  // App Identity
  static const String appName = 'Lambac Coffee Roastery';
  static const String appTagline = 'Artisan Japanese-Inspired Roastery';
  static const String defaultCurrency = '₱';
  static const String currencyCode = 'PHP';

  // Terms & Conditions Versioning
  static const String currentTermsVersion = '1.0.0';
  static const String termsEffectiveDate = 'October 2026';

  // Storage Keys
  static const String tokenKey = 'lambac_auth_token';
  static const String refreshTokenKey = 'lambac_refresh_token';
  static const String userIdKey = 'lambac_user_id';
  static const String userDataKey = 'lambac_user_data';
  static const String themeModeKey = 'lambac_theme_mode';
  static const String onboardingSeenKey = 'lambac_onboarding_seen';
  static const String customerTutorialCompletedKey = 'lambac_customer_tutorial_completed_v1';
  static const String customerTutorialVersionKey = 'lambac_customer_tutorial_version';
  static const String customerTutorialCompletedAtKey = 'lambac_customer_tutorial_completed_at';
  static const String staffTutorialCompletedKey = 'lambac_staff_tutorial_completed_v1';
  static const String staffTutorialVersionKey = 'lambac_staff_tutorial_version';
  static const String staffTutorialCompletedAtKey = 'lambac_staff_tutorial_completed_at';
  static const String adminTutorialCompletedKey = 'lambac_admin_tutorial_completed_v1';
  static const String adminTutorialVersionKey = 'lambac_admin_tutorial_version';
  static const String adminTutorialCompletedAtKey = 'lambac_admin_tutorial_completed_at';

  // Pagination & Lists
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Animation & Debounce Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration debounceDuration = Duration(milliseconds: 400);

  // Layout & Touch Targets
  static const double minTouchTargetSize = 48.0;
  static const double maxContentWidth = 600.0;
}
