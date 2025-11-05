# Task 09: Build Stack Screen

**Status**: ✅ DONE
**Priority**: HIGH
**Estimated Time**: 5 hours
**Assigned To**: Claude Code
**Dependencies**: Task 08 (Habit Model Enhancement)
**Completed**: 2025-11-05

---

## Objective

Create the habit stacking interface where users can visualize and build their habit chains, linking new habits to anchor habits.

## Acceptance Criteria

- [x] Build Stack screen displays all user's stacks
- [x] Empty state encourages creating first stack
- [x] "Create Stack" flow is intuitive (placeholder created)
- [x] Visual representation shows Anchor → Habit 1 → Habit 2 → Habit 3
- [ ] Can select anchor habit from existing habits (Task 10)
- [ ] Can add habits to stack in sequence (Task 10)
- [x] Stack cards show preview of chain
- [x] Can edit/delete existing stacks
- [x] Smooth animations and transitions

---

## Step-by-Step Instructions

### 1. Create Build Stack Screen

#### `lib/screens/build_stack/build_stack_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/habit_stacks_provider.dart';
import '../../widgets/cards/stack_card.dart';
import 'create_stack_screen.dart';

class BuildStackScreen extends ConsumerWidget {
  const BuildStackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stacksAsync = ref.watch(habitStacksNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      appBar: AppBar(
        title: Text('Build Stacks', style: AppTextStyles.headline),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppColors.primaryText),
            onPressed: () => _showStackingInfo(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(habitStacksNotifierProvider.notifier).refresh();
        },
        child: stacksAsync.when(
          data: (stacks) => stacks.isEmpty
              ? _buildEmptyState(context)
              : _buildStacksList(context, stacks, ref),
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Error loading stacks: $error'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateStack(context),
        backgroundColor: AppColors.deepBlue,
        icon: Icon(Icons.add),
        label: Text('Create Stack'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 100,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 24),
            Text(
              'No stacks yet',
              style: AppTextStyles.title.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Build your first habit stack by linking new habits to your existing strong habits (anchors).',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateStack(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepBlue,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: Icon(Icons.add),
              label: Text('Create Your First Stack'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStacksList(
    BuildContext context,
    List<dynamic> stacks,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: stacks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '${stacks.length} ${stacks.length == 1 ? 'stack' : 'stacks'}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          );
        }

        final stack = stacks[index - 1];
        return StackCard(
          stack: stack,
          onTap: () => _navigateToStackDetails(context, stack),
          onEdit: () => _navigateToEditStack(context, stack),
          onDelete: () => _confirmDeleteStack(context, ref, stack),
        );
      },
    );
  }

  void _navigateToCreateStack(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStackScreen(),
      ),
    );
  }

  void _navigateToStackDetails(BuildContext context, dynamic stack) {
    // TODO: Navigate to stack details/edit screen
  }

  void _navigateToEditStack(BuildContext context, dynamic stack) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStackScreen(existingStack: stack),
      ),
    );
  }

  void _confirmDeleteStack(BuildContext context, WidgetRef ref, dynamic stack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Stack?'),
        content: Text(
          'This will remove the stack but keep all habits. You can recreate the stack anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(habitStacksNotifierProvider.notifier).deleteStack(stack.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Stack deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.softRed)),
          ),
        ],
      ),
    );
  }

  void _showStackingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('What is Habit Stacking?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Habit stacking is a science-backed technique where you link new habits to existing strong habits (anchors).',
                style: AppTextStyles.body,
              ),
              SizedBox(height: 12),
              Text(
                'Example:',
                style: AppTextStyles.title.copyWith(fontSize: 14),
              ),
              SizedBox(height: 8),
              _buildInfoFlow(),
              SizedBox(height: 12),
              Text(
                'By linking habits to something you already do consistently, you\'re much more likely to stick with them!',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFlow() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFlowItem('Wake up', AppColors.deepBlue, isAnchor: true),
          _buildFlowArrow(),
          _buildFlowItem('Drink water', AppColors.gentleTeal),
          _buildFlowArrow(),
          _buildFlowItem('Stretch 5 min', AppColors.gentleTeal),
        ],
      ),
    );
  }

  Widget _buildFlowItem(String text, Color color, {bool isAnchor = false}) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: color, size: 20),
        SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.body.copyWith(
            fontWeight: isAnchor ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isAnchor) ...[
          SizedBox(width: 4),
          Text(
            '(Anchor)',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlowArrow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 8),
          Icon(Icons.arrow_downward, color: AppColors.neutralGray, size: 16),
        ],
      ),
    );
  }
}
```

### 2. Create Stack Card Widget

#### `lib/widgets/cards/stack_card.dart`

```dart
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
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
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
                  SizedBox(width: 12),

                  // Stack Name & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stack.name,
                          style: AppTextStyles.title.copyWith(fontSize: 18),
                        ),
                        if (stack.description != null) ...[
                          SizedBox(height: 4),
                          Text(
                            stack.description!,
                            style: AppTextStyles.caption.copyWith(
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
                    icon: Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
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

              SizedBox(height: 16),

              // Habit Flow Visualization
              _buildHabitFlow(),

              SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: AppColors.secondaryText),
                  SizedBox(width: 4),
                  Text(
                    '${stack.totalHabits} habits',
                    style: AppTextStyles.caption.copyWith(
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
        style: AppTextStyles.caption.copyWith(
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
          _buildHabitChip(habits[i], isAnchor: i == 0),
          if (i < habits.length - 1)
            Icon(Icons.arrow_forward, size: 16, color: AppColors.neutralGray),
        ],
      ],
    );
  }

  Widget _buildHabitChip(dynamic habit, {bool isAnchor = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        style: AppTextStyles.caption.copyWith(
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
```

### 3. Create Habit Stacks Provider

#### `lib/providers/habit_stacks_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_stack.dart';
import '../services/habit_stack_service.dart';
import 'user_provider.dart';

// Stack Service Provider
final habitStackServiceProvider = Provider<HabitStackService>((ref) {
  return HabitStackService();
});

// All Stacks Provider
final habitStacksProvider = FutureProvider<List<HabitStack>>((ref) async {
  final stackService = ref.read(habitStackServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await stackService.getAllStacks(user.id!);
});

// Stacks Notifier
class HabitStacksNotifier extends StateNotifier<AsyncValue<List<HabitStack>>> {
  final HabitStackService _stackService;
  final int userId;

  HabitStacksNotifier(this._stackService, this.userId)
      : super(AsyncValue.loading()) {
    _loadStacks();
  }

  Future<void> _loadStacks() async {
    state = AsyncValue.loading();
    try {
      final stacks = await _stackService.getAllStacks(userId);
      state = AsyncValue.data(stacks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createStack(HabitStack stack) async {
    try {
      await _stackService.createStack(stack);
      await _loadStacks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateStack(HabitStack stack) async {
    try {
      await _stackService.updateStack(stack);
      await _loadStacks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteStack(int stackId) async {
    try {
      await _stackService.deleteStack(stackId);
      await _loadStacks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadStacks();
  }
}

// Stacks State Provider
final habitStacksNotifierProvider =
    StateNotifierProvider<HabitStacksNotifier, AsyncValue<List<HabitStack>>>(
        (ref) {
  final stackService = ref.read(habitStackServiceProvider);
  final userAsync = ref.watch(userNotifierProvider);

  return userAsync.when(
    data: (user) => HabitStacksNotifier(stackService, user?.id ?? 0),
    loading: () => HabitStacksNotifier(stackService, 0),
    error: (_, __) => HabitStacksNotifier(stackService, 0),
  );
});
```

---

## Verification Checklist

- [x] Build Stack screen displays correctly
- [x] Empty state shows proper messaging
- [x] Stack cards display habit chains
- [x] Can navigate to create stack
- [x] Info dialog explains habit stacking
- [x] Edit/delete menu works
- [x] Pull-to-refresh updates stacks
- [x] Visual flow is clear and intuitive

---

## Next Task

After completion, proceed to: [10_drag_drop.md](./10_drag_drop.md)

Note: Task 09 creates the screen structure. The actual create/edit stack functionality will be completed in Task 10 with drag-and-drop.

---

**Last Updated**: 2025-10-29
