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

  factory Habit.fromMap(Map<String, dynamic> map) {
    // Parse grace period config
    int gracePeriod = 2; // default
    if (map['grace_period_config'] != null) {
      try {
        final config = jsonDecode(map['grace_period_config']);
        gracePeriod = config['weekly_misses'] ?? 2;
      } catch (e) {
        // Fallback to default if parsing fails
        gracePeriod = 2;
      }
    }

    return Habit(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isAnchor: (map['is_anchor'] as int) == 1,
      frequency: map['frequency'] as String? ?? 'daily',
      customDays: map['custom_days'] != null && (map['custom_days'] as String).isNotEmpty
          ? (map['custom_days'] as String).split(',').map((e) => int.parse(e.trim())).toList()
          : null,
      gracePeriodDays: gracePeriod,
      stackId: map['stack_id'] as int?,
      orderInStack: map['order_in_stack'] as int?,
      isActive: (map['is_active'] as int?) != 0, // Default to true if null
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

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
