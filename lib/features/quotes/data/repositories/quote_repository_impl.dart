import '../../domain/entities/quote.dart';
import '../../domain/repositories/quote_repository.dart';
import '../datasources/quote_local_ds.dart';
import '../datasources/quote_remote_ds.dart';

class QuoteRepositoryImpl implements QuoteRepository {
  QuoteRepositoryImpl(this._remote, this._local,
      {this.refreshEvery = const Duration(days: 3), this.batchSize = 6});

  final QuoteRemoteDataSource _remote;
  final QuoteLocalDataSource _local;
  final Duration refreshEvery;
  final int batchSize;

  @override
  Future<QuoteBatch> getBatch({DateTime? now}) async {
    final time = now ?? DateTime.now();
    final cached = _local.readCache();
    final fresh = cached != null &&
        cached.quotes.isNotEmpty &&
        time.difference(cached.fetchedAt) < refreshEvery;
    if (fresh) return cached;

    try {
      final bible = await _remote.fetchBible(batchSize);
      final motivational = await _remote.fetchMotivational(batchSize);
      if (bible.isEmpty || motivational.isEmpty) throw StateError('empty');
      final batch = QuoteBatch(fetchedAt: time, quotes: [...bible, ...motivational]);
      await _local.writeCache(batch);
      return batch;
    } catch (_) {
      if (cached != null && cached.quotes.isNotEmpty) return cached;
      final fallback = await _local.loadFallback();
      return QuoteBatch(fetchedAt: time, quotes: fallback);
    }
  }
}

