import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../test_providers_screen.dart';
import 'notification_settings_screen.dart';
import 'profile_screen.dart';

// Provider for app version info
final appVersionProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

// Provider for auth service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile
          ListTile(
            leading: Icon(Icons.person, color: AppColors.deepBlue),
            title: Text('Profile', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          Divider(),

          // Notifications
          ListTile(
            leading: Icon(Icons.notifications, color: AppColors.deepBlue),
            title: Text('Notifications', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
              );
            },
          ),
          Divider(),

          // Grace Periods
          ListTile(
            leading: Icon(Icons.timer, color: AppColors.deepBlue),
            title: Text('Grace Periods', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),

          // Upgrade to Premium
          ListTile(
            leading: Icon(Icons.workspace_premium, color: AppColors.warningAmber),
            title: Text('Upgrade to Premium', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),

          // Test Providers (Dev) - Only visible in debug mode
          if (kDebugMode) ...[
            ListTile(
              leading: Icon(Icons.science, color: AppColors.gentleTeal),
              title: Text('Test Providers (Dev)', style: AppTextStyles.body()),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestProvidersScreen()),
                );
              },
            ),
            Divider(),
          ],

          // Account Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'ACCOUNT',
              style: AppTextStyles.caption().copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Logout
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.neutralGray),
            title: Text('Logout', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showLogoutDialog(context, ref),
          ),
          Divider(),

          // Delete Account
          ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.softRed),
            title: Text(
              'Delete Account',
              style: AppTextStyles.body().copyWith(color: AppColors.softRed),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.softRed),
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
          Divider(),

          // Version Info
          versionAsync.when(
            data: (packageInfo) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'StackHabit',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.secondaryText,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            loading: () => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Loading version...',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Version 1.0.0',
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: AppTextStyles.title()),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.body()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performLogout(context, ref);
            },
            child: Text(
              'Logout',
              style: AppTextStyles.body().copyWith(
                color: AppColors.warmCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Logging out...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Call auth service logout
      final authService = ref.read(authServiceProvider);
      await authService.logout();

      // Clear user state
      await ref.read(userNotifierProvider.notifier).clearUser();

      // Dismiss loading snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to main/login screen
        // Note: Adjust this navigation based on your app's auth flow
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Dismiss loading snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: AppColors.softRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.softRed),
            SizedBox(width: 8),
            Text('Delete Account', style: AppTextStyles.title()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete your account and all associated data:',
              style: AppTextStyles.body(),
            ),
            SizedBox(height: 12),
            Text(
              '• All habits and stacks\n• All daily logs and notes\n• Streak history\n• Profile information',
              style: AppTextStyles.body().copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.softRed.withOpacity(0.3)),
              ),
              child: Text(
                '⚠️ This action cannot be undone!',
                style: AppTextStyles.body().copyWith(
                  color: AppColors.softRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Type DELETE to confirm:',
              style: AppTextStyles.body().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: AppTextStyles.body(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              confirmController.dispose();
              Navigator.pop(context);
            },
            child: Text('Cancel', style: AppTextStyles.body()),
          ),
          TextButton(
            onPressed: () {
              if (confirmController.text.trim().toUpperCase() == 'DELETE') {
                confirmController.dispose();
                Navigator.pop(context); // Close dialog
                _performDeleteAccount(context, ref);
              } else {
                // Show error if confirmation doesn't match
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please type DELETE to confirm'),
                    backgroundColor: AppColors.softRed,
                  ),
                );
              }
            },
            child: Text(
              'Delete Forever',
              style: AppTextStyles.body().copyWith(
                color: AppColors.softRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Deleting account...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Call auth service delete account
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount();

      // Clear all app state
      await ref.read(userNotifierProvider.notifier).clearUser();

      // Dismiss loading snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to main/login screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Dismiss loading snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: AppColors.softRed,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
