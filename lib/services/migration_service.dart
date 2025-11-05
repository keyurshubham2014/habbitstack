import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import 'supabase_service.dart';
import '../models/habit.dart';
import '../models/habit_stack.dart';
import '../models/daily_log.dart';
import '../models/streak.dart';

/// Progress callback: (current, total, description)
typedef ProgressCallback = void Function(int current, int total, String description);

/// Service to migrate local SQLite data to Supabase cloud
class MigrationService {
  final DatabaseService _localDb = DatabaseService.instance;
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Check if migration is needed for current user
  Future<bool> needsMigration(String userId) async {
    try {
      // Check if user has any data in cloud
      final cloudHabits = await _supabase
          .from('habits')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      // Check if user has local data
      final localHabits = await _localDb.query('habits', limit: 1);

      // Migration needed if: has local data AND no cloud data
      return localHabits.isNotEmpty && cloudHabits.isEmpty;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }

  /// Get total number of items to migrate
  Future<int> getTotalItemsToMigrate() async {
    try {
      final habits = await _localDb.query('habits');
      final stacks = await _localDb.query('habit_stacks');
      final logs = await _localDb.query('daily_logs');
      final streaks = await _localDb.query('streaks');

      return habits.length + stacks.length + logs.length + streaks.length;
    } catch (e) {
      print('Error counting items to migrate: $e');
      return 0;
    }
  }

  /// Migrate all local data to cloud
  Future<MigrationResult> migrateToCloud({
    required String userId,
    ProgressCallback? onProgress,
  }) async {
    final result = MigrationResult();
    int currentItem = 0;

    try {
      // Get total items
      final totalItems = await getTotalItemsToMigrate();
      if (totalItems == 0) {
        result.success = true;
        result.message = 'No data to migrate';
        return result;
      }

      onProgress?.call(currentItem, totalItems, 'Starting migration...');

      // Step 1: Create user profile in cloud
      onProgress?.call(currentItem, totalItems, 'Creating user profile...');
      await _createUserProfile(userId);
      currentItem++;

      // Step 2: Migrate habit stacks (must come before habits)
      onProgress?.call(currentItem, totalItems, 'Migrating habit stacks...');
      final stackIdMap = await _migrateHabitStacks(userId);
      currentItem += stackIdMap.length;
      result.habitStacksMigrated = stackIdMap.length;

      // Step 3: Migrate habits
      onProgress?.call(currentItem, totalItems, 'Migrating habits...');
      final habitIdMap = await _migrateHabits(userId, stackIdMap);
      currentItem += habitIdMap.length;
      result.habitsMigrated = habitIdMap.length;

      // Step 4: Migrate daily logs
      onProgress?.call(currentItem, totalItems, 'Migrating activity logs...');
      final logsMigrated = await _migrateDailyLogs(userId, habitIdMap);
      currentItem += logsMigrated;
      result.logsMigrated = logsMigrated;

      // Step 5: Migrate streaks
      onProgress?.call(currentItem, totalItems, 'Migrating streaks...');
      final streaksMigrated = await _migrateStreaks(userId, habitIdMap);
      currentItem += streaksMigrated;
      result.streaksMigrated = streaksMigrated;

      onProgress?.call(totalItems, totalItems, 'Migration complete!');

      result.success = true;
      result.message = 'Successfully migrated all data to cloud';
      return result;
    } catch (e, stackTrace) {
      print('Migration error: $e');
      print('Stack trace: $stackTrace');
      result.success = false;
      result.message = 'Migration failed: ${e.toString()}';
      result.error = e.toString();
      return result;
    }
  }

  /// Create user profile in cloud (if doesn't exist)
  Future<void> _createUserProfile(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Check if profile already exists
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing != null) {
        print('User profile already exists, skipping creation');
        return;
      }

      // Create user profile
      await _supabase.from('users').insert({
        'id': userId,
        'name': user.userMetadata?['name'] ?? 'StackHabit User',
        'email': user.email ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'premium_status': false,
      });

      print('✅ User profile created');
    } catch (e) {
      print('Error creating user profile: $e');
      // Don't throw - profile might already exist from auth signup
    }
  }

  /// Migrate habit stacks and return old ID -> new UUID map
  Future<Map<int, String>> _migrateHabitStacks(String userId) async {
    final idMap = <int, String>{};

    try {
      final localStacks = await _localDb.query('habit_stacks');

      for (final stackData in localStacks) {
        final stack = HabitStack.fromMap(stackData);

        // Insert into cloud (cloud will generate new UUID)
        final cloudStack = await _supabase.from('habit_stacks').insert({
          'user_id': userId,
          'name': stack.name,
          'description': stack.description,
          'color': stack.color,
          'icon': stack.icon,
          'is_active': stack.isActive,
          'created_at': stack.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).select().single();

        // Map old local ID to new cloud UUID
        idMap[stack.id!] = cloudStack['id'] as String;
      }

      print('✅ Migrated ${idMap.length} habit stacks');
    } catch (e) {
      print('Error migrating habit stacks: $e');
      rethrow;
    }

    return idMap;
  }

  /// Migrate habits and return old ID -> new UUID map
  Future<Map<int, String>> _migrateHabits(
    String userId,
    Map<int, String> stackIdMap,
  ) async {
    final idMap = <int, String>{};

    try {
      final localHabits = await _localDb.query('habits');

      for (final habitData in localHabits) {
        final habit = Habit.fromMap(habitData);

        // Convert old stack ID to new UUID (if exists)
        String? newStackId;
        if (habit.stackId != null) {
          newStackId = stackIdMap[habit.stackId];
        }

        // Insert into cloud
        final cloudHabit = await _supabase.from('habits').insert({
          'user_id': userId,
          'name': habit.name,
          'icon': habit.icon,
          'color': habit.color,
          'is_anchor': habit.isAnchor,
          'frequency': habit.frequency,
          'custom_days': habit.customDays?.join(','),
          'grace_period_config': jsonEncode({
            'weekly_misses': habit.gracePeriodDays,
          }),
          'stack_id': newStackId,
          'order_in_stack': habit.orderInStack,
          'is_active': habit.isActive,
          'created_at': habit.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).select().single();

        // Map old local ID to new cloud UUID
        idMap[habit.id!] = cloudHabit['id'] as String;
      }

      print('✅ Migrated ${idMap.length} habits');
    } catch (e) {
      print('Error migrating habits: $e');
      rethrow;
    }

    return idMap;
  }

  /// Migrate daily logs
  Future<int> _migrateDailyLogs(
    String userId,
    Map<int, String> habitIdMap,
  ) async {
    try {
      final localLogs = await _localDb.query('daily_logs');
      int migrated = 0;

      // Batch insert for better performance
      final logsToInsert = <Map<String, dynamic>>[];

      for (final logData in localLogs) {
        final log = DailyLog.fromMap(logData);

        // Convert old habit ID to new UUID
        final newHabitId = habitIdMap[log.habitId];
        if (newHabitId == null) {
          print('Warning: Skipping log with unknown habit ID: ${log.habitId}');
          continue;
        }

        logsToInsert.add({
          'user_id': userId,
          'habit_id': newHabitId,
          'completed_at': log.completedAt.toIso8601String(),
          'notes': log.notes,
          'sentiment': log.sentiment,
          'tags': log.tags, // PostgreSQL array
          'voice_note_path': log.voiceNotePath,
          'created_at': log.createdAt.toIso8601String(),
        });
      }

      // Insert in batches of 100
      if (logsToInsert.isNotEmpty) {
        for (var i = 0; i < logsToInsert.length; i += 100) {
          final batch = logsToInsert.skip(i).take(100).toList();
          await _supabase.from('daily_logs').insert(batch);
          migrated += batch.length;
        }
      }

      print('✅ Migrated $migrated daily logs');
      return migrated;
    } catch (e) {
      print('Error migrating daily logs: $e');
      rethrow;
    }
  }

  /// Migrate streaks
  Future<int> _migrateStreaks(
    String userId,
    Map<int, String> habitIdMap,
  ) async {
    try {
      final localStreaks = await _localDb.query('streaks');
      int migrated = 0;

      for (final streakData in localStreaks) {
        final streak = Streak.fromMap(streakData);

        // Convert old habit ID to new UUID
        final newHabitId = habitIdMap[streak.habitId];
        if (newHabitId == null) {
          print('Warning: Skipping streak with unknown habit ID: ${streak.habitId}');
          continue;
        }

        // Map local streak model to cloud schema
        // Cloud schema is simplified compared to local model
        await _supabase.from('streaks').insert({
          'user_id': userId,
          'habit_id': newHabitId,
          'current_streak': streak.currentStreak,
          'longest_streak': streak.longestStreak,
          'last_logged_date': streak.lastCompletedAt.toIso8601String().split('T')[0], // Date only
          'grace_period_active': streak.isInGracePeriod,
          'grace_strikes_used': streak.gracePeriodUsed,
          'status': streak.status.name,
          'updated_at': DateTime.now().toIso8601String(),
        });

        migrated++;
      }

      print('✅ Migrated $migrated streaks');
      return migrated;
    } catch (e) {
      print('Error migrating streaks: $e');
      rethrow;
    }
  }

  /// Clear local data after successful migration (optional)
  Future<void> clearLocalDataAfterMigration() async {
    try {
      // Keep the local database for offline fallback
      // But mark as "migrated" to prevent duplicate migrations
      print('ℹ️  Local data preserved for offline access');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  /// Rollback migration (delete cloud data for user)
  Future<void> rollbackMigration(String userId) async {
    try {
      print('⚠️  Rolling back migration for user $userId...');

      // Delete in reverse order due to foreign key constraints
      await _supabase.from('streaks').delete().eq('user_id', userId);
      await _supabase.from('daily_logs').delete().eq('user_id', userId);
      await _supabase.from('habits').delete().eq('user_id', userId);
      await _supabase.from('habit_stacks').delete().eq('user_id', userId);
      // Don't delete user profile - keep for auth

      print('✅ Rollback complete');
    } catch (e) {
      print('Error during rollback: $e');
      rethrow;
    }
  }
}

/// Result of migration operation
class MigrationResult {
  bool success = false;
  String message = '';
  String? error;
  int habitsMigrated = 0;
  int habitStacksMigrated = 0;
  int logsMigrated = 0;
  int streaksMigrated = 0;

  int get totalMigrated =>
      habitsMigrated + habitStacksMigrated + logsMigrated + streaksMigrated;

  @override
  String toString() {
    return 'MigrationResult(success: $success, '
        'habits: $habitsMigrated, '
        'stacks: $habitStacksMigrated, '
        'logs: $logsMigrated, '
        'streaks: $streaksMigrated, '
        'total: $totalMigrated, '
        'message: $message)';
  }
}
