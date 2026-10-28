import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanity/features/notifications/domain/entities/reminder_settings.dart';
import 'package:sanity/features/notifications/domain/usecases/reminder_planner.dart';

void main() {
  final day = DateTime(2026, 6, 10);

  group('planDayTimes', () {
    test('random count is 4 or 5, sorted, in window, with min gap', () {
      const s = ReminderSettings();
      final seen = <int>{};
      for (var seed = 0; seed < 300; seed++) {
        final t = planDayTimes(day, s, Random(seed));
        seen.add(t.length);
        expect(t.length, inInclusiveRange(4, 5));
        for (var i = 0; i < t.length; i++) {
          expect(t[i].hour * 60 + t[i].minute,
              inInclusiveRange(s.startHour * 60, s.endHour * 60));
          if (i > 0) {
            expect(t[i].difference(t[i - 1]).inMinutes, greaterThanOrEqualTo(90));
          }
        }
      }
      expect(seen, {4, 5});
    });

    test('fixed counts are respected', () {
      expect(
          planDayTimes(day, const ReminderSettings(count: ReminderCount.four), Random(1)).length,
          4);
      expect(
          planDayTimes(day, const ReminderSettings(count: ReminderCount.five), Random(1)).length,
          5);
    });

    test('tiny window still returns ordered times', () {
      const s = ReminderSettings(startHour: 9, endHour: 11, count: ReminderCount.five);
      final t = planDayTimes(day, s, Random(3));
      expect(t.length, 5);
      expect([...t]..sort(), t);
    });

    test('invalid window returns nothing', () {
      const s = ReminderSettings(startHour: 12, endHour: 12);
      expect(planDayTimes(day, s, Random(1)), isEmpty);
    });
  });

  group('planReminders', () {
    test('skips past times, unique ids, none when disabled', () {
      final now = DateTime(2026, 6, 10, 15);
      final plan = planReminders(
          now: now, settings: const ReminderSettings(), days: 7, random: Random(7));
      expect(plan.every((r) => r.time.isAfter(now)), isTrue);
      expect(plan.map((r) => r.id).toSet().length, plan.length);
      expect(plan.length, inInclusiveRange(24, 35));
      expect(
          planReminders(now: now, settings: const ReminderSettings(enabled: false)),
          isEmpty);
    });

    test('messages never mention addiction names', () {
      final plan = planReminders(
          now: DateTime(2026, 6, 10), settings: const ReminderSettings(), random: Random(2));
      expect(plan.every((r) => r.message.isNotEmpty), isTrue);
    });
  });
}

