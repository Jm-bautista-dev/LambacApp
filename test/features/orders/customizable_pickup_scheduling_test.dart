import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/cart/presentation/widgets/pickup_scheduler_widget.dart';
import 'package:lambac_app/features/orders/domain/services/pickup_scheduling_service.dart';

void main() {
  group('Lambac Roastery — Customizable Pickup Scheduling Suite', () {
    late PickupSchedulingService schedulingService;

    // Fixed reference time for deterministic testing: 2:00 PM on a Friday
    final testNow = DateTime(2026, 9, 25, 14, 0); // Friday, Sep 25, 2026 2:00 PM

    setUp(() {
      schedulingService = PickupSchedulingService();
    });

    // =========================================================================
    // 1. QUICK PRESETS CALCULATION TESTS
    // =========================================================================
    group('1. Quick Presets (+1h, +3h, +5h)', () {
      test('1 HR preset calculates pickup time to exactly 1 hour in advance (3:00 PM)', () {
        final result = schedulingService.calculatePresetSchedule(
          preset: PresetPrepOption.oneHour,
          now: testNow,
        );

        expect(result.preset, equals(PresetPrepOption.oneHour));
        expect(result.timeSlot, equals('3:00 PM'));
        expect(result.fullDateTime, equals(DateTime(2026, 9, 25, 15, 0)));
      });

      test('3 HRS preset calculates pickup time to exactly 3 hours in advance (5:00 PM)', () {
        final result = schedulingService.calculatePresetSchedule(
          preset: PresetPrepOption.threeHours,
          now: testNow,
        );

        expect(result.preset, equals(PresetPrepOption.threeHours));
        expect(result.timeSlot, equals('5:00 PM'));
        expect(result.fullDateTime, equals(DateTime(2026, 9, 25, 17, 0)));
      });

      test('5 HRS preset calculates pickup time to exactly 5 hours in advance (7:00 PM)', () {
        final result = schedulingService.calculatePresetSchedule(
          preset: PresetPrepOption.fiveHours,
          now: testNow,
        );

        expect(result.preset, equals(PresetPrepOption.fiveHours));
        expect(result.timeSlot, equals('7:00 PM'));
        expect(result.fullDateTime, equals(DateTime(2026, 9, 25, 19, 0)));
      });

      test('Preset when ordered at 2:15 PM rounds up to next 30-min slot (1 HR -> 3:30 PM)', () {
        final oddNow = DateTime(2026, 9, 25, 14, 15); // 2:15 PM
        final result = schedulingService.calculatePresetSchedule(
          preset: PresetPrepOption.oneHour,
          now: oddNow,
        );

        // 2:15 PM + 1h = 3:15 PM -> rounds up to 3:30 PM
        expect(result.timeSlot, equals('3:30 PM'));
        expect(result.fullDateTime, equals(DateTime(2026, 9, 25, 15, 30)));
      });

      test('Preset rolls over to tomorrow morning if target exceeds store closing (9:00 PM)', () {
        final eveningNow = DateTime(2026, 9, 25, 20, 0); // 8:00 PM Friday (closes 9:00 PM)
        final result = schedulingService.calculatePresetSchedule(
          preset: PresetPrepOption.threeHours,
          now: eveningNow,
        );

        // 8:00 PM + 3h = 11:00 PM (past 9 PM closing)
        // Rolls over to tomorrow (Saturday) morning opening (7:00 AM) + 1h prep buffer = 8:00 AM
        expect(result.date.day, equals(26));
        expect(result.timeSlot, equals('8:00 AM'));
      });
    });

    // =========================================================================
    // 2. BUSINESS HOURS & PREPARATION BUFFER TESTS
    // =========================================================================
    group('2. Business Hours & Preparation Buffer Rules', () {
      test('Operating hours respect location configuration (Daily 7:00 AM - 9:00 PM)', () {
        expect(PickupLocationModel.flagship.openHour, equals(7));
        expect(PickupLocationModel.flagship.closeHour, equals(21));
        expect(PickupLocationModel.flagship.prepBufferMinutes, equals(60));
        expect(PickupLocationModel.flagship.slotIntervalMinutes, equals(30));
      });

      test('Rejects pickup times outside store operating hours (before 7:00 AM or after 9:00 PM)', () {
        // 6:30 AM (before opening)
        final earlyRes = schedulingService.validateSchedule(
          dateStr: 'Tomorrow, Sep 26',
          timeSlotStr: '6:30 AM',
          now: testNow,
        );
        expect(earlyRes.isFailure, isTrue);
        expect(earlyRes.failureOrNull?.message, contains('within roastery hours'));

        // 9:30 PM (after closing)
        final lateRes = schedulingService.validateSchedule(
          dateStr: 'Tomorrow, Sep 26',
          timeSlotStr: '9:30 PM',
          now: testNow,
        );
        expect(lateRes.isFailure, isTrue);
        expect(lateRes.failureOrNull?.message, contains('within roastery hours'));
      });

      test('Rejects pickup times that violate minimum preparation buffer (e.g. within 60 mins)', () {
        // testNow is 2:00 PM. Earliest valid standard pickup is 3:00 PM.
        // 2:30 PM violates the 60-min preparation buffer!
        final bufferRes = schedulingService.validateSchedule(
          dateStr: 'Today, Sep 25',
          timeSlotStr: '2:30 PM',
          now: testNow,
        );

        expect(bufferRes.isFailure, isTrue);
        expect(bufferRes.failureOrNull, isA<ValidationFailure>());
        expect(bufferRes.failureOrNull?.message, contains('preparation buffer'));
      });

      test('Accepts pickup times that satisfy the preparation buffer (e.g. 3:30 PM when ordered at 2:00 PM)', () {
        final validRes = schedulingService.validateSchedule(
          dateStr: 'Today, Sep 25',
          timeSlotStr: '3:30 PM',
          now: testNow,
        );

        expect(validRes.isSuccess, isTrue);
        final scheduled = validRes.dataOrNull!;
        expect(scheduled.timeSlot, equals('3:30 PM'));
      });

      test('Rejects pickup times in the past', () {
        final pastRes = schedulingService.validateSchedule(
          dateStr: 'Today, Sep 25',
          timeSlotStr: '11:00 AM',
          now: testNow, // 2:00 PM
        );

        expect(pastRes.isFailure, isTrue);
        expect(pastRes.failureOrNull?.message, contains('already passed'));
      });
    });

    // =========================================================================
    // 3. DATE SELECTION & TIME SLOTS GENERATION TESTS
    // =========================================================================
    group('3. Date Selection & Structured Time Slots', () {
      test('getAvailableDates generates 7 days window starting from today', () {
        final dates = schedulingService.getAvailableDates(now: testNow);

        expect(dates.length, equals(7));
        expect(dates[0].label, equals('Today'));
        expect(dates[0].isToday, isTrue);
        expect(dates[1].label, equals('Tomorrow'));
        expect(dates[1].isToday, isFalse);
      });

      test('getAvailableTimeSlots generates 30-min intervals from 7:00 AM to 9:00 PM', () {
        final tomorrow = DateTime(2026, 9, 26);
        final slots = schedulingService.getAvailableTimeSlots(
          selectedDate: tomorrow,
          now: testNow,
        );

        expect(slots.first.displayTime, equals('7:00 AM'));
        expect(slots.last.displayTime, equals('9:00 PM'));

        // All slots for tomorrow should be available
        expect(slots.every((s) => s.isAvailable), isTrue);
      });

      test('getAvailableTimeSlots marks slots earlier than (now + prepBuffer) as unavailable for today', () {
        final today = DateTime(2026, 9, 25);
        final slots = schedulingService.getAvailableTimeSlots(
          selectedDate: today,
          now: testNow, // 2:00 PM
        );

        // Slots before 3:00 PM must be unavailable due to past / prep buffer
        final slot1pm = slots.firstWhere((s) => s.displayTime == '1:00 PM');
        expect(slot1pm.isAvailable, isFalse);

        final slot230pm = slots.firstWhere((s) => s.displayTime == '2:30 PM');
        expect(slot230pm.isAvailable, isFalse);
        expect(slot230pm.unavailableReason, contains('prep buffer'));

        // Slots at or after 3:00 PM must be available
        final slot330pm = slots.firstWhere((s) => s.displayTime == '3:30 PM');
        expect(slot330pm.isAvailable, isTrue);
      });
    });

    // =========================================================================
    // 4. WIDGET TEST: PICKUP SCHEDULER WIDGET
    // =========================================================================
    group('4. PickupSchedulerWidget Component Tests', () {
      testWidgets('Renders presets [ 1 HR ] [ 3 HRS ] [ 5 HRS ] [ CUSTOM ] and responds to taps', (WidgetTester tester) async {
        String lastDate = '';
        String lastTime = '';
        PresetPrepOption lastPreset = PresetPrepOption.oneHour;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PickupSchedulerWidget(
                initialDate: 'Today',
                initialTimeSlot: '3:00 PM',
                currentTimeOverride: testNow,
                onScheduleChanged: (date, time, preset, _) {
                  lastDate = date;
                  lastTime = time;
                  lastPreset = preset;
                },
              ),
            ),
          ),
        );

        expect(find.text('PICKUP TIME'), findsOneWidget);
        expect(find.text('1 HR'), findsOneWidget);
        expect(find.text('3 HRS'), findsOneWidget);
        expect(find.text('5 HRS'), findsOneWidget);
        expect(find.text('CUSTOM'), findsOneWidget);

        // Tap 3 HRS preset
        await tester.tap(find.text('3 HRS'));
        await tester.pump();

        expect(lastPreset, equals(PresetPrepOption.threeHours));
        expect(lastTime, equals('5:00 PM'));

        // Tap 5 HRS preset
        await tester.tap(find.text('5 HRS'));
        await tester.pump();

        expect(lastPreset, equals(PresetPrepOption.fiveHours));
        expect(lastTime, equals('7:00 PM'));

        // Tap CUSTOM preset
        await tester.tap(find.text('CUSTOM'));
        await tester.pump();

        expect(find.text('Pickup on'), findsOneWidget);
        expect(find.text('Pickup at'), findsOneWidget);
      });
    });

    // =========================================================================
    // 5. BACKEND VALIDATION & PROTECTION TESTS
    // =========================================================================
    group('5. Backend Validation Authority', () {
      test('Backend rejects order with pickup time outside operating hours', () async {
        final validation = schedulingService.validateSchedule(
          dateStr: 'Tomorrow, Sep 26',
          timeSlotStr: '11:30 PM', // Store closes at 9:00 PM
          now: testNow,
        );

        expect(validation.isFailure, isTrue);
        expect(validation.failureOrNull, isA<ValidationFailure>());
        expect(validation.failureOrNull?.message, contains('within roastery hours'));
      });

      test('Backend rejects order with pickup date in the past', () async {
        final validation = schedulingService.validateSchedule(
          dateStr: '2025-01-01',
          timeSlotStr: '2:00 PM',
          now: testNow,
        );

        expect(validation.isFailure, isTrue);
        expect(validation.failureOrNull, isA<ValidationFailure>());
        expect(validation.failureOrNull?.message, contains('cannot be in the past'));
      });
    });
  });
}
