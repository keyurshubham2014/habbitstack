import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigate to appropriate screen based on payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return result ?? false;
  }

  /// Schedule daily habit reminder
  Future<void> scheduleHabitReminder({
    required Habit habit,
    required TimeOfDay reminderTime,
  }) async {
    await _notifications.zonedSchedule(
      habit.id!, // Use habit ID as notification ID
      'Time for ${habit.name}!',
      'Don\'t break your streak - log your habit now',
      _nextInstanceOfTime(reminderTime),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Daily reminders for your habits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit:${habit.id}',
    );
  }

  /// Schedule bounce back reminder (6 hours before deadline)
  Future<void> scheduleBounceBackReminder({
    required Habit habit,
    required DateTime deadline,
  }) async {
    final reminderTime = deadline.subtract(const Duration(hours: 6));

    if (reminderTime.isBefore(DateTime.now())) {
      return; // Too late to send reminder
    }

    await _notifications.zonedSchedule(
      10000 + habit.id!, // Unique ID for bounce back notifications
      '⚡ Bounce Back Available',
      'You have 6 hours left to save your ${habit.name} streak!',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bounce_back',
          'Bounce Back Reminders',
          channelDescription: 'Reminders to save your streaks',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFFA726), // Warning amber
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
      payload: 'bounce_back:${habit.id}',
    );
  }

  /// Send streak milestone celebration
  Future<void> sendStreakMilestone({
    required Habit habit,
    required int streakDays,
  }) async {
    String title;
    String body;

    if (streakDays == 7) {
      title = '🎉 7-Day Streak!';
      body = 'Amazing! You\'ve completed ${habit.name} for a whole week!';
    } else if (streakDays == 14) {
      title = '🔥 2-Week Streak!';
      body = 'Incredible! ${habit.name} is becoming a real habit!';
    } else if (streakDays == 30) {
      title = '🏆 30-Day Streak!';
      body = 'Legendary! You\'ve mastered ${habit.name} for a month!';
    } else if (streakDays == 100) {
      title = '👑 100-Day Streak!';
      body = 'Unstoppable! ${habit.name} is part of who you are now!';
    } else {
      return; // Not a milestone
    }

    await _notifications.show(
      20000 + habit.id!, // Unique ID for milestone notifications
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'milestones',
          'Streak Milestones',
          channelDescription: 'Celebrations for streak achievements',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF66BB6A), // Success green
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'milestone:${habit.id}:$streakDays',
    );
  }

  /// Send grace period warning
  Future<void> sendGracePeriodWarning({
    required Habit habit,
    required int strikesRemaining,
  }) async {
    await _notifications.show(
      30000 + habit.id!, // Unique ID for grace warnings
      '⚠️ Grace Period Alert',
      'You have $strikesRemaining ${strikesRemaining == 1 ? 'strike' : 'strikes'} left for ${habit.name}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'grace_warnings',
          'Grace Period Warnings',
          channelDescription: 'Alerts when streak is at risk',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFFA726), // Warning amber
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'grace_warning:${habit.id}',
    );
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    await _notifications.show(
      99999, // Unique ID for test notifications
      '✅ Test Notification',
      'Great! Your notifications are working perfectly.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_notifications',
          'Test Notifications',
          channelDescription: 'Test notifications to verify setup',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4ECDC4), // Gentle teal
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test',
    );
  }

  /// Schedule daily app reminder (not habit-specific)
  Future<void> scheduleDailyReminder({
    required TimeOfDay reminderTime,
  }) async {
    final scheduledTime = _nextInstanceOfTime(reminderTime);

    debugPrint('🔔 Scheduling daily reminder for: $scheduledTime');
    debugPrint('🔔 Reminder will repeat daily at ${reminderTime.hour}:${reminderTime.minute}');

    await _notifications.zonedSchedule(
      99998, // Unique ID for daily app reminder
      '📝 Time to Log Your Day',
      'Take a moment to reflect and log your habits',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily reminder to log your habits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4ECDC4), // Gentle teal
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    // Verify it was scheduled
    final pending = await getPendingNotifications();
    debugPrint('🔔 Pending notifications: ${pending.length}');
    for (var notification in pending) {
      debugPrint('🔔 ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
    }
  }

  /// Cancel daily app reminder
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(99998);
  }

  /// Cancel habit reminder
  Future<void> cancelHabitReminder(int habitId) async {
    await _notifications.cancel(habitId);
  }

  /// Cancel all bounce back reminders for habit
  Future<void> cancelBounceBackReminder(int habitId) async {
    await _notifications.cancel(10000 + habitId);
  }

  /// Cancel all notifications for a habit
  Future<void> cancelAllForHabit(int habitId) async {
    await _notifications.cancel(habitId); // Daily reminder
    await _notifications.cancel(10000 + habitId); // Bounce back
    await _notifications.cancel(20000 + habitId); // Milestone
    await _notifications.cancel(30000 + habitId); // Grace warning
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Calculate next instance of a time
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
