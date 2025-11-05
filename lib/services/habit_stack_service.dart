import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/habit_stack.dart';
import '../models/habit.dart';

class HabitStackService {
  final DatabaseService _db = DatabaseService.instance;

  /// Create a new habit stack
  Future<int> createStack(HabitStack stack) async {
    return await _db.insert('habit_stacks', stack.toMap());
  }

  /// Get all stacks for a user
  Future<List<HabitStack>> getAllStacks(int userId) async {
    final results = await _db.query(
      'habit_stacks',
      where: 'user_id = ? AND is_active = ?',
      whereArgs: [userId, 1],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => HabitStack.fromMap(map)).toList();
  }

  /// Get a single stack by ID with its habits
  Future<HabitStack?> getStackWithHabits(int stackId) async {
    final results = await _db.query(
      'habit_stacks',
      where: 'id = ?',
      whereArgs: [stackId],
    );

    if (results.isEmpty) return null;

    final stack = HabitStack.fromMap(results.first);

    // Get anchor habit if exists
    Habit? anchorHabit;
    if (stack.anchorHabitId != null) {
      final anchorResults = await _db.query(
        'habits',
        where: 'id = ?',
        whereArgs: [stack.anchorHabitId],
      );
      if (anchorResults.isNotEmpty) {
        anchorHabit = Habit.fromMap(anchorResults.first);
      }
    }

    // Get all habits in this stack
    final habitResults = await _db.query(
      'habits',
      where: 'stack_id = ? AND is_active = ?',
      whereArgs: [stackId, 1],
      orderBy: 'order_in_stack ASC',
    );

    final stackedHabits = habitResults.map((map) => Habit.fromMap(map)).toList();

    return stack.copyWith(
      anchorHabit: anchorHabit,
      stackedHabits: stackedHabits,
    );
  }

  /// Update a habit stack
  Future<int> updateStack(HabitStack stack) async {
    final updatedStack = stack.copyWith(
      updatedAt: DateTime.now(),
    );
    return await _db.update(
      'habit_stacks',
      updatedStack.toMap(),
      where: 'id = ?',
      whereArgs: [stack.id],
    );
  }

  /// Soft delete a stack (sets is_active to false)
  Future<int> deleteStack(int stackId) async {
    return await _db.update(
      'habit_stacks',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [stackId],
    );
  }

  /// Hard delete a stack (permanent)
  Future<int> permanentlyDeleteStack(int stackId) async {
    // First, remove stack_id from all associated habits
    await _db.update(
      'habits',
      {'stack_id': null},
      where: 'stack_id = ?',
      whereArgs: [stackId],
    );

    // Then delete the stack
    return await _db.delete(
      'habit_stacks',
      where: 'id = ?',
      whereArgs: [stackId],
    );
  }

  /// Add a habit to a stack
  Future<int> addHabitToStack(int habitId, int stackId, int orderInStack) async {
    return await _db.update(
      'habits',
      {
        'stack_id': stackId,
        'order_in_stack': orderInStack,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  /// Remove a habit from a stack
  Future<int> removeHabitFromStack(int habitId) async {
    return await _db.update(
      'habits',
      {
        'stack_id': null,
        'order_in_stack': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  /// Reorder habits in a stack
  Future<void> reorderHabits(List<int> habitIds) async {
    for (int i = 0; i < habitIds.length; i++) {
      await _db.update(
        'habits',
        {
          'order_in_stack': i,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [habitIds[i]],
      );
    }
  }

  /// Get all habits not in any stack for a user
  Future<List<Habit>> getUnstackedHabits(int userId) async {
    final results = await _db.query(
      'habits',
      where: 'user_id = ? AND stack_id IS NULL AND is_active = ?',
      whereArgs: [userId, 1],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => Habit.fromMap(map)).toList();
  }

  /// Get statistics for a stack
  Future<Map<String, dynamic>> getStackStats(int stackId) async {
    final stack = await getStackWithHabits(stackId);
    if (stack == null) return {};

    final habitCount = stack.habitCount;

    // Get completion stats for today
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    int completedToday = 0;
    if (stack.stackedHabits != null) {
      for (final habit in stack.stackedHabits!) {
        final logs = await _db.query(
          'daily_logs',
          where: 'habit_id = ? AND completed_at >= ? AND completed_at < ?',
          whereArgs: [
            habit.id,
            startOfDay.toIso8601String(),
            endOfDay.toIso8601String(),
          ],
        );
        if (logs.isNotEmpty) completedToday++;
      }
    }

    return {
      'habitCount': habitCount,
      'completedToday': completedToday,
      'completionRate': habitCount > 0 ? (completedToday / habitCount * 100).round() : 0,
    };
  }

  /// Create a complete stack with habits in a single transaction
  Future<int> createStackWithHabits({
    required HabitStack stack,
    required Habit anchorHabit,
    required List<Habit> stackedHabits,
  }) async {
    return await _db.transaction((txn) async {
      // 1. Create the stack
      final stackMap = stack.toMap();
      stackMap.remove('id'); // Let DB auto-generate
      final stackId = await txn.insert('habit_stacks', stackMap);

      // 2. Update the stack with anchor habit reference
      await txn.update(
        'habit_stacks',
        {'anchor_habit_id': anchorHabit.id},
        where: 'id = ?',
        whereArgs: [stackId],
      );

      // 3. Update anchor habit
      final anchorMap = anchorHabit.copyWith(
        isAnchor: true,
        stackId: stackId,
        orderInStack: 0,
        updatedAt: DateTime.now(),
      ).toMap();
      await txn.update(
        'habits',
        anchorMap,
        where: 'id = ?',
        whereArgs: [anchorHabit.id],
      );

      // 4. Update stacked habits
      for (var i = 0; i < stackedHabits.length; i++) {
        final habitMap = stackedHabits[i].copyWith(
          stackId: stackId,
          orderInStack: i + 1,
          updatedAt: DateTime.now(),
        ).toMap();
        await txn.update(
          'habits',
          habitMap,
          where: 'id = ?',
          whereArgs: [stackedHabits[i].id],
        );
      }

      return stackId;
    });
  }

  /// Update an existing stack with new habits order in a transaction
  Future<void> updateStackWithHabits({
    required HabitStack stack,
    required Habit anchorHabit,
    required List<Habit> stackedHabits,
  }) async {
    await _db.transaction((txn) async {
      // 1. Update stack metadata
      final stackMap = stack.copyWith(updatedAt: DateTime.now()).toMap();
      await txn.update(
        'habit_stacks',
        stackMap,
        where: 'id = ?',
        whereArgs: [stack.id],
      );

      // 2. Clear all existing stack associations for this stack
      await txn.update(
        'habits',
        {'stack_id': null, 'order_in_stack': null, 'is_anchor': 0},
        where: 'stack_id = ?',
        whereArgs: [stack.id],
      );

      // 3. Update anchor habit ID in stack
      await txn.update(
        'habit_stacks',
        {'anchor_habit_id': anchorHabit.id},
        where: 'id = ?',
        whereArgs: [stack.id],
      );

      // 4. Set new anchor habit
      final anchorMap = anchorHabit.copyWith(
        isAnchor: true,
        stackId: stack.id,
        orderInStack: 0,
        updatedAt: DateTime.now(),
      ).toMap();
      await txn.update(
        'habits',
        anchorMap,
        where: 'id = ?',
        whereArgs: [anchorHabit.id],
      );

      // 5. Set new stacked habits with order
      for (var i = 0; i < stackedHabits.length; i++) {
        final habitMap = stackedHabits[i].copyWith(
          stackId: stack.id,
          orderInStack: i + 1,
          updatedAt: DateTime.now(),
        ).toMap();
        await txn.update(
          'habits',
          habitMap,
          where: 'id = ?',
          whereArgs: [stackedHabits[i].id],
        );
      }
    });
  }

  /// Delete stack and handle orphaned habits in a transaction
  Future<void> deleteStackCascade(int stackId, {bool deleteHabits = false}) async {
    await _db.transaction((txn) async {
      if (deleteHabits) {
        // Hard delete: Remove all habits in the stack
        await txn.delete(
          'habits',
          where: 'stack_id = ?',
          whereArgs: [stackId],
        );
      } else {
        // Soft delete: Unlink habits from stack (keep habits)
        await txn.update(
          'habits',
          {
            'stack_id': null,
            'order_in_stack': null,
            'is_anchor': 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'stack_id = ?',
          whereArgs: [stackId],
        );
      }

      // Soft delete the stack
      await txn.update(
        'habit_stacks',
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [stackId],
      );
    });
  }

  /// Get all orphaned habits (habits without a stack)
  Future<List<Habit>> getOrphanedHabits(int userId) async {
    final results = await _db.query(
      'habits',
      where: 'user_id = ? AND stack_id IS NULL AND is_active = ?',
      whereArgs: [userId, 1],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => Habit.fromMap(map)).toList();
  }

  /// Validate stack integrity
  Future<bool> validateStackIntegrity(int stackId) async {
    final stack = await getStackWithHabits(stackId);
    if (stack == null) return false;

    // Check if anchor habit exists
    if (stack.anchorHabit == null) {
      return false;
    }

    // Check if habit orders are sequential
    final habits = stack.stackedHabits ?? [];
    for (var i = 0; i < habits.length; i++) {
      if (habits[i].orderInStack != i + 1) {
        return false;
      }
    }

    return true;
  }

  /// Repair stack integrity issues
  Future<void> repairStackIntegrity(int stackId) async {
    final stack = await getStackWithHabits(stackId);
    if (stack == null) return;

    await _db.transaction((txn) async {
      // Reorder habits sequentially
      final habits = stack.stackedHabits ?? [];
      for (var i = 0; i < habits.length; i++) {
        await txn.update(
          'habits',
          {
            'order_in_stack': i + 1,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [habits[i].id],
        );
      }

      // Ensure anchor habit has order 0
      if (stack.anchorHabit != null) {
        await txn.update(
          'habits',
          {
            'order_in_stack': 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [stack.anchorHabit!.id],
        );
      }
    });
  }
}
