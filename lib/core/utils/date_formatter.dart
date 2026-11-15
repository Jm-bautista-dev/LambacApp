import 'package:intl/intl.dart';

/// Date and time formatting utilities for orders and chat
class DateFormatter {
  DateFormatter._();

  static final DateFormat _shortDate = DateFormat('MMM d, yyyy');
  static final DateFormat _timeOnly = DateFormat('h:mm a');
  static final DateFormat _dateTime = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _monthDay = DateFormat('MMM d');

  /// Format as 'Oct 24, 2026'
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return _shortDate.format(date);
  }

  /// Format as '2:30 PM'
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return _timeOnly.format(date);
  }

  /// Format as 'Oct 24, 2026 • 2:30 PM'
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return _dateTime.format(date);
  }

  /// Format relative timestamp for chat or notifications (e.g. 'Just now', '5m ago', '2h ago', 'Yesterday', 'Oct 24')
  static String formatRelative(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24 && now.day == date.day) {
      return _timeOnly.format(date);
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (now.day - date.day == 1 || (difference.inHours < 48 && yesterday.day == date.day)) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name e.g. Wednesday
    }

    return _monthDay.format(date);
  }
}
