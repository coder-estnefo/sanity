import '../entities/reminder_settings.dart';

abstract class NotificationRepository {
  ReminderSettings getSettings();
  Future<void> saveSettings(ReminderSettings settings);

  /// Asks for notification permission; returns whether granted.
  Future<bool> requestPermission();

  /// Cancels everything and schedules a fresh set per [settings].
  Future<void> reschedule(ReminderSettings settings, {DateTime? now});
  Future<void> cancelAll();
}

