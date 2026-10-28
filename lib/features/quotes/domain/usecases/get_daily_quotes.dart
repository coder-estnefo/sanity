import '../entities/quote.dart';
import '../repositories/quote_repository.dart';

/// Picks today's quotes (2 Bible + 1 motivational) from the cached batch.
/// Selection is seeded by the date so the set is stable all day and rotates
/// the next day.
class GetDailyQuotes {
  GetDailyQuotes(this._repo);
  final QuoteRepository _repo;

  Future<List<Quote>> call({DateTime? now, int bible = 2, int motivational = 1}) async {
    final today = now ?? DateTime.now();
    final batch = await _repo.getBatch(now: today);
    final day = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(2024))
        .inDays;
    return [
      ..._pick(batch.of(QuoteType.bible), day, bible),
      ..._pick(batch.of(QuoteType.motivational), day, motivational),
    ];
  }

  List<Quote> _pick(List<Quote> pool, int day, int count) {
    if (pool.isEmpty) return [];
    final n = count > pool.length ? pool.length : count;
    return [for (var i = 0; i < n; i++) pool[(day * count + i) % pool.length]];
  }
}

