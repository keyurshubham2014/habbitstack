import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/streak.dart';
import '../../models/habit.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../constants/habit_icons.dart';

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
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Habit Icon
                      _buildHabitIcon(habit),
                      const SizedBox(width: 12),

                      // Habit Name & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              style: AppTextStyles.title().copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusBadge(streak),
                          ],
                        ),
                      ),

                      // Streak Number
                      _buildStreakBadge(streak),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatItem(
                        icon: Icons.local_fire_department,
                        label: 'Current',
                        value: '${streak.currentStreak}',
                        color: AppColors.warningAmber,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        icon: Icons.emoji_events,
                        label: 'Longest',
                        value: '${streak.longestStreak}',
                        color: AppColors.successGreen,
                      ),
                      const SizedBox(width: 24),
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
                    const SizedBox(height: 12),
                    _buildGracePeriodIndicator(streak),
                  ],

                  // Motivational Message
                  if (streak.currentStreak >= 7) ...[
                    const SizedBox(height: 12),
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
        habit.icon != null
            ? HabitIcons.getIconByName(habit.icon!)
            : Icons.check_circle_outline,
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
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBadge(Streak streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(streak.status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${streak.currentStreak}',
            style: AppTextStyles.headline().copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          Text(
            streak.currentStreak == 1 ? 'day' : 'days',
            style: AppTextStyles.caption().copyWith(
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
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.body().copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption().copyWith(
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warningAmber, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.warningAmber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grace Period Active',
                  style: AppTextStyles.body().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$used of $total strikes used • $remaining remaining',
                  style: AppTextStyles.caption().copyWith(
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
              padding: const EdgeInsets.only(left: 4),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, color: AppColors.successGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption().copyWith(
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
