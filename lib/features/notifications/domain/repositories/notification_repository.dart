import '../../../tracker/domain/entities/addiction.dart';
import '../entities/notification_entry.dart';
import '../entities/reminder_settings.dart';

abstract class NotificationRepository {
  ReminderSettings getSettings();
  Future<void> saveSettings(ReminderSettings settings);

  /// Asks for notification permission; returns whether granted.
  Future<bool> requestPermission();

  /// Cancels everything and schedules a fresh set per [settings].
  Future<void> reschedule(ReminderSettings settings, {DateTime? now});
  Future<void> cancelAll();

  /// Notification inbox/history
  Future<List<NotificationEntry>> getHistory();
  Future<void> addHistoryEntry(NotificationEntry entry);
  Future<void> deleteHistoryEntry(String id);
  Future<void> clearHistory();

  /// Milestone scheduling
  Future<void> scheduleMilestones(List<Addiction> addictions, {DateTime? now});

  /// Stream of notification clicks emitting payload strings.
  Stream<String?> get notificationClicks;
}
