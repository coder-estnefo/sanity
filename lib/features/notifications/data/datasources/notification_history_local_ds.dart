import 'dart:convert';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/notification_entry.dart';
import '../models/notification_entry_model.dart';

abstract class NotificationHistoryLocalDataSource {
  Future<List<NotificationEntry>> getHistory();
  Future<void> saveHistory(List<NotificationEntry> entries);
  Future<void> addEntry(NotificationEntry entry);
  Future<void> deleteEntry(String id);
  Future<void> clear();
}

class NotificationHistoryLocalDataSourceImpl
    implements NotificationHistoryLocalDataSource {
  NotificationHistoryLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const _key = 'notification_history';

  @override
  Future<List<NotificationEntry>> getHistory() async {
    final raw = _store.read(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      final now = DateTime.now();
      // Only return real notifications that have actually occurred (timestamp <= now + 1 min grace)
      final maxAllowedTime = now.add(const Duration(minutes: 1));
      final entries = list
          .map((e) => NotificationEntryModel.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .where((e) => e.timestamp.isBefore(maxAllowedTime))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveHistory(List<NotificationEntry> entries) async {
    final sorted = [...entries]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final json = jsonEncode(
      sorted.map((e) => NotificationEntryModel.toJson(e)).toList(),
    );
    await _store.write(_key, json);
  }

  @override
  Future<void> addEntry(NotificationEntry entry) async {
    final history = await getHistory();
    // Prevent duplicate entries with the same id
    history.removeWhere((e) => e.id == entry.id);
    history.add(entry);
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await saveHistory(history);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final history = await getHistory();
    history.removeWhere((e) => e.id == id);
    await saveHistory(history);
  }

  @override
  Future<void> clear() async {
    await _store.write(_key, '[]');
  }
}

