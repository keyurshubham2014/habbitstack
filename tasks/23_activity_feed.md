# Task 23: Shared Activity Feed

**Status**: TODO
**Priority**: MEDIUM
**Estimated Time**: 5 hours
**Assigned To**: Claude
**Dependencies**: Task 21 (Authentication), Task 22 (Partner Invite)
**Completed**: -

---

## Objective

Create a shared activity feed where users can see their accountability partners' habit completions and progress, fostering motivation and accountability.

## Acceptance Criteria

- [ ] Feed shows partner activities in chronological order
- [ ] Display habit completions with timestamp
- [ ] Show streak milestones (7, 14, 30 days)
- [ ] Include partner's notes (if they chose to share)
- [ ] Real-time updates (or refresh on pull)
- [ ] Filter by partner
- [ ] Empty state for no partner activity
- [ ] Privacy settings (what to share)
- [ ] Like/react to partner activities (Task 24)

---

## Step-by-Step Instructions

### 1. Create Activity Feed Model

#### `lib/models/activity_feed_item.dart`

```dart
enum ActivityType {
  habitCompleted,
  streakMilestone,
  stackCompleted,
  bounceBack,
}

class ActivityFeedItem {
  final String id;
  final String userId;
  final String userName;
  final ActivityType type;
  final String habitName;
  final String? notes;
  final int? streakDays;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.habitName,
    this.notes,
    this.streakDays,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityFeedItem.fromMap(Map<String, dynamic> map) {
    return ActivityFeedItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['activity_type'],
        orElse: () => ActivityType.habitCompleted,
      ),
      habitName: map['habit_name'] as String,
      notes: map['notes'] as String?,
      streakDays: map['streak_days'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  String get displayText {
    switch (type) {
      case ActivityType.habitCompleted:
        return 'completed $habitName';
      case ActivityType.streakMilestone:
        return 'reached $streakDays day streak on $habitName!';
      case ActivityType.stackCompleted:
        return 'completed their $habitName stack';
      case ActivityType.bounceBack:
        return 'bounced back on $habitName';
    }
  }

  IconData get icon {
    switch (type) {
      case ActivityType.habitCompleted:
        return Icons.check_circle;
      case ActivityType.streakMilestone:
        return Icons.local_fire_department;
      case ActivityType.stackCompleted:
        return Icons.layers;
      case ActivityType.bounceBack:
        return Icons.refresh;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.habitCompleted:
        return Color(0xFF4ECDC4); // Teal
      case ActivityType.streakMilestone:
        return Color(0xFFFFA726); // Amber
      case ActivityType.stackCompleted:
        return Color(0xFF5E60CE); // Blue
      case ActivityType.bounceBack:
        return Color(0xFFFF6B6B); // Coral
    }
  }
}
```

### 2. Update Supabase Schema

Add activity feed table and function:

```sql
-- Activity Feed table (stores partner activities)
CREATE TABLE IF NOT EXISTS activity_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  activity_type TEXT NOT NULL,
  habit_name TEXT NOT NULL,
  notes TEXT,
  streak_days INTEGER,
  metadata JSONB,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_public BOOLEAN DEFAULT TRUE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_activity_feed_user_id ON activity_feed(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_feed_timestamp ON activity_feed(timestamp DESC);

-- Privacy Settings table
CREATE TABLE IF NOT EXISTS privacy_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  share_completions BOOLEAN DEFAULT TRUE,
  share_notes BOOLEAN DEFAULT FALSE,
  share_streaks BOOLEAN DEFAULT TRUE,
  share_bounce_backs BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;
ALTER TABLE privacy_settings ENABLE ROW LEVEL SECURITY;

-- Activity Feed: Partners can see each other's activities
CREATE POLICY "Partners can view shared activities"
  ON activity_feed FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id IN (
      SELECT partner_id FROM accountability_partners
      WHERE user_id = auth.uid() AND status = 'active'
    )
  );

CREATE POLICY "Users can insert own activities"
  ON activity_feed FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own activities"
  ON activity_feed FOR DELETE
  USING (auth.uid() = user_id);

-- Privacy Settings: Users manage own settings
CREATE POLICY "Users can view own privacy settings"
  ON privacy_settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own privacy settings"
  ON privacy_settings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own privacy settings"
  ON privacy_settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Function to get partner feed
CREATE OR REPLACE FUNCTION get_partner_activity_feed(p_user_id UUID, p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  user_name TEXT,
  activity_type TEXT,
  habit_name TEXT,
  notes TEXT,
  streak_days INTEGER,
  metadata JSONB,
  timestamp TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    af.id,
    af.user_id,
    af.user_name,
    af.activity_type,
    af.habit_name,
    af.notes,
    af.streak_days,
    af.metadata,
    af.timestamp
  FROM activity_feed af
  WHERE af.user_id IN (
    SELECT ap.partner_id
    FROM accountability_partners ap
    WHERE ap.user_id = p_user_id AND ap.status = 'active'
  )
  AND af.is_public = TRUE
  ORDER BY af.timestamp DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3. Create Activity Feed Service

#### `lib/services/activity_feed_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_feed_item.dart';
import '../models/daily_log.dart';
import '../models/streak.dart';

class PrivacySettings {
  final bool shareCompletions;
  final bool shareNotes;
  final bool shareStreaks;
  final bool shareBouncebacks;

  PrivacySettings({
    this.shareCompletions = true,
    this.shareNotes = false,
    this.shareStreaks = true,
    this.shareBouncebacks = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'share_completions': shareCompletions,
      'share_notes': shareNotes,
      'share_streaks': shareStreaks,
      'share_bounce_backs': shareBouncebacks,
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      shareCompletions: map['share_completions'] as bool? ?? true,
      shareNotes: map['share_notes'] as bool? ?? false,
      shareStreaks: map['share_streaks'] as bool? ?? true,
      shareBouncebacks: map['share_bounce_backs'] as bool? ?? true,
    );
  }
}

class ActivityFeedService {
  final _supabase = Supabase.instance.client;

  /// Get partner activity feed
  Future<List<ActivityFeedItem>> getPartnerFeed(
    String userId, {
    int limit = 50,
  }) async {
    final response = await _supabase.rpc(
      'get_partner_activity_feed',
      params: {
        'p_user_id': userId,
        'p_limit': limit,
      },
    );

    return (response as List)
        .map((json) => ActivityFeedItem.fromMap(json))
        .toList();
  }

  /// Post habit completion to feed
  Future<void> postHabitCompletion({
    required String userId,
    required String userName,
    required String habitName,
    String? notes,
  }) async {
    // Check privacy settings
    final settings = await getPrivacySettings(userId);
    if (!settings.shareCompletions) return;

    await _supabase.from('activity_feed').insert({
      'user_id': userId,
      'user_name': userName,
      'activity_type': 'habitCompleted',
      'habit_name': habitName,
      'notes': settings.shareNotes ? notes : null,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Post streak milestone to feed
  Future<void> postStreakMilestone({
    required String userId,
    required String userName,
    required String habitName,
    required int streakDays,
  }) async {
    final settings = await getPrivacySettings(userId);
    if (!settings.shareStreaks) return;

    // Only post major milestones (7, 14, 30, 100, etc.)
    if (![7, 14, 30, 50, 100, 365].contains(streakDays)) return;

    await _supabase.from('activity_feed').insert({
      'user_id': userId,
      'user_name': userName,
      'activity_type': 'streakMilestone',
      'habit_name': habitName,
      'streak_days': streakDays,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Post bounce back to feed
  Future<void> postBounceBack({
    required String userId,
    required String userName,
    required String habitName,
  }) async {
    final settings = await getPrivacySettings(userId);
    if (!settings.shareBouncebacks) return;

    await _supabase.from('activity_feed').insert({
      'user_id': userId,
      'user_name': userName,
      'activity_type': 'bounceBack',
      'habit_name': habitName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get user's privacy settings
  Future<PrivacySettings> getPrivacySettings(String userId) async {
    final response = await _supabase
        .from('privacy_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Create default settings
      await _supabase.from('privacy_settings').insert({
        'user_id': userId,
      });
      return PrivacySettings();
    }

    return PrivacySettings.fromMap(response);
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) async {
    await _supabase
        .from('privacy_settings')
        .upsert({
          'user_id': userId,
          ...settings.toMap(),
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  /// Delete activity from feed
  Future<void> deleteActivity(String activityId) async {
    await _supabase
        .from('activity_feed')
        .delete()
        .eq('id', activityId);
  }

  /// Get my recent activities
  Future<List<ActivityFeedItem>> getMyActivities(
    String userId, {
    int limit = 20,
  }) async {
    final response = await _supabase
        .from('activity_feed')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ActivityFeedItem.fromMap(json))
        .toList();
  }
}
```

### 4. Create Activity Feed Provider

#### `lib/providers/activity_feed_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_feed_item.dart';
import '../services/activity_feed_service.dart';
import 'auth_provider.dart';

// Activity Feed Service Provider
final activityFeedServiceProvider = Provider<ActivityFeedService>((ref) {
  return ActivityFeedService();
});

// Partner Activity Feed Provider
final partnerActivityFeedProvider = FutureProvider<List<ActivityFeedItem>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return [];

  final service = ref.read(activityFeedServiceProvider);
  return await service.getPartnerFeed(authState.value!.id);
});

// My Activities Provider
final myActivitiesProvider = FutureProvider<List<ActivityFeedItem>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return [];

  final service = ref.read(activityFeedServiceProvider);
  return await service.getMyActivities(authState.value!.id);
});

// Privacy Settings Provider
final privacySettingsProvider = FutureProvider<PrivacySettings>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return PrivacySettings();

  final service = ref.read(activityFeedServiceProvider);
  return await service.getPrivacySettings(authState.value!.id);
});
```

### 5. Create Activity Feed Screen

#### `lib/screens/accountability/activity_feed_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/activity_feed_provider.dart';
import '../../models/activity_feed_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'privacy_settings_screen.dart';

class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(partnerActivityFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Partner Activity', style: AppTextStyles.headline),
        backgroundColor: AppColors.primaryBg,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.primaryText),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacySettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(partnerActivityFeedProvider);
        },
        child: feedAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return _buildActivityCard(context, activities[index]);
              },
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'No Partner Activity Yet',
              style: AppTextStyles.title,
            ),
            SizedBox(height: 8),
            Text(
              'When your accountability partners log habits, you\'ll see their activity here!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, ActivityFeedItem activity) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activity.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activity.icon,
                    color: activity.color,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),

                // User & Activity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.body,
                          children: [
                            TextSpan(
                              text: activity.userName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' ${activity.displayText}'),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatTimestamp(activity.timestamp),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Reaction Button (Task 24)
                IconButton(
                  icon: Icon(Icons.favorite_border, size: 20),
                  color: AppColors.neutralGray,
                  onPressed: () {
                    // TODO: Task 24 - Add reaction
                  },
                ),
              ],
            ),

            // Notes (if shared)
            if (activity.notes != null && activity.notes!.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activity.notes!,
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('MMM d').format(timestamp);
  }
}
```

### 6. Update Log Service to Post Activities

When a habit is logged, post to activity feed:

```dart
// In LogService.createLog()
Future<int> createLog(DailyLog log) async {
  // ... existing code ...

  // Post to activity feed
  final user = await _userService.getCurrentUser();
  final habit = await _habitService.getHabit(log.habitId);

  if (user != null && habit != null) {
    await ActivityFeedService().postHabitCompletion(
      userId: user.id,
      userName: user.name,
      habitName: habit.name,
      notes: log.notes,
    );
  }

  return id;
}
```

---

## Verification Checklist

- [ ] Feed shows partner activities chronologically
- [ ] Habit completions display correctly
- [ ] Streak milestones post to feed
- [ ] Privacy settings control what's shared
- [ ] Notes only visible if user enabled sharing
- [ ] Pull-to-refresh updates feed
- [ ] Empty state shows when no partners
- [ ] Real-time updates work
- [ ] Can delete own activities

---

## Testing Scenarios

1. **Empty Feed**: No partners, verify empty state
2. **Partner Logs**: Partner completes habit, verify appears in feed
3. **Streak Milestone**: Partner hits 7-day streak, verify milestone post
4. **Privacy Off**: Disable sharing, verify activities don't post
5. **Notes Privacy**: Toggle notes sharing on/off
6. **Multiple Partners**: 3 partners logging, verify all show in feed
7. **Refresh**: Pull-to-refresh, verify updates

---

## Next Task

After completion, proceed to: [24_reactions.md](./24_reactions.md)

---

**Last Updated**: 2025-11-05
