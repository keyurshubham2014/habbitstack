import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/habit.dart';
import '../models/habit_stack.dart';
import '../models/daily_log.dart';
import '../models/streak.dart';

/// Service for cloud CRUD operations on habits and related data
class CloudHabitService {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Cache to store habitId (int hashCode) -> UUID mapping
  final Map<int, String> _habitIdToUuidCache = {};

  /// Find the cloud UUID for a habit given its local integer ID (hashCode)
  /// This is needed because we convert UUIDs to hashCode when fetching from cloud
  Future<String?> _findHabitUuid(int habitId) async {
    // Check cache first
    if (_habitIdToUuidCache.containsKey(habitId)) {
      return _habitIdToUuidCache[habitId];
    }

    final userId = _userId;
    if (userId == null) return null;

    try {
      // Fetch all user's habits and find the one with matching hashCode
      final habits = await _supabase
          .from('habits')
          .select('id')
          .eq('user_id', userId);

      for (final habit in habits) {
        final uuid = habit['id'] as String;
        if (uuid.hashCode == habitId) {
          _habitIdToUuidCache[habitId] = uuid;
          return uuid;
        }
      }
    } catch (e) {
      print('Error finding habit UUID: $e');
    }

    return null;
  }

  // ==================== HABITS ====================

  /// Create a habit in the cloud
  Future<Map<String, dynamic>> createHabit(Habit habit) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'user_id': _userId,
      'name': habit.name,
      'icon': habit.icon,
      'color': habit.color,
      'is_anchor': habit.isAnchor,
      'frequency': habit.frequency,
      'custom_days': habit.customDays?.join(','),
      'grace_period_config': jsonEncode({
        'weekly_misses': habit.gracePeriodDays,
      }),
      'stack_id': habit.stackId,
      'order_in_stack': habit.orderInStack,
      'is_active': habit.isActive,
      'created_at': habit.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    return await _supabase.from('habits').insert(data).select().single();
  }

  /// Get all habits for current user
  Future<List<Map<String, dynamic>>> getHabits() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('habits')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at');
  }

  /// Get a specific habit by cloud ID
  /// Accepts either String UUID or int hashCode
  Future<Habit?> getHabit(dynamic habitId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    String? uuid;

    if (habitId is String) {
      // Already a UUID
      uuid = habitId;
    } else if (habitId is int) {
      // Need to find UUID from hashCode
      uuid = await _findHabitUuid(habitId);
      if (uuid == null) {
        print('Could not find habit UUID for habitId: $habitId');
        return null;
      }
    } else {
      throw Exception('habitId must be String or int, got: ${habitId.runtimeType}');
    }

    final data = await _supabase
        .from('habits')
        .select()
        .eq('id', uuid)
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;

    // Convert cloud data to Habit model
    return Habit(
      id: data['id'].hashCode,
      userId: data['user_id'].hashCode,
      name: data['name'] as String,
      icon: data['icon'] as String?,
      color: data['color'] as String?,
      isAnchor: data['is_anchor'] as bool? ?? false,
      frequency: data['frequency'] as String? ?? 'daily',
      customDays: data['custom_days'] != null
          ? (data['custom_days'] as String).split(',').map((e) => int.parse(e.trim())).toList()
          : null,
      gracePeriodDays: 2, // Default, can parse from grace_period_config if needed
      stackId: data['stack_id'] as int?,
      orderInStack: data['order_in_stack'] as int?,
      isActive: data['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  /// Update a habit in the cloud
  Future<Map<String, dynamic>> updateHabit(
    String habitId,
    Map<String, dynamic> updates,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    // Add updated_at timestamp
    updates['updated_at'] = DateTime.now().toIso8601String();

    return await _supabase
        .from('habits')
        .update(updates)
        .eq('id', habitId)
        .eq('user_id', userId)
        .select()
        .single();
  }

  /// Soft delete a habit (set is_active = false)
  Future<void> deleteHabit(String habitId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('habits')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', habitId)
        .eq('user_id', userId);
  }

  // ==================== HABIT STACKS ====================

  /// Create a habit stack in the cloud
  Future<Map<String, dynamic>> createHabitStack(HabitStack stack) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'user_id': _userId,
      'name': stack.name,
      'description': stack.description,
      'color': stack.color,
      'icon': stack.icon,
      'is_active': stack.isActive,
      'created_at': stack.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    return await _supabase.from('habit_stacks').insert(data).select().single();
  }

  /// Get all habit stacks for current user
  Future<List<Map<String, dynamic>>> getHabitStacks() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('habit_stacks')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at');
  }

  /// Update a habit stack
  Future<Map<String, dynamic>> updateHabitStack(
    String stackId,
    Map<String, dynamic> updates,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    updates['updated_at'] = DateTime.now().toIso8601String();

    return await _supabase
        .from('habit_stacks')
        .update(updates)
        .eq('id', stackId)
        .eq('user_id', userId)
        .select()
        .single();
  }

  /// Soft delete a habit stack
  Future<void> deleteHabitStack(String stackId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('habit_stacks')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', stackId)
        .eq('user_id', userId);
  }

  // ==================== DAILY LOGS ====================

  /// Create a daily log in the cloud
  Future<Map<String, dynamic>> createDailyLog(DailyLog log, String habitId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'user_id': _userId,
      'habit_id': habitId,
      'completed_at': log.completedAt.toIso8601String(),
      'notes': log.notes,
      'sentiment': log.sentiment,
      'tags': log.tags,
      'voice_note_path': log.voiceNotePath,
      'created_at': log.createdAt.toIso8601String(),
    };

    return await _supabase.from('daily_logs').insert(data).select().single();
  }

  /// Get daily logs for a specific habit
  Future<List<Map<String, dynamic>>> getDailyLogs({
    String? habitId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    var query = _supabase.from('daily_logs').select().eq('user_id', userId);

    if (habitId != null) {
      query = query.eq('habit_id', habitId);
    }

    if (startDate != null) {
      query = query.gte('completed_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('completed_at', endDate.toIso8601String());
    }

    return await query.order('completed_at', ascending: false);
  }

  /// Update a daily log
  Future<Map<String, dynamic>> updateDailyLog(
    String logId,
    Map<String, dynamic> updates,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('daily_logs')
        .update(updates)
        .eq('id', logId)
        .eq('user_id', userId)
        .select()
        .single();
  }

  /// Delete a daily log
  Future<void> deleteDailyLog(String logId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('daily_logs')
        .delete()
        .eq('id', logId)
        .eq('user_id', userId);
  }

  // ==================== STREAKS ====================

  /// Create or update a streak in the cloud
  Future<Map<String, dynamic>> upsertStreak(
    String habitId,
    Streak streak,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'user_id': _userId,
      'habit_id': habitId,
      'current_streak': streak.currentStreak,
      'longest_streak': streak.longestStreak,
      'last_logged_date': streak.lastCompletedAt.toIso8601String().split('T')[0],
      'grace_period_active': streak.isInGracePeriod,
      'grace_strikes_used': streak.gracePeriodUsed,
      'status': streak.status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Upsert: Insert if not exists, update if exists
    return await _supabase
        .from('streaks')
        .upsert(data, onConflict: 'habit_id')
        .select()
        .single();
  }

  /// Get streak for a specific habit
  Future<Map<String, dynamic>?> getStreak(String habitId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('streaks')
        .select()
        .eq('user_id', userId)
        .eq('habit_id', habitId)
        .maybeSingle();
  }

  /// Get all streaks for current user
  Future<List<Map<String, dynamic>>> getStreaks() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('streaks')
        .select()
        .eq('user_id', userId)
        .order('current_streak', ascending: false);
  }

  // ==================== SYNC HELPERS ====================

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;

  /// Get last sync timestamp for a table
  Future<DateTime?> getLastSyncTime(String table) async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final result = await _supabase
          .from(table)
          .select('updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result != null && result['updated_at'] != null) {
        return DateTime.parse(result['updated_at'] as String);
      }
    } catch (e) {
      print('Error getting last sync time for $table: $e');
    }

    return null;
  }

  /// Get changes since last sync
  Future<List<Map<String, dynamic>>> getChangesSince(
    String table,
    DateTime since,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from(table)
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since.toIso8601String())
        .order('updated_at');
  }

  /// Batch create multiple records (for sync)
  Future<void> batchCreate(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    // Add user_id to all records
    final recordsWithUser = records.map((r) {
      r['user_id'] = _userId;
      return r;
    }).toList();

    // Insert in batches of 100
    for (var i = 0; i < recordsWithUser.length; i += 100) {
      final batch = recordsWithUser.skip(i).take(100).toList();
      await _supabase.from(table).insert(batch);
    }
  }
}
