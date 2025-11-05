# Task 08: Habit Data Models Enhancement

**Status**: DONE
**Priority**: HIGH
**Estimated Time**: 2 hours
**Assigned To**: Claude
**Dependencies**: Task 05 (State Management Setup)
**Completed**: 2025-11-05

---

## Objective

Enhance and extend the Habit model to support habit stacks, anchors, and advanced features like frequency patterns and grace periods.

## Acceptance Criteria

- [ ] `HabitStack` model created with full functionality
- [ ] `Habit` model supports anchor designation
- [ ] Frequency patterns implemented (daily, weekdays, custom)
- [ ] Grace period configuration supported
- [ ] Models have proper JSON serialization
- [ ] Validation logic for habit stacks
- [ ] Database migrations handled correctly
- [ ] All models properly tested

---

## Step-by-Step Instructions

### 1. Enhance Habit Model

The basic Habit model already exists from Task 05. Let's enhance it:

#### Update `lib/models/habit.dart`

```dart
import 'dart:convert';

class Habit {
  final int? id;
  final int userId;
  final String name;
  final String? icon;
  final String? color; // Hex color for visual customization
  final bool isAnchor;
  final String frequency; // 'daily', 'weekdays', 'weekends', 'custom'
  final List<int>? customDays; // [1,2,3,4,5] for Mon-Fri, 1=Monday, 7=Sunday
  final int gracePeriodDays;
  final int? stackId; // Reference to parent stack
  final int? orderInStack; // Position in stack (0, 1, 2...)
  final bool isActive; // Soft delete support
  final DateTime createdAt;
  final DateTime? updatedAt;

  Habit({
    this.id,
    required this.userId,
    required this.name,
    this.icon,
    this.color,
    this.isAnchor = false,
    this.frequency = 'daily',
    this.customDays,
    this.gracePeriodDays = 2,
    this.stackId,
    this.orderInStack,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_anchor': isAnchor ? 1 : 0,
      'frequency': frequency,
      'custom_days': customDays?.join(','),
      'grace_period_config': jsonEncode({
        'weekly_misses': gracePeriodDays,
      }),
      'stack_id': stackId,
      'order_in_stack': orderInStack,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from database map
  factory Habit.fromMap(Map<String, dynamic> map) {
    // Parse grace period config
    int gracePeriod = 2; // default
    if (map['grace_period_config'] != null) {
      try {
        final config = jsonDecode(map['grace_period_config']);
        gracePeriod = config['weekly_misses'] ?? 2;
      } catch (e) {
        print('Error parsing grace_period_config: $e');
      }
    }

    return Habit(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isAnchor: (map['is_anchor'] as int) == 1,
      frequency: map['frequency'] as String,
      customDays: map['custom_days'] != null
          ? (map['custom_days'] as String)
              .split(',')
              .map((e) => int.parse(e.trim()))
              .toList()
          : null,
      gracePeriodDays: gracePeriod,
      stackId: map['stack_id'] as int?,
      orderInStack: map['order_in_stack'] as int?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Create a copy with modified fields
  Habit copyWith({
    int? id,
    int? userId,
    String? name,
    String? icon,
    String? color,
    bool? isAnchor,
    String? frequency,
    List<int>? customDays,
    int? gracePeriodDays,
    int? stackId,
    int? orderInStack,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isAnchor: isAnchor ?? this.isAnchor,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      stackId: stackId ?? this.stackId,
      orderInStack: orderInStack ?? this.orderInStack,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if habit should be tracked today
  bool shouldTrackToday() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday

    switch (frequency) {
      case 'daily':
        return true;
      case 'weekdays':
        return weekday >= 1 && weekday <= 5;
      case 'weekends':
        return weekday == 6 || weekday == 7;
      case 'custom':
        return customDays?.contains(weekday) ?? false;
      default:
        return true;
    }
  }

  @override
  String toString() {
    return 'Habit{id: $id, name: $name, isAnchor: $isAnchor, frequency: $frequency}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
```

### 2. Create Habit Stack Model

#### `lib/models/habit_stack.dart`

```dart
import 'habit.dart';

class HabitStack {
  final int? id;
  final int userId;
  final String name;
  final String? description;
  final int? anchorHabitId; // The foundational anchor habit
  final String? color; // Stack theme color
  final String? icon; // Stack icon
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Not stored in DB, populated via joins
  final Habit? anchorHabit;
  final List<Habit>? stackedHabits;

  HabitStack({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    this.anchorHabitId,
    this.color,
    this.icon,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.anchorHabit,
    this.stackedHabits,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'anchor_habit_id': anchorHabitId,
      'color': color,
      'icon': icon,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from database map
  factory HabitStack.fromMap(Map<String, dynamic> map) {
    return HabitStack(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      anchorHabitId: map['anchor_habit_id'] as int?,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Create a copy with modified fields
  HabitStack copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    int? anchorHabitId,
    String? color,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Habit? anchorHabit,
    List<Habit>? stackedHabits,
  }) {
    return HabitStack(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      anchorHabitId: anchorHabitId ?? this.anchorHabitId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      anchorHabit: anchorHabit ?? this.anchorHabit,
      stackedHabits: stackedHabits ?? this.stackedHabits,
    );
  }

  /// Validate stack structure
  bool isValid() {
    // Must have a name
    if (name.trim().isEmpty) return false;

    // Must have an anchor habit
    if (anchorHabitId == null && anchorHabit == null) return false;

    // Anchor habit must be marked as anchor
    if (anchorHabit != null && !anchorHabit!.isAnchor) return false;

    return true;
  }

  /// Get total number of habits in this stack
  int get totalHabits {
    int count = anchorHabit != null ? 1 : 0;
    count += stackedHabits?.length ?? 0;
    return count;
  }

  /// Get all habits in correct order (anchor first, then ordered stacked habits)
  List<Habit> get allHabitsOrdered {
    final habits = <Habit>[];

    if (anchorHabit != null) {
      habits.add(anchorHabit!);
    }

    if (stackedHabits != null) {
      final sorted = List<Habit>.from(stackedHabits!);
      sorted.sort((a, b) =>
          (a.orderInStack ?? 0).compareTo(b.orderInStack ?? 0));
      habits.addAll(sorted);
    }

    return habits;
  }

  @override
  String toString() {
    return 'HabitStack{id: $id, name: $name, totalHabits: $totalHabits}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitStack && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
```

### 3. Create Frequency Helper

#### `lib/utils/frequency_helper.dart`

```dart
class FrequencyHelper {
  /// Get human-readable frequency description
  static String getFrequencyDescription(String frequency, List<int>? customDays) {
    switch (frequency) {
      case 'daily':
        return 'Every day';
      case 'weekdays':
        return 'Weekdays (Mon-Fri)';
      case 'weekends':
        return 'Weekends (Sat-Sun)';
      case 'custom':
        if (customDays == null || customDays.isEmpty) {
          return 'Custom schedule';
        }
        return 'Custom: ${_formatCustomDays(customDays)}';
      default:
        return 'Unknown frequency';
    }
  }

  /// Format custom days as readable string
  static String _formatCustomDays(List<int> days) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((day) => dayNames[day - 1]).join(', ');
  }

  /// Get full day names
  static List<String> getDayNames() {
    return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  }

  /// Get short day names
  static List<String> getShortDayNames() {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  /// Convert day name to number (1-7)
  static int dayNameToNumber(String dayName) {
    final names = getDayNames();
    final index = names.indexWhere(
      (name) => name.toLowerCase() == dayName.toLowerCase(),
    );
    return index == -1 ? 1 : index + 1;
  }

  /// Check if a specific date matches the frequency
  static bool shouldTrackOnDate(
    DateTime date,
    String frequency,
    List<int>? customDays,
  ) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday

    switch (frequency) {
      case 'daily':
        return true;
      case 'weekdays':
        return weekday >= 1 && weekday <= 5;
      case 'weekends':
        return weekday == 6 || weekday == 7;
      case 'custom':
        return customDays?.contains(weekday) ?? false;
      default:
        return true;
    }
  }

  /// Get all dates in a range that match frequency
  static List<DateTime> getDatesForFrequency(
    DateTime startDate,
    DateTime endDate,
    String frequency,
    List<int>? customDays,
  ) {
    final dates = <DateTime>[];
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      if (shouldTrackOnDate(currentDate, frequency, customDays)) {
        dates.add(currentDate);
      }
      currentDate = currentDate.add(Duration(days: 1));
    }

    return dates;
  }
}
```

### 4. Create Habit Stack Service

#### `lib/services/habit_stack_service.dart`

```dart
import 'database_service.dart';
import '../models/habit_stack.dart';
import '../models/habit.dart';
import 'habit_service.dart';

class HabitStackService {
  final DatabaseService _db = DatabaseService.instance;
  final HabitService _habitService = HabitService();

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

    final stacks = results.map((map) => HabitStack.fromMap(map)).toList();

    // Populate habits for each stack
    for (var i = 0; i < stacks.length; i++) {
      stacks[i] = await _populateStackHabits(stacks[i]);
    }

    return stacks;
  }

  /// Get a single stack with its habits
  Future<HabitStack?> getStack(int stackId) async {
    final results = await _db.query(
      'habit_stacks',
      where: 'id = ?',
      whereArgs: [stackId],
    );

    if (results.isEmpty) return null;

    var stack = HabitStack.fromMap(results.first);
    return await _populateStackHabits(stack);
  }

  /// Populate stack with its habits
  Future<HabitStack> _populateStackHabits(HabitStack stack) async {
    Habit? anchorHabit;
    List<Habit> stackedHabits = [];

    if (stack.anchorHabitId != null) {
      anchorHabit = await _habitService.getHabit(stack.anchorHabitId!);
    }

    final habits = await _db.query(
      'habits',
      where: 'stack_id = ? AND is_active = ?',
      whereArgs: [stack.id, 1],
      orderBy: 'order_in_stack ASC',
    );

    stackedHabits = habits.map((map) => Habit.fromMap(map)).toList();

    return stack.copyWith(
      anchorHabit: anchorHabit,
      stackedHabits: stackedHabits,
    );
  }

  /// Update a stack
  Future<int> updateStack(HabitStack stack) async {
    return await _db.update(
      'habit_stacks',
      stack.toMap(),
      where: 'id = ?',
      whereArgs: [stack.id],
    );
  }

  /// Delete (soft delete) a stack
  Future<int> deleteStack(int stackId) async {
    return await _db.update(
      'habit_stacks',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [stackId],
    );
  }

  /// Add a habit to a stack
  Future<void> addHabitToStack(int habitId, int stackId, int orderInStack) async {
    await _db.update(
      'habits',
      {
        'stack_id': stackId,
        'order_in_stack': orderInStack,
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  /// Remove a habit from a stack
  Future<void> removeHabitFromStack(int habitId) async {
    await _db.update(
      'habits',
      {
        'stack_id': null,
        'order_in_stack': null,
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  /// Reorder habits in a stack
  Future<void> reorderHabits(int stackId, List<int> habitIdsInOrder) async {
    for (var i = 0; i < habitIdsInOrder.length; i++) {
      await _db.update(
        'habits',
        {'order_in_stack': i},
        where: 'id = ? AND stack_id = ?',
        whereArgs: [habitIdsInOrder[i], stackId],
      );
    }
  }
}
```

---

## Verification Checklist

- [ ] Habit model enhanced with all fields
- [ ] HabitStack model created and functional
- [ ] Frequency helper methods work correctly
- [ ] Database can save and retrieve stacks
- [ ] Habits can be added to stacks
- [ ] Stack validation logic works
- [ ] Custom frequency patterns work
- [ ] No database errors

---

## Testing

Add test cases to verify models:

```dart
// Example test
void testHabitModel() {
  final habit = Habit(
    userId: 1,
    name: 'Morning Run',
    frequency: 'weekdays',
    createdAt: DateTime.now(),
  );

  print('Should track today: ${habit.shouldTrackToday()}');
  assert(habit.name == 'Morning Run');
  assert(habit.frequency == 'weekdays');
}

void testHabitStack() {
  final stack = HabitStack(
    userId: 1,
    name: 'Morning Routine',
    createdAt: DateTime.now(),
  );

  print('Stack valid: ${stack.isValid()}'); // Should be false (no anchor)
}
```

---

## Next Task

After completion, proceed to: [09_build_stack_screen.md](./09_build_stack_screen.md)

---

**Last Updated**: 2025-10-29
