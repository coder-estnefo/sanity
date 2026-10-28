import '../entities/notification_entry.dart';
import '../repositories/notification_repository.dart';

class GetNotificationHistory {
  GetNotificationHistory(this._repo);
  final NotificationRepository _repo;

  Future<List<NotificationEntry>> call() => _repo.getHistory();
}

class DeleteNotificationEntry {
  DeleteNotificationEntry(this._repo);
  final NotificationRepository _repo;

  Future<void> call(String id) => _repo.deleteHistoryEntry(id);
}

class ClearNotificationHistory {
  ClearNotificationHistory(this._repo);
  final NotificationRepository _repo;

  Future<void> call() => _repo.clearHistory();
}

class RecordNotificationEntry {
  RecordNotificationEntry(this._repo);
  final NotificationRepository _repo;

  Future<void> call(NotificationEntry entry) => _repo.addHistoryEntry(entry);
}

