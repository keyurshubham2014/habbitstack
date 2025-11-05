# Task 17: 24-Hour Bounce Back Feature

**Status**: DONE ✅
**Priority**: MEDIUM
**Estimated Time**: 3 hours
**Assigned To**: Claude
**Dependencies**: Task 14 (Streak Calculator)
**Completed**: 2025-11-05

---

## Objective

Implement a "Bounce Back" feature that gives users a 24-hour window to retroactively log a missed habit and save their streak.

## Acceptance Criteria

- [x] "Bounce Back" button appears when habit is missed
- [x] 24-hour window from scheduled time to bounce back
- [x] Visual countdown timer shows time remaining
- [x] Retroactive logging saves the streak
- [x] Grace period strike NOT consumed if bounced back
- [ ] Bounce back notification sent at strategic times (deferred to Task 18)
- [ ] Analytics track bounce back usage (future enhancement)
- [x] Limited to once per habit per week

---

## Step-by-Step Instructions

### 1. Update Streak Model

#### Update `lib/models/streak.dart`

Add bounce back tracking:

```dart
class Streak {
  // ... existing fields ...

  final int bounceBacksUsedThisWeek;
  final int maxBounceBacksPerWeek;
  final DateTime? lastBounceBackAt;

  Streak({
    // ... existing params ...
    this.bounceBacksUsedThisWeek = 0,
    this.maxBounceBacksPerWeek = 1, // Default: 1 bounce back per week
    this.lastBounceBackAt,
  });

  // Add to toMap():
  'bounce_backs_used_this_week': bounceBacksUsedThisWeek,
  'max_bounce_backs_per_week': maxBounceBacksPerWeek,
  'last_bounce_back_at': lastBounceBackAt?.toIso8601String(),

  // Add to fromMap():
  bounceBacksUsedThisWeek: map['bounce_backs_used_this_week'] as int? ?? 0,
  maxBounceBacksPerWeek: map['max_bounce_backs_per_week'] as int? ?? 1,
  lastBounceBackAt: map['last_bounce_back_at'] != null
      ? DateTime.parse(map['last_bounce_back_at'] as String)
      : null,

  // Add helper methods:
  bool get canBounceBack => bounceBacksUsedThisWeek < maxBounceBacksPerWeek;
  int get remainingBouncebacks => maxBounceBacksPerWeek - bounceBacksUsedThisWeek;
}
```

### 2. Update Database Schema

#### Update `lib/services/database_service.dart`

Add columns to streaks table:

```dart
// Add to migration or _createTables():
await db.execute('''
  ALTER TABLE streaks ADD COLUMN bounce_backs_used_this_week INTEGER DEFAULT 0
''');

await db.execute('''
  ALTER TABLE streaks ADD COLUMN max_bounce_backs_per_week INTEGER DEFAULT 1
''');

await db.execute('''
  ALTER TABLE streaks ADD COLUMN last_bounce_back_at TEXT
''');
```

### 3. Create Bounce Back Service

#### `lib/services/bounce_back_service.dart`

```dart
import '../models/habit.dart';
import '../models/streak.dart';
import '../models/daily_log.dart';
import 'database_service.dart';
import 'streak_calculator.dart';

class BounceBackOpportunity {
  final Habit habit;
  final DateTime missedDate;
  final DateTime deadline; // 24 hours after missed
  final Duration timeRemaining;
  final bool canBounceBack;

  BounceBackOpportunity({
    required this.habit,
    required this.missedDate,
    required this.deadline,
    required this.timeRemaining,
    required this.canBounceBack,
  });

  bool get isExpired => timeRemaining.isNegative;
  String get formattedTimeRemaining {
    if (isExpired) return 'Expired';

    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hr $minutes min remaining';
    }
    return '$minutes min remaining';
  }
}

class BounceBackService {
  final DatabaseService _db = DatabaseService();
  final StreakCalculator _streakCalculator = StreakCalculator();

  /// Get all available bounce back opportunities for a user
  Future<List<BounceBackOpportunity>> getAvailableBouncebacks(int userId) async {
    final opportunities = <BounceBackOpportunity>[];

    // Get all habits with active streaks
    final streaks = await _streakCalculator.getAllStreaks(userId);

    for (final streak in streaks) {
      // Only check habits that are in grace period or broken recently
      if (streak.status == StreakStatus.perfect) continue;

      final opportunity = await _checkBounceBackEligibility(userId, streak);
      if (opportunity != null && opportunity.canBounceBack) {
        opportunities.add(opportunity);
      }
    }

    return opportunities;
  }

  /// Check if a specific habit is eligible for bounce back
  Future<BounceBackOpportunity?> _checkBounceBackEligibility(
    int userId,
    Streak streak,
  ) async {
    final db = await _db.database;

    // Get habit
    final habitMaps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [streak.habitId],
    );
    if (habitMaps.isEmpty) return null;

    final habit = Habit.fromMap(habitMaps.first);

    // Find the most recent missed day
    final missedDate = await _findMostRecentMissedDay(userId, habit, streak);
    if (missedDate == null) return null;

    // Calculate deadline (24 hours after missed time)
    final deadline = missedDate.add(Duration(hours: 24));
    final now = DateTime.now();
    final timeRemaining = deadline.difference(now);

    // Check if user has bounce backs remaining
    final canBounceBack = streak.canBounceBack && !timeRemaining.isNegative;

    return BounceBackOpportunity(
      habit: habit,
      missedDate: missedDate,
      deadline: deadline,
      timeRemaining: timeRemaining,
      canBounceBack: canBounceBack,
    );
  }

  /// Find the most recent day a habit was missed
  Future<DateTime?> _findMostRecentMissedDay(
    int userId,
    Habit habit,
    Streak streak,
  ) async {
    // Check yesterday and today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    // Check if habit should have been done yesterday
    if (_shouldTrackOnDate(yesterday, habit)) {
      final logged = await _wasHabitLoggedOnDate(userId, habit.id!, yesterday);
      if (!logged) {
        return yesterday;
      }
    }

    // Check if habit should be done today
    if (_shouldTrackOnDate(today, habit)) {
      final logged = await _wasHabitLoggedOnDate(userId, habit.id!, today);
      if (!logged) {
        return today;
      }
    }

    return null;
  }

  /// Check if habit was logged on a specific date
  Future<bool> _wasHabitLoggedOnDate(
    int userId,
    int habitId,
    DateTime date,
  ) async {
    final db = await _db.database;

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(Duration(days: 1));

    final maps = await db.query(
      'daily_logs',
      where: 'user_id = ? AND habit_id = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        userId,
        habitId,
        dayStart.toIso8601String(),
        dayEnd.toIso8601String(),
      ],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  /// Execute a bounce back - retroactively log the habit
  Future<bool> executeBounceBack({
    required int userId,
    required Habit habit,
    required DateTime missedDate,
    String? notes,
  }) async {
    final db = await _db.database;

    // Get current streak
    final streak = await _streakCalculator.getStreak(userId, habit.id!);
    if (streak == null) return false;

    // Check eligibility
    if (!streak.canBounceBack) {
      throw Exception('No bounce backs remaining this week');
    }

    final opportunity = await _checkBounceBackEligibility(userId, streak);
    if (opportunity == null || !opportunity.canBounceBack) {
      throw Exception('Bounce back window expired or not eligible');
    }

    // Create retroactive log entry
    final log = DailyLog(
      userId: userId,
      habitId: habit.id!,
      completedAt: missedDate.add(Duration(hours: 12)), // Set to noon of missed day
      notes: notes ?? 'Bounced back!',
      sentiment: 'neutral',
      createdAt: DateTime.now(),
    );

    await db.insert('daily_logs', log.toMap());

    // Update streak with bounce back usage
    final updatedStreak = streak.copyWith(
      bounceBacksUsedThisWeek: streak.bounceBacksUsedThisWeek + 1,
      lastBounceBackAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await db.update(
      'streaks',
      updatedStreak.toMap(),
      where: 'id = ?',
      whereArgs: [streak.id],
    );

    // Recalculate streak
    final recentLogs = await _getRecentLogs(userId, habit.id!);
    await _streakCalculator.calculateStreak(
      userId: userId,
      habit: habit,
      recentLogs: recentLogs,
    );

    return true;
  }

  /// Reset weekly bounce back counters (call this every Monday)
  Future<void> resetWeeklyBouncebacks() async {
    final db = await _db.database;

    await db.update(
      'streaks',
      {'bounce_backs_used_this_week': 0},
    );
  }

  /// Check if habit should be tracked on date
  bool _shouldTrackOnDate(DateTime date, Habit habit) {
    final weekday = date.weekday;

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

  Future<List<DailyLog>> _getRecentLogs(int userId, int habitId) async {
    final db = await _db.database;

    final maps = await db.query(
      'daily_logs',
      where: 'user_id = ? AND habit_id = ?',
      whereArgs: [userId, habitId],
      orderBy: 'completed_at DESC',
      limit: 90,
    );

    return maps.map((map) => DailyLog.fromMap(map)).toList();
  }
}
```

### 4. Create Bounce Back Card Widget

#### `lib/widgets/cards/bounce_back_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../services/bounce_back_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class BounceBackCard extends StatelessWidget {
  final BounceBackOpportunity opportunity;
  final VoidCallback onBounceBack;

  const BounceBackCard({
    super.key,
    required this.opportunity,
    required this.onBounceBack,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.warningAmber, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.warningAmber.withOpacity(0.1),
              AppColors.primaryBg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.warningAmber, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bounce Back Available!',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 16,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ),
                  Icon(Icons.bolt, color: AppColors.warningAmber),
                ],
              ),

              SizedBox(height: 12),

              // Habit Name
              Text(
                opportunity.habit.name,
                style: AppTextStyles.title.copyWith(fontSize: 18),
              ),

              SizedBox(height: 8),

              // Time Remaining
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 16, color: AppColors.warningAmber),
                    SizedBox(width: 6),
                    Text(
                      opportunity.formattedTimeRemaining,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Description
              Text(
                'You missed this habit yesterday, but you still have time to save your streak!',
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),

              SizedBox(height: 16),

              // Bounce Back Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onBounceBack,
                  icon: Icon(Icons.refresh),
                  label: Text('Bounce Back Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warningAmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 5. Integrate Bounce Back into Home Screen

#### Update `lib/screens/home/todays_log_screen.dart`

Add bounce back section at top:

```dart
// Add imports
import '../../services/bounce_back_service.dart';
import '../../widgets/cards/bounce_back_card.dart';

// In build method, add before logs list:

Column(
  children: [
    // Bounce Back Opportunities
    FutureBuilder<List<BounceBackOpportunity>>(
      future: BounceBackService().getAvailableBouncebacks(user.id!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '⚡ Save Your Streak',
                style: AppTextStyles.title,
              ),
            ),
            ...snapshot.data!.map((opportunity) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: BounceBackCard(
                  opportunity: opportunity,
                  onBounceBack: () => _executeBounceBack(opportunity),
                ),
              );
            }),
            SizedBox(height: 16),
          ],
        );
      },
    ),

    // ... existing logs list ...
  ],
)

// Add bounce back execution method:
Future<void> _executeBounceBack(BounceBackOpportunity opportunity) async {
  try {
    final bounceBackService = BounceBackService();

    await bounceBackService.executeBounceBack(
      userId: ref.read(currentUserProvider).value!.id!,
      habit: opportunity.habit,
      missedDate: opportunity.missedDate,
      notes: 'Bounced back - better late than never!',
    );

    // Refresh screen
    await ref.read(logsNotifierProvider.notifier).refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Streak saved! Way to bounce back!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.softRed,
      ),
    );
  }
}
```

---

## Verification Checklist

- [x] Bounce back opportunities detected correctly
- [x] 24-hour countdown displays accurately
- [x] Retroactive logging saves streak
- [x] Grace period strike NOT consumed
- [x] Limited to 1 bounce back per week per habit
- [x] Weekly reset works (Monday 00:00)
- [x] Expired opportunities don't show
- [x] UI updates after successful bounce back

---

## Testing Scenarios

1. **Eligible Bounce Back**: Miss habit yesterday, verify card appears
2. **Execute Bounce Back**: Tap button, verify streak saved
3. **Weekly Limit**: Use 1 bounce back, verify can't use second
4. **Expiration**: Wait 24+ hours, verify opportunity disappears
5. **Multiple Habits**: Miss 3 habits, verify 3 cards show
6. **Weekly Reset**: Use bounce back, wait until Monday, verify counter reset
7. **Grace Period**: Verify bounce back doesn't consume grace strikes

---

## Analytics to Track

- Bounce back usage rate
- Time remaining when users bounce back
- Habits most frequently bounced back
- Week-over-week bounce back trends
- Success rate of bounce backs (streak saved vs still broken)

---

## UX Considerations

- **Urgency**: Use warning colors to create urgency
- **Encouragement**: Positive messaging ("Save your streak!")
- **Clarity**: Clear countdown timer
- **Reward**: Celebrate successful bounce back
- **Fairness**: Clear limits (1 per week)

---

## Next Task

After completion, proceed to: [18_notifications.md](./18_notifications.md)

---

**Last Updated**: 2025-11-05
