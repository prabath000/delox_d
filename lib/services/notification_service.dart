import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      final currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.toString()));
    } catch (e) {
      debugPrint('Notification Service Timezone Error: $e');
      try {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (inner) {
        debugPrint('Notification Service Fatal Timezone Error: $inner');
      }
    }
    
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('Notification Service Initialization Error: $e');
    }
  }

  Future<bool> checkPermissionStatus() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? notificationsEnabled = await androidImplementation.areNotificationsEnabled();
      // On Android 13+, we should also check for exact alarm if possible,
      // but areNotificationsEnabled is the primary driver.
      return notificationsEnabled ?? false;
    }
    
    // For iOS, we can check basic permissions if needed, 
    // but for now focusing on Android reliability.
    return true; 
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      try {
        // This will open the system settings for exact alarms if not granted
        // on some Android versions.
        await androidImplementation.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('Exact alarm permission request not supported or failed: $e');
      }
    }
  }

  // ---- Immediate popup notification (fires right away) ----
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_updates_v4',
      'Task Updates',
      channelDescription: 'Alerts for task creation and updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      ticker: 'ticker',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  // ---- Scheduled notification exactly at task time ----
  Future<void> scheduleTaskNotification(Task task) async {
    // If task is completed, don't schedule.
    // If task time is more than 5 minutes in the past, don't schedule.
    if (task.isCompleted || task.date.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      return;
    }

    final int id = task.id.hashCode.abs() % 1000000;
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders_v6',
      'Task Reminders',
      channelDescription: 'High-priority alerts for scheduled tasks',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      category: AndroidNotificationCategory.reminder,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      ledColor: Color.fromARGB(255, 233, 30, 140),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      final scheduledDate = tz.TZDateTime.from(task.date, tz.local);
      final now = tz.TZDateTime.now(tz.local);
      
      debugPrint('Scheduling task "${task.title}" (ID: $id) for $scheduledDate. Current time: $now');

      // If the date is in the past, zonedSchedule will throw an error.
      if (scheduledDate.isBefore(now)) {
        // If it was scheduled for "now" or very recently, 
        // trigger an immediate notification.
        if (scheduledDate.isAfter(now.subtract(const Duration(minutes: 2)))) {
          debugPrint('Task "${task.title}" is due now/recently. Showing immediate reminder.');
          await _notificationsPlugin.show(
            id,
            '⚡ TASK STARTING NOW',
            'Time to start: ${task.title}',
            details,
          );
        }
        return;
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        '⏰ Task Reminder',
        '${task.title} is starting now!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelTaskNotification(String id) async {
    await _notificationsPlugin.cancel(id.hashCode.abs() % 1000000);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> rescheduleAllTasks(List<Task> tasks) async {
    if (!_initialized) await init();
    
    // We DON'T call cancelAll() here because it can cause race conditions 
    // where a notification due right now is cancelled and then rescheduled 
    // slightly late or missed. scheduleTaskNotification handles updates 
    // correctly by using the same hash-based ID.
    
    final List<Future<void>> futures = [];
    for (final task in tasks) {
      futures.add(scheduleTaskNotification(task));
    }
    await Future.wait(futures);
  }
}
