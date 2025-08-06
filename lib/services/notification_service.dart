import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'database_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // Request permissions on iOS
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to specific screens based on the payload
  }

  // Schedule water reminders
  Future<void> scheduleWaterReminders() async {
    final settings = await DatabaseService.instance.getNotificationSettings();
    final enabled = settings['water_reminder_enabled'] ?? true;
    final interval = settings['water_reminder_interval'] ?? 30;

    // Cancel existing water reminders
    await cancelWaterReminders();

    if (!enabled) return;

    // Schedule reminders for the day (8 AM to 10 PM)
    final now = DateTime.now();
    var nextReminder = DateTime(now.year, now.month, now.day, 8, 0);
    if (nextReminder.isBefore(now)) {
      // Find next interval
      while (nextReminder.isBefore(now)) {
        nextReminder = nextReminder.add(Duration(minutes: interval));
      }
    }

    int id = 1000; // Starting ID for water reminders
    while (nextReminder.hour < 22) { // Until 10 PM
      await _notifications.zonedSchedule(
        id++,
        'Time to hydrate! 💧',
        'Remember to drink some water to stay healthy.',
        tz.TZDateTime.from(nextReminder, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminders',
            'Water Reminders',
            channelDescription: 'Reminds you to drink water regularly',
            importance: Importance.high,
            priority: Priority.high,
            // Remove the custom icon reference
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'water_reminder',
      );

      nextReminder = nextReminder.add(Duration(minutes: interval));
    }
  }

  Future<void> cancelWaterReminders() async {
    // Cancel all water reminder notifications (IDs 1000-1999)
    for (int i = 1000; i < 2000; i++) {
      await _notifications.cancel(i);
    }
  }

  // Schedule goal reminders
  Future<void> scheduleGoalReminders() async {
    final settings = await DatabaseService.instance.getNotificationSettings();
    final enabled = settings['goal_reminder_enabled'] ?? true;
    final count = settings['goal_reminder_count'] ?? 5;

    // Cancel existing goal reminders
    await cancelGoalReminders();

    if (!enabled) return;

    final goals = await DatabaseService.instance.getTodayGoals();
    final incompleteGoals = goals.where((g) => !g.isCompleted).toList();

    if (incompleteGoals.isEmpty) return;

    // Schedule reminders evenly throughout the day (9 AM to 9 PM)
    final now = DateTime.now();
    final startHour = 9;
    final endHour = 21;
    final totalHours = endHour - startHour;
    final intervalHours = totalHours / count;

    int id = 2000; // Starting ID for goal reminders
    for (int i = 0; i < count; i++) {
      final hour = startHour + (intervalHours * i).round();
      final reminderTime = DateTime(now.year, now.month, now.day, hour, 0);

      if (reminderTime.isAfter(now)) {
        await _notifications.zonedSchedule(
          id++,
          'Daily Goal Reminder 🎯',
          'You have ${incompleteGoals.length} goal${incompleteGoals.length > 1 ? 's' : ''} to complete today!',
          tz.TZDateTime.from(reminderTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'goal_reminders',
              'Goal Reminders',
              channelDescription: 'Reminds you to complete your daily goals',
              importance: Importance.high,
              priority: Priority.high,
              // Remove the custom icon reference
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'goal_reminder',
        );
      }
    }
  }

  Future<void> cancelGoalReminders() async {
    // Cancel all goal reminder notifications (IDs 2000-2999)
    for (int i = 2000; i < 3000; i++) {
      await _notifications.cancel(i);
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true; // Assume true for iOS or if we can't check
  }

  // Request notification permissions explicitly
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    return false;
  }

  // Update all notifications based on current settings
  Future<void> updateAllNotifications() async {
    await scheduleWaterReminders();
    await scheduleGoalReminders();
  }
}