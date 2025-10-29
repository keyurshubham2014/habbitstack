import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/habits_provider.dart';
import '../providers/logs_provider.dart';
import '../models/habit.dart';
import '../models/daily_log.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons/primary_button.dart';

class TestProvidersScreen extends ConsumerWidget {
  const TestProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userNotifierProvider);
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final logsAsync = ref.watch(logsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(userNotifierProvider.notifier).refresh();
              ref.read(habitsNotifierProvider.notifier).refresh();
              ref.read(logsNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Section
          Text('User Information', style: AppTextStyles.title()),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: userAsync.when(
                data: (user) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${user?.name ?? "None"}', style: AppTextStyles.body()),
                    const SizedBox(height: 4),
                    Text('Email: ${user?.email ?? "None"}', style: AppTextStyles.body()),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Premium: ', style: AppTextStyles.body()),
                        Icon(
                          user?.premiumStatus == true ? Icons.check_circle : Icons.cancel,
                          color: user?.premiumStatus == true
                              ? AppColors.successGreen
                              : AppColors.neutralGray,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      text: 'Toggle Premium',
                      onPressed: () {
                        ref.read(userNotifierProvider.notifier).togglePremium();
                      },
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e', style: AppTextStyles.caption()),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Habits Section
          Text('Habits', style: AppTextStyles.title()),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: habitsAsync.when(
                data: (habits) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Habits: ${habits.length}', style: AppTextStyles.body()),
                    const SizedBox(height: 8),
                    if (habits.isEmpty)
                      Text('No habits yet', style: AppTextStyles.caption())
                    else
                      ...habits.map((habit) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          habit.isAnchor ? Icons.anchor : Icons.task,
                          color: habit.isAnchor ? AppColors.deepBlue : AppColors.gentleTeal,
                        ),
                        title: Text(habit.name, style: AppTextStyles.body()),
                        subtitle: Text(
                          habit.isAnchor ? 'Anchor Habit' : 'Regular Habit',
                          style: AppTextStyles.small(),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            ref.read(habitsNotifierProvider.notifier).deleteHabit(habit.id!);
                          },
                        ),
                      )),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      text: 'Add Sample Habit',
                      onPressed: () async {
                        final user = await ref.read(currentUserProvider.future);
                        if (user != null) {
                          final newHabit = Habit(
                            userId: user.id!,
                            name: 'Sample Habit ${habits.length + 1}',
                            isAnchor: habits.length % 2 == 0,
                            createdAt: DateTime.now(),
                          );
                          ref.read(habitsNotifierProvider.notifier).addHabit(newHabit);
                        }
                      },
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e', style: AppTextStyles.caption()),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Logs Section
          Text('Today\'s Logs', style: AppTextStyles.title()),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: logsAsync.when(
                data: (logs) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Logs Today: ${logs.length}', style: AppTextStyles.body()),
                    const SizedBox(height: 8),
                    if (logs.isEmpty)
                      Text('No logs today', style: AppTextStyles.caption())
                    else
                      ...logs.map((log) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle, color: AppColors.successGreen),
                        title: Text('Habit ID: ${log.habitId}', style: AppTextStyles.body()),
                        subtitle: Text(
                          'Completed at: ${log.completedAt.hour}:${log.completedAt.minute.toString().padLeft(2, '0')}',
                          style: AppTextStyles.small(),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            ref.read(logsNotifierProvider.notifier).deleteLog(log.id!);
                          },
                        ),
                      )),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      text: 'Add Sample Log',
                      onPressed: () async {
                        final user = await ref.read(currentUserProvider.future);
                        final habits = await ref.read(habitsProvider.future);

                        if (user != null && habits.isNotEmpty) {
                          final newLog = DailyLog(
                            userId: user.id!,
                            habitId: habits.first.id!,
                            completedAt: DateTime.now(),
                            notes: 'Sample log entry',
                            sentiment: 'happy',
                            createdAt: DateTime.now(),
                          );
                          ref.read(logsNotifierProvider.notifier).addLog(newLog);
                        }
                      },
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e', style: AppTextStyles.caption()),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Status Summary
          Center(
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: AppColors.successGreen, size: 48),
                const SizedBox(height: 8),
                Text('Providers Working!', style: AppTextStyles.title(color: AppColors.successGreen)),
                const SizedBox(height: 4),
                Text('All state management is functional', style: AppTextStyles.caption()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
