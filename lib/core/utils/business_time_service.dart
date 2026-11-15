import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Representation of an authoritative Asia/Manila business date range
class ManilaDateRange {
  final DateTime startUtc;
  final DateTime endUtcExclusive;
  final DateTime startManila;
  final DateTime endManilaExclusive;
  final String label;
  final int expectedDaysCount;

  const ManilaDateRange({
    required this.startUtc,
    required this.endUtcExclusive,
    required this.startManila,
    required this.endManilaExclusive,
    required this.label,
    required this.expectedDaysCount,
  });

  Timestamp get startTimestamp => Timestamp.fromDate(startUtc);
  Timestamp get endTimestamp => Timestamp.fromDate(endUtcExclusive);

  /// Half-open check: startUtc <= dt < endUtcExclusive
  bool contains(DateTime dt) {
    final utc = dt.toUtc();
    return !utc.isBefore(startUtc) && utc.isBefore(endUtcExclusive);
  }

  /// Generate each Manila calendar date bucket across this period (inclusive start to day before end)
  List<DateTime> getDailyBuckets() {
    final buckets = <DateTime>[];
    for (int i = 0; i < expectedDaysCount; i++) {
      buckets.add(startManila.add(Duration(days: i)));
    }
    return buckets;
  }
}

/// Authoritative Business Time & Calendar Boundaries Service for Lambac Coffee Roastery
/// Business Timezone: Asia/Manila (UTC+8, no daylight saving time)
class BusinessTimeService {
  BusinessTimeService._();

  static const Duration manilaOffset = Duration(hours: 8);

  /// Convert any DateTime to Asia/Manila calendar time as UTC DateTime (for extracting components safely)
  static DateTime toManila(DateTime dt) {
    return dt.toUtc().add(manilaOffset);
  }

  /// Convert Manila calendar date components directly to authoritative UTC DateTime
  static DateTime toUtcFromManilaDate(int year, int month, int day, [int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) {
    return DateTime.utc(year, month, day, hour, minute, second, millisecond).subtract(manilaOffset);
  }

  /// Convert a Manila-localized calendar DateTime back to UTC
  static DateTime toUtcFromManila(DateTime manilaDt) {
    return DateTime.utc(manilaDt.year, manilaDt.month, manilaDt.day, manilaDt.hour, manilaDt.minute, manilaDt.second, manilaDt.millisecond).subtract(manilaOffset);
  }

  /// Current time in Asia/Manila
  static DateTime nowInManila() {
    return toManila(DateTime.now());
  }

  /// Resolves the exact half-open [startOfToday <= timestamp < startOfTomorrow] range in Asia/Manila
  static ManilaDateRange getTodayRange({DateTime? now}) {
    final effectiveNow = (now ?? DateTime.now()).toUtc();
    final manilaNow = effectiveNow.add(manilaOffset);

    final startUtc = DateTime.utc(manilaNow.year, manilaNow.month, manilaNow.day).subtract(manilaOffset);
    final endUtc = startUtc.add(const Duration(days: 1));

    final startManila = DateTime.utc(manilaNow.year, manilaNow.month, manilaNow.day);
    final endManila = startManila.add(const Duration(days: 1));

    return ManilaDateRange(
      startUtc: startUtc,
      endUtcExclusive: endUtc,
      startManila: startManila,
      endManilaExclusive: endManila,
      label: 'Today',
      expectedDaysCount: 1,
    );
  }

  /// Last 7 Days (Today + preceding 6 calendar days in Asia/Manila)
  static ManilaDateRange getLast7DaysRange({DateTime? now}) {
    final today = getTodayRange(now: now);
    final startManila = today.startManila.subtract(const Duration(days: 6));
    final startUtc = today.startUtc.subtract(const Duration(days: 6));

    return ManilaDateRange(
      startUtc: startUtc,
      endUtcExclusive: today.endUtcExclusive,
      startManila: startManila,
      endManilaExclusive: today.endManilaExclusive,
      label: '7 Days',
      expectedDaysCount: 7,
    );
  }

  /// Last 15 Days (Today + preceding 14 calendar days in Asia/Manila)
  static ManilaDateRange getLast15DaysRange({DateTime? now}) {
    final today = getTodayRange(now: now);
    final startManila = today.startManila.subtract(const Duration(days: 14));
    final startUtc = today.startUtc.subtract(const Duration(days: 14));

    return ManilaDateRange(
      startUtc: startUtc,
      endUtcExclusive: today.endUtcExclusive,
      startManila: startManila,
      endManilaExclusive: today.endManilaExclusive,
      label: '15 Days',
      expectedDaysCount: 15,
    );
  }

  /// Last 30 Days (Today + preceding 29 calendar days in Asia/Manila)
  static ManilaDateRange getLast30DaysRange({DateTime? now}) {
    final today = getTodayRange(now: now);
    final startManila = today.startManila.subtract(const Duration(days: 29));
    final startUtc = today.startUtc.subtract(const Duration(days: 29));

    return ManilaDateRange(
      startUtc: startUtc,
      endUtcExclusive: today.endUtcExclusive,
      startManila: startManila,
      endManilaExclusive: today.endManilaExclusive,
      label: '30 Days',
      expectedDaysCount: 30,
    );
  }

  /// Last 3 Months (Approx 90 calendar days in Asia/Manila)
  static ManilaDateRange getLast3MonthsRange({DateTime? now}) {
    final today = getTodayRange(now: now);
    final startManila = today.startManila.subtract(const Duration(days: 89));
    final startUtc = today.startUtc.subtract(const Duration(days: 89));

    return ManilaDateRange(
      startUtc: startUtc,
      endUtcExclusive: today.endUtcExclusive,
      startManila: startManila,
      endManilaExclusive: today.endManilaExclusive,
      label: '3 Months',
      expectedDaysCount: 90,
    );
  }

  /// Custom Date Range starting at start date 00:00:00 to end date + 1 day 00:00:00 (exclusive)
  static ManilaDateRange getCustomRange(DateTime startManilaDate, DateTime endManilaDate) {
    final startUtc = DateTime.utc(startManilaDate.year, startManilaDate.month, startManilaDate.day).subtract(manilaOffset);
    final endUtc = DateTime.utc(endManilaDate.year, endManilaDate.month, endManilaDate.day).add(const Duration(days: 1)).subtract(manilaOffset);

    final startManila = DateTime.utc(startManilaDate.year, startManilaDate.month, startManilaDate.day);
    final endManila = startManila.add(Duration(days: endManilaDate.difference(startManilaDate).inDays + 1));
    final days = (endUtc.difference(startUtc).inHours / 24).round();

    final label = '${DateFormat('MMM d').format(startManila)} - ${DateFormat('MMM d').format(endManilaDate)}';

    return ManilaDateRange(
      startUtc: startUtc,
      endUtcExclusive: endUtc,
      startManila: startManila,
      endManilaExclusive: endManila,
      label: label,
      expectedDaysCount: days > 0 ? days : 1,
    );
  }

  /// Universal range resolver accepting: "Today", "7D", "7 Days", "30D", "30 Days", "3M", "Custom:yyyy-MM-dd:yyyy-MM-dd"
  static ManilaDateRange resolveRange(String dateRangeKey, {DateTime? now}) {
    final key = dateRangeKey.trim().toLowerCase();

    if (key.startsWith('custom:')) {
      final parts = dateRangeKey.split(':');
      if (parts.length >= 3) {
        final parsedStart = DateTime.tryParse(parts[1]);
        final parsedEnd = DateTime.tryParse(parts[2]);
        if (parsedStart != null && parsedEnd != null) {
          return getCustomRange(parsedStart, parsedEnd);
        }
      }
      return getLast7DaysRange(now: now);
    }

    switch (key) {
      case 'today':
        return getTodayRange(now: now);
      case '7d':
      case '7 days':
      case 'last 7 days':
        return getLast7DaysRange(now: now);
      case '15d':
      case '15 days':
      case 'last 15 days':
        return getLast15DaysRange(now: now);
      case '3m':
      case '3 months':
      case 'last 3 months':
      case '90d':
        return getLast3MonthsRange(now: now);
      case '30d':
      case '30 days':
      case 'last 30 days':
      default:
        return getLast30DaysRange(now: now);
    }
  }

  /// Resolves the corresponding prior comparison period of identical duration immediately preceding [currentRange]
  static ManilaDateRange getPriorComparisonPeriod(ManilaDateRange currentRange) {
    final duration = currentRange.endUtcExclusive.difference(currentRange.startUtc);
    final priorEndUtc = currentRange.startUtc;
    final priorStartUtc = priorEndUtc.subtract(duration);

    final priorEndManila = currentRange.startManila;
    final priorStartManila = priorEndManila.subtract(duration);

    return ManilaDateRange(
      startUtc: priorStartUtc,
      endUtcExclusive: priorEndUtc,
      startManila: priorStartManila,
      endManilaExclusive: priorEndManila,
      label: 'Prior ${currentRange.label}',
      expectedDaysCount: currentRange.expectedDaysCount,
    );
  }

  /// Fast check if [dt] belongs to today in Asia/Manila
  static bool isToday(DateTime dt, {DateTime? now}) {
    return getTodayRange(now: now).contains(dt);
  }
}
