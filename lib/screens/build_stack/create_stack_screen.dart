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
import '../../widgets/common/anchor_suggestions.dart';

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
          style: AppTextStyles.headline(),
        ),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
      ),
      body: habitsAsync.when(
        data: (habits) => _buildContent(habits),
        loading: () => const Center(child: CircularProgressIndicator()),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stack Name
            Text('Stack Name', style: AppTextStyles.title()),
            const SizedBox(height: 8),
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

            const SizedBox(height: 16),

            // Description (Optional)
            Text('Description (optional)', style: AppTextStyles.title()),
            const SizedBox(height: 8),
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

            const SizedBox(height: 24),

            // Anchor Suggestions (only show if no anchor selected yet)
            if (_anchorHabit == null && widget.existingStack == null) ...[
              AnchorSuggestions(
                onAnchorSelected: (habit) {
                  setState(() => _anchorHabit = habit);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected "${habit.name}" as anchor'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Stack Builder Area
            Text('Build Your Stack', style: AppTextStyles.headline().copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Drag habits to build your stack. Start with an anchor habit.',
              style: AppTextStyles.body().copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),

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

            const SizedBox(height: 24),

            // Available Habits
            Text('Available Habits', style: AppTextStyles.title()),
            const SizedBox(height: 12),

            if (availableHabits.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No more habits available. Create new habits from the Today\'s Log screen.',
                  style: AppTextStyles.body().copyWith(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.existingStack == null ? 'Create Stack' : 'Save Changes',
                    style: AppTextStyles.title().copyWith(
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
        const SnackBar(content: Text('Please enter a stack name')),
      );
      return;
    }

    if (_anchorHabit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an anchor habit')),
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

      // Use transactional methods for data integrity
      if (widget.existingStack == null) {
        // Create new stack with all habits in a single transaction
        await stackService.createStackWithHabits(
          stack: stack,
          anchorHabit: _anchorHabit!,
          stackedHabits: _stackedHabits,
        );
      } else {
        // Update existing stack with transaction
        await stackService.updateStackWithHabits(
          stack: stack.copyWith(id: widget.existingStack!.id),
          anchorHabit: _anchorHabit!,
          stackedHabits: _stackedHabits,
        );
      }

      // Refresh providers after successful transaction
      await ref.read(habitStacksNotifierProvider.notifier).refresh();
      await ref.read(habitsNotifierProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingStack == null
                ? 'Stack created successfully!'
                : 'Stack updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving stack: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

