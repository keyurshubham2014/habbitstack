import 'database_service.dart';
import '../models/user.dart';

class UserService {
  final DatabaseService _db = DatabaseService.instance;

  Future<int> createUser(User user) async {
    return await _db.insert('users', user.toMap());
  }

  Future<User?> getUser(int id) async {
    final results = await _db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<User?> getCurrentUser() async {
    // For MVP, we'll have a single user
    final results = await _db.query('users', limit: 1);

    if (results.isEmpty) {
      // Create default user if none exists
      final userId = await createUser(User(
        name: 'Default User',
        email: null,
        createdAt: DateTime.now(),
        premiumStatus: false,
      ));
      return getUser(userId);
    }

    return User.fromMap(results.first);
  }

  Future<int> updateUser(User user) async {
    return await _db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
