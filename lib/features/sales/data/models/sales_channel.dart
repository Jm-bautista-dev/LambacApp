/// Sales Channel Enum distinguishing transaction origin across POS and Mobile App
enum SalesChannel {
  mobileApp,
  walkIn;

  /// Canonical database value for persistence and indexing
  String get canonicalKey {
    return switch (this) {
      SalesChannel.mobileApp => 'MOBILE_APP_PICKUP',
      SalesChannel.walkIn => 'WALK_IN',
    };
  }

  String get displayName {
    return switch (this) {
      SalesChannel.mobileApp => 'Mobile App Pickup',
      SalesChannel.walkIn => 'Walk-In Store (POS)',
    };
  }

  String get badgeText {
    return switch (this) {
      SalesChannel.mobileApp => 'MOBILE APP PICKUP',
      SalesChannel.walkIn => 'WALK-IN POS',
    };
  }

  static SalesChannel fromString(String? val) {
    final clean = val?.toLowerCase().trim();
    return switch (clean) {
      'walk_in' || 'walkin' || 'walk-in' || 'pos' => SalesChannel.walkIn,
      'mobile_app_pickup' || 'mobile_app' || 'mobileapp' || 'mobile' => SalesChannel.mobileApp,
      _ => SalesChannel.mobileApp,
    };
  }
}
