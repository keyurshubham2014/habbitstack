import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/logs_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/daily_log.dart';
import '../../services/bounce_back_service.dart';
import '../../widgets/cards/log_entry_card.dart';
import '../../widgets/cards/bounce_back_card.dart';
import '../../widgets/common/notes_search.dart';
import 'add_log_sheet.dart';

class TodaysLogScreen extends ConsumerStatefulWidget {
  const TodaysLogScreen({super.key});

  @override
  ConsumerState<TodaysLogScreen> createState() => _TodaysLogScreenState();
}

class _TodaysLogScreenState extends ConsumerState<TodaysLogScreen> {
  final BounceBackService _bounceBackService = BounceBackService();

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(logsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      appBar: AppBar(
        title: Text('Today\'s Log', style: AppTextStyles.headline()),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primaryText),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NotesSearchDelegate(ref),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.primaryText),
            onPressed: () {
              // TODO: Navigate to calendar view
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(logsNotifierProvider.notifier).refresh();
        },
        child: logsAsync.when(
          data: (logs) => logs.isEmpty
              ? _buildEmptyState(context)
              : _buildLogsList(logs, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Error loading logs: $error'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'todays_log_fab',
        onPressed: () => _showAddLogSheet(context, ref),
        backgroundColor: AppColors.warmCoral,
        icon: const Icon(Icons.add),
        label: const Text('Log Activity'),
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
              Icons.psychology_outlined,
              size: 100,
              color: AppColors.neutralGray,
            ),
            const SizedBox(height: 24),
            Text(
              'No activities logged yet',
              style: AppTextStyles.title().copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the button below to record what you\'ve accomplished today. No pressure!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList(List<DailyLog> logs, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bounce Back Opportunities
            FutureBuilder<List<BounceBackOpportunity>>(
              future: _bounceBackService.getAvailableBouncebacks(user.id!),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚡ Save Your Streak',
                      style: AppTextStyles.title(),
                    ),
                    const SizedBox(height: 12),
                    ...snapshot.data!.map((opportunity) {
                      return BounceBackCard(
                        opportunity: opportunity,
                        onBounceBack: () => _executeBounceBack(opportunity),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${logs.length} ${logs.length == 1 ? 'activity' : 'activities'} logged',
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),

            // Logs List
            ...logs.map((log) => LogEntryCard(
              log: log,
              onEdit: () => _showEditLogSheet(context, ref, log),
              onDelete: () => _confirmDelete(context, ref, log),
            )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading user')),
    );
  }

  void _showAddLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddLogSheet(),
    );
  }

  void _showEditLogSheet(BuildContext context, WidgetRef ref, DailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLogSheet(existingLog: log),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DailyLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log Entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(logsNotifierProvider.notifier).deleteLog(log.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log entry deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.softRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBounceBack(BounceBackOpportunity opportunity) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to use bounce back'),
              backgroundColor: AppColors.softRed,
            ),
          );
        }
        return;
      }

      await _bounceBackService.executeBounceBack(
        userId: user.id!,
        habit: opportunity.habit,
        missedDate: opportunity.missedDate,
        notes: 'Bounced back - better late than never!',
      );

      // Refresh logs
      await ref.read(logsNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Streak saved! Way to bounce back!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    }
  }
}
