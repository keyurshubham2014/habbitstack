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
