import 'package:sqflite/sqflite.dart';
import '../models/streak.dart';
import '../models/habit.dart';
import '../models/daily_log.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakCalculator {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notificationService = NotificationService();

  /// Calculate and update streak for a habit after logging
  Future<Streak> calculateStreak({
    required int userId,
    required Habit habit,
    required List<DailyLog> recentLogs,
  }) async {
    // Get existing streak or create new one
    final existingStreak = await getStreak(userId, habit.id!);

    if (existingStreak == null) {
      return await _createInitialStreak(userId, habit, recentLogs);
    }

    return await _updateStreak(existingStreak, habit, recentLogs);
  }

  /// Get streak for a specific habit
  Future<Streak?> getStreak(int userId, int habitId) async {
    final results = await _db.query(
      'streaks',
      where: 'user_id = ? AND habit_id = ?',
      whereArgs: [userId, habitId],
    );

    if (results.isEmpty) return null;
    return Streak.fromMap(results.first);
  }

  /// Get all streaks for a user
  Future<List<Streak>> getAllStreaks(int userId) async {
    final results = await _db.query(
      'streaks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'current_streak DESC',
    );

    return results.map((map) => Streak.fromMap(map)).toList();
  }

  /// Create initial streak for a habit
  Future<Streak> _createInitialStreak(
    int userId,
    Habit habit,
    List<DailyLog> logs,
  ) async {
    final now = DateTime.now();
    final streak = Streak(
      userId: userId,
      habitId: habit.id!,
      currentStreak: logs.isNotEmpty ? 1 : 0,
      longestStreak: logs.isNotEmpty ? 1 : 0,
      totalCompletions: logs.length,
      lastCompletedAt: logs.isNotEmpty ? logs.first.completedAt : now,
      createdAt: now,
      updatedAt: now,
    );

    final id = await _saveStreak(streak);
    return streak.copyWith(id: id);
  }

  /// Update existing streak based on recent logs
  Future<Streak> _updateStreak(
    Streak currentStreak,
    Habit habit,
    List<DailyLog> recentLogs,
  ) async {
    // Sort logs by date (most recent first)
    final sortedLogs = List<DailyLog>.from(recentLogs);
    sortedLogs.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    // Calculate streak from logs
    final streakData = _calculateStreakFromLogs(
      habit: habit,
      logs: sortedLogs,
      currentStreak: currentStreak,
    );

    // Determine status based on grace period
    final status = _determineStreakStatus(
      streakData['missedDays'] as int,
      currentStreak.gracePeriodUsed,
      currentStreak.maxGracePeriod,
    );

    // Calculate new grace period used
    int newGraceUsed = currentStreak.gracePeriodUsed;
    if (streakData['missedDays'] as int > 0) {
      newGraceUsed = (currentStreak.gracePeriodUsed + (streakData['missedDays'] as int))
          .clamp(0, currentStreak.maxGracePeriod);
    }

    // Check if we should reset grace period (weekly reset)
    final shouldResetGrace = _shouldResetGracePeriod(
      currentStreak.lastGracePeriodResetAt ?? currentStreak.createdAt,
    );

    if (shouldResetGrace) {
      newGraceUsed = 0;
    }

    // Build updated streak
    final updatedStreak = currentStreak.copyWith(
      currentStreak: streakData['currentStreak'] as int,
      longestStreak: (streakData['currentStreak'] as int > currentStreak.longestStreak)
          ? streakData['currentStreak'] as int
          : currentStreak.longestStreak,
      totalCompletions: currentStreak.totalCompletions + 1,
      gracePeriodUsed: newGraceUsed,
      status: status,
      lastCompletedAt: sortedLogs.first.completedAt,
      lastGracePeriodResetAt: shouldResetGrace ? DateTime.now() : currentStreak.lastGracePeriodResetAt,
      updatedAt: DateTime.now(),
    );

    await _saveStreak(updatedStreak);

    // Send milestone notification if reached
    await _checkAndSendMilestoneNotification(habit, updatedStreak);

    // Send grace period warning if needed
    await _checkAndSendGracePeriodWarning(habit, updatedStreak);

    return updatedStreak;
  }

  /// Check if milestone reached and send notification
  Future<void> _checkAndSendMilestoneNotification(Habit habit, Streak streak) async {
    final prefs = await SharedPreferences.getInstance();
    final milestoneNotificationsEnabled = prefs.getBool('milestone_notifications_enabled') ?? true;

    if (!milestoneNotificationsEnabled) return;

    // Check if current streak is a milestone
    final milestones = [7, 14, 30, 100];
    if (milestones.contains(streak.currentStreak)) {
      await _notificationService.sendStreakMilestone(
        habit: habit,
        streakDays: streak.currentStreak,
      );
    }
  }

  /// Check if grace period warning should be sent
  Future<void> _checkAndSendGracePeriodWarning(Habit habit, Streak streak) async {
    final prefs = await SharedPreferences.getInstance();
    final gracePeriodWarningsEnabled = prefs.getBool('grace_period_warnings_enabled') ?? true;

    if (!gracePeriodWarningsEnabled) return;

    // Send warning if user has 1 strike remaining
    if (streak.remainingGraceStrikes == 1 && streak.status == StreakStatus.gracePeriod) {
      await _notificationService.sendGracePeriodWarning(
        habit: habit,
        strikesRemaining: streak.remainingGraceStrikes,
      );
    }
  }

  /// Calculate streak and missed days from logs
  Map<String, int> _calculateStreakFromLogs({
    required Habit habit,
    required List<DailyLog> logs,
    required Streak currentStreak,
  }) {
    if (logs.isEmpty) {
      return {'currentStreak': 0, 'missedDays': 0};
    }

    int streakCount = 0;
    int missedDays = 0;
    DateTime checkDate = DateTime.now();

    // Normalize to start of day
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // Create set of logged dates for quick lookup
    final loggedDates = logs.map((log) {
      final date = log.completedAt;
      return DateTime(date.year, date.month, date.day);
    }).toSet();

    // Check backwards from today
    bool foundGap = false;
    for (int i = 0; i < 90; i++) { // Check up to 90 days back
      if (!_shouldTrackOnDate(checkDate, habit)) {
        // Skip days not in habit frequency
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      if (loggedDates.contains(checkDate)) {
        if (!foundGap) {
          streakCount++;
        } else {
          break; // Stop counting after first gap
        }
      } else {
        // Found a missed day
        if (streakCount == 0 && i < 7) {
          // Only count misses in the last week for grace period
          missedDays++;
        }
        foundGap = true;
      }

      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return {
      'currentStreak': streakCount,
      'missedDays': missedDays,
    };
  }

  /// Determine streak status based on grace period
  StreakStatus _determineStreakStatus(
    int missedDays,
    int currentGraceUsed,
    int maxGracePeriod,
  ) {
    if (missedDays == 0 && currentGraceUsed == 0) {
      return StreakStatus.perfect;
    } else if (currentGraceUsed < maxGracePeriod) {
      return StreakStatus.gracePeriod;
    } else {
      return StreakStatus.broken;
    }
  }

  /// Check if habit should be tracked on a specific date
  bool _shouldTrackOnDate(DateTime date, Habit habit) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday

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

  /// Check if grace period should reset (weekly)
  bool _shouldResetGracePeriod(DateTime lastReset) {
    final now = DateTime.now();
    final daysSinceReset = now.difference(lastReset).inDays;
    return daysSinceReset >= 7;
  }

  /// Save streak to database
  Future<int> _saveStreak(Streak streak) async {
    if (streak.id == null) {
      // Insert new streak
      return await _db.insert('streaks', streak.toMap());
    } else {
      // Update existing streak
      await _db.update(
        'streaks',
        streak.toMap(),
        where: 'id = ?',
        whereArgs: [streak.id],
      );
      return streak.id!;
    }
  }

  /// Recalculate all streaks for a user (useful for migrations)
  Future<void> recalculateAllStreaks(int userId) async {
    // Get all habits for user
    final habitResults = await _db.query(
      'habits',
      where: 'user_id = ? AND is_active = ?',
      whereArgs: [userId, 1],
    );

    for (final habitMap in habitResults) {
      final habit = Habit.fromMap(habitMap);

      // Get recent logs for this habit
      final logResults = await _db.query(
        'daily_logs',
        where: 'habit_id = ? AND user_id = ?',
        whereArgs: [habit.id, userId],
        orderBy: 'completed_at DESC',
        limit: 90,
      );

      final logs = logResults.map((map) => DailyLog.fromMap(map)).toList();

      if (logs.isNotEmpty) {
        // Recalculate streak
        await calculateStreak(
          userId: userId,
          habit: habit,
          recentLogs: logs,
        );
      }
    }
  }

  /// Delete streak when habit is deleted
  Future<void> deleteStreak(int userId, int habitId) async {
    await _db.delete(
      'streaks',
      where: 'user_id = ? AND habit_id = ?',
      whereArgs: [userId, habitId],
    );
  }
}
