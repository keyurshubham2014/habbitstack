import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _dailyReminderEnabled = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 20, minute: 0);

  bool _bounceBackRemindersEnabled = true;
  bool _milestoneNotificationsEnabled = true;
  bool _gracePeriodWarningsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? false;
      final dailyHour = prefs.getInt('daily_reminder_hour') ?? 20;
      final dailyMinute = prefs.getInt('daily_reminder_minute') ?? 0;
      _dailyReminderTime = TimeOfDay(hour: dailyHour, minute: dailyMinute);

      _bounceBackRemindersEnabled =
          prefs.getBool('bounce_back_reminders_enabled') ?? true;
      _milestoneNotificationsEnabled =
          prefs.getBool('milestone_notifications_enabled') ?? true;
      _gracePeriodWarningsEnabled =
          prefs.getBool('grace_period_warnings_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('daily_reminder_enabled', _dailyReminderEnabled);
    await prefs.setInt('daily_reminder_hour', _dailyReminderTime.hour);
    await prefs.setInt('daily_reminder_minute', _dailyReminderTime.minute);

    await prefs.setBool(
        'bounce_back_reminders_enabled', _bounceBackRemindersEnabled);
    await prefs.setBool(
        'milestone_notifications_enabled', _milestoneNotificationsEnabled);
    await prefs.setBool(
        'grace_period_warnings_enabled', _gracePeriodWarningsEnabled);

    // Schedule or cancel daily reminder based on toggle
    final notificationService = NotificationService();
    if (_dailyReminderEnabled) {
      // Request permission if not granted
      if (!mounted) return;
      final permissionGranted = await PermissionService()
          .requestNotificationPermission(context: context);

      if (permissionGranted) {
        await notificationService.scheduleDailyReminder(
          reminderTime: _dailyReminderTime,
        );

        if (!mounted) return;
        final timeString = _dailyReminderTime.format(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily reminder scheduled for $timeString'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        // Permission denied, turn off toggle
        setState(() => _dailyReminderEnabled = false);
        await prefs.setBool('daily_reminder_enabled', false);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission required'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    } else {
      await notificationService.cancelDailyReminder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily reminder cancelled'),
          backgroundColor: AppColors.neutralGray,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.headline()),
        backgroundColor: AppColors.primaryBg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Daily Reminder Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Daily Reminder',
                    subtitle: 'Get reminded to log your habits every day',
                    value: _dailyReminderEnabled,
                    onChanged: (value) {
                      setState(() => _dailyReminderEnabled = value);
                      _saveSettings();
                    },
                  ),
                  if (_dailyReminderEnabled)
                    ListTile(
                      title: Text('Reminder Time', style: AppTextStyles.body()),
                      subtitle: Text(
                        _dailyReminderTime.format(context),
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time,
                          color: AppColors.gentleTeal),
                      onTap: _pickDailyReminderTime,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'ADDITIONAL NOTIFICATIONS',
              style: AppTextStyles.caption().copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const Divider(),

          // Bounce Back Reminders
          _buildSwitchTile(
            title: 'Bounce Back Reminders',
            subtitle: 'Alerts to save your streaks (6 hours before expiry)',
            value: _bounceBackRemindersEnabled,
            onChanged: (value) {
              setState(() => _bounceBackRemindersEnabled = value);
              _saveSettings();
            },
          ),

          const Divider(),

          // Milestone Notifications
          _buildSwitchTile(
            title: 'Milestone Celebrations',
            subtitle: 'Get celebrated for 7, 14, 30, 100 day streaks',
            value: _milestoneNotificationsEnabled,
            onChanged: (value) {
              setState(() => _milestoneNotificationsEnabled = value);
              _saveSettings();
            },
          ),

          const Divider(),

          // Grace Period Warnings
          _buildSwitchTile(
            title: 'Grace Period Warnings',
            subtitle: 'Alerts when you have 1 strike remaining',
            value: _gracePeriodWarningsEnabled,
            onChanged: (value) {
              setState(() => _gracePeriodWarningsEnabled = value);
              _saveSettings();
            },
          ),

          const SizedBox(height: 24),

          // Test Notification Button
          ElevatedButton.icon(
            onPressed: _sendTestNotification,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send Test Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 16),

          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.deepBlue),
                      const SizedBox(width: 8),
                      Text('About Notifications', style: AppTextStyles.title()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Daily Reminder: Prompts you to log habits at your chosen time\n\n'
                    '• Bounce Back Alerts: 6 hours before the 24-hour window closes\n\n'
                    '• Milestone Celebrations: When you reach 7, 14, 30, or 100 day streaks\n\n'
                    '• Grace Warnings: When you have 1 strike left before losing a streak',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.body()),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption().copyWith(
          color: AppColors.secondaryText,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.successGreen,
    );
  }

  Future<void> _pickDailyReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dailyReminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.deepBlue,
              onPrimary: Colors.white,
              surface: AppColors.primaryBg,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dailyReminderTime) {
      setState(() {
        _dailyReminderTime = picked;
      });
      await _saveSettings();
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      // Request permission first
      final permissionGranted =
          await PermissionService().requestNotificationPermission(
        context: context,
        showRationale: true,
      );

      if (!permissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission required'),
              backgroundColor: AppColors.softRed,
            ),
          );
        }
        return;
      }

      // Send test notification
      final notificationService = NotificationService();
      await notificationService.sendTestNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent! Check your notification tray.'),
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
