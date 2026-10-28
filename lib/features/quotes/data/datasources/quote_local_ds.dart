import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/quote.dart';

abstract class QuoteLocalDataSource {
  QuoteBatch? readCache();
  Future<void> writeCache(QuoteBatch batch);
  Future<List<Quote>> loadFallback();
}

class QuoteLocalDataSourceImpl implements QuoteLocalDataSource {
  QuoteLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const _key = 'quote_batch';

  @override
  QuoteBatch? readCache() {
    final raw = _store.read(_key);
    if (raw == null) return null;
    try {
      return QuoteBatch.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeCache(QuoteBatch batch) =>
      _store.write(_key, jsonEncode(batch.toJson()));

  @override
  Future<List<Quote>> loadFallback() async {
    final raw = await rootBundle.loadString('assets/quotes_fallback.json');
    return (jsonDecode(raw) as List)
        .map((e) => Quote.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

