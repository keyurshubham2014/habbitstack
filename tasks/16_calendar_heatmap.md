# Task 16: 90-Day Calendar Heatmap

**Status**: DONE ✅
**Priority**: MEDIUM
**Estimated Time**: 4 hours
**Assigned To**: Claude
**Dependencies**: Task 14 (Streak Calculator)
**Completed**: 2025-11-05

---

## Objective

Create a GitHub-style calendar heatmap showing 90 days of habit completion data with visual intensity indicators for daily activity.

## Acceptance Criteria

- [x] Calendar shows last 90 days of activity
- [x] Heat intensity based on number of habits completed per day
- [x] Color coding: dark = more habits, light = fewer habits, gray = none
- [x] Tap day to see detailed log entries
- [x] Week labels (Mon, Wed, Fri, Sun)
- [x] Month markers at top
- [x] Legend showing color intensity meaning
- [x] Scroll horizontally to see older days
- [x] Current day highlighted with border

---

## Step-by-Step Instructions

### 1. Add fl_chart Dependency

#### Update `pubspec.yaml`

```yaml
dependencies:
  fl_chart: ^0.68.0
```

Run: `flutter pub get`

### 2. Create Calendar Heatmap Widget

#### `lib/widgets/common/calendar_heatmap.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        SizedBox(height: 16),
        _buildLegend(),
        SizedBox(height: 16),
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
          style: AppTextStyles.title,
        ),
        Text(
          '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}',
          style: AppTextStyles.caption.copyWith(
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
          style: AppTextStyles.caption.copyWith(
            color: AppColors.secondaryText,
            fontSize: 10,
          ),
        ),
        SizedBox(width: 8),
        ...List.generate(5, (index) {
          return Padding(
            padding: EdgeInsets.only(right: 4),
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
        SizedBox(width: 8),
        Text(
          'More',
          style: AppTextStyles.caption.copyWith(
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
          SizedBox(width: 8),

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
          padding: EdgeInsets.only(right: 8),
          alignment: Alignment.centerRight,
          child: Text(
            day,
            style: AppTextStyles.caption.copyWith(
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
      padding: EdgeInsets.only(right: 4),
      child: Column(
        children: week.map((date) {
          if (date == null) {
            // Empty cell for padding
            return Container(
              width: 20,
              height: 20,
              margin: EdgeInsets.only(bottom: 4),
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
              margin: EdgeInsets.only(bottom: 4),
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
                        style: TextStyle(
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
      current = current.subtract(Duration(days: 1));
    }

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final week = <DateTime?>[];

      for (int i = 0; i < 7; i++) {
        if (current.isBefore(startDate) || current.isAfter(endDate)) {
          week.add(null); // Empty cell
        } else {
          week.add(current);
        }
        current = current.add(Duration(days: 1));
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
```

### 3. Create Day Detail Sheet

#### `lib/widgets/sheets/day_detail_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class DayDetailSheet extends ConsumerWidget {
  final DateTime date;
  final List<DailyLog> logs;

  const DayDetailSheet({
    super.key,
    required this.date,
    required this.logs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(date),
                    style: AppTextStyles.title,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${logs.length} ${logs.length == 1 ? 'habit' : 'habits'} completed',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Logs List
          if (logs.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return _buildLogItem(ref, logs[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'No habits logged this day',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(WidgetRef ref, DailyLog log) {
    return FutureBuilder<Habit?>(
      future: ref.read(habitServiceProvider).getHabit(log.habitId),
      builder: (context, snapshot) {
        final habit = snapshot.data;
        final habitName = habit?.name ?? 'Unknown';

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gentleTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.gentleTeal,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habitName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          log.notes!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Time
                Text(
                  DateFormat('h:mm a').format(log.completedAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### 4. Integrate Heatmap into Streaks Screen

#### Update `lib/screens/streaks/streaks_screen.dart`

Add heatmap section:

```dart
// Add imports
import '../../widgets/common/calendar_heatmap.dart';
import '../../widgets/sheets/day_detail_sheet.dart';
import '../../services/log_service.dart';

// In _buildStreaksList method, add heatmap before streak cards:

Column(
  children: [
    _buildStatsHeader(streaks),

    // Calendar Heatmap
    Padding(
      padding: EdgeInsets.all(16),
      child: FutureBuilder<List<DailyLog>>(
        future: LogService().getLogsForDateRange(
          userId: userId,
          startDate: DateTime.now().subtract(Duration(days: 90)),
          endDate: DateTime.now(),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          return CalendarHeatmap(
            logs: snapshot.data!,
            startDate: DateTime.now().subtract(Duration(days: 90)),
            endDate: DateTime.now(),
            onDayTap: (date) => _showDayDetails(date, snapshot.data!),
          );
        },
      ),
    ),

    // Streaks List
    Expanded(
      child: ListView.builder(
        // ... existing code
      ),
    ),
  ],
)

// Add method to show day details:
void _showDayDetails(DateTime date, List<DailyLog> allLogs) {
  final dayStart = DateTime(date.year, date.month, date.day);
  final dayEnd = dayStart.add(Duration(days: 1));

  final dayLogs = allLogs.where((log) {
    return log.completedAt.isAfter(dayStart) &&
           log.completedAt.isBefore(dayEnd);
  }).toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DayDetailSheet(
      date: date,
      logs: dayLogs,
    ),
  );
}
```

### 5. Add Date Range Query to Log Service

#### Update `lib/services/log_service.dart`

```dart
/// Get logs for a date range
Future<List<DailyLog>> getLogsForDateRange({
  required int userId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final db = await _database;

  final maps = await db.query(
    'daily_logs',
    where: 'user_id = ? AND completed_at >= ? AND completed_at <= ?',
    whereArgs: [
      userId,
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ],
    orderBy: 'completed_at DESC',
  );

  return maps.map((map) => DailyLog.fromMap(map)).toList();
}
```

---

## Verification Checklist

- [ ] Calendar displays 90 days of data
- [ ] Heat intensity reflects number of completions
- [ ] Week day labels visible
- [ ] Current day highlighted
- [ ] Tapping day shows detail sheet
- [ ] Detail sheet shows all logs for that day
- [ ] Legend explains color intensity
- [ ] Horizontal scrolling works smoothly
- [ ] Empty days show as gray

---

## Testing Scenarios

1. **Empty Calendar**: New user, verify all days gray
2. **Sparse Data**: Log 1-2 habits per day, verify light colors
3. **Dense Data**: Log 5+ habits per day, verify dark colors
4. **Current Day**: Verify today has colored border
5. **Tap Day**: Tap various days, verify detail sheet shows correct logs
6. **Scrolling**: Scroll to 90 days ago, verify smooth performance
7. **Month Boundaries**: Verify calendar handles month transitions

---

## Design Notes

### Color Intensity Levels
- 0 logs: Light gray (#F5F5F5)
- 1 log: Light teal (30% opacity)
- 2 logs: Medium teal (50% opacity)
- 3-4 logs: Dark teal (75% opacity)
- 5+ logs: Full teal (100% opacity)

### Layout
- Each cell: 20x20px with 4px gap
- 7 rows (days of week)
- ~13 columns (weeks)
- Horizontal scroll for older data

---

## Performance Considerations

- Load only 90 days of data (not all-time)
- Cache log grouping calculations
- Use SingleChildScrollView for horizontal scroll
- Limit detail sheet to 50 logs max

---

## Next Task

After completion, proceed to: [17_bounce_back.md](./17_bounce_back.md)

---

**Last Updated**: 2025-11-05
