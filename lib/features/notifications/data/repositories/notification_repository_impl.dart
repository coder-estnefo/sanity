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
  }) : _historyDs = historyDataSource ?? NotificationHistoryLocalDataSourceImpl(_store);

  final KeyValueStore _store;
  final NotificationService _service;
  final NotificationHistoryLocalDataSource _historyDs;
  static const _key = 'reminder_settings';

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

    // Save scheduled reminders that start today to history
    // so the inbox has today's gentle motivations
    for (final r in plan.take(3)) {
      await _historyDs.addEntry(NotificationEntry(
        id: 'soft_${r.id}',
        title: 'Gentle Reminder',
        body: r.message,
        timestamp: r.time,
        kind: NotificationKind.soft,
      ));
    }
  }

  @override
  Future<void> scheduleMilestones(List<Addiction> addictions, {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final milestones = MilestonePlanner.planMilestones(
      addictions: addictions,
      now: currentTime,
    );
    await _service.scheduleMilestones(milestones);

    // Also record achieved milestones in history for past milestones
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
          await _historyDs.addEntry(NotificationEntry(
            id: 'milestone_${a.id}_$m',
            title: 'Milestone Reached! 🎉',
            body: 'You have been $m days free from ${a.name}! A monumental victory.',
            timestamp: reachedDate,
            kind: NotificationKind.hard,
          ));
        }
      }
    }
  }

  @override
  Future<void> cancelAll() => _service.cancelAll();

  @override
  Future<List<NotificationEntry>> getHistory() => _historyDs.getHistory();

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
