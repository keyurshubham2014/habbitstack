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

  // ==================== HABITS ====================

  /// Create a habit in the cloud
  Future<Map<String, dynamic>> createHabit(Habit habit) async {
    if (_userId == null) throw Exception('User not authenticated');

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
    if (_userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .order('created_at');
  }

  /// Get a specific habit by cloud ID
  Future<Map<String, dynamic>?> getHabit(String habitId) async {
    if (_userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('habits')
        .select()
        .eq('id', habitId)
        .eq('user_id', _userId)
        .maybeSingle();
  }

  /// Update a habit in the cloud
  Future<Map<String, dynamic>> updateHabit(
    String habitId,
    Map<String, dynamic> updates,
  ) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Add updated_at timestamp
    updates['updated_at'] = DateTime.now().toIso8601String();

    return await _supabase
        .from('habits')
        .update(updates)
        .eq('id', habitId)
        .eq('user_id', _userId)
        .select()
        .single();
  }

  /// Soft delete a habit (set is_active = false)
  Future<void> deleteHabit(String habitId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('habits')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', habitId)
        .eq('user_id', _userId);
  }

  // ==================== HABIT STACKS ====================

  /// Create a habit stack in the cloud
  Future<Map<String, dynamic>> createHabitStack(HabitStack stack) async {
    if (_userId == null) throw Exception('User not authenticated');

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
    if (_userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('habit_stacks')
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .order('created_at');
  }

  /// Update a habit stack
  Future<Map<String, dynamic>> updateHabitStack(
    String stackId,
    Map<String, dynamic> updates,
  ) async {
    if (_userId == null) throw Exception('User not authenticated');

    updates['updated_at'] = DateTime.now().toIso8601String();

    return await _supabase
        .from('habit_stacks')
        .update(updates)
        .eq('id', stackId)
        .eq('user_id', _userId)
        .select()
        .single();
  }

  /// Soft delete a habit stack
  Future<void> deleteHabitStack(String stackId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('habit_stacks')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', stackId)
        .eq('user_id', _userId);
  }

  // ==================== DAILY LOGS ====================

  /// Create a daily log in the cloud
  Future<Map<String, dynamic>> createDailyLog(DailyLog log, String habitId) async {
    if (_userId == null) throw Exception('User not authenticated');

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
    if (_userId == null) throw Exception('User not authenticated');

    var query = _supabase.from('daily_logs').select().eq('user_id', _userId);

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
    if (_userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('daily_logs')
        .update(updates)
        .eq('id', logId)
        .eq('user_id', _userId)
        .select()
        .single();
  }

  /// Delete a daily log
  Future<void> deleteDailyLog(String logId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('daily_logs')
        .delete()
        .eq('id', logId)
        .eq('user_id', _userId);
  }

  // ==================== STREAKS ====================

  /// Create or update a streak in the cloud
  Future<Map<String, dynamic>> upsertStreak(
    String habitId,
    Streak streak,
  ) async {
    if (_userId == null) throw Exception('User not authenticated');

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
    if (_userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('streaks')
        .select()
        .eq('user_id', _userId)
        .eq('habit_id', habitId)
        .maybeSingle();
  }

  /// Get all streaks for current user
  Future<List<Map<String, dynamic>>> getStreaks() async {
    if (_userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('streaks')
        .select()
        .eq('user_id', _userId)
        .order('current_streak', ascending: false);
  }

  // ==================== SYNC HELPERS ====================

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;

  /// Get last sync timestamp for a table
  Future<DateTime?> getLastSyncTime(String table) async {
    if (_userId == null) return null;

    try {
      final result = await _supabase
          .from(table)
          .select('updated_at')
          .eq('user_id', _userId)
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
    if (_userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from(table)
        .select()
        .eq('user_id', _userId)
        .gte('updated_at', since.toIso8601String())
        .order('updated_at');
  }

  /// Batch create multiple records (for sync)
  Future<void> batchCreate(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    if (_userId == null) throw Exception('User not authenticated');

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
