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
      String? currentTimeZone;
      try {
        final result = await FlutterTimezone.getLocalTimezone();
        currentTimeZone = result.toString();
      } catch (e) {
        debugPrint('FlutterTimezone failed, trying manual detection: $e');
      }
      
      // Fallback for India if detection fails (very common)
      currentTimeZone ??= 'Asia/Kolkata'; 
      
      try {
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
      } catch (e) {
        debugPrint('Location $currentTimeZone not found, falling back to UTC');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint('Notification Service Fatal Timezone Error: $e');
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
    // For iOS, check permission status
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    
    return true; 
  }

  Future<void> requestPermissions() async {
    // Request iOS permissions
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
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

  // Diagnostic test for the user
  Future<void> testImmediateNotification() async {
    await showImmediateNotification(
      title: '🔔 Test Notification',
      body: 'If you see this, your notifications are working perfectly!',
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
