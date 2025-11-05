import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/logs_provider.dart';
import '../../models/habit.dart';
import '../../providers/habits_provider.dart';
import '../../widgets/common/calendar_heatmap.dart';
import '../../models/daily_log.dart';

class CalendarViewScreen extends ConsumerWidget {
  const CalendarViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text('Activity Calendar', style: AppTextStyles.headline()),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: logsAsync.when(
        data: (logs) => _buildCalendarView(context, logs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.softRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading calendar',
                style: AppTextStyles.title(),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context, List<DailyLog> logs) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(const Duration(days: 89)); // 90 days total

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Stats Card
          _buildSummaryCard(logs, startDate, endDate),
          const SizedBox(height: 24),

          // Calendar Heatmap
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CalendarHeatmap(
                logs: logs,
                startDate: startDate,
                endDate: endDate,
                onDayTap: (date) => _showDayDetails(context, logs, date),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Activity Breakdown
          _buildActivityBreakdown(logs, startDate, endDate),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<DailyLog> logs, DateTime startDate, DateTime endDate) {
    // Filter logs within date range
    final logsInRange = logs.where((log) {
      final logDate = log.completedAt;
      return (logDate.isAfter(startDate) || logDate.isAtSameMomentAs(startDate)) &&
          (logDate.isBefore(endDate) || logDate.isAtSameMomentAs(endDate));
    }).toList();

    // Calculate stats
    final totalLogs = logsInRange.length;
    final uniqueDays = logsInRange
        .map((log) => '${log.completedAt.year}-${log.completedAt.month}-${log.completedAt.day}')
        .toSet()
        .length;
    final avgPerDay = uniqueDays > 0 ? (totalLogs / uniqueDays).toStringAsFixed(1) : '0.0';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.secondaryBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '90-Day Summary',
              style: AppTextStyles.title(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Logs', totalLogs.toString(), Icons.check_circle),
                _buildStatItem('Active Days', uniqueDays.toString(), Icons.calendar_today),
                _buildStatItem('Avg/Day', avgPerDay, Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gentleTeal, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.title().copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityBreakdown(List<DailyLog> logs, DateTime startDate, DateTime endDate) {
    // Filter logs within date range
    final logsInRange = logs.where((log) {
      final logDate = log.completedAt;
      return (logDate.isAfter(startDate) || logDate.isAtSameMomentAs(startDate)) &&
          (logDate.isBefore(endDate) || logDate.isAtSameMomentAs(endDate));
    }).toList();

    // Group by intensity
    int zeroLogs = 0;
    int lowLogs = 0;
    int mediumLogs = 0;
    int highLogs = 0;

    final logsByDay = <String, int>{};
    for (final log in logsInRange) {
      final dayKey = '${log.completedAt.year}-${log.completedAt.month}-${log.completedAt.day}';
      logsByDay[dayKey] = (logsByDay[dayKey] ?? 0) + 1;
    }

    for (final count in logsByDay.values) {
      if (count == 0) {
        zeroLogs++;
      } else if (count == 1) {
        lowLogs++;
      } else if (count == 2 || count == 3) {
        mediumLogs++;
      } else {
        highLogs++;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Intensity',
              style: AppTextStyles.title(),
            ),
            const SizedBox(height: 16),
            _buildIntensityRow('Low (1 log)', lowLogs, AppColors.gentleTeal.withOpacity(0.3)),
            const SizedBox(height: 8),
            _buildIntensityRow('Medium (2-3 logs)', mediumLogs, AppColors.gentleTeal.withOpacity(0.6)),
            const SizedBox(height: 8),
            _buildIntensityRow('High (4+ logs)', highLogs, AppColors.gentleTeal),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body(),
          ),
        ),
        Text(
          '$count days',
          style: AppTextStyles.body().copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  void _showDayDetails(BuildContext context, List<DailyLog> logs, DateTime date) {
    final dayLogs = logs.where((log) {
      return log.completedAt.year == date.year &&
          log.completedAt.month == date.month &&
          log.completedAt.day == date.day;
    }).toList();

    if (dayLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No activities logged on ${_formatDate(date)}'),
          backgroundColor: AppColors.neutralGray,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final habitService = ref.read(habitServiceProvider);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.gentleTeal),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(date),
                      style: AppTextStyles.title(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${dayLogs.length} ${dayLogs.length == 1 ? 'activity' : 'activities'} logged',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                ...dayLogs.map((log) => FutureBuilder(
                  future: habitService.getHabit(log.habitId),
                  builder: (context, snapshot) {
                    final habit = snapshot.data as Habit?;
                    final habitName = habit?.name ?? 'Activity';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habitName,
                                  style: AppTextStyles.body().copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (log.notes != null && log.notes!.isNotEmpty)
                                  Text(
                                    log.notes!,
                                    style: AppTextStyles.caption().copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
