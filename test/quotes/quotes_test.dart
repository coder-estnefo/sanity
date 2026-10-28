import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanity/features/quotes/data/datasources/quote_local_ds.dart';
import 'package:sanity/features/quotes/data/datasources/quote_remote_ds.dart';
import 'package:sanity/features/quotes/data/repositories/quote_repository_impl.dart';
import 'package:sanity/features/quotes/domain/entities/quote.dart';
import 'package:sanity/features/quotes/domain/repositories/quote_repository.dart';
import 'package:sanity/features/quotes/domain/usecases/get_daily_quotes.dart';

class MockRemote extends Mock implements QuoteRemoteDataSource {}

class MockLocal extends Mock implements QuoteLocalDataSource {}

class FakeRepo implements QuoteRepository {
  FakeRepo(this.batch);
  final QuoteBatch batch;
  @override
  Future<QuoteBatch> getBatch({DateTime? now}) async => batch;
}

Quote q(String t, QuoteType type) => Quote(text: t, source: 's', type: type);

void main() {
  late MockRemote remote;
  late MockLocal local;
  late QuoteRepositoryImpl repo;
  final now = DateTime(2026, 6, 10);
  final bibles = [for (var i = 0; i < 6; i++) q('b$i', QuoteType.bible)];
  final mots = [for (var i = 0; i < 6; i++) q('m$i', QuoteType.motivational)];

  setUpAll(() => registerFallbackValue(QuoteBatch(fetchedAt: DateTime(2026), quotes: const [])));

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    repo = QuoteRepositoryImpl(remote, local);
    when(() => local.writeCache(any())).thenAnswer((_) async {});
  });

  test('fresh cache (< 3 days) is used without network', () async {
    final cached = QuoteBatch(
        fetchedAt: now.subtract(const Duration(days: 2)), quotes: [...bibles, ...mots]);
    when(() => local.readCache()).thenReturn(cached);
    expect(await repo.getBatch(now: now), cached);
    verifyNever(() => remote.fetchBible(any()));
  });

  test('stale cache triggers fetch and is re-cached', () async {
    when(() => local.readCache()).thenReturn(QuoteBatch(
        fetchedAt: now.subtract(const Duration(days: 3)), quotes: [...bibles, ...mots]));
    when(() => remote.fetchBible(any())).thenAnswer((_) async => bibles);
    when(() => remote.fetchMotivational(any())).thenAnswer((_) async => mots);
    final batch = await repo.getBatch(now: now);
    expect(batch.fetchedAt, now);
    verify(() => local.writeCache(any())).called(1);
  });

  test('network failure falls back to stale cache', () async {
    final stale = QuoteBatch(
        fetchedAt: now.subtract(const Duration(days: 9)), quotes: [...bibles, ...mots]);
    when(() => local.readCache()).thenReturn(stale);
    when(() => remote.fetchBible(any())).thenThrow(Exception('offline'));
    expect(await repo.getBatch(now: now), stale);
  });

  test('no cache and no network falls back to bundled quotes', () async {
    when(() => local.readCache()).thenReturn(null);
    when(() => remote.fetchBible(any())).thenThrow(Exception('offline'));
    when(() => local.loadFallback()).thenAnswer((_) async => [...bibles, ...mots]);
    final batch = await repo.getBatch(now: now);
    expect(batch.quotes.length, 12);
  });

  group('GetDailyQuotes', () {
    final uc = GetDailyQuotes(FakeRepo(QuoteBatch(fetchedAt: now, quotes: [...bibles, ...mots])));

    test('returns 2 Bible + 1 motivational', () async {
      final r = await uc(now: now);
      expect(r.length, 3);
      expect(r.where((x) => x.type == QuoteType.bible).length, 2);
    });

    test('stable within a day, changes next day', () async {
      expect(await uc(now: now), await uc(now: now.add(const Duration(hours: 5))));
      expect(await uc(now: now), isNot(await uc(now: now.add(const Duration(days: 1)))));
    });
  });
}
