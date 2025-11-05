import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_log.dart';
import '../services/log_service.dart';
import '../services/cloud_log_service.dart';
import 'user_provider.dart';
import 'auth_provider.dart';

// Log Service Provider - Hybrid Mode (Cloud when logged in, Local otherwise)
final logServiceProvider = Provider<dynamic>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  if (isLoggedIn) {
    return CloudLogService(); // ✅ Use cloud when authenticated
  }
  return LogService(); // ✅ Use local when offline
});

// Today's Logs Provider
final todaysLogsProvider = FutureProvider<List<DailyLog>>((ref) async {
  final logService = ref.read(logServiceProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  if (isLoggedIn && logService is CloudLogService) {
    // Cloud mode: Fetch from Supabase
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final cloudLogs = await logService.getLogs(
      startDate: startOfDay,
      endDate: endOfDay,
    );
    return cloudLogs.map((data) => _logFromCloudData(data)).toList();
  } else if (logService is LogService) {
    // Local mode: Fetch from SQLite
    return await logService.getTodaysLogs(user.id!);
  }

  return [];
});

// Logs Notifier
class LogsNotifier extends StateNotifier<AsyncValue<List<DailyLog>>> {
  final dynamic _logService;
  final bool _isLoggedIn;
  final String? _authUserId;
  final int? _localUserId;

  LogsNotifier(
    this._logService,
    this._isLoggedIn,
    this._authUserId,
    this._localUserId,
  ) : super(const AsyncValue.loading()) {
    _loadTodaysLogs();
  }

  Future<void> _loadTodaysLogs() async {
    state = const AsyncValue.loading();
    try {
      if (_isLoggedIn && _logService is CloudLogService) {
        // Cloud mode
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final cloudLogs = await _logService.getLogs(
          startDate: startOfDay,
          endDate: endOfDay,
        );
        final logs = cloudLogs.map<DailyLog>((data) => _logFromCloudData(data)).toList();
        state = AsyncValue.data(logs);
      } else if (_logService is LogService && _localUserId != null) {
        // Local mode
        final logs = await _logService.getTodaysLogs(_localUserId!);
        state = AsyncValue.data(logs);
      } else {
        state = AsyncValue.data([]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addLog(DailyLog log) async {
    try {
      if (_isLoggedIn && _logService is CloudLogService) {
        // Cloud mode
        await _logService.createLog(log);
      } else if (_logService is LogService) {
        // Local mode
        await _logService.createLog(log);
      }
      await _loadTodaysLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateLog(DailyLog log) async {
    try {
      if (_isLoggedIn && _logService is CloudLogService) {
        // Cloud mode - need to convert DailyLog to update map
        // Note: We don't update habit_id - logs are tied to the habit they were created with
        final updates = {
          'completed_at': log.completedAt.toIso8601String(),
          'notes': log.notes,
          'sentiment': log.sentiment,
          'voice_note_path': log.voiceNotePath,
        };
        // Note: Cloud logs use UUID string IDs
        await _logService.updateLog(log.id.toString(), updates);
      } else if (_logService is LogService) {
        // Local mode
        await _logService.updateLog(log);
      }
      await _loadTodaysLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteLog(int logId) async {
    try {
      if (_isLoggedIn && _logService is CloudLogService) {
        // Cloud mode
        await _logService.deleteLog(logId.toString());
      } else if (_logService is LogService) {
        // Local mode
        await _logService.deleteLog(logId);
      }
      await _loadTodaysLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadTodaysLogs();
  }
}

// Logs State Provider - Uses auth user ID when logged in
final logsNotifierProvider = StateNotifierProvider<LogsNotifier, AsyncValue<List<DailyLog>>>((ref) {
  final logService = ref.watch(logServiceProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final authUser = ref.watch(currentAuthUserProvider);
  final localUser = ref.watch(currentUserProvider).value;

  return LogsNotifier(
    logService,
    isLoggedIn,
    authUser?.id, // Supabase UUID
    localUser?.id, // Local integer ID
  );
});

// Provider for logs of a specific habit
final habitLogsProvider = FutureProvider.family<List<DailyLog>, int>((ref, habitId) async {
  final logService = ref.read(logServiceProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);

  if (isLoggedIn && logService is CloudLogService) {
    // Cloud mode: Fetch all logs and filter by habitId
    final cloudLogs = await logService.getLogs();
    return cloudLogs
        .map((data) => _logFromCloudData(data))
        .where((log) => log.habitId == habitId)
        .toList();
  } else if (logService is LogService) {
    // Local mode
    return await logService.getLogsForHabit(habitId);
  }

  return [];
});

// Helper function to convert cloud data to DailyLog model
DailyLog _logFromCloudData(Map<String, dynamic> data) {
  return DailyLog(
    id: data['id'].hashCode, // Convert UUID string to int hash
    userId: data['user_id'].hashCode, // Convert UUID string to int hash
    habitId: int.tryParse(data['habit_id'] as String) ?? data['habit_id'].hashCode,
    completedAt: DateTime.parse(data['completed_at'] as String),
    notes: data['notes'] as String?,
    sentiment: data['sentiment'] as String?,
    voiceNotePath: data['voice_note_path'] as String?,
    createdAt: DateTime.parse(data['created_at'] as String),
  );
}
