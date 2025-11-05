# Task 25: Partner Activity Push Notifications

**Status**: TODO
**Priority**: MEDIUM
**Estimated Time**: 3 hours
**Assigned To**: Claude
**Dependencies**: Task 21 (Auth), Task 22 (Partners), Task 23 (Activity Feed)
**Completed**: -

---

## Objective

Implement push notifications for partner activities (completions, reactions, milestones) using Firebase Cloud Messaging to keep users engaged.

## Acceptance Criteria

- [ ] Push notifications for partner habit completions
- [ ] Notifications for partner streak milestones
- [ ] Reaction notifications ("X reacted to your activity")
- [ ] New partner request notifications
- [ ] Partner accepts invite notification
- [ ] User can enable/disable partner notifications
- [ ] Works on both iOS and Android
- [ ] Notifications open relevant screen when tapped

---

## Step-by-Step Instructions

### 1. Add Firebase Cloud Messaging

#### Update `pubspec.yaml`

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
```

#### iOS Setup: `ios/Runner/Info.plist`

Already configured in Task 18, but verify:

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

#### Android Setup: `android/app/build.gradle`

```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.5.1')
    implementation 'com.google.firebase:firebase-messaging'
}
```

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<service
    android:name="com.google.firebase.messaging.FirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### 2. Create Push Notification Service

#### `lib/services/push_notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize push notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications for foreground
    await _initializeLocalNotifications();

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveFCMToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _handleLocalNotificationTap(response.payload);
      },
    );
  }

  /// Save FCM token to database
  Future<void> _saveFCMToken(String token) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    await supabase.from('users').update({
      'fcm_token': token,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    print('FCM token saved: $token');
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'partner_activity',
          'Partner Activity',
          channelDescription: 'Notifications for partner activities',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'],
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null) {
      _navigateToRoute(route);
    }
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(String? payload) {
    if (payload != null) {
      _navigateToRoute(payload);
    }
  }

  /// Navigate to specific route based on notification type
  void _navigateToRoute(String route) {
    // TODO: Implement navigation
    // Use Navigator or GoRouter to navigate to route
    print('Navigate to: $route');
  }

  /// Subscribe to partner activity topic
  Future<void> subscribeToPartnerTopic(String partnerId) async {
    await _messaging.subscribeToTopic('partner_$partnerId');
  }

  /// Unsubscribe from partner activity topic
  Future<void> unsubscribeFromPartnerTopic(String partnerId) async {
    await _messaging.unsubscribeFromTopic('partner_$partnerId');
  }
}
```

### 3. Update Supabase Schema

Add FCM token to users table:

```sql
-- Add FCM token column
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON users(fcm_token);

-- Notification preferences table
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  partner_completions BOOLEAN DEFAULT TRUE,
  partner_milestones BOOLEAN DEFAULT TRUE,
  partner_reactions BOOLEAN DEFAULT TRUE,
  new_partner_requests BOOLEAN DEFAULT TRUE,
  partner_accepted BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notification prefs"
  ON notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notification prefs"
  ON notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification prefs"
  ON notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

### 4. Create Server-Side Notification Function

Create a Supabase Edge Function to send push notifications:

#### `supabase/functions/send-notification/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')!

serve(async (req) => {
  try {
    const { userId, title, body, route, data } = await req.json()

    // Get user's FCM token
    const supabase = createClient(supabaseUrl, supabaseKey)
    const { data: user } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id', userId)
      .single()

    if (!user?.fcm_token) {
      return new Response(JSON.stringify({ error: 'No FCM token found' }), {
        status: 404,
      })
    }

    // Send FCM notification
    const fcmPayload = {
      to: user.fcm_token,
      notification: {
        title,
        body,
        sound: 'default',
      },
      data: {
        route: route || '/activity-feed',
        ...data,
      },
    }

    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${fcmServerKey}`,
      },
      body: JSON.stringify(fcmPayload),
    })

    const result = await fcmResponse.json()

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    })
  }
})
```

### 5. Create Database Triggers for Notifications

```sql
-- Function to notify partners when activity is posted
CREATE OR REPLACE FUNCTION notify_partners_of_activity()
RETURNS TRIGGER AS $$
DECLARE
  partner_record RECORD;
BEGIN
  -- Get all active partners of the user who posted activity
  FOR partner_record IN
    SELECT ap.partner_id, u.name
    FROM accountability_partners ap
    JOIN users u ON u.id = NEW.user_id
    WHERE ap.user_id = NEW.user_id AND ap.status = 'active'
  LOOP
    -- Call Edge Function to send push notification
    PERFORM
      net.http_post(
        url := current_setting('app.supabase_url') || '/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key')
        ),
        body := jsonb_build_object(
          'userId', partner_record.partner_id,
          'title', partner_record.name || ' completed a habit!',
          'body', NEW.habit_name,
          'route', '/activity-feed'
        )
      );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on activity_feed insert
CREATE TRIGGER on_activity_posted
  AFTER INSERT ON activity_feed
  FOR EACH ROW
  EXECUTE FUNCTION notify_partners_of_activity();
```

### 6. Create Notification Settings Screen

#### `lib/screens/settings/notification_preferences_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _partnerCompletions = true;
  bool _partnerMilestones = true;
  bool _partnerReactions = true;
  bool _newPartnerRequests = true;
  bool _partnerAccepted = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partner Notifications', style: AppTextStyles.headline),
        backgroundColor: AppColors.primaryBg,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Get notified when:',
            style: AppTextStyles.title,
          ),
          SizedBox(height: 16),

          _buildSwitchTile(
            title: 'Partner Completions',
            subtitle: 'When partners complete habits',
            value: _partnerCompletions,
            onChanged: (value) => setState(() => _partnerCompletions = value),
          ),

          _buildSwitchTile(
            title: 'Streak Milestones',
            subtitle: 'When partners reach streak goals',
            value: _partnerMilestones,
            onChanged: (value) => setState(() => _partnerMilestones = value),
          ),

          _buildSwitchTile(
            title: 'Reactions',
            subtitle: 'When partners react to your activities',
            value: _partnerReactions,
            onChanged: (value) => setState(() => _partnerReactions = value),
          ),

          _buildSwitchTile(
            title: 'Partner Requests',
            subtitle: 'When someone sends you a partner request',
            value: _newPartnerRequests,
            onChanged: (value) => setState(() => _newPartnerRequests = value),
          ),

          _buildSwitchTile(
            title: 'Partner Accepted',
            subtitle: 'When someone accepts your invite',
            value: _partnerAccepted,
            onChanged: (value) => setState(() => _partnerAccepted = value),
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
      title: Text(title, style: AppTextStyles.body),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.successGreen,
    );
  }
}
```

### 7. Initialize in Main

#### Update `lib/main.dart`

```dart
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize push notifications
  await PushNotificationService().initialize();

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

---

## Verification Checklist

- [ ] Firebase configured for iOS and Android
- [ ] FCM token saved to database
- [ ] Partner completion notifications send
- [ ] Streak milestone notifications send
- [ ] Reaction notifications send
- [ ] New partner request notifications send
- [ ] Settings screen toggles work
- [ ] Tapping notification opens correct screen
- [ ] Background notifications work

---

## Testing Scenarios

1. **Partner Completes**: Partner logs habit, verify notification
2. **Streak Milestone**: Partner hits 7-day streak, verify notification
3. **Reaction**: Partner reacts to your activity, verify notification
4. **Partner Request**: Someone sends invite, verify notification
5. **Settings**: Toggle notifications off, verify they stop
6. **Tap Notification**: Tap notification, verify opens activity feed
7. **Background**: App closed, receive notification, verify works

---

## Notes

- **FCM Server Key**: Get from Firebase Console → Project Settings → Cloud Messaging
- **Supabase Edge Function**: Deploy with `supabase functions deploy send-notification`
- **Testing**: Use Firebase Console to send test notifications

---

## Next Task

After completion, proceed to Phase 2 Week 9-10: AI Integration
- [26_openrouter_setup.md](./26_openrouter_setup.md)

---

**Last Updated**: 2025-11-05
