import 'dart:math';

import '../entities/reminder_settings.dart';
import 'message_bank.dart';

/// Picks random reminder times for a single day, always sorted and spaced by
/// at least [minGapMinutes] (reduced only if the window is too small).
List<DateTime> planDayTimes(
  DateTime day,
  ReminderSettings s,
  Random random, {
  int minGapMinutes = 90,
}) {
  final n = switch (s.count) {
    ReminderCount.four => 4,
    ReminderCount.five => 5,
    ReminderCount.random => 4 + random.nextInt(2),
  };
  final start = s.startHour * 60;
  final end = s.endHour * 60;
  final total = end - start;
  if (total <= 0) return [];
  final gap = min(minGapMinutes, total ~/ n);
  final slack = total - (n - 1) * gap;
  final offsets = List.generate(n, (_) => random.nextInt(slack + 1))..sort();
  return [
    for (var i = 0; i < n; i++)
      DateTime(day.year, day.month, day.day).add(
        Duration(minutes: start + offsets[i] + i * gap),
      ),
  ];
}

/// Plans reminders for [days] days starting today, skipping times already
/// past. Ids are stable per (day offset, slot).
List<ScheduledReminder> planReminders({
  required DateTime now,
  required ReminderSettings settings,
  int days = 7,
  Random? random,
}) {
  if (!settings.enabled) return [];
  final r = random ?? Random();
  final messages = [...MessageBank.messages]..shuffle(r);
  final out = <ScheduledReminder>[];
  var m = 0;
  for (var d = 0; d < days; d++) {
    final day = DateTime(now.year, now.month, now.day + d);
    final times = planDayTimes(day, settings, r);
    for (var i = 0; i < times.length; i++) {
      final message = messages[m++ % messages.length];
      if (times[i].isAfter(now)) {
        out.add(ScheduledReminder(id: d * 10 + i, time: times[i], message: message));
      }
    }
  }
  return out;
}

