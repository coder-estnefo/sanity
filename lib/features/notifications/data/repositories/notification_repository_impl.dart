import 'dart:convert';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/reminder_planner.dart';
import '../datasources/notification_service.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._store, this._service);
  final KeyValueStore _store;
  final NotificationService _service;
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
    await _service.cancelAll();
    final plan = planReminders(now: now ?? DateTime.now(), settings: settings);
    await _service.scheduleAll(plan);
  }

  @override
  Future<void> cancelAll() => _service.cancelAll();
}

