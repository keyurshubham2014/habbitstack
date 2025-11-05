# Task 10: Drag-and-Drop Habit Reordering

**Status**: ✅ DONE
**Priority**: MEDIUM
**Estimated Time**: 4 hours
**Assigned To**: Claude Code
**Dependencies**: Task 09 (Build Stack Screen)
**Completed**: 2025-11-05

---

## Objective

Implement drag-and-drop functionality for creating and reordering habits within stacks, providing an intuitive visual interface for habit stacking.

## Acceptance Criteria

- [x] Create Stack screen with drag-and-drop interface
- [x] Can select anchor habit from list
- [x] Can drag habits into stack area
- [x] Can reorder habits within stack
- [x] Visual feedback during drag (elevation, opacity)
- [x] Auto-scroll when dragging near edges (handled by Flutter)
- [x] Save button persists the stack order
- [x] Smooth animations for reordering
- [x] Works reliably on both iOS and Android

---

## Step-by-Step Instructions

### 1. Create Stack Creation Screen

#### `lib/screens/build_stack/create_stack_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habit.dart';
import '../../models/habit_stack.dart';
import '../../providers/habits_provider.dart';
import '../../providers/habit_stacks_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/draggable_habit_item.dart';
import '../../widgets/common/stack_builder_area.dart';

class CreateStackScreen extends ConsumerStatefulWidget {
  final HabitStack? existingStack;

  const CreateStackScreen({super.key, this.existingStack});

  @override
  ConsumerState<CreateStackScreen> createState() => _CreateStackScreenState();
}

class _CreateStackScreenState extends ConsumerState<CreateStackScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  Habit? _anchorHabit;
  List<Habit> _stackedHabits = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingStack?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingStack?.description ?? '',
    );

    if (widget.existingStack != null) {
      _anchorHabit = widget.existingStack!.anchorHabit;
      _stackedHabits = List.from(widget.existingStack!.stackedHabits ?? []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      appBar: AppBar(
        title: Text(
          widget.existingStack == null ? 'Create Stack' : 'Edit Stack',
          style: AppTextStyles.headline,
        ),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
      ),
      body: habitsAsync.when(
        data: (habits) => _buildContent(habits),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildContent(List<Habit> allHabits) {
    // Filter out habits already in the stack
    final availableHabits = allHabits.where((habit) {
      if (_anchorHabit?.id == habit.id) return false;
      return !_stackedHabits.any((h) => h.id == habit.id);
    }).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stack Name
            Text('Stack Name', style: AppTextStyles.title),
            SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Morning Routine',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.primaryBg,
              ),
            ),

            SizedBox(height: 16),

            // Description (Optional)
            Text('Description (optional)', style: AppTextStyles.title),
            SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'What is this stack for?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.primaryBg,
              ),
            ),

            SizedBox(height: 24),

            // Stack Builder Area
            Text('Build Your Stack', style: AppTextStyles.headline.copyWith(fontSize: 20)),
            SizedBox(height: 8),
            Text(
              'Drag habits to build your stack. Start with an anchor habit.',
              style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
            ),
            SizedBox(height: 16),

            StackBuilderArea(
              anchorHabit: _anchorHabit,
              stackedHabits: _stackedHabits,
              onAnchorChanged: (habit) {
                setState(() => _anchorHabit = habit);
              },
              onStackChanged: (habits) {
                setState(() => _stackedHabits = habits);
              },
              onRemoveHabit: (habit) {
                setState(() {
                  if (_anchorHabit?.id == habit.id) {
                    _anchorHabit = null;
                  } else {
                    _stackedHabits.removeWhere((h) => h.id == habit.id);
                  }
                });
              },
            ),

            SizedBox(height: 24),

            // Available Habits
            Text('Available Habits', style: AppTextStyles.title),
            SizedBox(height: 12),

            if (availableHabits.isEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No more habits available. Create new habits from the Today\'s Log screen.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...availableHabits.map((habit) => DraggableHabitItem(habit: habit)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveStack,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.existingStack == null ? 'Create Stack' : 'Save Changes',
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.invertedText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveStack() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a stack name')),
      );
      return;
    }

    if (_anchorHabit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an anchor habit')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not found');

      // Create or update stack
      final stack = HabitStack(
        id: widget.existingStack?.id,
        userId: user.id!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        anchorHabitId: _anchorHabit!.id,
        createdAt: widget.existingStack?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final stackService = ref.read(habitStackServiceProvider);
      final habitService = ref.read(habitServiceProvider);

      int stackId;
      if (widget.existingStack == null) {
        stackId = await stackService.createStack(stack);
      } else {
        await stackService.updateStack(stack);
        stackId = stack.id!;
      }

      // Update anchor habit
      final updatedAnchor = _anchorHabit!.copyWith(
        isAnchor: true,
        stackId: stackId,
        orderInStack: 0,
      );
      await habitService.updateHabit(updatedAnchor);

      // Update stacked habits
      for (var i = 0; i < _stackedHabits.length; i++) {
        final updatedHabit = _stackedHabits[i].copyWith(
          stackId: stackId,
          orderInStack: i + 1, // +1 because anchor is 0
        );
        await habitService.updateHabit(updatedHabit);
      }

      // Refresh providers
      await ref.read(habitStacksNotifierProvider.notifier).refresh();
      await ref.read(habitsNotifierProvider.notifier).refresh();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingStack == null
              ? 'Stack created successfully!'
              : 'Stack updated successfully!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving stack: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
```

### 2. Create Draggable Habit Item Widget

#### `lib/widgets/common/draggable_habit_item.dart`

```dart
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
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
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
                  offset: Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            color: AppColors.neutralGray,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              habit.name,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Create Stack Builder Area Widget

#### `lib/widgets/common/stack_builder_area.dart`

```dart
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
      padding: EdgeInsets.all(16),
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
            SizedBox(height: 16),
            _buildStackArrow(),
            SizedBox(height: 16),

            // Stacked Habits
            _buildStackedHabitsArea(),
          ],
        ],
      ),
    );
  }

  Widget _buildAnchorDropZone() {
    return DragTarget<Habit>(
      onWillAccept: (habit) => habit != null,
      onAccept: (habit) {
        widget.onAnchorChanged(habit);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        if (widget.anchorHabit == null) {
          return Container(
            padding: EdgeInsets.all(20),
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
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Drag an anchor habit here\n(An existing strong habit)',
                    style: AppTextStyles.body.copyWith(
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
      physics: NeverScrollableScrollPhysics(),
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
                SizedBox(height: 8),
                _buildStackArrow(),
                SizedBox(height: 8),
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
        onWillAccept: (habit) => habit != null && habit.id != widget.anchorHabit?.id,
        onAccept: (habit) {
          final updatedList = List<Habit>.from(widget.stackedHabits);
          updatedList.add(habit);
          widget.onStackChanged(updatedList);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHovering
                  ? AppColors.gentleTeal.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHovering ? AppColors.gentleTeal : AppColors.neutralGray,
                width: 2,
                style: BorderStyle.dashed,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: isHovering ? AppColors.gentleTeal : AppColors.neutralGray,
                ),
                SizedBox(width: 8),
                Text(
                  'Drag habit here to add to stack',
                  style: AppTextStyles.body.copyWith(
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
      padding: EdgeInsets.all(12),
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
          if (!isAnchor)
            Icon(Icons.drag_indicator, color: AppColors.neutralGray),
          if (!isAnchor) SizedBox(width: 8),
          Icon(
            isAnchor ? Icons.anchor : Icons.check_circle,
            color: isAnchor ? AppColors.deepBlue : AppColors.gentleTeal,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isAnchor) ...[
                  SizedBox(height: 4),
                  Text(
                    'Anchor Habit',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.deepBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            color: AppColors.neutralGray,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _buildStackArrow() {
    return Center(
      child: Icon(
        Icons.arrow_downward,
        color: AppColors.neutralGray,
        size: 24,
      ),
    );
  }
}
```

---

## Verification Checklist

- [x] Can drag habits from available list
- [x] Can drop habit into anchor zone
- [x] Can drop habits into stack area
- [x] Can reorder habits by dragging
- [x] Can remove habits from stack
- [x] Visual feedback during drag is clear
- [x] Stack saves with correct order
- [x] No bugs when reordering multiple times

---

## Testing Scenarios

1. **Create Stack**: Drag anchor, add 2-3 habits, save
2. **Reorder**: Change habit order multiple times
3. **Remove**: Remove habits from stack
4. **Replace Anchor**: Remove anchor and add new one
5. **Edge Cases**: Try dragging same habit twice, empty stack save

---

## Next Task

After completion, proceed to: [11_habit_icons.md](./11_habit_icons.md)

---

**Last Updated**: 2025-10-29
