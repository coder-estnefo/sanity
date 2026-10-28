import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/reminder_settings.dart';
import '../bloc/notification_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _hour(int h) => '${h.toString().padLeft(2, '0')}:00';

  Future<void> _pickHour(BuildContext context, ReminderSettings s, bool start) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start ? s.startHour : s.endHour, minute: 0),
    );
    if (t == null || !context.mounted) return;
    final next = start ? s.copyWith(startHour: t.hour) : s.copyWith(endHour: t.hour);
    if (next.endHour <= next.startHour) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')));
      return;
    }
    context.read<NotificationBloc>().add(UpdateSettings(next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gentle reminders')),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          final s = state.settings;
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Daily reminders'),
                subtitle: const Text('4–5 soft nudges at random times each day'),
                value: s.enabled,
                onChanged: (v) => context
                    .read<NotificationBloc>()
                    .add(UpdateSettings(s.copyWith(enabled: v))),
              ),
              if (s.enabled && !state.permissionGranted)
                const ListTile(
                  leading: Icon(Icons.warning_amber, color: Colors.orange),
                  title: Text('Notifications are blocked'),
                  subtitle: Text('Enable them for Sanity in system settings.'),
                ),
              ListTile(
                title: const Text('Start time'),
                trailing: Text(_hour(s.startHour)),
                enabled: s.enabled,
                onTap: () => _pickHour(context, s, true),
              ),
              ListTile(
                title: const Text('End time'),
                trailing: Text(_hour(s.endHour)),
                enabled: s.enabled,
                onTap: () => _pickHour(context, s, false),
              ),
              ListTile(
                title: const Text('Reminders per day'),
                trailing: DropdownButton<ReminderCount>(
                  value: s.count,
                  onChanged: s.enabled
                      ? (v) => context
                          .read<NotificationBloc>()
                          .add(UpdateSettings(s.copyWith(count: v)))
                      : null,
                  items: const [
                    DropdownMenuItem(value: ReminderCount.random, child: Text('Random 4–5')),
                    DropdownMenuItem(value: ReminderCount.four, child: Text('4')),
                    DropdownMenuItem(value: ReminderCount.five, child: Text('5')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

