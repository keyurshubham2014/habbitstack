# Task 05: State Management Setup (Riverpod)

**Status**: TODO
**Priority**: HIGH
**Estimated Time**: 3 hours
**Assigned To**: TBD
**Dependencies**: Task 01, Task 03

---

## Objective

Set up Riverpod for state management across the app with providers for habits, logs, streaks, and user data.

## Acceptance Criteria

- [ ] Riverpod properly configured in the app
- [ ] User provider created and working
- [ ] Habits provider with CRUD operations
- [ ] Logs provider with CRUD operations
- [ ] Streaks provider with calculation logic
- [ ] Providers properly tested and functional

---

## Step-by-Step Instructions

### 1. Wrap App with ProviderScope

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'services/user_service.dart';
import 'widgets/common/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;

  // Ensure default user exists
  await UserService().getCurrentUser();

  runApp(
    // Wrap entire app with ProviderScope
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackHabit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: MainNavigation(),
    );
  }
}
```

### 2. Create User Provider

#### `lib/providers/user_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/user_service.dart';

// User Service Provider
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Current User Provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final userService = ref.read(userServiceProvider);
  return await userService.getCurrentUser();
});

// User State Notifier
class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final UserService _userService;

  UserNotifier(this._userService) : super(AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    state = AsyncValue.loading();
    try {
      final user = await _userService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _userService.updateUser(user);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> togglePremium() async {
    final currentUser = state.value;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        premiumStatus: !currentUser.premiumStatus,
      );
      await updateUser(updatedUser);
    }
  }
}

// User State Provider
final userNotifierProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  final userService = ref.read(userServiceProvider);
  return UserNotifier(userService);
});
```

### 3. Create Habit Model & Service

#### `lib/models/habit.dart`

```dart
class Habit {
  final int? id;
  final int userId;
  final String name;
  final String? icon;
  final bool isAnchor;
  final String frequency; // 'daily', 'weekdays', 'custom'
  final List<int>? customDays; // [1,2,3] for Mon, Tue, Wed
  final int gracePeriodDays;
  final DateTime createdAt;

  Habit({
    this.id,
    required this.userId,
    required this.name,
    this.icon,
    this.isAnchor = false,
    this.frequency = 'daily',
    this.customDays,
    this.gracePeriodDays = 2,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'is_anchor': isAnchor ? 1 : 0,
      'frequency': frequency,
      'custom_days': customDays?.join(','),
      'grace_period_config': '{"weekly_misses": $gracePeriodDays}',
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      isAnchor: (map['is_anchor'] as int) == 1,
      frequency: map['frequency'] as String,
      customDays: map['custom_days'] != null
          ? (map['custom_days'] as String).split(',').map(int.parse).toList()
          : null,
      gracePeriodDays: 2, // Parse from grace_period_config JSON if needed
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Habit copyWith({
    int? id,
    int? userId,
    String? name,
    String? icon,
    bool? isAnchor,
    String? frequency,
    List<int>? customDays,
    int? gracePeriodDays,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isAnchor: isAnchor ?? this.isAnchor,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

#### `lib/services/habit_service.dart`

```dart
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
```

### 4. Create Habits Provider

#### `lib/providers/habits_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import 'user_provider.dart';

// Habit Service Provider
final habitServiceProvider = Provider<HabitService>((ref) {
  return HabitService();
});

// All Habits Provider
final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final habitService = ref.read(habitServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await habitService.getAllHabits(user.id!);
});

// Anchor Habits Provider
final anchorHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final habitService = ref.read(habitServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await habitService.getAnchorHabits(user.id!);
});

// Habits Notifier
class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final HabitService _habitService;
  final int userId;

  HabitsNotifier(this._habitService, this.userId) : super(AsyncValue.loading()) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    state = AsyncValue.loading();
    try {
      final habits = await _habitService.getAllHabits(userId);
      state = AsyncValue.data(habits);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addHabit(Habit habit) async {
    try {
      await _habitService.createHabit(habit);
      await _loadHabits(); // Reload all habits
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      await _habitService.updateHabit(habit);
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteHabit(int habitId) async {
    try {
      await _habitService.deleteHabit(habitId);
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleAnchor(int habitId, bool isAnchor) async {
    try {
      await _habitService.markAsAnchor(habitId, isAnchor);
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadHabits();
  }
}

// Habits State Provider
final habitsNotifierProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>((ref) {
  final habitService = ref.read(habitServiceProvider);
  final userAsync = ref.watch(userNotifierProvider);

  return userAsync.when(
    data: (user) => HabitsNotifier(habitService, user?.id ?? 0),
    loading: () => HabitsNotifier(habitService, 0),
    error: (_, __) => HabitsNotifier(habitService, 0),
  );
});
```

### 5. Create Daily Log Model & Service

#### `lib/models/daily_log.dart`

```dart
class DailyLog {
  final int? id;
  final int userId;
  final int habitId;
  final DateTime completedAt;
  final String? notes;
  final String? sentiment; // 'happy', 'neutral', 'struggled'
  final String? voiceNotePath;
  final DateTime createdAt;

  DailyLog({
    this.id,
    required this.userId,
    required this.habitId,
    required this.completedAt,
    this.notes,
    this.sentiment,
    this.voiceNotePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'habit_id': habitId,
      'completed_at': completedAt.toIso8601String(),
      'notes': notes,
      'sentiment': sentiment,
      'voice_note_path': voiceNotePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      habitId: map['habit_id'] as int,
      completedAt: DateTime.parse(map['completed_at'] as String),
      notes: map['notes'] as String?,
      sentiment: map['sentiment'] as String?,
      voiceNotePath: map['voice_note_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DailyLog copyWith({
    int? id,
    int? userId,
    int? habitId,
    DateTime? completedAt,
    String? notes,
    String? sentiment,
    String? voiceNotePath,
    DateTime? createdAt,
  }) {
    return DailyLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      sentiment: sentiment ?? this.sentiment,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

#### `lib/services/log_service.dart`

```dart
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
    final endOfDay = startOfDay.add(Duration(days: 1));

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
```

### 6. Create Logs Provider

#### `lib/providers/logs_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_log.dart';
import '../services/log_service.dart';
import 'user_provider.dart';

// Log Service Provider
final logServiceProvider = Provider<LogService>((ref) {
  return LogService();
});

// Today's Logs Provider
final todaysLogsProvider = FutureProvider<List<DailyLog>>((ref) async {
  final logService = ref.read(logServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await logService.getTodaysLogs(user.id!);
});

// Logs Notifier
class LogsNotifier extends StateNotifier<AsyncValue<List<DailyLog>>> {
  final LogService _logService;
  final int userId;

  LogsNotifier(this._logService, this.userId) : super(AsyncValue.loading()) {
    _loadTodaysLogs();
  }

  Future<void> _loadTodaysLogs() async {
    state = AsyncValue.loading();
    try {
      final logs = await _logService.getTodaysLogs(userId);
      state = AsyncValue.data(logs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addLog(DailyLog log) async {
    try {
      await _logService.createLog(log);
      await _loadTodaysLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateLog(DailyLog log) async {
    try {
      await _logService.updateLog(log);
      await _loadTodaysLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteLog(int logId) async {
    try {
      await _logService.deleteLog(logId);
      await _loadTodaysLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadTodaysLogs();
  }
}

// Logs State Provider
final logsNotifierProvider = StateNotifierProvider<LogsNotifier, AsyncValue<List<DailyLog>>>((ref) {
  final logService = ref.read(logServiceProvider);
  final userAsync = ref.watch(userNotifierProvider);

  return userAsync.when(
    data: (user) => LogsNotifier(logService, user?.id ?? 0),
    loading: () => LogsNotifier(logService, 0),
    error: (_, __) => LogsNotifier(logService, 0),
  );
});
```

---

## Verification Checklist

- [ ] ProviderScope wraps the app
- [ ] User provider loads current user
- [ ] Habits provider works with CRUD operations
- [ ] Logs provider works with CRUD operations
- [ ] No errors when running the app
- [ ] Providers properly rebuild widgets on state change

---

## Testing

Add this test widget to verify providers:

```dart
// lib/screens/test_providers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/habits_provider.dart';
import '../providers/logs_provider.dart';

class TestProvidersScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userNotifierProvider);
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final logsAsync = ref.watch(logsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Provider Test')),
      body: ListView(
        children: [
          userAsync.when(
            data: (user) => ListTile(
              title: Text('User: ${user?.name ?? "None"}'),
              subtitle: Text('Premium: ${user?.premiumStatus}'),
            ),
            loading: () => ListTile(title: Text('Loading user...')),
            error: (e, _) => ListTile(title: Text('Error: $e')),
          ),
          Divider(),
          ListTile(title: Text('Habits: ${habitsAsync.value?.length ?? 0}')),
          ListTile(title: Text('Today\'s Logs: ${logsAsync.value?.length ?? 0}')),
        ],
      ),
    );
  }
}
```

---

## Next Task

After completion, proceed to: [06_todays_log_screen.md](./06_todays_log_screen.md)

---

**Last Updated**: 2025-10-29
