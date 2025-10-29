import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class AccountabilityScreen extends StatelessWidget {
  const AccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accountability'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 80,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'Stay Accountable',
              style: AppTextStyles.title(),
            ),
            SizedBox(height: 8),
            Text(
              'Connect with accountability partners',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
    );
  }
}
