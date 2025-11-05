import 'database_service.dart';
import '../models/daily_log.dart';
import 'streak_calculator.dart';
import 'habit_service.dart';

class LogService {
  final DatabaseService _db = DatabaseService.instance;
  final StreakCalculator _streakCalculator = StreakCalculator();
  final HabitService _habitService = HabitService();

  Future<int> createLog(DailyLog log) async {
    // Extract tags from notes before saving
    final tags = DailyLog.extractTags(log.notes);
    final logWithTags = log.copyWith(tags: tags.isNotEmpty ? tags : null);

    final id = await _db.insert('daily_logs', logWithTags.toMap());

    // Calculate streak after logging
    try {
      final habit = await _habitService.getHabit(log.habitId);
      if (habit != null) {
        final recentLogs = await getLogsForHabit(log.habitId, days: 90);
        await _streakCalculator.calculateStreak(
          userId: log.userId,
          habit: habit,
          recentLogs: recentLogs,
        );
      }
    } catch (e) {
      // Log error but don't fail the log creation
      print('Error calculating streak: $e');
    }

    return id;
  }

  Future<List<DailyLog>> getTodaysLogs(int userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = await _db.query(
      'daily_logs',
      where: 'user_id = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'completed_at DESC',
    );

    return results.map((map) => DailyLog.fromMap(map)).toList();
  }

  Future<List<DailyLog>> getLogsForHabit(int habitId, {int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final results = await _db.query(
      'daily_logs',
      where: 'habit_id = ? AND completed_at >= ?',
      whereArgs: [habitId, startDate.toIso8601String()],
      orderBy: 'completed_at DESC',
    );

    return results.map((map) => DailyLog.fromMap(map)).toList();
  }

  Future<List<DailyLog>> getLogsForDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await _db.query(
      'daily_logs',
      where: 'user_id = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'completed_at DESC',
    );

    return results.map((map) => DailyLog.fromMap(map)).toList();
  }

  Future<int> updateLog(DailyLog log) async {
    // Extract tags from notes before updating
    final tags = DailyLog.extractTags(log.notes);
    final logWithTags = log.copyWith(tags: tags.isNotEmpty ? tags : null);

    return await _db.update(
      'daily_logs',
      logWithTags.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteLog(int id) async {
    return await _db.delete(
      'daily_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all logs that have notes (for search functionality)
  Future<List<DailyLog>> getAllLogsWithNotes(int userId, {int days = 90}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final results = await _db.query(
      'daily_logs',
      where: 'user_id = ? AND completed_at >= ? AND (notes IS NOT NULL AND notes != "")',
      whereArgs: [userId, startDate.toIso8601String()],
      orderBy: 'completed_at DESC',
    );

    return results.map((map) => DailyLog.fromMap(map)).toList();
  }

  /// Get all unique tags from user's logs
  Future<List<String>> getAllTags(int userId, {int days = 90}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final results = await _db.query(
      'daily_logs',
      where: 'user_id = ? AND completed_at >= ? AND (tags IS NOT NULL AND tags != "")',
      whereArgs: [userId, startDate.toIso8601String()],
    );

    final allTags = <String>{};
    for (final map in results) {
      final tagsStr = map['tags'] as String?;
      if (tagsStr != null && tagsStr.isNotEmpty) {
        allTags.addAll(tagsStr.split(','));
      }
    }

    return allTags.toList()..sort();
  }

  /// Get sentiment distribution for analytics
  Future<Map<String, int>> getSentimentDistribution(int userId, {int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    final results = await _db.query(
      'daily_logs',
      where: 'user_id = ? AND completed_at >= ? AND sentiment IS NOT NULL',
      whereArgs: [userId, startDate.toIso8601String()],
    );

    final distribution = <String, int>{
      'happy': 0,
      'neutral': 0,
      'struggled': 0,
    };

    for (final map in results) {
      final sentiment = map['sentiment'] as String?;
      if (sentiment != null && distribution.containsKey(sentiment)) {
        distribution[sentiment] = distribution[sentiment]! + 1;
      }
    }

    return distribution;
  }
}
