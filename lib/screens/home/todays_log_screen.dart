import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class TodaysLogScreen extends StatelessWidget {
  const TodaysLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Log'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 80,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'Log Your Activities',
              style: AppTextStyles.title(),
            ),
            SizedBox(height: 8),
            Text(
              'Track what you accomplish each day',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Will implement in Task 06
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
