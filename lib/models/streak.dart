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
  final int bounceBacksUsedThisWeek;
  final int maxBounceBacksPerWeek;
  final DateTime? lastBounceBackAt;
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
    this.bounceBacksUsedThisWeek = 0,
    this.maxBounceBacksPerWeek = 1, // Default: 1 bounce back per week
    this.lastBounceBackAt,
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
      'bounce_backs_used_this_week': bounceBacksUsedThisWeek,
      'max_bounce_backs_per_week': maxBounceBacksPerWeek,
      'last_bounce_back_at': lastBounceBackAt?.toIso8601String(),
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
      bounceBacksUsedThisWeek: map['bounce_backs_used_this_week'] as int? ?? 0,
      maxBounceBacksPerWeek: map['max_bounce_backs_per_week'] as int? ?? 1,
      lastBounceBackAt: map['last_bounce_back_at'] != null
          ? DateTime.parse(map['last_bounce_back_at'] as String)
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
    int? bounceBacksUsedThisWeek,
    int? maxBounceBacksPerWeek,
    DateTime? lastBounceBackAt,
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
      bounceBacksUsedThisWeek: bounceBacksUsedThisWeek ?? this.bounceBacksUsedThisWeek,
      maxBounceBacksPerWeek: maxBounceBacksPerWeek ?? this.maxBounceBacksPerWeek,
      lastBounceBackAt: lastBounceBackAt ?? this.lastBounceBackAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  int get remainingGraceStrikes => maxGracePeriod - gracePeriodUsed;
  bool get isInGracePeriod => status == StreakStatus.gracePeriod;
  bool get isBroken => status == StreakStatus.broken;
  bool get isPerfect => status == StreakStatus.perfect;
  bool get canBounceBack => bounceBacksUsedThisWeek < maxBounceBacksPerWeek;
  int get remainingBouncebacks => maxBounceBacksPerWeek - bounceBacksUsedThisWeek;

  @override
  String toString() {
    return 'Streak{id: $id, habitId: $habitId, current: $currentStreak, status: ${status.name}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Streak && other.id == id && other.habitId == habitId;
  }

  @override
  int get hashCode => id.hashCode ^ habitId.hashCode;
}
