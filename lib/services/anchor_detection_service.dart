import '../models/habit.dart';
import '../models/daily_log.dart';
import 'log_service.dart';
import 'habit_service.dart';

class AnchorCandidate {
  final Habit habit;
  final double consistencyScore; // 0.0 to 1.0
  final int totalDays;
  final int loggedDays;
  final int currentStreak;

  AnchorCandidate({
    required this.habit,
    required this.consistencyScore,
    required this.totalDays,
    required this.loggedDays,
    required this.currentStreak,
  });

  String get consistencyPercentage => '${(consistencyScore * 100).toInt()}%';

  bool get isExcellent => consistencyScore >= 0.8;
  bool get isGood => consistencyScore >= 0.6;
  bool get isFair => consistencyScore >= 0.4;
}

class AnchorDetectionService {
  final LogService _logService = LogService();
  final HabitService _habitService = HabitService();

  /// Detect potential anchor habits based on logging consistency
  Future<List<AnchorCandidate>> detectAnchorCandidates(
    int userId, {
    int daysToAnalyze = 30,
    double minConsistencyScore = 0.5,
  }) async {
    // Get all habits for the user
    final habits = await _habitService.getAllHabits(userId);

    if (habits.isEmpty) return [];

    final candidates = <AnchorCandidate>[];
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysToAnalyze));

    for (final habit in habits) {
      // Skip habits that are too new (less than 14 days old)
      if (habit.createdAt.isAfter(startDate.add(const Duration(days: 14)))) {
        continue;
      }

      // Skip habits already marked as anchors
      if (habit.isAnchor) {
        continue;
      }

      // Get logs for this habit
      final logs = await _logService.getLogsForHabit(
        habit.id!,
        days: daysToAnalyze,
      );

      // Calculate consistency
      final analysis = _analyzeConsistency(
        habit: habit,
        logs: logs,
        startDate: startDate,
        endDate: endDate,
      );

      if (analysis.consistencyScore >= minConsistencyScore) {
        candidates.add(analysis);
      }
    }

    // Sort by consistency score (highest first)
    candidates.sort((a, b) => b.consistencyScore.compareTo(a.consistencyScore));

    return candidates;
  }

  /// Analyze consistency of a habit over a date range
  AnchorCandidate _analyzeConsistency({
    required Habit habit,
    required List<DailyLog> logs,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Get expected tracking days based on frequency
    final expectedDays = _getExpectedTrackingDays(
      habit: habit,
      startDate: startDate,
      endDate: endDate,
    );

    // Count unique logged days
    final loggedDaySet = <String>{};
    for (final log in logs) {
      final dayKey = _getDayKey(log.completedAt);
      loggedDaySet.add(dayKey);
    }
    final loggedDays = loggedDaySet.length;

    // Calculate consistency score
    final consistencyScore = expectedDays > 0
        ? (loggedDays / expectedDays).clamp(0.0, 1.0)
        : 0.0;

    // Calculate current streak
    final currentStreak = _calculateCurrentStreak(logs, habit);

    return AnchorCandidate(
      habit: habit,
      consistencyScore: consistencyScore,
      totalDays: expectedDays,
      loggedDays: loggedDays,
      currentStreak: currentStreak,
    );
  }

  /// Get expected number of tracking days based on habit frequency
  int _getExpectedTrackingDays({
    required Habit habit,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    int expectedDays = 0;
    DateTime current = startDate;

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (_shouldTrackOnDate(current, habit)) {
        expectedDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return expectedDays;
  }

  /// Check if habit should be tracked on a specific date
  bool _shouldTrackOnDate(DateTime date, Habit habit) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday

    switch (habit.frequency) {
      case 'daily':
        return true;
      case 'weekdays':
        return weekday >= 1 && weekday <= 5;
      case 'weekends':
        return weekday == 6 || weekday == 7;
      case 'custom':
        return habit.customDays?.contains(weekday) ?? false;
      default:
        return true;
    }
  }

  /// Calculate current streak for a habit
  int _calculateCurrentStreak(List<DailyLog> logs, Habit habit) {
    if (logs.isEmpty) return 0;

    // Sort logs by date (most recent first)
    final sortedLogs = List<DailyLog>.from(logs);
    sortedLogs.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    int streak = 0;
    DateTime checkDate = DateTime.now();
    final logDates = sortedLogs.map((log) => _getDayKey(log.completedAt)).toSet();

    // Check backwards from today
    while (true) {
      if (!_shouldTrackOnDate(checkDate, habit)) {
        // Skip days that aren't part of the frequency
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      final dayKey = _getDayKey(checkDate);
      if (logDates.contains(dayKey)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }

      // Safety: Don't check more than 90 days back
      if (checkDate.isBefore(DateTime.now().subtract(const Duration(days: 90)))) {
        break;
      }
    }

    return streak;
  }

  /// Get day key for grouping logs by day
  String _getDayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get suggestion message for user
  String getSuggestionMessage(List<AnchorCandidate> candidates) {
    if (candidates.isEmpty) {
      return 'Keep logging your habits! After 2 weeks of consistent tracking, we\'ll suggest anchor habits for you.';
    }

    final topCandidate = candidates.first;
    return 'Great job! "${topCandidate.habit.name}" is ${topCandidate.consistencyPercentage} consistent. Perfect for an anchor habit!';
  }
}
