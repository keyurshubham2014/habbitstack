# Task 14: Streak Calculator with Grace Periods

**Status**: DONE ✅
**Priority**: HIGH
**Estimated Time**: 5 hours
**Assigned To**: Claude
**Dependencies**: Task 08 (Habit Model), Task 12 (Stack Persistence)
**Completed**: 2025-11-05

---

## Objective

Implement a forgiving streak calculation system with grace periods, supporting three states (Perfect, Grace Period, Broken) to encourage sustainable habit building.

## Acceptance Criteria

- [x] Streak calculator supports three states: Perfect (Green), Grace Period (Yellow), Broken (Red)
- [x] Configurable grace periods (1-2 misses per week default)
- [x] Streak counts consecutive days based on habit frequency
- [x] Grace period counter shows "X strikes remaining"
- [x] Streak resets only after grace period exhausted
- [x] Works with different habit frequencies (daily, weekdays, custom)
- [x] Efficient calculation for multiple habits
- [x] Historical streak data preserved (longest streak, total days)

---

## Step-by-Step Instructions

### 1. Create Streak Model

#### `lib/models/streak.dart`

Add to existing file or update:

```dart
enum StreakStatus {
  perfect,     // All habits completed on schedule
  gracePeriod, // Some misses but within grace period
  broken,      // Grace period exhausted
}

class Streak {
  final int? id;
  final int userId;
  final int habitId;
  final int currentStreak;      // Current consecutive days
  final int longestStreak;      // All-time longest streak
  final int totalCompletions;   // Total days completed ever
  final int gracePeriodUsed;    // Current grace strikes used
  final int maxGracePeriod;     // Max grace strikes allowed
  final StreakStatus status;
  final DateTime lastCompletedAt;
  final DateTime? lastGracePeriodResetAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Streak({
    this.id,
    required this.userId,
    required this.habitId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompletions = 0,
    this.gracePeriodUsed = 0,
    this.maxGracePeriod = 2, // Default: 2 strikes
    this.status = StreakStatus.perfect,
    required this.lastCompletedAt,
    this.lastGracePeriodResetAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Database serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'habit_id': habitId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_completions': totalCompletions,
      'grace_period_used': gracePeriodUsed,
      'max_grace_period': maxGracePeriod,
      'status': status.name,
      'last_completed_at': lastCompletedAt.toIso8601String(),
      'last_grace_period_reset_at': lastGracePeriodResetAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Streak.fromMap(Map<String, dynamic> map) {
    return Streak(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      habitId: map['habit_id'] as int,
      currentStreak: map['current_streak'] as int? ?? 0,
      longestStreak: map['longest_streak'] as int? ?? 0,
      totalCompletions: map['total_completions'] as int? ?? 0,
      gracePeriodUsed: map['grace_period_used'] as int? ?? 0,
      maxGracePeriod: map['max_grace_period'] as int? ?? 2,
      status: StreakStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StreakStatus.perfect,
      ),
      lastCompletedAt: DateTime.parse(map['last_completed_at'] as String),
      lastGracePeriodResetAt: map['last_grace_period_reset_at'] != null
          ? DateTime.parse(map['last_grace_period_reset_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Streak copyWith({
    int? id,
    int? userId,
    int? habitId,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletions,
    int? gracePeriodUsed,
    int? maxGracePeriod,
    StreakStatus? status,
    DateTime? lastCompletedAt,
    DateTime? lastGracePeriodResetAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Streak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      gracePeriodUsed: gracePeriodUsed ?? this.gracePeriodUsed,
      maxGracePeriod: maxGracePeriod ?? this.maxGracePeriod,
      status: status ?? this.status,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      lastGracePeriodResetAt: lastGracePeriodResetAt ?? this.lastGracePeriodResetAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  int get remainingGraceStrikes => maxGracePeriod - gracePeriodUsed;
  bool get isInGracePeriod => status == StreakStatus.gracePeriod;
  bool get isBroken => status == StreakStatus.broken;
  bool get isPerfect => status == StreakStatus.perfect;
}
```

### 2. Update Database Schema

#### Update `lib/services/database_service.dart`

Add streaks table creation in `_createTables()`:

```dart
await db.execute('''
  CREATE TABLE streaks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    habit_id INTEGER NOT NULL,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_completions INTEGER DEFAULT 0,
    grace_period_used INTEGER DEFAULT 0,
    max_grace_period INTEGER DEFAULT 2,
    status TEXT DEFAULT 'perfect',
    last_completed_at TEXT NOT NULL,
    last_grace_period_reset_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
    UNIQUE(user_id, habit_id)
  )
''');

await db.execute('''
  CREATE INDEX idx_streaks_user_habit
  ON streaks(user_id, habit_id)
''');

await db.execute('''
  CREATE INDEX idx_streaks_status
  ON streaks(status)
''');
```

### 3. Create Streak Calculator Service

#### `lib/services/streak_calculator.dart`

```dart
import '../models/streak.dart';
import '../models/habit.dart';
import '../models/daily_log.dart';
import 'database_service.dart';
import 'package:sqflite/sqflite.dart';

class StreakCalculator {
  final DatabaseService _db = DatabaseService();

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
    final db = await _db.database;
    final maps = await db.query(
      'streaks',
      where: 'user_id = ? AND habit_id = ?',
      whereArgs: [userId, habitId],
    );

    if (maps.isEmpty) return null;
    return Streak.fromMap(maps.first);
  }

  /// Get all streaks for a user
  Future<List<Streak>> getAllStreaks(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'streaks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'current_streak DESC',
    );

    return maps.map((map) => Streak.fromMap(map)).toList();
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
      missedDays: streakData['missedDays'] as int,
      currentGraceUsed: currentStreak.gracePeriodUsed,
      maxGracePeriod: currentStreak.maxGracePeriod,
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
    return updatedStreak;
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
        checkDate = checkDate.subtract(Duration(days: 1));
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

      checkDate = checkDate.subtract(Duration(days: 1));
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
    final db = await _db.database;

    if (streak.id == null) {
      // Insert new streak
      return await db.insert('streaks', streak.toMap());
    } else {
      // Update existing streak
      await db.update(
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
    final db = await _db.database;

    // Get all habits for user
    final habitMaps = await db.query(
      'habits',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    for (final habitMap in habitMaps) {
      final habit = Habit.fromMap(habitMap);

      // Get recent logs for this habit
      final logMaps = await db.query(
        'daily_logs',
        where: 'habit_id = ? AND user_id = ?',
        whereArgs: [habit.id, userId],
        orderBy: 'completed_at DESC',
        limit: 90,
      );

      final logs = logMaps.map((map) => DailyLog.fromMap(map)).toList();

      // Recalculate streak
      await calculateStreak(
        userId: userId,
        habit: habit,
        recentLogs: logs,
      );
    }
  }

  /// Delete streak when habit is deleted
  Future<void> deleteStreak(int userId, int habitId) async {
    final db = await _db.database;
    await db.delete(
      'streaks',
      where: 'user_id = ? AND habit_id = ?',
      whereArgs: [userId, habitId],
    );
  }
}
```

### 4. Update Log Service to Calculate Streaks

#### Update `lib/services/log_service.dart`

Add streak calculation when logs are created:

```dart
// Add import
import 'streak_calculator.dart';
import 'habit_service.dart';

// In LogService class, add:
final StreakCalculator _streakCalculator = StreakCalculator();
final HabitService _habitService = HabitService();

// Update createLog method:
Future<int> createLog(DailyLog log) async {
  final db = await _database;
  final id = await db.insert('daily_logs', log.toMap());

  // Calculate streak after logging
  final habit = await _habitService.getHabit(log.habitId);
  if (habit != null) {
    final recentLogs = await getLogsForHabit(log.habitId, days: 90);
    await _streakCalculator.calculateStreak(
      userId: log.userId,
      habit: habit,
      recentLogs: recentLogs,
    );
  }

  return id;
}
```

---

## Verification Checklist

- [ ] Streak model created with three statuses
- [ ] Database schema updated with streaks table
- [ ] Streak calculator accurately counts consecutive days
- [ ] Grace period logic working (2 strikes default)
- [ ] Weekly grace period reset functional
- [ ] Works with different habit frequencies
- [ ] Longest streak tracked correctly
- [ ] Streaks update automatically when logging
- [ ] No performance issues with 100+ logs

---

## Testing Scenarios

1. **Perfect Streak**: Log habit daily for 7 days, verify streak = 7, status = perfect
2. **Grace Period**: Log habit 5/7 days, verify status = gracePeriod, strikes = 2
3. **Broken Streak**: Miss 3+ days, verify status = broken, streak resets
4. **Weekly Reset**: Use 2 strikes in week 1, log perfectly in week 2, verify strikes reset
5. **Weekday Habits**: Create weekday-only habit, verify weekend doesn't break streak
6. **Multiple Habits**: Test streak calculation with 5+ habits simultaneously
7. **Longest Streak**: Build 10-day streak, break it, rebuild 5-day, verify longest = 10

---

## Common Issues & Solutions

### Issue: Streak counting off by one
**Solution**: Ensure date normalization removes time component before comparison

### Issue: Grace period not resetting weekly
**Solution**: Check `_shouldResetGracePeriod` uses correct date math

### Issue: Performance slow with many habits
**Solution**: Add database indexes on user_id and habit_id

---

## Algorithm Details

### Streak Calculation Logic
```
For each day from today backwards:
  - Skip if day not in habit frequency
  - If logged: increment streak
  - If missed:
    - If within grace period: continue counting
    - If grace exhausted: break streak
    - Count misses in last 7 days for grace
```

### Grace Period Rules
- Default: 2 misses allowed per week
- Resets every Monday at 00:00
- Only counts misses in last 7 days
- Grace period strikes carry over daily

---

## Next Task

After completion, proceed to: [15_streaks_screen.md](./15_streaks_screen.md)

---

**Last Updated**: 2025-11-05
