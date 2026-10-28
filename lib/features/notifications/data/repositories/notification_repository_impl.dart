import 'dart:convert';

import '../../../../core/storage/key_value_store.dart';
import '../../../tracker/domain/entities/addiction.dart';
import '../../domain/entities/notification_entry.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/milestone_planner.dart';
import '../../domain/usecases/reminder_planner.dart';
import '../datasources/notification_history_local_ds.dart';
import '../datasources/notification_service.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(
    this._store,
    this._service, {
    NotificationHistoryLocalDataSource? historyDataSource,
  }) : _historyDs =
            historyDataSource ?? NotificationHistoryLocalDataSourceImpl(_store);

  final KeyValueStore _store;
  final NotificationService _service;
  final NotificationHistoryLocalDataSource _historyDs;
  static const _key = 'reminder_settings';
  static const _scheduledRemindersKey = 'scheduled_reminders_pending';

  @override
  ReminderSettings getSettings() {
    final raw = _store.read(_key);
    if (raw == null) return const ReminderSettings();
    return ReminderSettings.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  @override
  Future<void> saveSettings(ReminderSettings s) =>
      _store.write(_key, jsonEncode(s.toJson()));

  @override
  Future<bool> requestPermission() => _service.requestPermission();

  @override
  Future<void> reschedule(ReminderSettings settings, {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    await _service.cancelAll();
    final plan = planReminders(now: currentTime, settings: settings);
    await _service.scheduleAll(plan);

    // Save pending reminders so when their scheduled time arrives,
    // they transition into real notification history.
    final jsonList = plan
        .map((r) => {
              'id': r.id,
              'time': r.time.toIso8601String(),
              'message': r.message,
            })
        .toList();
    await _store.write(_scheduledRemindersKey, jsonEncode(jsonList));
  }

  @override
  Future<void> syncDeliveredNotifications({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();

    final rawPending = _store.read(_scheduledRemindersKey);
    if (rawPending != null) {
      try {
        final list = (jsonDecode(rawPending) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final remaining = <Map<String, dynamic>>[];

        for (final item in list) {
          final time = DateTime.parse(item['time'] as String);
          if (time.isBefore(currentTime) || time.isAtSameMomentAs(currentTime)) {
            // This reminder has legitimately arrived in the real world
            final id =
                'delivered_soft_${item['id']}_${time.millisecondsSinceEpoch}';
            await _historyDs.addEntry(NotificationEntry(
              id: id,
              title: 'Gentle Reminder',
              body: item['message'] as String,
              timestamp: time,
              kind: NotificationKind.soft,
            ));
          } else {
            remaining.add(item);
          }
        }
        await _store.write(_scheduledRemindersKey, jsonEncode(remaining));
      } catch (_) {}
    }
  }

  @override
  Future<void> sendTestNotification({
    NotificationKind kind = NotificationKind.soft,
    String? message,
  }) async {
    final now = DateTime.now();
    final isHard = kind == NotificationKind.hard;
    final title = isHard ? 'Milestone Reached! 🎉' : 'Gentle Reminder';
    final body = message ??
        (isHard
            ? 'You achieved a milestone! Every moment of strength builds your new life.'
            : 'Breathe deeply. You are stronger than your urges right now.');
    final entryId = 'test_${kind.name}_${now.millisecondsSinceEpoch}';

    // Show on system notification drawer
    await _service.showNow(
      id: now.millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      kind: kind,
    );

    // Save to real notification history
    await _historyDs.addEntry(NotificationEntry(
      id: entryId,
      title: title,
      body: body,
      timestamp: now,
      kind: kind,
    ));
  }

  @override
  Future<void> scheduleMilestones(List<Addiction> addictions,
      {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final milestones = MilestonePlanner.planMilestones(
      addictions: addictions,
      now: currentTime,
    );
    await _service.scheduleMilestones(milestones);

    // Record achieved milestones in history for past milestones
    for (final a in addictions) {
      final days = a.daysFreeAt(currentTime);
      for (final m in MilestonePlanner.milestoneDays) {
        if (days >= m) {
          final reachedDate = DateTime(
            a.quitDate.year,
            a.quitDate.month,
            a.quitDate.day + m,
            9,
            0,
          );
          if (reachedDate.isBefore(currentTime) ||
              reachedDate.isAtSameMomentAs(currentTime)) {
            await _historyDs.addEntry(NotificationEntry(
              id: 'milestone_${a.id}_$m',
              title: 'Milestone Reached! 🎉',
              body:
                  'You have been $m days free from ${a.name}! A monumental victory.',
              timestamp: reachedDate,
              kind: NotificationKind.hard,
            ));
          }
        }
      }
    }
  }

  @override
  Future<void> cancelAll() => _service.cancelAll();

  @override
  Future<List<NotificationEntry>> getHistory() async {
    await syncDeliveredNotifications();
    return _historyDs.getHistory();
  }

  @override
  Future<void> addHistoryEntry(NotificationEntry entry) =>
      _historyDs.addEntry(entry);

  @override
  Future<void> deleteHistoryEntry(String id) => _historyDs.deleteEntry(id);

  @override
  Future<void> clearHistory() => _historyDs.clear();

  @override
  Stream<String?> get notificationClicks => _service.notificationClicks;
}
