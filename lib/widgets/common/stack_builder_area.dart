import 'package:flutter/material.dart';
import '../../models/habit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StackBuilderArea extends StatefulWidget {
  final Habit? anchorHabit;
  final List<Habit> stackedHabits;
  final Function(Habit?) onAnchorChanged;
  final Function(List<Habit>) onStackChanged;
  final Function(Habit) onRemoveHabit;

  const StackBuilderArea({
    super.key,
    required this.anchorHabit,
    required this.stackedHabits,
    required this.onAnchorChanged,
    required this.onStackChanged,
    required this.onRemoveHabit,
  });

  @override
  State<StackBuilderArea> createState() => _StackBuilderAreaState();
}

class _StackBuilderAreaState extends State<StackBuilderArea> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.deepBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Anchor Habit Drop Zone
          _buildAnchorDropZone(),

          if (widget.anchorHabit != null) ...[
            const SizedBox(height: 16),
            _buildStackArrow(),
            const SizedBox(height: 16),

            // Stacked Habits
            _buildStackedHabitsArea(),
          ],
        ],
      ),
    );
  }

  Widget _buildAnchorDropZone() {
    return DragTarget<Habit>(
      onWillAcceptWithDetails: (details) => details.data != null,
      onAcceptWithDetails: (details) {
        widget.onAnchorChanged(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        if (widget.anchorHabit == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isHovering
                  ? AppColors.deepBlue.withOpacity(0.1)
                  : AppColors.tertiaryBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHovering ? AppColors.deepBlue : AppColors.neutralGray,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.anchor,
                  color: isHovering ? AppColors.deepBlue : AppColors.neutralGray,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Drag an anchor habit here\n(An existing strong habit)',
                    style: AppTextStyles.body().copyWith(
                      color: isHovering
                          ? AppColors.deepBlue
                          : AppColors.secondaryText,
                      fontWeight: isHovering ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return _buildHabitChip(
          widget.anchorHabit!,
          isAnchor: true,
          onRemove: () => widget.onAnchorChanged(null),
        );
      },
    );
  }

  Widget _buildStackedHabitsArea() {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final habit = widget.stackedHabits.removeAt(oldIndex);
          widget.stackedHabits.insert(newIndex, habit);
          widget.onStackChanged(widget.stackedHabits);
        });
      },
      footer: _buildAddHabitDropZone(),
      children: [
        for (var i = 0; i < widget.stackedHabits.length; i++)
          Column(
            key: ValueKey(widget.stackedHabits[i].id),
            children: [
              _buildHabitChip(
                widget.stackedHabits[i],
                onRemove: () => widget.onRemoveHabit(widget.stackedHabits[i]),
              ),
              if (i < widget.stackedHabits.length - 1) ...[
                const SizedBox(height: 8),
                _buildStackArrow(),
                const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildAddHabitDropZone() {
    return Padding(
      padding: EdgeInsets.only(top: widget.stackedHabits.isNotEmpty ? 16 : 0),
      child: DragTarget<Habit>(
        onWillAcceptWithDetails: (details) =>
            details.data != null && details.data.id != widget.anchorHabit?.id,
        onAcceptWithDetails: (details) {
          final updatedList = List<Habit>.from(widget.stackedHabits);
          updatedList.add(details.data);
          widget.onStackChanged(updatedList);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHovering
                  ? AppColors.gentleTeal.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHovering ? AppColors.gentleTeal : AppColors.neutralGray,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: isHovering ? AppColors.gentleTeal : AppColors.neutralGray,
                ),
                const SizedBox(width: 8),
                Text(
                  'Drag habit here to add to stack',
                  style: AppTextStyles.body().copyWith(
                    color: isHovering ? AppColors.gentleTeal : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitChip(
    Habit habit, {
    bool isAnchor = false,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAnchor
            ? AppColors.deepBlue.withOpacity(0.1)
            : AppColors.gentleTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnchor ? AppColors.deepBlue : AppColors.gentleTeal,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (!isAnchor) const Icon(Icons.drag_indicator, color: AppColors.neutralGray),
          if (!isAnchor) const SizedBox(width: 8),
          Icon(
            isAnchor ? Icons.anchor : Icons.check_circle,
            color: isAnchor ? AppColors.deepBlue : AppColors.gentleTeal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: AppTextStyles.body().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isAnchor) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Anchor Habit',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.deepBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.neutralGray,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _buildStackArrow() {
    return const Center(
      child: Icon(
        Icons.arrow_downward,
        color: AppColors.neutralGray,
        size: 24,
      ),
    );
  }
}
