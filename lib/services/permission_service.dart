import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle runtime permissions
/// Best practices:
/// - Request permissions only when needed (just-in-time)
/// - Explain why permission is needed before requesting
/// - Handle denied/permanently denied states gracefully
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request notification permission
  /// iOS: Shows system dialog
  /// Android 13+: Shows system dialog
  /// Android <13: Automatically granted
  Future<bool> requestNotificationPermission({
    required BuildContext context,
    bool showRationale = true,
  }) async {
    // Check current status
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    // Show rationale dialog if requested
    if (showRationale && context.mounted) {
      final shouldRequest = await _showPermissionRationale(
        context: context,
        title: 'Enable Notifications',
        message:
            'StackHabit needs notification permission to send you daily reminders, '
            'streak celebrations, and bounce-back alerts.\n\n'
            'Stay consistent with timely reminders!',
        icon: Icons.notifications_active,
      );

      if (!shouldRequest) {
        return false;
      }
    }

    // Request permission
    final result = await Permission.notification.request();

    if (result.isPermanentlyDenied && context.mounted) {
      await _showOpenSettingsDialog(
        context: context,
        title: 'Notification Permission Required',
        message:
            'Please enable notifications in Settings to receive reminders and alerts.',
      );
      return false;
    }

    return result.isGranted;
  }

  /// Request microphone permission for voice notes
  Future<bool> requestMicrophonePermission({
    required BuildContext context,
    bool showRationale = true,
  }) async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (showRationale && context.mounted) {
      final shouldRequest = await _showPermissionRationale(
        context: context,
        title: 'Enable Microphone',
        message:
            'StackHabit needs microphone access to capture voice notes for your habits.\n\n'
            'This makes logging faster and more convenient!',
        icon: Icons.mic,
      );

      if (!shouldRequest) {
        return false;
      }
    }

    final result = await Permission.microphone.request();

    if (result.isPermanentlyDenied && context.mounted) {
      await _showOpenSettingsDialog(
        context: context,
        title: 'Microphone Permission Required',
        message:
            'Please enable microphone access in Settings to use voice notes.',
      );
      return false;
    }

    return result.isGranted;
  }

  /// Request speech recognition permission (iOS)
  Future<bool> requestSpeechPermission({
    required BuildContext context,
  }) async {
    final status = await Permission.speech.status;

    if (status.isGranted) {
      return true;
    }

    final result = await Permission.speech.request();
    return result.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> isMicrophonePermissionGranted() async {
    return await Permission.microphone.isGranted;
  }

  /// Show rationale dialog before requesting permission
  Future<bool> _showPermissionRationale({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(icon, color: const Color(0xFF4ECDC4), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show dialog to open app settings
  Future<void> _showOpenSettingsDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
