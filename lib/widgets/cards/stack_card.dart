import 'package:flutter/material.dart';
import '../../models/habit_stack.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StackCard extends StatelessWidget {
  final HabitStack stack;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StackCard({
    super.key,
    required this.stack,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Stack Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStackColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.layers,
                      color: _getStackColor(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Stack Name & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stack.name,
                          style: AppTextStyles.title().copyWith(fontSize: 18),
                        ),
                        if (stack.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            stack.description!,
                            style: AppTextStyles.caption().copyWith(
                              color: AppColors.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions Menu
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.softRed),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.softRed)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Habit Flow Visualization
              _buildHabitFlow(),

              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: AppColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    '${stack.totalHabits} habits',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitFlow() {
    final habits = stack.allHabitsOrdered;

    if (habits.isEmpty) {
      return Text(
        'No habits in stack',
        style: AppTextStyles.caption().copyWith(
          color: AppColors.secondaryText,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < habits.length; i++) ...[
          _buildHabitChip(habits[i], isAnchor: i == 0 && stack.anchorHabit != null),
          if (i < habits.length - 1)
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.neutralGray),
        ],
      ],
    );
  }

  Widget _buildHabitChip(dynamic habit, {bool isAnchor = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAnchor
            ? AppColors.deepBlue.withOpacity(0.1)
            : AppColors.gentleTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAnchor ? AppColors.deepBlue : AppColors.gentleTeal,
          width: 1.5,
        ),
      ),
      child: Text(
        habit.name,
        style: AppTextStyles.caption().copyWith(
          color: isAnchor ? AppColors.deepBlue : AppColors.gentleTeal,
          fontWeight: isAnchor ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getStackColor() {
    if (stack.color != null) {
      try {
        return Color(int.parse(stack.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return AppColors.deepBlue;
      }
    }
    return AppColors.deepBlue;
  }
}
