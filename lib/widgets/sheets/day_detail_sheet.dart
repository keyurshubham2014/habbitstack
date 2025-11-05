import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../constants/habit_icons.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
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
                    style: AppTextStyles.title(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${logs.length} ${logs.length == 1 ? 'habit' : 'habits'} completed',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Logs List
          if (logs.isEmpty)
            _buildEmptyState()
          else
            Flexible(
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
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.neutralGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No habits logged this day',
              style: AppTextStyles.body().copyWith(
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
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                    habit?.icon != null
                        ? HabitIcons.getIconByName(habit!.icon!)
                        : Icons.check_circle,
                    color: AppColors.gentleTeal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Info
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
                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          log.notes!,
                          style: AppTextStyles.caption().copyWith(
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
                  style: AppTextStyles.caption().copyWith(
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
