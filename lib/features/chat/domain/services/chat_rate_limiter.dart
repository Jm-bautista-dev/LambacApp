/// Sliding window rate limiter to protect AI endpoint from automated abuse & rapid flooding
class ChatRateLimiter {
  final int maxRequestsPerWindow;
  final Duration windowDuration;

  // customerId -> timestamps of recent requests
  final Map<String, List<DateTime>> _requestLogs = {};

  ChatRateLimiter({
    this.maxRequestsPerWindow = 5,
    this.windowDuration = const Duration(seconds: 60),
  });

  /// Checks if customer request is allowed or rate limited
  bool isAllowed(String customerId) {
    if (customerId.isEmpty) return true;

    final now = DateTime.now();
    final cutoff = now.subtract(windowDuration);

    final timestamps = _requestLogs.putIfAbsent(customerId, () => []);
    // Prune expired timestamps
    timestamps.removeWhere((t) => t.isBefore(cutoff));

    if (timestamps.length >= maxRequestsPerWindow) {
      return false;
    }

    timestamps.add(now);
    return true;
  }

  /// Resets all logs (used in test isolation)
  void reset() {
    _requestLogs.clear();
  }
}
