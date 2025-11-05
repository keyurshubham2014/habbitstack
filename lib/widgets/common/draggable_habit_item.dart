import 'package:flutter/material.dart';
import '../../models/habit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class DraggableHabitItem extends StatelessWidget {
  final Habit habit;

  const DraggableHabitItem({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Habit>(
      data: habit,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.8,
          child: _buildHabitCard(isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildHabitCard(),
      ),
      child: _buildHabitCard(),
    );
  }

  Widget _buildHabitCard({bool isDragging = false}) {
    return Container(
      width: isDragging ? 300 : double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.neutralGray.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.drag_indicator,
            color: AppColors.neutralGray,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              habit.name,
              style: AppTextStyles.body(),
            ),
          ),
        ],
      ),
    );
  }
}
