import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_scale_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../orders/domain/services/pickup_scheduling_service.dart';
import '../../data/models/pickup_location_model.dart';

/// Callback when customer alters scheduled pickup
typedef OnScheduleChanged = void Function(
  String dateDisplay,
  String timeSlot,
  PresetPrepOption preset,
  DateTime fullDateTime,
);

/// Premium Customizable Pickup Scheduling Component for Lambac Roastery
/// Supports Quick Presets (+1h, +3h, +5h) and Polished Custom Date/Time Selection
class PickupSchedulerWidget extends StatefulWidget {
  final PickupLocationModel location;
  final String initialDate;
  final String initialTimeSlot;
  final PresetPrepOption initialPreset;
  final OnScheduleChanged onScheduleChanged;
  final DateTime? currentTimeOverride;

  const PickupSchedulerWidget({
    super.key,
    this.location = PickupLocationModel.flagship,
    required this.initialDate,
    required this.initialTimeSlot,
    this.initialPreset = PresetPrepOption.oneHour,
    required this.onScheduleChanged,
    this.currentTimeOverride,
  });

  @override
  State<PickupSchedulerWidget> createState() => _PickupSchedulerWidgetState();
}

class _PickupSchedulerWidgetState extends State<PickupSchedulerWidget> {
  final PickupSchedulingService _schedulingService = PickupSchedulingService();

  late PresetPrepOption _selectedPreset;
  late DateTime _selectedDate;
  late String _selectedDateDisplay;
  late String _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    _initializeSchedule();
  }

  void _initializeSchedule() {
    final now = widget.currentTimeOverride ?? DateTime.now();

    if (_selectedPreset != PresetPrepOption.custom) {
      final scheduled = _schedulingService.calculatePresetSchedule(
        preset: _selectedPreset,
        now: now,
        location: widget.location,
      );
      _selectedDate = scheduled.date;
      _selectedDateDisplay = scheduled.dateDisplay;
      _selectedTimeSlot = scheduled.timeSlot;
    } else {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedDateDisplay = widget.initialDate.isNotEmpty
          ? widget.initialDate
          : _schedulingService.formatFullDate(_selectedDate);
      _selectedTimeSlot = widget.initialTimeSlot.isNotEmpty
          ? widget.initialTimeSlot
          : '5:30 PM';
    }
  }

  void _handlePresetSelected(PresetPrepOption preset) {
    setState(() => _selectedPreset = preset);
    final now = widget.currentTimeOverride ?? DateTime.now();

    if (preset == PresetPrepOption.custom) {
      // Keep or default custom date & time
      widget.onScheduleChanged(
        _selectedDateDisplay,
        _selectedTimeSlot,
        preset,
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      );
    } else {
      final computed = _schedulingService.calculatePresetSchedule(
        preset: preset,
        now: now,
        location: widget.location,
      );

      setState(() {
        _selectedDate = computed.date;
        _selectedDateDisplay = computed.dateDisplay;
        _selectedTimeSlot = computed.timeSlot;
      });

      widget.onScheduleChanged(
        computed.dateDisplay,
        computed.timeSlot,
        preset,
        computed.fullDateTime,
      );
    }
  }

  void _handleDateSelected(PickupDateOption dateOpt) {
    if (!dateOpt.isAvailable) return;
    setState(() {
      _selectedDate = dateOpt.date;
      _selectedDateDisplay = dateOpt.fullDisplay;
      _selectedPreset = PresetPrepOption.custom;
    });

    final now = widget.currentTimeOverride ?? DateTime.now();
    final availableSlots = _schedulingService.getAvailableTimeSlots(
      selectedDate: _selectedDate,
      now: now,
      location: widget.location,
    );

    // If current selected time slot is invalid for the new date, pick first valid slot
    final currentSlotValid = availableSlots.any((s) => s.displayTime == _selectedTimeSlot && s.isAvailable);
    if (!currentSlotValid) {
      final firstAvailable = availableSlots.firstWhere(
        (s) => s.isAvailable,
        orElse: () => availableSlots.first,
      );
      _selectedTimeSlot = firstAvailable.displayTime;
    }

    _notifyChange();
  }

  void _handleTimeSlotSelected(PickupTimeSlot slot) {
    if (!slot.isAvailable) return;
    setState(() {
      _selectedTimeSlot = slot.displayTime;
      _selectedPreset = PresetPrepOption.custom;
    });

    _notifyChange();
  }

  void _notifyChange() {
    final parsedTime = _schedulingService.parseTimeString(_selectedTimeSlot) ?? const TimeOfDay(hour: 12, minute: 0);
    final fullDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );

    widget.onScheduleChanged(
      _selectedDateDisplay,
      _selectedTimeSlot,
      _selectedPreset,
      fullDateTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = widget.currentTimeOverride ?? DateTime.now();

    final availableDates = _schedulingService.getAvailableDates(
      now: now,
      location: widget.location,
    );

    final availableTimeSlots = _schedulingService.getAvailableTimeSlots(
      selectedDate: _selectedDate,
      now: now,
      location: widget.location,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------------
        // Section Header: PICKUP TIME
        // ---------------------------------------------------------------------
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 18,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                ),
                const SizedBox(width: 8),
                Text(
                  'PICKUP TIME',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppRadius.radiusPill,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Text(
                'Pickup Only',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vSpaceSm,

        // ---------------------------------------------------------------------
        // Preset Row: [ 1 HR ] [ 3 HRS ] [ 5 HRS ] [ CUSTOM ]
        // ---------------------------------------------------------------------
        Row(
          children: PresetPrepOption.values.map((preset) {
            final isSelected = _selectedPreset == preset;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AppScaleButton(
                  onPressed: () => _handlePresetSelected(preset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.brandAmber.withOpacity(0.25) : AppColors.brandAmber.withOpacity(0.15))
                          : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 1.8 : 0.9,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (isDark ? AppColors.brandAmber : AppColors.brandAmber).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        preset.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: 0.3,
                          color: isSelected
                              ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        AppSpacing.vSpaceMd,

        // ---------------------------------------------------------------------
        // Scheduled Pickup Display Card: Pickup Date & Pickup Time
        // ---------------------------------------------------------------------
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup Date',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedDateDisplay,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 38,
                    width: 1,
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup Time',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedTimeSlot,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_selectedPreset != PresetPrepOption.custom) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.matchaSage.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedPreset.fullTitle,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.matchaSage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Operating hours: ${widget.location.operatingHours}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        AppSpacing.vSpaceSm,

        // ---------------------------------------------------------------------
        // CUSTOM PICKER VIEW: Date & Time Selector
        // ---------------------------------------------------------------------
        if (_selectedPreset == PresetPrepOption.custom) ...[
          // Subheader: Pickup on
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pickup on',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _selectedDateDisplay,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date Chips Row
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableDates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final dateOpt = availableDates[index];
                final isSelected = _selectedDate.year == dateOpt.date.year &&
                    _selectedDate.month == dateOpt.date.month &&
                    _selectedDate.day == dateOpt.date.day;

                return AppScaleButton(
                  onPressed: dateOpt.isAvailable ? () => _handleDateSelected(dateOpt) : null,
                  child: Opacity(
                    opacity: dateOpt.isAvailable ? 1.0 : 0.45,
                    child: Container(
                      width: 82,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.brandAmber.withOpacity(0.25) : AppColors.brandAmber.withOpacity(0.15))
                            : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 1.8 : 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dateOpt.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateOpt.formattedDate,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          AppSpacing.vSpaceMd,

          // Subheader: Pickup at
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pickup at',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                _selectedTimeSlot,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Structured Time Slots Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTimeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot.displayTime;

              return AppScaleButton(
                onPressed: slot.isAvailable ? () => _handleTimeSlotSelected(slot) : null,
                child: Opacity(
                  opacity: slot.isAvailable ? 1.0 : 0.35,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.brandAmber.withOpacity(0.25) : AppColors.brandAmber.withOpacity(0.15))
                          : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 1.6 : 0.8,
                      ),
                    ),
                    child: Text(
                      slot.displayTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        decoration: !slot.isAvailable ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // ---------------------------------------------------------------------
        // Business Rules & Prep Buffer Footer Note
        // ---------------------------------------------------------------------
        AppSpacing.vSpaceSm,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Roastery Hours: ${widget.location.operatingHours} • Min. ${widget.location.prepBufferMinutes}-minute preparation buffer enforced.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
