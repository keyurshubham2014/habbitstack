import 'database_service.dart';
import '../models/daily_log.dart';

class LogService {
  final DatabaseService _db = DatabaseService.instance;

  Future<int> createLog(DailyLog log) async {
    return await _db.insert('daily_logs', log.toMap());
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
    return await _db.update(
      'daily_logs',
      log.toMap(),
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
}
