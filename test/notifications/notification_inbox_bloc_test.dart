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
    registerFallbackValue(NotificationKind.soft);
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
    when(() => mockRepo.sendTestNotification(
          kind: any(named: 'kind'),
          message: any(named: 'message'),
        )).thenAnswer((_) async {});
  });

  NotificationInboxBloc buildBloc() => NotificationInboxBloc(
        getHistory: GetNotificationHistory(mockRepo),
        triggerTest: TriggerTestNotificationUseCase(mockRepo),
      );

  test('initial state has empty entries and all filter', () {
    final bloc = buildBloc();
    expect(bloc.state.allEntries, isEmpty);
    expect(bloc.state.filter, NotificationFilter.all);
    expect(bloc.state.loading, isTrue);
    bloc.close();
  });

  blocTest<NotificationInboxBloc, NotificationInboxState>(
    'loads history with soft and hard entries sorted newest first',
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
      // Hard entry (11:00) should be first, soft entry (09:00) second
      expect(b.state.visibleEntries.first.id, 'hard_1');
      expect(b.state.visibleEntries.last.id, 'soft_1');
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
    'sends test notification and reloads inbox',
    build: buildBloc,
    act: (b) => b.add(const SendTestNotificationEvent(kind: NotificationKind.soft)),
    verify: (b) {
      verify(() => mockRepo.sendTestNotification(
            kind: NotificationKind.soft,
            message: any(named: 'message'),
          )).called(1);
      verify(() => mockRepo.getHistory()).called(1);
    },
  );
}
