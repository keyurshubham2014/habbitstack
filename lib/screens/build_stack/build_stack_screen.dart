import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class BuildStackScreen extends StatelessWidget {
  const BuildStackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Build Stack'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link,
              size: 80,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'Create Habit Stacks',
              style: AppTextStyles.title(),
            ),
            SizedBox(height: 8),
            Text(
              'Link new habits to existing anchors',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Will implement in Task 09
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
