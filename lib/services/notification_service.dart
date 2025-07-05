import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() => _instance;

  NotificationService._internal();

  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _reminderDaysKey = 'reminder_days';

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      // Set local timezone
      final String timeZoneName = 'Europe/Berlin';
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      print('Notification service initialized: $initialized');

      // Request permissions explicitly
      await _requestPermissions();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      // iOS permissions
      final bool? iosPermission = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: false,
          );

      // Android permissions (for Android 13+)
      final bool? androidPermission = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      print(
          'iOS permission: $iosPermission, Android permission: $androidPermission');

      return iosPermission ?? androidPermission ?? false;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleReadingReminder({
    required TimeOfDay time,
    required List<int> weekdays,
    String? bookTitle,
  }) async {
    try {
      print(
          'Scheduling reminders for time: ${time.hour}:${time.minute}, days: $weekdays');

      // Cancel existing reminders
      await cancelAllReminders();

      // Schedule for each selected day
      for (int weekday in weekdays) {
        await _scheduleWeeklyNotification(
          id: weekday,
          time: time,
          weekday: weekday,
          bookTitle: bookTitle,
        );
      }

      // Save settings
      await _saveReminderSettings(time, weekdays);

      // Verify scheduled notifications
      final pending = await getPendingNotifications();
      print('Scheduled ${pending.length} notifications');
      for (var notification in pending) {
        print(
            'Notification ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
      }
    } catch (e) {
      print('Error scheduling reminders: $e');
      rethrow;
    }
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required TimeOfDay time,
    required int weekday,
    String? bookTitle,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Adjust to the correct weekday
      while (scheduledDate.weekday != weekday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // If the time has already passed today, schedule for next week
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      final title = bookTitle != null
          ? 'Zeit zum Lesen: $bookTitle'
          : 'Zeit zum Lesen! 📚';

      const body = 'Vergiss nicht, heute ein paar Seiten zu lesen.';

      print('Scheduling notification for: $scheduledDate (weekday: $weekday)');

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'reading_reminders',
            'Leseerinnerungen',
            channelDescription: 'Erinnerungen für deine tägliche Lesezeit',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            autoCancel: false,
            ongoing: false,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
            threadIdentifier: 'reading_reminders',
            categoryIdentifier: 'reading_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'reading_reminder',
      );

      print('Notification scheduled successfully for ID: $id');
    } catch (e) {
      print('Error scheduling notification for weekday $weekday: $e');
      rethrow;
    }
  }

  // Add test notification method
  Future<void> showTestNotification() async {
    try {
      await _notifications.show(
        999,
        'Test Notification',
        'This is a test notification to verify the setup works.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      print('Test notification sent');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  // Add immediate test notification (5 seconds from now)
  Future<void> scheduleTestNotification() async {
    try {
      final scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

      await _notifications.zonedSchedule(
        998,
        'Scheduled Test',
        'This test notification was scheduled 5 seconds ago',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Test notification scheduled for 5 seconds from now');
    } catch (e) {
      print('Error scheduling test notification: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await _notifications.cancel(id);
      print('Notification $id cancelled');
    } catch (e) {
      print('Error cancelling notification $id: $e');
    }
  }

  Future<bool> isReminderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_reminderEnabledKey) ?? false;
    } catch (e) {
      print('Error checking if reminder enabled: $e');
      return false;
    }
  }

  Future<TimeOfDay?> getReminderTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_reminderTimeKey);
      if (timeString == null || timeString.isEmpty) return null;

      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      print('Error getting reminder time: $e');
      return null;
    }
  }

  Future<List<int>> getReminderDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final daysString = prefs.getString(_reminderDaysKey);
      if (daysString == null || daysString.isEmpty) return [];

      return daysString
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => int.parse(e))
          .toList();
    } catch (e) {
      print('Error getting reminder days: $e');
      return [];
    }
  }

  Future<void> _saveReminderSettings(TimeOfDay time, List<int> weekdays) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderEnabledKey, true);
      await prefs.setString(_reminderTimeKey, '${time.hour}:${time.minute}');
      await prefs.setString(_reminderDaysKey, weekdays.join(','));
      print('Reminder settings saved');
    } catch (e) {
      print('Error saving reminder settings: $e');
    }
  }

  Future<void> disableReminders() async {
    try {
      await cancelAllReminders();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderEnabledKey, false);
      print('Reminders disabled');
    } catch (e) {
      print('Error disabling reminders: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }
}

// Extension to get TimeOfDay from Flutter
extension TimeOfDayExtension on TimeOfDay {
  String get formatted {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
