import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanity/core/storage/key_value_store.dart';
import 'package:sanity/features/notifications/data/datasources/notification_history_local_ds.dart';
import 'package:sanity/features/notifications/domain/entities/notification_entry.dart';
import 'package:sanity/features/notifications/domain/usecases/notification_history_usecases.dart';
import 'package:sanity/features/notifications/presentation/bloc/notification_inbox_bloc.dart';
import 'package:sanity/features/notifications/domain/repositories/notification_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(NotificationEntry(
      id: 'dummy',
      title: 'dummy',
      body: 'dummy',
      timestamp: DateTime(2026),
      kind: NotificationKind.soft,
    ));
  });

  late MemoryKeyValueStore store;
  late NotificationHistoryLocalDataSource historyDs;
  late MockNotificationRepository mockRepo;

  final softEntry = NotificationEntry(
    id: 'soft_1',
    title: 'Gentle Reminder',
    body: 'One more day of light.',
    timestamp: DateTime(2026, 6, 10, 9, 0),
    kind: NotificationKind.soft,
  );

  final hardEntry = NotificationEntry(
    id: 'hard_1',
    title: 'Milestone Reached! 🎉',
    body: '7 days free from Smoking!',
    timestamp: DateTime(2026, 6, 10, 11, 0),
    kind: NotificationKind.hard,
  );

  setUp(() {
    store = MemoryKeyValueStore();
    historyDs = NotificationHistoryLocalDataSourceImpl(store);
    mockRepo = MockNotificationRepository();

    when(() => mockRepo.getHistory()).thenAnswer((_) => historyDs.getHistory());
    when(() => mockRepo.addHistoryEntry(any()))
        .thenAnswer((inv) => historyDs.addEntry(inv.positionalArguments.first as NotificationEntry));
    when(() => mockRepo.deleteHistoryEntry(any()))
        .thenAnswer((inv) => historyDs.deleteEntry(inv.positionalArguments.first as String));
    when(() => mockRepo.clearHistory()).thenAnswer((_) => historyDs.clear());
  });

  NotificationInboxBloc buildBloc() => NotificationInboxBloc(
        getHistory: GetNotificationHistory(mockRepo),
        deleteEntry: DeleteNotificationEntry(mockRepo),
        clearHistory: ClearNotificationHistory(mockRepo),
      );

  test('initial state has empty entries and all filter', () {
    final bloc = buildBloc();
    expect(bloc.state.allEntries, isEmpty);
    expect(bloc.state.filter, NotificationFilter.all);
    expect(bloc.state.loading, isTrue);
    bloc.close();
  });

  blocTest<NotificationInboxBloc, NotificationInboxState>(
    'loads history with soft and hard entries',
    setUp: () async {
      await historyDs.addEntry(softEntry);
      await historyDs.addEntry(hardEntry);
    },
    build: buildBloc,
    act: (b) => b.add(const LoadNotificationInbox()),
    verify: (b) {
      expect(b.state.loading, isFalse);
      expect(b.state.allEntries.length, 2);
      expect(b.state.visibleEntries.length, 2);
    },
  );

  blocTest<NotificationInboxBloc, NotificationInboxState>(
    'filters entries by soft and hard',
    setUp: () async {
      await historyDs.addEntry(softEntry);
      await historyDs.addEntry(hardEntry);
    },
    build: buildBloc,
    seed: () => NotificationInboxState(
      allEntries: [hardEntry, softEntry],
      loading: false,
    ),
    act: (b) => b.add(const ChangeNotificationFilter(NotificationFilter.soft)),
    verify: (b) {
      expect(b.state.filter, NotificationFilter.soft);
      expect(b.state.visibleEntries.length, 1);
      expect(b.state.visibleEntries.first.kind, NotificationKind.soft);
      expect(b.state.countFor(NotificationFilter.hard), 1);
      expect(b.state.countFor(NotificationFilter.soft), 1);
    },
  );

  blocTest<NotificationInboxBloc, NotificationInboxState>(
    'deletes individual entry from inbox',
    setUp: () async {
      await historyDs.addEntry(softEntry);
      await historyDs.addEntry(hardEntry);
    },
    build: buildBloc,
    act: (b) => b.add(const DeleteInboxNotification('soft_1')),
    verify: (b) {
      expect(b.state.allEntries.length, 1);
      expect(b.state.allEntries.first.id, 'hard_1');
    },
  );

  blocTest<NotificationInboxBloc, NotificationInboxState>(
    'clears all entries from inbox',
    setUp: () async {
      await historyDs.addEntry(softEntry);
      await historyDs.addEntry(hardEntry);
    },
    build: buildBloc,
    act: (b) => b.add(const ClearAllNotifications()),
    verify: (b) {
      expect(b.state.allEntries, isEmpty);
      expect(b.state.visibleEntries, isEmpty);
    },
  );
}

