# Task 12: Stack Persistence & Database Integration

**Status**: ✅ DONE
**Priority**: HIGH
**Estimated Time**: 3 hours
**Assigned To**: Claude Code
**Dependencies**: Task 10 (Drag-and-Drop)
**Completed**: 2025-11-05

---

## Objective

Ensure habit stacks are properly saved, loaded, and synchronized with the SQLite database, maintaining data integrity across app sessions.

## Acceptance Criteria

- [x] Stacks persist across app restarts
- [x] Habit order within stacks maintained
- [x] Stack-habit relationships correctly stored
- [x] Orphaned habits handled gracefully
- [x] Database migrations handle schema changes
- [x] Cascade delete logic for stacks
- [x] Performance optimized for large datasets (indexes added)
- [x] Data integrity constraints enforced (transactions)

---

## Step-by-Step Instructions

### 1. Verify Database Schema

Ensure the database schema from Task 03 includes all necessary fields. Update if needed:

#### `lib/services/database_service.dart` - Update Schema

```dart
Future<void> _onCreate(Database db, int version) async {
  // ... existing tables ...

  // Ensure habit_stacks table exists
  await db.execute('''
    CREATE TABLE IF NOT EXISTS habit_stacks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      anchor_habit_id INTEGER,
      color TEXT,
      icon TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (anchor_habit_id) REFERENCES habits(id) ON DELETE SET NULL
    )
  ''');

  // Ensure habits table has stack fields
  await db.execute('''
    CREATE TABLE IF NOT EXISTS habits (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      icon TEXT,
      color TEXT,
      is_anchor INTEGER DEFAULT 0,
      frequency TEXT DEFAULT 'daily',
      custom_days TEXT,
      grace_period_config TEXT,
      stack_id INTEGER,
      order_in_stack INTEGER,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (stack_id) REFERENCES habit_stacks(id) ON DELETE SET NULL
    )
  ''');

  // Create indexes for better performance
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_habits_stack_id ON habits(stack_id)
  ''');

  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id)
  ''');

  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_stacks_user_id ON habit_stacks(user_id)
  ''');
}
```

### 2. Add Database Migration Support

#### Update `lib/services/database_service.dart`

```dart
class DatabaseService {
  // ... existing code ...

  static const int _databaseVersion = 2; // Increment version

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add stack_id and order_in_stack to habits if upgrading from v1
      await db.execute('''
        ALTER TABLE habits ADD COLUMN stack_id INTEGER
      ''');
      await db.execute('''
        ALTER TABLE habits ADD COLUMN order_in_stack INTEGER
      ''');
      await db.execute('''
        ALTER TABLE habits ADD COLUMN color TEXT
      ''');

      // Create habit_stacks table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS habit_stacks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          anchor_habit_id INTEGER,
          color TEXT,
          icon TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // Create indexes
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_habits_stack_id ON habits(stack_id)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_stacks_user_id ON habit_stacks(user_id)
      ''');
    }
  }

  // Add transaction support for complex operations
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }
}
```

### 3. Enhance Habit Stack Service with Transaction Support

#### Update `lib/services/habit_stack_service.dart`

```dart
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/habit_stack.dart';
import '../models/habit.dart';
import 'habit_service.dart';

class HabitStackService {
  final DatabaseService _db = DatabaseService.instance;
  final HabitService _habitService = HabitService();

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

  /// Update an existing stack with new habits order
  Future<void> updateStackWithHabits({
    required HabitStack stack,
    required Habit anchorHabit,
    required List<Habit> stackedHabits,
  }) async {
    await _db.transaction((txn) async {
      // 1. Update stack metadata
      await txn.update(
        'habit_stacks',
        stack.toMap(),
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

      // 3. Set new anchor habit
      final anchorMap = anchorHabit.copyWith(
        isAnchor: true,
        stackId: stack.id,
        orderInStack: 0,
      ).toMap();
      await txn.update(
        'habits',
        anchorMap,
        where: 'id = ?',
        whereArgs: [anchorHabit.id],
      );

      // 4. Set new stacked habits with order
      for (var i = 0; i < stackedHabits.length; i++) {
        final habitMap = stackedHabits[i].copyWith(
          stackId: stack.id,
          orderInStack: i + 1,
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

  /// Delete stack and handle orphaned habits
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
          {'stack_id': null, 'order_in_stack': null, 'is_anchor': 0},
          where: 'stack_id = ?',
          whereArgs: [stackId],
        );
      }

      // Delete the stack
      await txn.update(
        'habit_stacks',
        {'is_active': 0},
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
    final stack = await getStack(stackId);
    if (stack == null) return false;

    // Check if anchor habit exists
    if (stack.anchorHabit == null) {
      print('Stack $stackId missing anchor habit');
      return false;
    }

    // Check if habit orders are sequential
    final habits = stack.stackedHabits ?? [];
    for (var i = 0; i < habits.length; i++) {
      if (habits[i].orderInStack != i + 1) {
        print('Stack $stackId has non-sequential habit order');
        return false;
      }
    }

    return true;
  }

  /// Repair stack integrity issues
  Future<void> repairStackIntegrity(int stackId) async {
    final stack = await getStack(stackId);
    if (stack == null) return;

    await _db.transaction((txn) async {
      // Reorder habits sequentially
      final habits = stack.stackedHabits ?? [];
      for (var i = 0; i < habits.length; i++) {
        await txn.update(
          'habits',
          {'order_in_stack': i + 1},
          where: 'id = ?',
          whereArgs: [habits[i].id],
        );
      }
    });
  }

  // ... existing methods ...
}
```

### 4. Update Create Stack Screen to Use Transactions

#### Update `lib/screens/build_stack/create_stack_screen.dart`

```dart
Future<void> _saveStack() async {
  // ... existing validation ...

  setState(() => _isSaving = true);

  try {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) throw Exception('User not found');

    final stack = HabitStack(
      id: widget.existingStack?.id,
      userId: user.id!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      createdAt: widget.existingStack?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final stackService = ref.read(habitStackServiceProvider);

    if (widget.existingStack == null) {
      // Create new stack with all habits in transaction
      await stackService.createStackWithHabits(
        stack: stack,
        anchorHabit: _anchorHabit!,
        stackedHabits: _stackedHabits,
      );
    } else {
      // Update existing stack with transaction
      await stackService.updateStackWithHabits(
        stack: stack.copyWith(id: widget.existingStack!.id),
        anchorHabit: _anchorHabit!,
        stackedHabits: _stackedHabits,
      );
    }

    // Refresh providers
    await ref.read(habitStacksNotifierProvider.notifier).refresh();
    await ref.read(habitsNotifierProvider.notifier).refresh();

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingStack == null
            ? 'Stack created successfully!'
            : 'Stack updated successfully!'),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving stack: $e'),
        backgroundColor: AppColors.softRed,
      ),
    );
  } finally {
    setState(() => _isSaving = false);
  }
}
```

---

## Verification Checklist

- [x] Stacks persist after app restart
- [x] Habit order maintained correctly
- [x] Database migrations work without data loss
- [x] Orphaned habits handled properly
- [x] Stack deletion works (soft delete)
- [x] Transaction rollback on error (automatic in SQLite transactions)
- [x] Stack integrity validation works (validateStackIntegrity method)
- [x] Performance acceptable with indexes on stack_id and user_id

---

## Testing Scenarios

1. **Create Stack**: Create stack, restart app, verify stack persists
2. **Update Stack**: Modify stack order, verify changes saved
3. **Delete Stack**: Delete stack, verify habits remain but unlinked
4. **Migration**: Downgrade and upgrade database version
5. **Orphaned Habits**: Create habit, delete its stack, verify habit exists
6. **Integrity**: Manually corrupt data, run repair function
7. **Performance**: Create 50 habits in 10 stacks, measure load time

---

## Common Issues & Solutions

### Issue: Stack habits disappear after update
**Solution**: Ensure transaction commits before provider refresh

### Issue: Database locked errors
**Solution**: Use proper transaction isolation, avoid nested transactions

### Issue: Orphaned habits accumulate
**Solution**: Implement periodic cleanup or orphan detection UI

---

## Next Task

After completion, proceed to: [13_anchor_detection.md](./13_anchor_detection.md)

---

**Last Updated**: 2025-10-29
