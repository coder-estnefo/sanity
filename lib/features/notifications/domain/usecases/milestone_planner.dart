import '../../../tracker/domain/entities/addiction.dart';
import '../entities/reminder_settings.dart';

class MilestonePlanner {
  static const milestoneDays = [1, 7, 14, 30, 60, 90, 180, 365];

  /// Plans hard milestone celebration notifications for all active addictions.
  /// Only schedules milestones that are in the future relative to [now].
  static List<ScheduledReminder> planMilestones({
    required List<Addiction> addictions,
    required DateTime now,
  }) {
    final list = <ScheduledReminder>[];
    for (final a in addictions) {
      for (final m in milestoneDays) {
        final milestoneDate = DateTime(
          a.quitDate.year,
          a.quitDate.month,
          a.quitDate.day + m,
          9, // 9:00 AM celebration
          0,
        );
        if (milestoneDate.isAfter(now)) {
          // Unique stable id for each addiction + milestone
          final id = 10000 + (a.id.hashCode % 1000).abs() * 10 + milestoneDays.indexOf(m);
          list.add(ScheduledReminder(
            id: id,
            time: milestoneDate,
            message: '🎉 $m days free from ${a.name}! A monumental milestone in your journey.',
          ));
        }
      }
    }
    return list;
  }
}

