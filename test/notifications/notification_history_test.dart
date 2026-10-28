import 'package:flutter_test/flutter_test.dart';
import 'package:sanity/core/storage/key_value_store.dart';
import 'package:sanity/features/notifications/data/datasources/notification_history_local_ds.dart';
import 'package:sanity/features/notifications/domain/entities/notification_entry.dart';

void main() {
  late MemoryKeyValueStore store;
  late NotificationHistoryLocalDataSourceImpl dataSource;

  final softEntry = NotificationEntry(
    id: 's1',
    title: 'Gentle Reminder',
    body: 'You are doing great.',
    timestamp: DateTime(2026, 6, 10, 10, 0),
    kind: NotificationKind.soft,
  );

  final hardEntry = NotificationEntry(
    id: 'h1',
    title: 'Milestone Reached! 🎉',
    body: '7 days free from Smoking!',
    timestamp: DateTime(2026, 6, 10, 14, 0),
    kind: NotificationKind.hard,
  );

  setUp(() {
    store = MemoryKeyValueStore();
    dataSource = NotificationHistoryLocalDataSourceImpl(store);
  });

  test('empty history initially', () async {
    expect(await dataSource.getHistory(), isEmpty);
  });

  test('adds and persists entries, sorted newest first', () async {
    await dataSource.addEntry(softEntry);
    await dataSource.addEntry(hardEntry);

    final history = await dataSource.getHistory();
    expect(history.length, 2);
    // Hard entry (14:00) should be before soft entry (10:00)
    expect(history.first.id, 'h1');
    expect(history.last.id, 's1');
  });

  test('deletes individual entry by id', () async {
    await dataSource.addEntry(softEntry);
    await dataSource.addEntry(hardEntry);

    await dataSource.deleteEntry('s1');
    final history = await dataSource.getHistory();
    expect(history.length, 1);
    expect(history.first.id, 'h1');
  });

  test('clears all entries', () async {
    await dataSource.addEntry(softEntry);
    await dataSource.addEntry(hardEntry);

    await dataSource.clear();
    expect(await dataSource.getHistory(), isEmpty);
  });
}

