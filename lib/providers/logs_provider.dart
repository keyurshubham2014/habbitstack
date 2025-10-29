import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_log.dart';
import '../services/log_service.dart';
import 'user_provider.dart';

// Log Service Provider
final logServiceProvider = Provider<LogService>((ref) {
  return LogService();
});

// Today's Logs Provider
final todaysLogsProvider = FutureProvider<List<DailyLog>>((ref) async {
  final logService = ref.read(logServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await logService.getTodaysLogs(user.id!);
});

// Logs Notifier
class LogsNotifier extends StateNotifier<AsyncValue<List<DailyLog>>> {
  final LogService _logService;
  final int userId;

  LogsNotifier(this._logService, this.userId) : super(const AsyncValue.loading()) {
    _loadTodaysLogs();
  }

  Future<void> _loadTodaysLogs() async {
    state = const AsyncValue.loading();
    try {
      final logs = await _logService.getTodaysLogs(userId);
      state = AsyncValue.data(logs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addLog(DailyLog log) async {
    try {
      await _logService.createLog(log);
      await _loadTodaysLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateLog(DailyLog log) async {
    try {
      await _logService.updateLog(log);
      await _loadTodaysLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteLog(int logId) async {
    try {
      await _logService.deleteLog(logId);
      await _loadTodaysLogs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadTodaysLogs();
  }
}

// Logs State Provider
final logsNotifierProvider = StateNotifierProvider<LogsNotifier, AsyncValue<List<DailyLog>>>((ref) {
  final logService = ref.read(logServiceProvider);
  final userAsync = ref.watch(userNotifierProvider);

  return userAsync.when(
    data: (user) => LogsNotifier(logService, user?.id ?? 0),
    loading: () => LogsNotifier(logService, 0),
    error: (_, __) => LogsNotifier(logService, 0),
  );
});

// Provider for logs of a specific habit
final habitLogsProvider = FutureProvider.family<List<DailyLog>, int>((ref, habitId) async {
  final logService = ref.read(logServiceProvider);
  return await logService.getLogsForHabit(habitId);
});
