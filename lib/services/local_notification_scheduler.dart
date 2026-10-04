import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:subbies/models/subscription.dart';
import 'package:subbies/services/reminder_planner.dart';
import 'package:subbies/services/reminder_scheduler.dart';


class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _testNotificationId = 9999;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'renewal_reminders', 
      'Renewal reminders',
      channelDescription: 'A heads-up the day before something renews or a free trial ends.',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF0E7C66),
    ),
    iOS: DarwinNotificationDetails(),
  );


  Future<void> _ensureInitialized() async {
    if(_initialized) return;

    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (error) {
      debugPrint('Could not read the time zone, using UTC: $error');
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }

    return false;
  }

  @override
  Future<void> scheduleFor(List<Subscription> subscriptions) async {
    await _ensureInitialized();

    // Simplest reliable approach: wipe all pending reminders, then
    // schedule a fresh set. No risk of leftover reminders for deleted
    // or edited subscriptions.
    await _plugin.cancelAllPendingNotifications();
    final planned = planReminders(subscriptions, DateTime.now());

    for (var i = 0; i < planned.length; i++) {
      final reminder = planned[i];
      await _plugin.zonedSchedule(
        id: i, // Each pending notification needs a unique number
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime(
          tz.local,
          reminder.at.year,
          reminder.at.month,
          reminder.at.day,
          reminder.at.hour,
        ),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAllPendingNotifications();
  }

  @override
  Future<void> sendTestNotification() async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id: _testNotificationId,
      title: 'Subbies test',
      body: 'Reminders are working.',
      scheduledDate:
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

}