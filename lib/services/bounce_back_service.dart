import '../models/habit.dart';
import '../models/streak.dart';
import '../models/daily_log.dart';
import 'database_service.dart';
import 'streak_calculator.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BounceBackOpportunity {
  final Habit habit;
  final DateTime missedDate;
  final DateTime deadline; // 24 hours after missed
  final Duration timeRemaining;
  final bool canBounceBack;

  BounceBackOpportunity({
    required this.habit,
    required this.missedDate,
    required this.deadline,
    required this.timeRemaining,
    required this.canBounceBack,
  });

  bool get isExpired => timeRemaining.isNegative;

  String get formattedTimeRemaining {
    if (isExpired) return 'Expired';

    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hr $minutes min remaining';
    }
    return '$minutes min remaining';
  }
}

class BounceBackService {
  final DatabaseService _db = DatabaseService.instance;
  final StreakCalculator _streakCalculator = StreakCalculator();
  final NotificationService _notificationService = NotificationService();

  /// Get all available bounce back opportunities for a user
  Future<List<BounceBackOpportunity>> getAvailableBouncebacks(int userId) async {
    final opportunities = <BounceBackOpportunity>[];

    // Check if bounce back reminders are enabled
    final prefs = await SharedPreferences.getInstance();
    final bounceBackRemindersEnabled = prefs.getBool('bounce_back_reminders_enabled') ?? true;

    // Get all habits with active streaks
    final streaks = await _streakCalculator.getAllStreaks(userId);

    for (final streak in streaks) {
      // Only check habits that are in grace period or broken recently
      if (streak.status == StreakStatus.perfect) continue;

      final opportunity = await _checkBounceBackEligibility(userId, streak);
      if (opportunity != null && opportunity.canBounceBack && !opportunity.isExpired) {
        opportunities.add(opportunity);

        // Schedule notification if enabled
        if (bounceBackRemindersEnabled) {
          await _notificationService.scheduleBounceBackReminder(
            habit: opportunity.habit,
            deadline: opportunity.deadline,
          );
        }
      }
    }

    return opportunities;
  }

  /// Check if a specific habit is eligible for bounce back
  Future<BounceBackOpportunity?> _checkBounceBackEligibility(
    int userId,
    Streak streak,
  ) async {
    // Get habit
    final habitMaps = await _db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [streak.habitId],
    );
    if (habitMaps.isEmpty) return null;

    final habit = Habit.fromMap(habitMaps.first);

    // Find the most recent missed day
    final missedDate = await _findMostRecentMissedDay(userId, habit, streak);
    if (missedDate == null) return null;

    // Calculate deadline (24 hours after end of missed day)
    final endOfMissedDay = DateTime(missedDate.year, missedDate.month, missedDate.day, 23, 59, 59);
    final deadline = endOfMissedDay.add(const Duration(hours: 24));
    final now = DateTime.now();
    final timeRemaining = deadline.difference(now);

    // Check if user has bounce backs remaining
    final canBounceBack = streak.canBounceBack && !timeRemaining.isNegative;

    return BounceBackOpportunity(
      habit: habit,
      missedDate: missedDate,
      deadline: deadline,
      timeRemaining: timeRemaining,
      canBounceBack: canBounceBack,
    );
  }

  /// Find the most recent day a habit was missed
  Future<DateTime?> _findMostRecentMissedDay(
    int userId,
    Habit habit,
    Streak streak,
  ) async {
    // Check yesterday and today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if habit should have been done yesterday
    if (_shouldTrackOnDate(yesterday, habit)) {
      final logged = await _wasHabitLoggedOnDate(userId, habit.id!, yesterday);
      if (!logged) {
        return yesterday;
      }
    }

    return null;
  }

  /// Check if habit was logged on a specific date
  Future<bool> _wasHabitLoggedOnDate(
    int userId,
    int habitId,
    DateTime date,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final maps = await _db.query(
      'daily_logs',
      where: 'user_id = ? AND habit_id = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        userId,
        habitId,
        dayStart.toIso8601String(),
        dayEnd.toIso8601String(),
      ],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  /// Execute a bounce back - retroactively log the habit
  Future<bool> executeBounceBack({
    required int userId,
    required Habit habit,
    required DateTime missedDate,
    String? notes,
  }) async {
    // Get current streak
    final streak = await _streakCalculator.getStreak(userId, habit.id!);
    if (streak == null) return false;

    // Check eligibility
    if (!streak.canBounceBack) {
      throw Exception('No bounce backs remaining this week');
    }

    final opportunity = await _checkBounceBackEligibility(userId, streak);
    if (opportunity == null || !opportunity.canBounceBack) {
      throw Exception('Bounce back window expired or not eligible');
    }

    // Create retroactive log entry
    final log = DailyLog(
      userId: userId,
      habitId: habit.id!,
      completedAt: missedDate.add(const Duration(hours: 12)), // Set to noon of missed day
      notes: notes ?? 'Bounced back - better late than never!',
      sentiment: 'neutral',
      createdAt: DateTime.now(),
    );

    await _db.insert('daily_logs', log.toMap());

    // Update streak with bounce back usage
    final updatedStreak = streak.copyWith(
      bounceBacksUsedThisWeek: streak.bounceBacksUsedThisWeek + 1,
      lastBounceBackAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.update(
      'streaks',
      updatedStreak.toMap(),
      where: 'id = ?',
      whereArgs: [streak.id],
    );

    // Recalculate streak
    final recentLogs = await _getRecentLogs(userId, habit.id!);
    await _streakCalculator.calculateStreak(
      userId: userId,
      habit: habit,
      recentLogs: recentLogs,
    );

    return true;
  }

  /// Check if habit should be tracked on date
  bool _shouldTrackOnDate(DateTime date, Habit habit) {
    final weekday = date.weekday;

    switch (habit.frequency) {
      case 'daily':
        return true;
      case 'weekdays':
        return weekday >= 1 && weekday <= 5;
      case 'weekends':
        return weekday == 6 || weekday == 7;
      case 'custom':
        return habit.customDays?.contains(weekday) ?? false;
      default:
        return true;
    }
  }

  Future<List<DailyLog>> _getRecentLogs(int userId, int habitId) async {
    final maps = await _db.query(
      'daily_logs',
      where: 'user_id = ? AND habit_id = ?',
      whereArgs: [userId, habitId],
      orderBy: 'completed_at DESC',
      limit: 90,
    );

    return maps.map((map) => DailyLog.fromMap(map)).toList();
  }
}
