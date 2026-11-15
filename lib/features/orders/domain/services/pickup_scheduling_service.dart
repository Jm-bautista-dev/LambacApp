import 'package:flutter/material.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../cart/data/models/pickup_location_model.dart';

/// Available preset preparation time options for quick scheduling
enum PresetPrepOption {
  oneHour,
  threeHours,
  fiveHours,
  custom;

  String get label {
    return switch (this) {
      PresetPrepOption.oneHour => '1 HR',
      PresetPrepOption.threeHours => '3 HRS',
      PresetPrepOption.fiveHours => '5 HRS',
      PresetPrepOption.custom => 'CUSTOM',
    };
  }

  String get fullTitle {
    return switch (this) {
      PresetPrepOption.oneHour => '+1 Hour (Quick Prep)',
      PresetPrepOption.threeHours => '+3 Hours (Afternoon Slot)',
      PresetPrepOption.fiveHours => '+5 Hours (Evening Slot)',
      PresetPrepOption.custom => 'Custom Date & Time',
    };
  }

  int? get hours {
    return switch (this) {
      PresetPrepOption.oneHour => 1,
      PresetPrepOption.threeHours => 3,
      PresetPrepOption.fiveHours => 5,
      PresetPrepOption.custom => null,
    };
  }
}

/// Representation of a selectable pickup date
class PickupDateOption {
  final DateTime date;
  final String label; // "Today", "Tomorrow", "Fri", "Sat"
  final String formattedDate; // "Sep 25"
  final String fullDisplay; // "Friday, Sep 25"
  final bool isToday;
  final bool isAvailable;
  final String? unavailableReason;

  const PickupDateOption({
    required this.date,
    required this.label,
    required this.formattedDate,
    required this.fullDisplay,
    required this.isToday,
    required this.isAvailable,
    this.unavailableReason,
  });
}

/// Representation of a structured time slot
class PickupTimeSlot {
  final TimeOfDay time;
  final String displayTime; // "5:30 PM"
  final bool isAvailable;
  final String? unavailableReason;

  const PickupTimeSlot({
    required this.time,
    required this.displayTime,
    required this.isAvailable,
    this.unavailableReason,
  });
}

/// Computed pickup schedule holding date, time slot, and preset reference
class ScheduledPickup {
  final DateTime date;
  final String dateDisplay;
  final String timeSlot;
  final PresetPrepOption preset;
  final DateTime fullDateTime;

  const ScheduledPickup({
    required this.date,
    required this.dateDisplay,
    required this.timeSlot,
    required this.preset,
    required this.fullDateTime,
  });

  @override
  String toString() => '$dateDisplay at $timeSlot';
}

/// Production Pickup Scheduling Service for Lambac Roastery
/// Enforces Business Hours, Configurable Preparation Buffers, and Strict Date/Time Rules
class PickupSchedulingService {
  static const PickupSchedulingService _instance = PickupSchedulingService._internal();
  factory PickupSchedulingService() => _instance;
  const PickupSchedulingService._internal();

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _fullMonthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<String> _shortDayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  /// Formats a DateTime into a friendly display: "Friday, September 25"
  String formatFullDate(DateTime dt) {
    final dayName = _dayNames[dt.weekday - 1];
    final monthName = _fullMonthNames[dt.month - 1];
    return '$dayName, $monthName ${dt.day}';
  }

  /// Formats a DateTime into a concise display: "Friday, Sep 25"
  String formatShortDate(DateTime dt) {
    final dayName = _dayNames[dt.weekday - 1];
    final monthName = _monthNames[dt.month - 1];
    return '$dayName, $monthName ${dt.day}';
  }

  /// Formats TimeOfDay into "5:30 PM"
  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Parses a time string like "5:30 PM" or "05:30 PM" into TimeOfDay
  TimeOfDay? parseTimeString(String timeStr) {
    var trimmed = timeStr.trim().toUpperCase();
    if (trimmed.contains('-') || trimmed.contains('–')) {
      trimmed = trimmed.split(RegExp(r'[-–]')).first.trim();
    }
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(trimmed);
    if (match == null) return null;

    int hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final isPm = match.group(3) == 'PM';

    if (isPm && hour < 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Generates the list of available booking dates respecting operating schedule
  List<PickupDateOption> getAvailableDates({
    DateTime? now,
    PickupLocationModel location = PickupLocationModel.flagship,
  }) {
    final current = now ?? DateTime.now();
    final dates = <PickupDateOption>[];

    for (int i = 0; i < location.maxAdvanceDays; i++) {
      final date = DateTime(current.year, current.month, current.day).add(Duration(days: i));
      final isToday = i == 0;
      final isTomorrow = i == 1;

      String label;
      if (isToday) {
        label = 'Today';
      } else if (isTomorrow) {
        label = 'Tomorrow';
      } else {
        label = _shortDayNames[date.weekday - 1];
      }

      final formattedDate = '${_monthNames[date.month - 1]} ${date.day}';
      final fullDisplay = formatFullDate(date);

      // Check if any slots are available today (must have current + prepBuffer < closingTime)
      bool isAvailable = true;
      String? unavailableReason;

      if (isToday) {
        final earliestSlot = current.add(location.prepBuffer);
        final closingTime = DateTime(current.year, current.month, current.day, location.closeHour, location.closeMinute);
        if (earliestSlot.isAfter(closingTime)) {
          isAvailable = false;
          unavailableReason = 'Store closing soon; no slots remain today';
        }
      }

      dates.add(
        PickupDateOption(
          date: date,
          label: label,
          formattedDate: formattedDate,
          fullDisplay: fullDisplay,
          isToday: isToday,
          isAvailable: isAvailable,
          unavailableReason: unavailableReason,
        ),
      );
    }

    return dates;
  }

  /// Generates structured time slots for a given date respecting operating hours & preparation buffer
  List<PickupTimeSlot> getAvailableTimeSlots({
    required DateTime selectedDate,
    DateTime? now,
    PickupLocationModel location = PickupLocationModel.flagship,
  }) {
    final current = now ?? DateTime.now();
    final slots = <PickupTimeSlot>[];

    final openMinutes = location.openHour * 60 + location.openMinute;
    final closeMinutes = location.closeHour * 60 + location.closeMinute;
    final step = location.slotIntervalMinutes;

    final isSelectedDateToday = selectedDate.year == current.year &&
        selectedDate.month == current.month &&
        selectedDate.day == current.day;

    final earliestAllowedTime = current.add(location.prepBuffer);

    for (int m = openMinutes; m <= closeMinutes; m += step) {
      final hour = m ~/ 60;
      final minute = m % 60;
      final time = TimeOfDay(hour: hour, minute: minute);
      final displayTime = formatTimeOfDay(time);

      bool isAvailable = true;
      String? unavailableReason;

      final slotDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        hour,
        minute,
      );

      if (slotDateTime.isBefore(current)) {
        isAvailable = false;
        unavailableReason = 'Past time';
      } else if (isSelectedDateToday && slotDateTime.isBefore(earliestAllowedTime)) {
        isAvailable = false;
        unavailableReason = 'Requires at least ${location.prepBufferMinutes} min prep buffer';
      }

      slots.add(
        PickupTimeSlot(
          time: time,
          displayTime: displayTime,
          isAvailable: isAvailable,
          unavailableReason: unavailableReason,
        ),
      );
    }

    return slots;
  }

  /// Calculates an appropriate scheduled pickup time for a preset (+1h, +3h, +5h)
  ScheduledPickup calculatePresetSchedule({
    required PresetPrepOption preset,
    DateTime? now,
    PickupLocationModel location = PickupLocationModel.flagship,
  }) {
    final current = now ?? DateTime.now();

    if (preset == PresetPrepOption.custom) {
      // Default custom schedule to earliest valid slot
      return getEarliestAvailableSchedule(now: current, location: location);
    }

    final hoursToAdd = preset.hours ?? 1;
    var target = current.add(Duration(hours: hoursToAdd));

    // Round up target minute to nearest slotInterval (e.g. 30 mins)
    final interval = location.slotIntervalMinutes;
    final remainder = target.minute % interval;
    if (remainder != 0) {
      target = target.add(Duration(minutes: interval - remainder));
    }
    target = DateTime(target.year, target.month, target.day, target.hour, target.minute);

    // If target is earlier than today's opening time (e.g. ordered early morning)
    final openToday = DateTime(target.year, target.month, target.day, location.openHour, location.openMinute);
    if (target.isBefore(openToday)) {
      target = openToday.add(location.prepBuffer);
    }

    // If target exceeds closing time for today, roll over to tomorrow morning opening + prep buffer
    final closeToday = DateTime(target.year, target.month, target.day, location.closeHour, location.closeMinute);
    if (target.isAfter(closeToday)) {
      final tomorrow = current.add(const Duration(days: 1));
      target = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        location.openHour,
        location.openMinute,
      ).add(location.prepBuffer);
    }

    final timeOfDay = TimeOfDay(hour: target.hour, minute: target.minute);
    final displayTime = formatTimeOfDay(timeOfDay);
    final displayDate = formatFullDate(target);

    return ScheduledPickup(
      date: DateTime(target.year, target.month, target.day),
      dateDisplay: displayDate,
      timeSlot: displayTime,
      preset: preset,
      fullDateTime: target,
    );
  }

  /// Finds the earliest valid pickup time respecting operating hours & preparation buffer
  ScheduledPickup getEarliestAvailableSchedule({
    DateTime? now,
    PickupLocationModel location = PickupLocationModel.flagship,
  }) {
    final current = now ?? DateTime.now();
    var earliest = current.add(location.prepBuffer);

    // Round up minute to next interval
    final interval = location.slotIntervalMinutes;
    final remainder = earliest.minute % interval;
    if (remainder != 0) {
      earliest = earliest.add(Duration(minutes: interval - remainder));
    }
    earliest = DateTime(earliest.year, earliest.month, earliest.day, earliest.hour, earliest.minute);

    final openToday = DateTime(earliest.year, earliest.month, earliest.day, location.openHour, location.openMinute);
    if (earliest.isBefore(openToday)) {
      earliest = openToday;
    }

    final closeToday = DateTime(earliest.year, earliest.month, earliest.day, location.closeHour, location.closeMinute);
    if (earliest.isAfter(closeToday)) {
      final tomorrow = current.add(const Duration(days: 1));
      earliest = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        location.openHour,
        location.openMinute,
      ).add(location.prepBuffer);
    }

    final timeOfDay = TimeOfDay(hour: earliest.hour, minute: earliest.minute);
    return ScheduledPickup(
      date: DateTime(earliest.year, earliest.month, earliest.day),
      dateDisplay: formatFullDate(earliest),
      timeSlot: formatTimeOfDay(timeOfDay),
      preset: PresetPrepOption.custom,
      fullDateTime: earliest,
    );
  }

  /// Validates a pickup schedule on both client and backend source of truth
  Result<ScheduledPickup, ValidationFailure> validateSchedule({
    required String? dateStr,
    required String? timeSlotStr,
    DateTime? now,
    PickupLocationModel location = PickupLocationModel.flagship,
  }) {
    final current = now ?? DateTime.now();

    if (dateStr == null || dateStr.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Please select a pickup date.'),
      );
    }

    if (timeSlotStr == null || timeSlotStr.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Please select a pickup time slot.'),
      );
    }

    // 1. Resolve Date
    DateTime? resolvedDate;
    final dateLower = dateStr.trim().toLowerCase();

    if (dateLower.startsWith('today')) {
      resolvedDate = DateTime(current.year, current.month, current.day);
    } else if (dateLower.startsWith('tomorrow')) {
      final tmr = current.add(const Duration(days: 1));
      resolvedDate = DateTime(tmr.year, tmr.month, tmr.day);
    } else {
      // Try parsing formats: "Friday, September 25", "Friday, Sep 25", "Sep 25", etc.
      for (int i = 0; i < location.maxAdvanceDays + 2; i++) {
        final candidate = DateTime(current.year, current.month, current.day).add(Duration(days: i));
        final fullMatch = formatFullDate(candidate).toLowerCase();
        final shortMatch = formatShortDate(candidate).toLowerCase();
        if (fullMatch == dateLower || shortMatch == dateLower || dateLower.contains('${_monthNames[candidate.month - 1].toLowerCase()} ${candidate.day}')) {
          resolvedDate = candidate;
          break;
        }
      }
    }

    if (resolvedDate == null) {
      // Fallback try standard ISO date parse
      try {
        final parsed = DateTime.parse(dateStr);
        resolvedDate = DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        return Result.failure(
          ValidationFailure(message: 'Invalid pickup date: "$dateStr".'),
        );
      }
    }

    // Check date is not in the past
    final todayMidnight = DateTime(current.year, current.month, current.day);
    if (resolvedDate.isBefore(todayMidnight)) {
      return const Result.failure(
        ValidationFailure(message: 'Pickup date cannot be in the past.'),
      );
    }

    // Check date does not exceed max booking window
    final maxDate = todayMidnight.add(Duration(days: location.maxAdvanceDays));
    if (resolvedDate.isAfter(maxDate)) {
      return Result.failure(
        ValidationFailure(message: 'Pickup date cannot exceed ${location.maxAdvanceDays} days in advance.'),
      );
    }

    // 2. Resolve Time Slot
    // Handle special legacy or express slots if present
    if (timeSlotStr.toLowerCase().contains('asap')) {
      final isOutsideHours = current.isBefore(DateTime(current.year, current.month, current.day, location.openHour, location.openMinute)) ||
          current.isAfter(DateTime(current.year, current.month, current.day, location.closeHour, location.closeMinute));
      final fullDate = isOutsideHours
          ? DateTime(current.year, current.month, current.day + 1, location.openHour, location.openMinute).add(location.prepBuffer)
          : current.add(const Duration(minutes: 20));

      return Result.success(
        ScheduledPickup(
          date: resolvedDate,
          dateDisplay: formatFullDate(resolvedDate),
          timeSlot: timeSlotStr,
          preset: PresetPrepOption.custom,
          fullDateTime: fullDate,
        ),
      );
    }

    final parsedTime = parseTimeString(timeSlotStr);
    if (parsedTime == null) {
      return Result.failure(
        ValidationFailure(message: 'Invalid pickup time format: "$timeSlotStr".'),
      );
    }

    // Check operating hours: [openHour:openMinute] to [closeHour:closeMinute]
    final openMinutes = location.openHour * 60 + location.openMinute;
    final closeMinutes = location.closeHour * 60 + location.closeMinute;
    final slotMinutes = parsedTime.hour * 60 + parsedTime.minute;

    if (slotMinutes < openMinutes || slotMinutes > closeMinutes) {
      return Result.failure(
        ValidationFailure(
          message: 'Pickup time must be within roastery hours (${location.operatingHours}).',
        ),
      );
    }

    // Construct full DateTime
    final fullDateTime = DateTime(
      resolvedDate.year,
      resolvedDate.month,
      resolvedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );

    // Check not in the past
    if (fullDateTime.isBefore(current)) {
      return const Result.failure(
        ValidationFailure(message: 'Selected pickup time has already passed.'),
      );
    }

    // Check preparation buffer (only applies if pickup is today)
    final isToday = resolvedDate.isAtSameMomentAs(todayMidnight);
    if (isToday) {
      final earliestAllowed = current.add(location.prepBuffer);
      if (fullDateTime.isBefore(earliestAllowed)) {
        return Result.failure(
          ValidationFailure(
            message: 'Minimum preparation buffer is ${location.prepBufferMinutes} minutes. Earliest available pickup is ${formatTimeOfDay(TimeOfDay.fromDateTime(earliestAllowed))}.',
          ),
        );
      }
    }

    return Result.success(
      ScheduledPickup(
        date: resolvedDate,
        dateDisplay: formatFullDate(resolvedDate),
        timeSlot: timeSlotStr,
        preset: PresetPrepOption.custom,
        fullDateTime: fullDateTime,
      ),
    );
  }
}
