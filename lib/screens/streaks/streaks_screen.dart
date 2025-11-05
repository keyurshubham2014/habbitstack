import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/streak.dart';
import '../../models/daily_log.dart';
import '../../providers/streaks_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/cards/streak_card.dart';
import '../../widgets/common/calendar_heatmap.dart';
import '../../widgets/sheets/day_detail_sheet.dart';
import '../../services/log_service.dart';

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
  final LogService _logService = LogService();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      appBar: AppBar(
        title: Text('Streaks', style: AppTextStyles.headline()),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        actions: [
          PopupMenuButton<StreakSortOption>(
            icon: const Icon(Icons.sort, color: AppColors.primaryText),
            onSelected: (option) {
              setState(() => _sortOption = option);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: StreakSortOption.currentStreak,
                child: Text('Sort by Current Streak'),
              ),
              const PopupMenuItem(
                value: StreakSortOption.longestStreak,
                child: Text('Sort by Longest Streak'),
              ),
              const PopupMenuItem(
                value: StreakSortOption.status,
                child: Text('Sort by Status'),
              ),
              const PopupMenuItem(
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
            return const Center(child: Text('Please log in'));
          }
          return _buildStreaksList(user.id!);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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

              // Calendar Heatmap
              Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<List<DailyLog>>(
                  future: _logService.getLogsForDateRange(
                    userId,
                    DateTime.now().subtract(const Duration(days: 90)),
                    DateTime.now(),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    return CalendarHeatmap(
                      logs: snapshot.data!,
                      startDate: DateTime.now().subtract(const Duration(days: 90)),
                      endDate: DateTime.now(),
                      onDayTap: (date) => _showDayDetails(date, snapshot.data!),
                    );
                  },
                ),
              ),

              // Streaks List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading streaks: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              size: 100,
              color: AppColors.neutralGray,
            ),
            const SizedBox(height: 24),
            Text(
              'No Streaks Yet',
              style: AppTextStyles.title().copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start logging habits to build your first streak!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Active Days',
            style: AppTextStyles.caption().copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalDays',
            style: AppTextStyles.headline().copyWith(
              fontSize: 32,
              color: AppColors.deepBlue,
            ),
          ),
          const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: AppTextStyles.title().copyWith(fontSize: 16),
        ),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
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
        title: const Text('Streak Details'),
        content: const Text('Detailed history with calendar heatmap!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(DateTime date, List<DailyLog> allLogs) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

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
}
