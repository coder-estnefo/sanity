import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/quote.dart';
import '../bloc/quotes_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class QuotesSection extends StatelessWidget {
  const QuotesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotesBloc, QuotesState>(
      builder: (context, state) {
        if (state.loading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.failed || state.quotes.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s words', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final q in state.quotes) QuoteCard(quote: q),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => launchUrl(Uri.parse('https://zenquotes.io/'),
                    mode: LaunchMode.externalApplication),
                child: const Text('Inspirational quotes provided by ZenQuotes API',
                    style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.quote});
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final bible = quote.type == QuoteType.bible;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: bible ? const Color(0xFFFFF3D6) : const Color(0xFFEAF3EC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(bible ? Icons.menu_book_outlined : Icons.spa_outlined,
                  size: 18, color: AppTheme.sage),
              const SizedBox(width: 6),
              Text(bible ? 'Scripture' : 'Motivation',
                  style: Theme.of(context).textTheme.labelMedium),
            ]),
            const SizedBox(height: 8),
            Text('“${quote.text}”',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, height: 1.4)),
            const SizedBox(height: 8),
            Text('— ${quote.source}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

