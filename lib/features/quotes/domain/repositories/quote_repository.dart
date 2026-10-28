import '../entities/quote.dart';

abstract class QuoteRepository {
  /// Returns the cached batch if fresh, otherwise tries to fetch a new one,
  /// falling back to a stale cache and finally the bundled quotes.
  Future<QuoteBatch> getBatch({DateTime? now});
}

