import 'package:equatable/equatable.dart';

/// How many reminders per day: fixed 4, fixed 5, or random 4-5 each day.
enum ReminderCount { four, five, random }

class ReminderSettings extends Equatable {
  const ReminderSettings({
    this.enabled = true,
    this.startHour = 8,
    this.endHour = 21,
    this.count = ReminderCount.random,
  });

  final bool enabled;
  final int startHour;
  final int endHour;
  final ReminderCount count;

  ReminderSettings copyWith({
    bool? enabled,
    int? startHour,
    int? endHour,
    ReminderCount? count,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        startHour: startHour ?? this.startHour,
        endHour: endHour ?? this.endHour,
        count: count ?? this.count,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'startHour': startHour,
        'endHour': endHour,
        'count': count.name,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
        enabled: j['enabled'] as bool? ?? true,
        startHour: j['startHour'] as int? ?? 8,
        endHour: j['endHour'] as int? ?? 21,
        count: ReminderCount.values.firstWhere(
          (c) => c.name == j['count'],
          orElse: () => ReminderCount.random,
        ),
      );

  @override
  List<Object?> get props => [enabled, startHour, endHour, count];
}

class ScheduledReminder extends Equatable {
  const ScheduledReminder({required this.id, required this.time, required this.message});
  final int id;
  final DateTime time;
  final String message;

  @override
  List<Object?> get props => [id, time, message];
}

