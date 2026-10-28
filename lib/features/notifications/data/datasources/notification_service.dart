import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/reminder_settings.dart';

abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> scheduleAll(List<ScheduledReminder> reminders);
  Future<void> scheduleMilestones(List<ScheduledReminder> milestones);
  Future<void> cancelAll();
  Stream<String?> get notificationClicks;
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _clickController = StreamController<String?>.broadcast();
  String? _initialPayload;

  static const _softDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'sanity_reminders',
      'Gentle reminders',
      channelDescription: 'Soft motivational reminders through the day',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const _hardDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'sanity_milestones',
      'Milestone celebrations',
      channelDescription: 'Celebrations when reaching major sobriety milestones',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    ),
  );

  @override
  Stream<String?> get notificationClicks async* {
    if (_initialPayload != null) {
      yield _initialPayload;
      _initialPayload = null;
    }
    yield* _clickController.stream;
  }

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      _initialPayload =
          launchDetails.notificationResponse?.payload ?? 'sanity://notifications';
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _clickController.add(response.payload ?? 'sanity://notifications');
      },
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
        notificationDetails: _softDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'sanity://notifications?type=soft&id=${r.id}',
      );
    }
  }

  @override
  Future<void> scheduleMilestones(List<ScheduledReminder> milestones) async {
    for (final m in milestones) {
      await _plugin.zonedSchedule(
        id: m.id,
        title: 'Milestone Reached! 🎉',
        body: m.message,
        scheduledDate: tz.TZDateTime.from(m.time, tz.local),
        notificationDetails: _hardDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'sanity://notifications?type=hard&id=${m.id}',
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
