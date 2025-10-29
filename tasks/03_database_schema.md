# Task 03: Database Schema Setup

**Status**: TODO
**Priority**: HIGH
**Estimated Time**: 3 hours
**Assigned To**: TBD
**Dependencies**: Task 01

---

## Objective

Set up SQLite database with all required tables and create a database service for CRUD operations.

## Acceptance Criteria

- [ ] SQLite database initialized on app startup
- [ ] All 8 tables created with proper schema
- [ ] Database service with CRUD methods implemented
- [ ] Database helper methods tested and working
- [ ] Migration strategy in place for future updates

---

## Step-by-Step Instructions

### 1. Create Database Service

#### `lib/services/database_service.dart`

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stackhabit.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        created_at TEXT NOT NULL,
        premium_status INTEGER DEFAULT 0
      )
    ''');

    // Habits table
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        icon TEXT,
        is_anchor INTEGER DEFAULT 0,
        frequency TEXT NOT NULL,
        custom_days TEXT,
        grace_period_config TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Habit Stacks table
    await db.execute('''
      CREATE TABLE habit_stacks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        anchor_habit_id INTEGER NOT NULL,
        habit_order TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(anchor_habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    // Daily Logs table
    await db.execute('''
      CREATE TABLE daily_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        habit_id INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        notes TEXT,
        sentiment TEXT,
        voice_note_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    // Streaks table
    await db.execute('''
      CREATE TABLE streaks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        habit_id INTEGER NOT NULL,
        current_count INTEGER DEFAULT 0,
        longest_count INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        grace_uses_this_period INTEGER DEFAULT 0,
        last_completed_at TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    // Accountability Partners table
    await db.execute('''
      CREATE TABLE accountability_partners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        partner_user_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Shared Habits table
    await db.execute('''
      CREATE TABLE shared_habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        habit_id INTEGER NOT NULL,
        partner_id INTEGER NOT NULL,
        visibility TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    // AI Insights table (Premium feature)
    await db.execute('''
      CREATE TABLE ai_insights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        generated_at TEXT NOT NULL,
        insights_json TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_habits_user ON habits(user_id)'
    );
    await db.execute(
      'CREATE INDEX idx_logs_user_date ON daily_logs(user_id, completed_at)'
    );
    await db.execute(
      'CREATE INDEX idx_streaks_user ON streaks(user_id)'
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE users ADD COLUMN new_field TEXT');
    // }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
```

### 2. Create User Service

#### `lib/services/user_service.dart`

```dart
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
```

### 3. Create User Model

#### `lib/models/user.dart`

```dart
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
```

### 4. Initialize Database in Main

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'services/user_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;

  // Ensure default user exists
  await UserService().getCurrentUser();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackHabit',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(title: Text('StackHabit')),
        body: Center(
          child: Text('Database Initialized!'),
        ),
      ),
    );
  }
}
```

### 5. Create Database Test Helper

#### `lib/utils/database_test_helper.dart`

```dart
import '../services/database_service.dart';

class DatabaseTestHelper {
  static Future<void> printAllTables() async {
    final db = await DatabaseService.instance.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );

    print('=== Database Tables ===');
    for (var table in tables) {
      print(table['name']);
    }
    print('====================');
  }

  static Future<void> verifySchema() async {
    final db = await DatabaseService.instance.database;

    final expectedTables = [
      'users',
      'habits',
      'habit_stacks',
      'daily_logs',
      'streaks',
      'accountability_partners',
      'shared_habits',
      'ai_insights',
    ];

    print('=== Schema Verification ===');

    for (var tableName in expectedTables) {
      final result = await db.rawQuery(
        "PRAGMA table_info($tableName)"
      );

      if (result.isEmpty) {
        print('❌ Table $tableName does not exist');
      } else {
        print('✅ Table $tableName exists with ${result.length} columns');
      }
    }

    print('=========================');
  }

  static Future<void> clearAllData() async {
    final db = await DatabaseService.instance.database;

    // Delete in correct order (respecting foreign keys)
    await db.delete('ai_insights');
    await db.delete('shared_habits');
    await db.delete('accountability_partners');
    await db.delete('streaks');
    await db.delete('daily_logs');
    await db.delete('habit_stacks');
    await db.delete('habits');
    await db.delete('users');

    print('All data cleared from database');
  }
}
```

---

## Verification Checklist

- [ ] Database file created in device storage
- [ ] All 8 tables created successfully
- [ ] Indexes created for performance
- [ ] User model works correctly
- [ ] Can insert and retrieve user data
- [ ] Foreign key constraints working
- [ ] No errors on app startup

---

## Testing Steps

1. Run the app:
```bash
flutter run
```

2. Add temporary test code to verify database:

```dart
// In main() after database initialization
import 'utils/database_test_helper.dart';

// Add this for testing
await DatabaseTestHelper.printAllTables();
await DatabaseTestHelper.verifySchema();
```

3. Check console output - should show all 8 tables with ✅

4. Test CRUD operations:

```dart
// Test user creation
final userService = UserService();
final user = await userService.getCurrentUser();
print('Current user: ${user?.name}');
```

---

## Common Issues & Solutions

### Issue: Database not found
**Solution**: Ensure `WidgetsFlutterBinding.ensureInitialized()` is called in main()

### Issue: Foreign key constraints not enforced
**Solution**: SQLite foreign keys are enabled by default in sqflite package

### Issue: Table already exists error
**Solution**: Uninstall and reinstall app, or increment database version number

---

## Next Task

After completion, proceed to: [04_bottom_navigation.md](./04_bottom_navigation.md)

---

## Notes

- Database is stored locally on device
- All timestamps use ISO 8601 format
- Boolean values stored as INTEGER (0/1)
- JSON data stored as TEXT (will be parsed in models)

**Last Updated**: 2025-10-29
