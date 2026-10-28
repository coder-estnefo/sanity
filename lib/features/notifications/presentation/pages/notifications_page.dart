import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/notification_entry.dart';
import '../bloc/notification_inbox_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationInboxBloc, NotificationInboxState>(
            builder: (context, state) {
              if (state.allEntries.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear all',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () => _confirmClear(context),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationInboxBloc, NotificationInboxState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = state.visibleEntries;

          return Column(
            children: [
              _FilterBar(currentFilter: state.filter, state: state),
              Expanded(
                child: entries.isEmpty
                    ? _EmptyInbox(filter: state.filter)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final item = entries[index];
                          return _NotificationCard(entry: item);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This will remove all saved gentle reminders and milestone celebrations from your inbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.read<NotificationInboxBloc>().add(const ClearAllNotifications());
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.currentFilter, required this.state});
  final NotificationFilter currentFilter;
  final NotificationInboxState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _chip(
            context,
            filter: NotificationFilter.all,
            label: 'All (${state.countFor(NotificationFilter.all)})',
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            filter: NotificationFilter.soft,
            label: 'Gentle (${state.countFor(NotificationFilter.soft)})',
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            filter: NotificationFilter.hard,
            label: 'Milestones (${state.countFor(NotificationFilter.hard)})',
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required NotificationFilter filter,
    required String label,
  }) {
    final isSelected = currentFilter == filter;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppTheme.sage.withValues(alpha: 0.25),
      checkmarkColor: AppTheme.sage,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.ink : Colors.black54,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (_) {
        context
            .read<NotificationInboxBloc>()
            .add(ChangeNotificationFilter(filter));
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.entry});
  final NotificationEntry entry;

  @override
  Widget build(BuildContext context) {
    final isHard = entry.kind == NotificationKind.hard;
    final theme = Theme.of(context);

    final cardBg = isHard ? const Color(0xFFFFF3D6) : const Color(0xFFEAF3EC);
    final accentColor = isHard ? AppTheme.gold : AppTheme.sage;
    final icon = isHard ? Icons.emoji_events_outlined : Icons.spa_outlined;
    final badgeLabel = isHard ? 'MILESTONE' : 'GENTLE MOTIVATION';

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: Colors.red.shade700),
      ),
      onDismissed: (_) {
        context
            .read<NotificationInboxBloc>()
            .add(DeleteInboxNotification(entry.id));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: cardBg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    badgeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(entry.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                entry.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  fontWeight: isHard ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    final timeStr = DateFormat.jm().format(dt);
    if (date == today) {
      return 'Today, $timeStr';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $timeStr';
    } else {
      return '${DateFormat.MMMd().format(dt)}, $timeStr';
    }
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.filter});
  final NotificationFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      NotificationFilter.all =>
        'No notifications yet.\nGentle motivations and milestone celebrations will appear here.',
      NotificationFilter.soft =>
        'No gentle reminders recorded yet.',
      NotificationFilter.hard =>
        'No milestone celebrations yet.\nKeep going, your victories are coming!',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_paused_outlined,
              size: 56,
              color: AppTheme.sage,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

