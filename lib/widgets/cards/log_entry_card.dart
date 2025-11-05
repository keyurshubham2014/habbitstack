import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LogEntryCard extends ConsumerWidget {
  final DailyLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LogEntryCard({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitService = ref.read(habitServiceProvider);

    return FutureBuilder<Habit?>(
      future: habitService.getHabit(log.habitId),
      builder: (context, snapshot) {
        final habit = snapshot.data;
        final habitName = habit?.name ?? 'Unknown Habit';
        final habitIcon = habit?.icon;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Habit Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.gentleTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconData(habitIcon),
                          color: AppColors.gentleTeal,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Habit Name & Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habitName,
                              style: AppTextStyles.title().copyWith(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(log.completedAt),
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sentiment Badge
                      if (log.sentiment != null)
                        _buildSentimentBadge(log.sentiment!),

                      const SizedBox(width: 8),

                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppColors.neutralGray,
                        onPressed: onDelete,
                      ),
                    ],
                  ),

                  // Notes
                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        log.notes!,
                        style: AppTextStyles.body().copyWith(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentimentBadge(String sentiment) {
    IconData icon;
    Color color;

    switch (sentiment) {
      case 'happy':
        icon = Icons.sentiment_very_satisfied;
        color = AppColors.successGreen;
        break;
      case 'struggled':
        icon = Icons.sentiment_dissatisfied;
        color = AppColors.warningAmber;
        break;
      default:
        icon = Icons.sentiment_neutral;
        color = AppColors.neutralGray;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  IconData _getIconData(String? iconName) {
    // Default icon
    if (iconName == null) return Icons.check_circle_outline;

    // Map icon names to IconData
    // TODO: Implement proper icon mapping in Task 11
    return Icons.check_circle_outline;
  }
}
