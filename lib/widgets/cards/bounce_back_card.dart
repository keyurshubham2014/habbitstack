import 'package:flutter/material.dart';
import '../../services/bounce_back_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class BounceBackCard extends StatelessWidget {
  final BounceBackOpportunity opportunity;
  final VoidCallback onBounceBack;

  const BounceBackCard({
    super.key,
    required this.opportunity,
    required this.onBounceBack,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.warningAmber, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.warningAmber.withOpacity(0.1),
              AppColors.primaryBg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.warningAmber, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bounce Back Available!',
                      style: AppTextStyles.title().copyWith(
                        fontSize: 16,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ),
                  const Icon(Icons.bolt, color: AppColors.warningAmber),
                ],
              ),

              const SizedBox(height: 12),

              // Habit Name
              Text(
                opportunity.habit.name,
                style: AppTextStyles.title().copyWith(fontSize: 18),
              ),

              const SizedBox(height: 8),

              // Time Remaining
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 16, color: AppColors.warningAmber),
                    const SizedBox(width: 6),
                    Text(
                      opportunity.formattedTimeRemaining,
                      style: AppTextStyles.body().copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'You missed this habit yesterday, but you still have time to save your streak!',
                style: AppTextStyles.body().copyWith(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),

              const SizedBox(height: 16),

              // Bounce Back Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onBounceBack,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Bounce Back Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warningAmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
