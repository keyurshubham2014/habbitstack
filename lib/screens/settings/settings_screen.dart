import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../test_providers_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person, color: AppColors.deepBlue),
            title: Text('Profile', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications, color: AppColors.deepBlue),
            title: Text('Notifications', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.timer, color: AppColors.deepBlue),
            title: Text('Grace Periods', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.workspace_premium, color: AppColors.warningAmber),
            title: Text('Upgrade to Premium', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.science, color: AppColors.gentleTeal),
            title: Text('Test Providers (Dev)', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TestProvidersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
