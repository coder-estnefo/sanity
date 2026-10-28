import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanity/core/storage/key_value_store.dart';
import 'package:sanity/features/tracker/data/repositories/tracker_repository_impl.dart';
import 'package:sanity/features/tracker/domain/entities/addiction.dart';
import 'package:sanity/features/tracker/domain/usecases/tracker_usecases.dart';
import 'package:sanity/features/tracker/presentation/bloc/tracker_bloc.dart';
import 'package:sanity/features/widgets/domain/repositories/home_widget_repository.dart';
import 'package:sanity/features/widgets/domain/usecases/sync_home_widgets.dart';

class _FakeSync implements HomeWidgetRepository {
  final calls = <List<Addiction>>[];
  final pinned = <String>[];
  @override
  Future<void> sync(List<Addiction> trackers) async => calls.add(trackers);
  @override
  Future<void> pinTracker(String id) async => pinned.add(id);
}

void main() {
  late _FakeSync sync;
  late TrackerRepositoryImpl repo;
  final today = DateTime(2026, 6, 10, 14);

  TrackerBloc build() => TrackerBloc(
        getAddictions: GetAddictions(repo),
        saveAddiction: SaveAddiction(repo),
        deleteAddiction: DeleteAddiction(repo),
        resetAddiction: ResetAddiction(repo),
        clock: () => today,
      );

  setUp(() => repo = TrackerRepositoryImpl(MemoryKeyValueStore()));

  final a = Addiction(id: '1', name: 'Smoking', quitDate: DateTime(2026, 6, 1));

  test('repository persists and round-trips', () async {
    await repo.save(a);
    expect(await repo.getAll(), [a]);
    await repo.save(a.copyWith(name: 'Vaping'));
    expect((await repo.getAll()).single.name, 'Vaping');
    await repo.delete('1');
    expect(await repo.getAll(), isEmpty);
  });

  test('daysFreeAt', () => expect(a.daysFreeAt(today), 9));

  test('SaveAddiction rejects future dates and empty names', () {
    final uc = SaveAddiction(repo);
    expect(() => uc(Addiction(id: '2', name: 'x', quitDate: DateTime(2030)), now: today),
        throwsArgumentError);
    expect(() => uc(Addiction(id: '2', name: '  ', quitDate: DateTime(2020)), now: today),
        throwsArgumentError);
  });

  test('ResetAddiction sets quit date to today and counts relapse', () async {
    await ResetAddiction(repo)(a, now: today);
    final saved = (await repo.getAll()).single;
    expect(saved.quitDate, DateTime(2026, 6, 10));
    expect(saved.relapses, 1);
  });

  blocTest<TrackerBloc, TrackerState>(
    'save then load emits items',
    build: build,
    act: (b) => b.add(SaveTracker(a)),
    verify: (b) {
      expect(b.state.items, [a]);
      expect(b.state.loading, false);
    },
  );

  blocTest<TrackerBloc, TrackerState>(
    'syncs home widgets after every reload',
    build: () {
      sync = _FakeSync();
      return TrackerBloc(
        getAddictions: GetAddictions(repo),
        saveAddiction: SaveAddiction(repo),
        deleteAddiction: DeleteAddiction(repo),
        resetAddiction: ResetAddiction(repo),
        syncHomeWidgets: SyncHomeWidgets(sync),
        clock: () => today,
      );
    },
    act: (b) async {
      b.add(SaveTracker(a));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      b.add(DeleteTracker(a.id));
    },
    wait: const Duration(milliseconds: 100),
    verify: (_) {
      expect(sync.calls.length, 2);
      expect(sync.calls.first, [a]);
      expect(sync.calls.last, isEmpty);
    },
  );

  blocTest<TrackerBloc, TrackerState>(
    'future date surfaces an error',
    build: build,
    act: (b) => b.add(SaveTracker(Addiction(id: '3', name: 'x', quitDate: DateTime(2035)))),
    verify: (b) => expect(b.state.error, isNotNull),
  );
}

