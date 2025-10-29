import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class StreaksScreen extends StatelessWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Streaks'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 80,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'Track Your Progress',
              style: AppTextStyles.title(),
            ),
            SizedBox(height: 8),
            Text(
              'View your habit streaks and achievements',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
    );
  }
}
