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
      version: 6,
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
        color TEXT,
        is_anchor INTEGER DEFAULT 0,
        frequency TEXT NOT NULL,
        custom_days TEXT,
        grace_period_config TEXT,
        stack_id INTEGER,
        order_in_stack INTEGER,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(stack_id) REFERENCES habit_stacks(id) ON DELETE SET NULL
      )
    ''');

    // Habit Stacks table
    await db.execute('''
      CREATE TABLE habit_stacks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        anchor_habit_id INTEGER,
        color TEXT,
        icon TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(anchor_habit_id) REFERENCES habits(id) ON DELETE SET NULL
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
        tags TEXT,
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
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        total_completions INTEGER DEFAULT 0,
        grace_period_used INTEGER DEFAULT 0,
        max_grace_period INTEGER DEFAULT 2,
        status TEXT DEFAULT 'perfect',
        last_completed_at TEXT NOT NULL,
        last_grace_period_reset_at TEXT,
        bounce_backs_used_this_week INTEGER DEFAULT 0,
        max_bounce_backs_per_week INTEGER DEFAULT 1,
        last_bounce_back_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE,
        UNIQUE(user_id, habit_id)
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
      'CREATE INDEX idx_habits_stack_id ON habits(stack_id)'
    );
    await db.execute(
      'CREATE INDEX idx_stacks_user_id ON habit_stacks(user_id)'
    );
    await db.execute(
      'CREATE INDEX idx_logs_user_date ON daily_logs(user_id, completed_at)'
    );
    await db.execute(
      'CREATE INDEX idx_streaks_user ON streaks(user_id)'
    );
    await db.execute(
      'CREATE INDEX idx_streaks_user_habit ON streaks(user_id, habit_id)'
    );
    await db.execute(
      'CREATE INDEX idx_streaks_status ON streaks(status)'
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to 2: Add new habit and habit_stack fields
    if (oldVersion < 2) {
      // Add new columns to habits table
      await db.execute('ALTER TABLE habits ADD COLUMN color TEXT');
      await db.execute('ALTER TABLE habits ADD COLUMN stack_id INTEGER');
      await db.execute('ALTER TABLE habits ADD COLUMN order_in_stack INTEGER');
      await db.execute('ALTER TABLE habits ADD COLUMN is_active INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE habits ADD COLUMN updated_at TEXT');

      // Drop and recreate habit_stacks table with new schema
      await db.execute('DROP TABLE IF EXISTS habit_stacks');
      await db.execute('''
        CREATE TABLE habit_stacks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          anchor_habit_id INTEGER,
          color TEXT,
          icon TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY(anchor_habit_id) REFERENCES habits(id) ON DELETE SET NULL
        )
      ''');
    }

    // Migration from version 2 to 3: Update streaks table for grace periods
    if (oldVersion < 3) {
      // Drop and recreate streaks table with new schema
      await db.execute('DROP TABLE IF EXISTS streaks');
      await db.execute('''
        CREATE TABLE streaks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          habit_id INTEGER NOT NULL,
          current_streak INTEGER DEFAULT 0,
          longest_streak INTEGER DEFAULT 0,
          total_completions INTEGER DEFAULT 0,
          grace_period_used INTEGER DEFAULT 0,
          max_grace_period INTEGER DEFAULT 2,
          status TEXT DEFAULT 'perfect',
          last_completed_at TEXT NOT NULL,
          last_grace_period_reset_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE,
          UNIQUE(user_id, habit_id)
        )
      ''');

      // Create new indexes
      await db.execute(
        'CREATE INDEX idx_streaks_user_habit ON streaks(user_id, habit_id)'
      );
      await db.execute(
        'CREATE INDEX idx_streaks_status ON streaks(status)'
      );
    }

    // Migration from version 3 to 4: Add bounce back columns
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE streaks ADD COLUMN bounce_backs_used_this_week INTEGER DEFAULT 0'
      );
      await db.execute(
        'ALTER TABLE streaks ADD COLUMN max_bounce_backs_per_week INTEGER DEFAULT 1'
      );
      await db.execute(
        'ALTER TABLE streaks ADD COLUMN last_bounce_back_at TEXT'
      );
    }

    // Migration from version 4 to 5: Add tags column to daily_logs
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE daily_logs ADD COLUMN tags TEXT'
      );
    }

    // Migration from version 5 to 6: Add sync_queue table
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          operation TEXT NOT NULL,
          data TEXT NOT NULL,
          local_id INTEGER,
          created_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          synced_at TEXT
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_sync_queue_synced ON sync_queue(synced)'
      );
    }
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

  // Transaction support for complex operations
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
