class User {
  final int? id;
  final String name;
  final String? email;
  final DateTime createdAt;
  final bool premiumStatus;

  User({
    this.id,
    required this.name,
    this.email,
    required this.createdAt,
    this.premiumStatus = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'premium_status': premiumStatus ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      premiumStatus: (map['premium_status'] as int) == 1,
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? createdAt,
    bool? premiumStatus,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      premiumStatus: premiumStatus ?? this.premiumStatus,
    );
  }
}
