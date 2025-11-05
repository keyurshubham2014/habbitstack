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
      isActive: (map['is_active'] as int?) != 0,
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

  /// Validate that stack has at least one habit
  bool isValid() {
    return anchorHabitId != null || (stackedHabits != null && stackedHabits!.isNotEmpty);
  }

  /// Get the total number of habits in the stack
  int get habitCount {
    int count = 0;
    if (anchorHabit != null) count++;
    if (stackedHabits != null) count += stackedHabits!.length;
    return count;
  }

  /// Alias for habitCount for consistency with task spec
  int get totalHabits => habitCount;

  /// Get all habits in order: anchor first, then stacked habits
  List<Habit> get allHabitsOrdered {
    final List<Habit> result = [];
    if (anchorHabit != null) {
      result.add(anchorHabit!);
    }
    if (stackedHabits != null && stackedHabits!.isNotEmpty) {
      result.addAll(stackedHabits!);
    }
    return result;
  }

  @override
  String toString() {
    return 'HabitStack{id: $id, name: $name, anchorHabitId: $anchorHabitId, habitCount: $habitCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitStack && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
