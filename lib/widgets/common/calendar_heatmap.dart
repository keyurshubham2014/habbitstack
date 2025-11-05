import 'package:flutter/material.dart';
import '../../models/daily_log.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:intl/intl.dart';

class CalendarHeatmap extends StatelessWidget {
  final List<DailyLog> logs;
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime)? onDayTap;

  const CalendarHeatmap({
    super.key,
    required this.logs,
    required this.startDate,
    required this.endDate,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildLegend(),
        const SizedBox(height: 16),
        _buildHeatmap(context),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '90-Day Activity',
          style: AppTextStyles.title(),
        ),
        Text(
          '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}',
          style: AppTextStyles.caption().copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Text(
          'Less',
          style: AppTextStyles.caption().copyWith(
            color: AppColors.secondaryText,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getIntensityColor(index),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'More',
          style: AppTextStyles.caption().copyWith(
            color: AppColors.secondaryText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    // Group logs by day
    final logsByDay = _groupLogsByDay();

    // Calculate weeks
    final weeks = _calculateWeeks();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week day labels
          _buildWeekDayLabels(),
          const SizedBox(width: 8),

          // Calendar grid
          ...weeks.map((week) => _buildWeekColumn(context, week, logsByDay)),
        ],
      ),
    );
  }

  Widget _buildWeekDayLabels() {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weekDays.map((day) {
        return Container(
          height: 24,
          padding: const EdgeInsets.only(right: 8),
          alignment: Alignment.centerRight,
          child: Text(
            day,
            style: AppTextStyles.caption().copyWith(
              fontSize: 10,
              color: AppColors.secondaryText,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekColumn(
    BuildContext context,
    List<DateTime?> week,
    Map<String, List<DailyLog>> logsByDay,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        children: week.map((date) {
          if (date == null) {
            // Empty cell for padding
            return Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(bottom: 4),
            );
          }

          final dayKey = _getDayKey(date);
          final dayLogs = logsByDay[dayKey] ?? [];
          final isToday = _isToday(date);

          return GestureDetector(
            onTap: () => onDayTap?.call(date),
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: _getColorForDay(dayLogs.length),
                borderRadius: BorderRadius.circular(4),
                border: isToday
                    ? Border.all(color: AppColors.warmCoral, width: 2)
                    : null,
              ),
              child: dayLogs.isEmpty
                  ? null
                  : Center(
                      child: Text(
                        '${dayLogs.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Group logs by day
  Map<String, List<DailyLog>> _groupLogsByDay() {
    final grouped = <String, List<DailyLog>>{};

    for (final log in logs) {
      final dayKey = _getDayKey(log.completedAt);
      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(log);
    }

    return grouped;
  }

  // Calculate weeks for grid layout
  List<List<DateTime?>> _calculateWeeks() {
    final weeks = <List<DateTime?>>[];
    DateTime current = startDate;

    // Start from the first Monday before or on startDate
    while (current.weekday != DateTime.monday) {
      current = current.subtract(const Duration(days: 1));
    }

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final week = <DateTime?>[];

      for (int i = 0; i < 7; i++) {
        if (current.isBefore(startDate) || current.isAfter(endDate)) {
          week.add(null); // Empty cell
        } else {
          week.add(current);
        }
        current = current.add(const Duration(days: 1));
      }

      weeks.add(week);
    }

    return weeks;
  }

  // Get color based on number of completions
  Color _getColorForDay(int count) {
    if (count == 0) return AppColors.tertiaryBg;
    if (count == 1) return AppColors.gentleTeal.withOpacity(0.3);
    if (count == 2) return AppColors.gentleTeal.withOpacity(0.5);
    if (count >= 3 && count <= 4) return AppColors.gentleTeal.withOpacity(0.75);
    return AppColors.gentleTeal; // 5+
  }

  // Get intensity color for legend
  Color _getIntensityColor(int level) {
    if (level == 0) return AppColors.tertiaryBg;
    if (level == 1) return AppColors.gentleTeal.withOpacity(0.3);
    if (level == 2) return AppColors.gentleTeal.withOpacity(0.5);
    if (level == 3) return AppColors.gentleTeal.withOpacity(0.75);
    return AppColors.gentleTeal;
  }

  String _getDayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
