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
          PopupMenuButton<NotificationKind>(
            tooltip: 'Send test notification',
            icon: const Icon(Icons.add_alert_outlined),
            onSelected: (kind) {
              context
                  .read<NotificationInboxBloc>()
                  .add(SendTestNotificationEvent(kind: kind));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(kind == NotificationKind.hard
                      ? 'Milestone celebration triggered!'
                      : 'Gentle reminder notification triggered!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: NotificationKind.soft,
                child: Row(
                  children: [
                    Icon(Icons.spa_outlined, size: 18, color: AppTheme.sage),
                    SizedBox(width: 8),
                    Text('Test gentle reminder'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NotificationKind.hard,
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 18, color: AppTheme.gold),
                    SizedBox(width: 8),
                    Text('Test milestone alert'),
                  ],
                ),
              ),
            ],
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
                          final showDateHeader = index == 0 ||
                              !_isSameDay(
                                  entries[index - 1].timestamp, item.timestamp);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDateHeader)
                                _DateGroupHeader(timestamp: item.timestamp),
                              _NotificationCard(entry: item),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({required this.timestamp});
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

    String label;
    if (date == today) {
      label = 'Today';
    } else if (date == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else if (date.year == today.year) {
      label = DateFormat.MMMMd().format(timestamp);
    } else {
      label = DateFormat.yMMMMd().format(timestamp);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.45),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
    );
  }

  String _formatTime(DateTime dt) {
    return DateFormat.jm().format(dt);
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.filter});
  final NotificationFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      NotificationFilter.all =>
        'No notifications yet.\nGentle motivations and milestone celebrations will appear here as they occur.',
      NotificationFilter.soft => 'No gentle reminders recorded yet.',
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
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                context.read<NotificationInboxBloc>().add(
                      const SendTestNotificationEvent(
                        kind: NotificationKind.soft,
                      ),
                    );
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Send test notification'),
            ),
          ],
        ),
      ),
    );
  }
}
