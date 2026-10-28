import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/reminder_settings.dart';

/// Thin wrapper around flutter_local_notifications so the repository can be
/// unit tested with a fake.
abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> scheduleAll(List<ScheduledReminder> reminders);
  Future<void> cancelAll();
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'sanity_reminders',
      'Gentle reminders',
      channelDescription: 'Soft motivational reminders through the day',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final a = await android?.requestNotificationsPermission();
    final i = await ios?.requestPermissions(alert: true, badge: false, sound: true);
    return (a ?? true) && (i ?? true);
  }

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: 'Sanity',
        body: r.message,
        scheduledDate: tz.TZDateTime.from(r.time, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

