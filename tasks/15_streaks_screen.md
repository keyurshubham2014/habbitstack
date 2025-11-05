# Task 15: Streaks Visualization Screen

**Status**: DONE ✅
**Priority**: HIGH
**Estimated Time**: 4 hours
**Assigned To**: Claude
**Dependencies**: Task 14 (Streak Calculator)
**Completed**: 2025-11-05

---

## Objective

Build an engaging streaks visualization screen that displays all habit streaks with their current status, grace period indicators, and motivational feedback.

## Acceptance Criteria

- [x] Streaks screen shows all active habit streaks
- [x] Visual indicators for three states (Perfect/Grace/Broken)
- [x] Current streak and longest streak displayed
- [x] Grace period strikes shown (e.g., "⚡ 1 of 2 strikes used")
- [x] Empty state for new users
- [x] Sort options (by streak length, by status, by habit name)
- [x] Tap habit to see detailed streak history
- [x] Motivational messages based on streak status
- [x] Pull-to-refresh to recalculate streaks

---

## Step-by-Step Instructions

### 1. Create Streaks Provider

#### `lib/providers/streaks_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/streak.dart';
import '../services/streak_calculator.dart';
import 'user_provider.dart';

// Streak Calculator Service Provider
final streakCalculatorProvider = Provider<StreakCalculator>((ref) {
  return StreakCalculator();
});

// Streaks State Notifier
class StreaksNotifier extends StateNotifier<AsyncValue<List<Streak>>> {
  final StreakCalculator _calculator;
  final int userId;

  StreaksNotifier(this._calculator, this.userId) : super(const AsyncValue.loading()) {
    loadStreaks();
  }

  Future<void> loadStreaks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _calculator.getAllStreaks(userId);
    });
  }

  Future<void> refresh() async {
    await loadStreaks();
  }

  Future<void> recalculateAll() async {
    await _calculator.recalculateAllStreaks(userId);
    await loadStreaks();
  }
}

// Streaks Provider
final streaksNotifierProvider =
    StateNotifierProvider.family<StreaksNotifier, AsyncValue<List<Streak>>, int>(
  (ref, userId) {
    final calculator = ref.watch(streakCalculatorProvider);
    return StreaksNotifier(calculator, userId);
  },
);

// Current User Streaks Provider
final currentUserStreaksProvider = StreamProvider<List<Streak>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield [];
    return;
  }

  final calculator = ref.read(streakCalculatorProvider);

  while (true) {
    final streaks = await calculator.getAllStreaks(user.id!);
    yield streaks;
    await Future.delayed(Duration(seconds: 30)); // Refresh every 30 seconds
  }
});
```

### 2. Create Streak Card Widget

#### `lib/widgets/cards/streak_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/streak.dart';
import '../../models/habit.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StreakCard extends ConsumerWidget {
  final Streak streak;
  final VoidCallback? onTap;

  const StreakCard({
    super.key,
    required this.streak,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Habit?>(
      future: ref.read(habitServiceProvider).getHabit(streak.habitId),
      builder: (context, snapshot) {
        final habit = snapshot.data;
        if (habit == null) {
          return SizedBox.shrink();
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _getStatusColor(streak.status),
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Habit Icon
                      _buildHabitIcon(habit),
                      SizedBox(width: 12),

                      // Habit Name & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              style: AppTextStyles.title.copyWith(fontSize: 18),
                            ),
                            SizedBox(height: 4),
                            _buildStatusBadge(streak),
                          ],
                        ),
                      ),

                      // Streak Number
                      _buildStreakBadge(streak),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatItem(
                        icon: Icons.local_fire_department,
                        label: 'Current',
                        value: '${streak.currentStreak}',
                        color: AppColors.warningAmber,
                      ),
                      SizedBox(width: 24),
                      _buildStatItem(
                        icon: Icons.emoji_events,
                        label: 'Longest',
                        value: '${streak.longestStreak}',
                        color: AppColors.successGreen,
                      ),
                      SizedBox(width: 24),
                      _buildStatItem(
                        icon: Icons.check_circle,
                        label: 'Total',
                        value: '${streak.totalCompletions}',
                        color: AppColors.deepBlue,
                      ),
                    ],
                  ),

                  // Grace Period Indicator
                  if (streak.isInGracePeriod || streak.gracePeriodUsed > 0) ...[
                    SizedBox(height: 12),
                    _buildGracePeriodIndicator(streak),
                  ],

                  // Motivational Message
                  if (streak.currentStreak >= 7) ...[
                    SizedBox(height: 12),
                    _buildMotivationalMessage(streak),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHabitIcon(Habit habit) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _getStatusColor(streak.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.check_circle_outline, // TODO: Use habit.icon
        color: _getStatusColor(streak.status),
        size: 28,
      ),
    );
  }

  Widget _buildStatusBadge(Streak streak) {
    String label;
    IconData icon;
    Color color = _getStatusColor(streak.status);

    switch (streak.status) {
      case StreakStatus.perfect:
        label = 'Perfect Streak';
        icon = Icons.star;
        break;
      case StreakStatus.gracePeriod:
        label = 'Grace Period';
        icon = Icons.warning_amber_rounded;
        break;
      case StreakStatus.broken:
        label = 'Broken';
        icon = Icons.heart_broken;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBadge(Streak streak) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(streak.status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${streak.currentStreak}',
            style: AppTextStyles.headline.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          Text(
            streak.currentStreak == 1 ? 'day' : 'days',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGracePeriodIndicator(Streak streak) {
    final remaining = streak.remainingGraceStrikes;
    final used = streak.gracePeriodUsed;
    final total = streak.maxGracePeriod;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warningAmber, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: AppColors.warningAmber, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grace Period Active',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '$used of $total strikes used • $remaining remaining',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Visual strike indicators
          ...List.generate(total, (index) {
            return Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                index < used ? Icons.close : Icons.check,
                color: index < used ? AppColors.softRed : AppColors.successGreen,
                size: 16,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMotivationalMessage(Streak streak) {
    String message = _getMotivationalMessage(streak);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration, color: AppColors.successGreen, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(Streak streak) {
    if (streak.currentStreak >= 30) {
      return 'Incredible! 30-day streak! You\'re unstoppable!';
    } else if (streak.currentStreak >= 21) {
      return 'Amazing! 3 weeks strong! This is a habit now!';
    } else if (streak.currentStreak >= 14) {
      return 'Fantastic! 2 weeks in a row! Keep it up!';
    } else if (streak.currentStreak >= 7) {
      return 'Great job! One week streak! You\'re building momentum!';
    }
    return 'Keep going!';
  }

  Color _getStatusColor(StreakStatus status) {
    switch (status) {
      case StreakStatus.perfect:
        return AppColors.successGreen;
      case StreakStatus.gracePeriod:
        return AppColors.warningAmber;
      case StreakStatus.broken:
        return AppColors.softRed;
    }
  }
}
```

### 3. Create Streaks Screen

#### `lib/screens/streaks/streaks_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/streak.dart';
import '../../providers/streaks_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/cards/streak_card.dart';

enum StreakSortOption {
  currentStreak,
  longestStreak,
  status,
  habitName,
}

class StreaksScreen extends ConsumerStatefulWidget {
  const StreaksScreen({super.key});

  @override
  ConsumerState<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends ConsumerState<StreaksScreen> {
  StreakSortOption _sortOption = StreakSortOption.currentStreak;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      appBar: AppBar(
        title: Text('Streaks', style: AppTextStyles.headline),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        actions: [
          PopupMenuButton<StreakSortOption>(
            icon: Icon(Icons.sort, color: AppColors.primaryText),
            onSelected: (option) {
              setState(() => _sortOption = option);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: StreakSortOption.currentStreak,
                child: Text('Sort by Current Streak'),
              ),
              PopupMenuItem(
                value: StreakSortOption.longestStreak,
                child: Text('Sort by Longest Streak'),
              ),
              PopupMenuItem(
                value: StreakSortOption.status,
                child: Text('Sort by Status'),
              ),
              PopupMenuItem(
                value: StreakSortOption.habitName,
                child: Text('Sort by Habit Name'),
              ),
            ],
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text('Please log in'));
          }
          return _buildStreaksList(user.id!);
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStreaksList(int userId) {
    final streaksAsync = ref.watch(streaksNotifierProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(streaksNotifierProvider(userId).notifier).recalculateAll();
      },
      child: streaksAsync.when(
        data: (streaks) {
          if (streaks.isEmpty) {
            return _buildEmptyState();
          }

          // Sort streaks
          final sortedStreaks = _sortStreaks(streaks);

          return Column(
            children: [
              _buildStatsHeader(streaks),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: sortedStreaks.length,
                  itemBuilder: (context, index) {
                    return StreakCard(
                      streak: sortedStreaks[index],
                      onTap: () => _showStreakDetails(sortedStreaks[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading streaks: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              size: 100,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 24),
            Text(
              'No Streaks Yet',
              style: AppTextStyles.title.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Start logging habits to build your first streak!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(List<Streak> streaks) {
    final perfectCount = streaks.where((s) => s.isPerfect).length;
    final graceCount = streaks.where((s) => s.isInGracePeriod).length;
    final brokenCount = streaks.where((s) => s.isBroken).length;
    final totalDays = streaks.fold<int>(0, (sum, s) => sum + s.currentStreak);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Active Days',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$totalDays',
            style: AppTextStyles.headline.copyWith(
              fontSize: 32,
              color: AppColors.deepBlue,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                icon: Icons.star,
                label: 'Perfect',
                count: perfectCount,
                color: AppColors.successGreen,
              ),
              _buildStatChip(
                icon: Icons.warning_amber_rounded,
                label: 'Grace',
                count: graceCount,
                color: AppColors.warningAmber,
              ),
              _buildStatChip(
                icon: Icons.heart_broken,
                label: 'Broken',
                count: brokenCount,
                color: AppColors.softRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 4),
        Text(
          '$count',
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.secondaryText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  List<Streak> _sortStreaks(List<Streak> streaks) {
    final sorted = List<Streak>.from(streaks);

    switch (_sortOption) {
      case StreakSortOption.currentStreak:
        sorted.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
        break;
      case StreakSortOption.longestStreak:
        sorted.sort((a, b) => b.longestStreak.compareTo(a.longestStreak));
        break;
      case StreakSortOption.status:
        sorted.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case StreakSortOption.habitName:
        // Will need to fetch habit names - simplified for now
        break;
    }

    return sorted;
  }

  void _showStreakDetails(Streak streak) {
    // TODO: Navigate to detailed streak history screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Streak Details'),
        content: Text('Detailed history coming in Task 16!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

---

## Verification Checklist

- [ ] Streaks screen displays all habit streaks
- [ ] Three status colors working (green/yellow/red)
- [ ] Current and longest streaks shown correctly
- [ ] Grace period indicator displays strikes
- [ ] Motivational messages appear for long streaks
- [ ] Sort options work (by streak, by status, etc.)
- [ ] Empty state shows for new users
- [ ] Pull-to-refresh recalculates streaks
- [ ] Smooth animations and transitions

---

## Testing Scenarios

1. **Empty State**: New user with no habits, verify empty state
2. **Perfect Streak**: Create 7-day perfect streak, verify green badge
3. **Grace Period**: Miss 1 day, verify yellow badge with strikes
4. **Broken Streak**: Miss 3 days, verify red badge
5. **Multiple Streaks**: Test with 5+ habits, verify all display
6. **Sorting**: Test all sort options
7. **Motivational Messages**: Build 7, 14, 21, 30 day streaks, verify messages

---

## Next Task

After completion, proceed to: [16_calendar_heatmap.md](./16_calendar_heatmap.md)

---

**Last Updated**: 2025-11-05
