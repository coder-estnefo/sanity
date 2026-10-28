import 'package:equatable/equatable.dart';

enum QuoteType { bible, motivational }

class Quote extends Equatable {
  const Quote({required this.text, required this.source, required this.type});

  final String text;

  /// Bible reference (e.g. "Psalm 23:1") or author name.
  final String source;
  final QuoteType type;

  Map<String, dynamic> toJson() =>
      {'text': text, 'source': source, 'type': type.name};

  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
        text: j['text'] as String,
        source: j['source'] as String,
        type: QuoteType.values.firstWhere((t) => t.name == j['type']),
      );

  @override
  List<Object?> get props => [text, source, type];
}

/// A batch of quotes fetched at [fetchedAt].
class QuoteBatch extends Equatable {
  const QuoteBatch({required this.fetchedAt, required this.quotes});
  final DateTime fetchedAt;
  final List<Quote> quotes;

  List<Quote> of(QuoteType t) => quotes.where((q) => q.type == t).toList();

  Map<String, dynamic> toJson() => {
        'fetchedAt': fetchedAt.toIso8601String(),
        'quotes': quotes.map((q) => q.toJson()).toList(),
      };

  factory QuoteBatch.fromJson(Map<String, dynamic> j) => QuoteBatch(
        fetchedAt: DateTime.parse(j['fetchedAt'] as String),
        quotes: (j['quotes'] as List)
            .map((e) => Quote.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  @override
  List<Object?> get props => [fetchedAt, quotes];
}

