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
      return list
          .map((e) => NotificationEntryModel.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveHistory(List<NotificationEntry> entries) async {
    final json = jsonEncode(
      entries.map((e) => NotificationEntryModel.toJson(e)).toList(),
    );
    await _store.write(_key, json);
  }

  @override
  Future<void> addEntry(NotificationEntry entry) async {
    final history = await getHistory();
    // Prevent duplicate entries with the same id
    history.removeWhere((e) => e.id == entry.id);
    history.insert(0, entry);
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

