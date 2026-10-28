import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../tracker/domain/entities/addiction.dart';
import '../tracker/presentation/bloc/tracker_bloc.dart';
import '../tracker/presentation/pages/add_edit_page.dart';
import '../quotes/presentation/widgets/quotes_section.dart';
import '../notifications/presentation/pages/settings_page.dart';
import '../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const milestones = [1, 7, 14, 30, 60, 90, 180, 365];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanity'),
        actions: [
          IconButton(
            tooltip: 'Reminder settings',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddEditPage())),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: BlocConsumer<TrackerBloc, TrackerState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, s) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.error!))),
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = state.now ?? DateTime.now();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const QuotesSection(),
              const SizedBox(height: 16),
              if (state.items.isEmpty)
                const _EmptyState()
              else
                for (final a in state.items) _TrackerCard(addiction: a, now: now),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.wb_sunny_outlined, size: 64, color: AppTheme.gold),
            SizedBox(height: 12),
            Text(
              'Add what you are leaving behind.\nEvery day free begins here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({required this.addiction, required this.now});
  final Addiction addiction;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final days = addiction.daysFreeAt(now);
    final next = HomePage.milestones.firstWhere((m) => m > days, orElse: () => days + 365);
    final prev = HomePage.milestones.lastWhere((m) => m <= days, orElse: () => 0);
    final progress = (days - prev) / (next - prev);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(addiction.name, style: theme.textTheme.titleMedium),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _onMenu(context, v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'reset', child: Text('I relapsed (reset)')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$days',
                    style: theme.textTheme.displayMedium
                        ?.copyWith(color: AppTheme.sage, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(days == 1 ? 'day free' : 'days free'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                color: AppTheme.gold,
                backgroundColor: AppTheme.peach.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Next milestone: $next days · Since ${DateFormat.yMMMd().format(addiction.quitDate)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, String v) async {
    final bloc = context.read<TrackerBloc>();
    switch (v) {
      case 'edit':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => AddEditPage(existing: addiction)));
      case 'reset':
        if (await _confirm(context, 'Reset counter?',
            'Be kind to yourself. A slip does not erase your progress as a person. The counter restarts today.')) {
          bloc.add(ResetTracker(addiction));
        }
      case 'delete':
        if (await _confirm(context, 'Delete "${addiction.name}"?', 'This cannot be undone.')) {
          bloc.add(DeleteTracker(addiction.id));
        }
    }
  }

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
        ],
      ),
    );
    return ok ?? false;
  }
}

