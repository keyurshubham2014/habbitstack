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
