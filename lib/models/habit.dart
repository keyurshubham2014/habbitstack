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
      customDays: map['custom_days'] != null && (map['custom_days'] as String).isNotEmpty
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
