import 'dart:math';

import 'package:dio/dio.dart';

import '../../domain/entities/quote.dart';

abstract class QuoteRemoteDataSource {
  Future<List<Quote>> fetchBible(int count);
  Future<List<Quote>> fetchMotivational(int count);
}

class QuoteRemoteDataSourceImpl implements QuoteRemoteDataSource {
  QuoteRemoteDataSourceImpl(this._dio, {Random? random})
      : _random = random ?? Random();
  final Dio _dio;
  final Random _random;

  /// Curated, hope-oriented references.
  static const references = [
    'Psalm 23:1', 'Psalm 23:4', 'Psalm 46:1', 'Psalm 27:1', 'Psalm 34:18',
    'Psalm 55:22', 'Psalm 121:1-2', 'Psalm 30:5', 'Psalm 91:2',
    'Isaiah 41:10', 'Isaiah 40:31', 'Isaiah 43:2', 'Jeremiah 29:11',
    'Joshua 1:9', 'Proverbs 3:5-6', 'Proverbs 24:16', 'Matthew 11:28',
    'Matthew 6:34', 'John 8:36', 'John 16:33', 'Romans 8:28', 'Romans 12:2',
    'Romans 8:37', '1 Corinthians 10:13', '2 Corinthians 5:17',
    '2 Corinthians 12:9', 'Galatians 5:1', 'Galatians 6:9',
    'Philippians 4:6-7', 'Philippians 4:13', 'Philippians 1:6',
    '2 Timothy 1:7', 'Hebrews 12:1', 'James 4:7', '1 Peter 5:7',
    'Lamentations 3:22-23',
  ];

  @override
  Future<List<Quote>> fetchBible(int count) async {
    final picks = [...references]..shuffle(_random);
    final out = <Quote>[];
    for (final ref in picks.take(count)) {
      final res = await _dio.get(
        'https://bible-api.com/${Uri.encodeComponent(ref)}',
        queryParameters: {'translation': 'kjv'},
      );
      final data = res.data as Map;
      final text = (data['text'] as String).replaceAll(RegExp(r'\s+'), ' ').trim();
      out.add(Quote(
        text: text,
        source: (data['reference'] as String?) ?? ref,
        type: QuoteType.bible,
      ));
    }
    return out;
  }

  @override
  Future<List<Quote>> fetchMotivational(int count) async {
    final res = await _dio.get('https://zenquotes.io/api/quotes');
    final list = (res.data as List).cast<Map>();
    final quotes = list
        .where((e) => e['q'] != null && !(e['q'] as String).contains('Too many requests'))
        .map((e) => Quote(
              text: e['q'] as String,
              source: (e['a'] as String?) ?? 'Unknown',
              type: QuoteType.motivational,
            ))
        .toList()
      ..shuffle(_random);
    return quotes.take(count).toList();
  }
}

