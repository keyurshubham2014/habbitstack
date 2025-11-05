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
        title: Text('Build Stacks', style: AppTextStyles.headline()),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.primaryText),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Error loading stacks: $error'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateStack(context),
        backgroundColor: AppColors.deepBlue,
        icon: const Icon(Icons.add),
        label: const Text('Create Stack'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.layers_outlined,
              size: 100,
              color: AppColors.neutralGray,
            ),
            const SizedBox(height: 24),
            Text(
              'No stacks yet',
              style: AppTextStyles.title().copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Build your first habit stack by linking new habits to your existing strong habits (anchors).',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateStack(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Stack'),
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
      padding: const EdgeInsets.all(16),
      itemCount: stacks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${stacks.length} ${stacks.length == 1 ? 'stack' : 'stacks'}',
              style: AppTextStyles.caption().copyWith(
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
        builder: (context) => const CreateStackScreen(),
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
        title: const Text('Delete Stack?'),
        content: const Text(
          'This will remove the stack but keep all habits. You can recreate the stack anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(habitStacksNotifierProvider.notifier).deleteStack(stack.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stack deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.softRed)),
          ),
        ],
      ),
    );
  }

  void _showStackingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What is Habit Stacking?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Habit stacking is a science-backed technique where you link new habits to existing strong habits (anchors).',
                style: AppTextStyles.body(),
              ),
              const SizedBox(height: 12),
              Text(
                'Example:',
                style: AppTextStyles.title().copyWith(fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildInfoFlow(),
              const SizedBox(height: 12),
              Text(
                'By linking habits to something you already do consistently, you\'re much more likely to stick with them!',
                style: AppTextStyles.body().copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFlow() {
    return Container(
      padding: const EdgeInsets.all(12),
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
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.body().copyWith(
            fontWeight: isAnchor ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isAnchor) ...[
          const SizedBox(width: 4),
          Text(
            '(Anchor)',
            style: AppTextStyles.caption().copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlowArrow() {
    return const Padding(
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
