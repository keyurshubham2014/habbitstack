import 'database_service.dart';
import '../models/habit.dart';

class HabitService {
  final DatabaseService _db = DatabaseService.instance;

  Future<int> createHabit(Habit habit) async {
    return await _db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getAllHabits(int userId) async {
    final results = await _db.query(
      'habits',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> getAnchorHabits(int userId) async {
    final results = await _db.query(
      'habits',
      where: 'user_id = ? AND is_anchor = ?',
      whereArgs: [userId, 1],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => Habit.fromMap(map)).toList();
  }

  Future<Habit?> getHabit(int id) async {
    final results = await _db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Habit.fromMap(results.first);
  }

  Future<int> updateHabit(Habit habit) async {
    return await _db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    return await _db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsAnchor(int habitId, bool isAnchor) async {
    await _db.update(
      'habits',
      {'is_anchor': isAnchor ? 1 : 0},
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }
}
