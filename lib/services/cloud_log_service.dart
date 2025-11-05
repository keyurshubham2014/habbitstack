import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/daily_log.dart';

/// Service for cloud CRUD operations on daily logs
class CloudLogService {
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

  /// Create a daily log in the cloud
  Future<Map<String, dynamic>> createLog(DailyLog log) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    // Find the cloud habit UUID from the local habitId (hashCode)
    final habitUuid = await _findHabitUuid(log.habitId);
    if (habitUuid == null) {
      throw Exception('Could not find habit UUID for habitId: ${log.habitId}');
    }

    final data = {
      'user_id': userId,
      'habit_id': habitUuid, // Use the actual cloud UUID
      'completed_at': log.completedAt.toIso8601String(),
      'notes': log.notes,
      'sentiment': log.sentiment,
      'voice_note_path': log.voiceNotePath,
      'tags': log.tags?.join(','),
      'created_at': log.createdAt.toIso8601String(),
    };

    return await _supabase.from('daily_logs').insert(data).select().single();
  }

  /// Get all logs for current user
  Future<List<Map<String, dynamic>>> getLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    var query = _supabase
        .from('daily_logs')
        .select()
        .eq('user_id', userId)
        ;

    if (startDate != null) {
      query = query.gte('completed_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('completed_at', endDate.toIso8601String());
    }

    return await query.order('completed_at', ascending: false);
  }

  /// Get logs for a specific habit
  Future<List<Map<String, dynamic>>> getHabitLogs(String habitId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('daily_logs')
        .select()
        .eq('user_id', userId)
        .eq('habit_id', habitId)
        ;
  }

  /// Get logs for today
  Future<List<Map<String, dynamic>>> getTodayLogs() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _supabase
        .from('daily_logs')
        .select()
        .eq('user_id', userId)
        .gte('completed_at', startOfDay.toIso8601String())
        .lt('completed_at', endOfDay.toIso8601String())
        ;
  }

  /// Get a specific log by cloud ID
  Future<Map<String, dynamic>?> getLog(String logId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('daily_logs')
        .select()
        .eq('id', logId)
        .eq('user_id', userId)
        .maybeSingle();
  }

  /// Update a log in the cloud
  Future<Map<String, dynamic>> updateLog(
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

  /// Delete a log from the cloud
  Future<void> deleteLog(String logId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('daily_logs')
        .delete()
        .eq('id', logId)
        .eq('user_id', userId);
  }

  /// Search logs by notes content
  Future<List<Map<String, dynamic>>> searchLogs(String query) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('daily_logs')
        .select()
        .eq('user_id', userId)
        .ilike('notes', '%$query%')
        ;
  }

  /// Get logs by sentiment
  Future<List<Map<String, dynamic>>> getLogsBySentiment(
    String sentiment,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('daily_logs')
        .select()
        .eq('user_id', userId)
        .eq('sentiment', sentiment)
        ;
  }

  /// Get logs by tag
  Future<List<Map<String, dynamic>>> getLogsByTag(String tag) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('daily_logs')
        .select()
        .eq('user_id', userId)
        .like('tags', '%$tag%')
        ;
  }

  /// Get log count for a date range
  Future<int> getLogCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    var query = _supabase
        .from('daily_logs')
        .select()
        .eq('user_id', userId);

    if (startDate != null) {
      query = query.gte('completed_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('completed_at', endDate.toIso8601String());
    }

    final response = await query;
    return (response as List).length;
  }

  /// Bulk create logs (for migration)
  Future<List<Map<String, dynamic>>> bulkCreateLogs(
    List<DailyLog> logs,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    // Pre-fetch all habit UUIDs to avoid multiple queries
    final habitIds = logs.map((log) => log.habitId).toSet();
    for (final habitId in habitIds) {
      await _findHabitUuid(habitId); // This will populate the cache
    }

    final data = <Map<String, dynamic>>[];
    for (final log in logs) {
      final habitUuid = _habitIdToUuidCache[log.habitId];
      if (habitUuid != null) {
        data.add({
          'user_id': userId,
          'habit_id': habitUuid,
          'completed_at': log.completedAt.toIso8601String(),
          'notes': log.notes,
          'sentiment': log.sentiment,
          'voice_note_path': log.voiceNotePath,
          'tags': log.tags?.join(','),
          'created_at': log.createdAt.toIso8601String(),
        });
      }
    }

    if (data.isEmpty) {
      throw Exception('No valid habit UUIDs found for bulk log creation');
    }

    return await _supabase.from('daily_logs').insert(data).select();
  }
}
