import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/anchor_detection_service.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/habit.dart';
import '../../constants/habit_icons.dart';

class AnchorSuggestions extends ConsumerWidget {
  final Function(Habit) onAnchorSelected;

  const AnchorSuggestions({
    super.key,
    required this.onAnchorSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return _buildSuggestions(context, user.id!);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSuggestions(BuildContext context, int userId) {
    return FutureBuilder<List<AnchorCandidate>>(
      future: AnchorDetectionService().detectAnchorCandidates(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoSuggestions();
        }

        final candidates = snapshot.data!;
        return _buildCandidatesList(context, candidates);
      },
    );
  }

  Widget _buildNoSuggestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.lightbulb_outline, size: 48, color: AppColors.neutralGray),
          const SizedBox(height: 12),
          Text(
            'No anchor suggestions yet',
            style: AppTextStyles.title().copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Log habits consistently for 2 weeks to get personalized anchor suggestions.',
            style: AppTextStyles.body().copyWith(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesList(BuildContext context, List<AnchorCandidate> candidates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.deepBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              'Suggested Anchor Habits',
              style: AppTextStyles.title().copyWith(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Based on your logging patterns, these habits are great anchors:',
          style: AppTextStyles.caption().copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 12),
        ...candidates.take(3).map((candidate) => _buildCandidateCard(context, candidate)),
      ],
    );
  }

  Widget _buildCandidateCard(BuildContext context, AnchorCandidate candidate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: candidate.isExcellent
              ? AppColors.successGreen
              : candidate.isGood
                  ? AppColors.deepBlue
                  : AppColors.neutralGray,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => onAnchorSelected(candidate.habit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Consistency Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getConsistencyColor(candidate).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      candidate.consistencyPercentage,
                      style: AppTextStyles.title().copyWith(
                        fontSize: 16,
                        color: _getConsistencyColor(candidate),
                      ),
                    ),
                    Text(
                      'consistent',
                      style: AppTextStyles.caption().copyWith(
                        fontSize: 10,
                        color: _getConsistencyColor(candidate),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Habit Icon
              if (candidate.habit.icon != null)
                Icon(
                  HabitIcons.getIconByName(candidate.habit.icon!),
                  size: 24,
                  color: _getConsistencyColor(candidate),
                ),
              if (candidate.habit.icon != null) const SizedBox(width: 8),

              // Habit Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.habit.name,
                      style: AppTextStyles.body().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 14, color: AppColors.warningAmber),
                        const SizedBox(width: 4),
                        Text(
                          '${candidate.currentStreak} day streak',
                          style: AppTextStyles.caption().copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Excellence Badge
              if (candidate.isExcellent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Excellent',
                    style: AppTextStyles.caption().copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConsistencyColor(AnchorCandidate candidate) {
    if (candidate.isExcellent) return AppColors.successGreen;
    if (candidate.isGood) return AppColors.deepBlue;
    return AppColors.warningAmber;
  }
}
