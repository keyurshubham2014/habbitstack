# Task 24: Quick Emoji Reactions

**Status**: TODO
**Priority**: LOW
**Estimated Time**: 2 hours
**Assigned To**: Claude
**Dependencies**: Task 23 (Activity Feed)
**Completed**: -

---

## Objective

Add quick emoji reactions to partner activities for easy encouragement and engagement without requiring full comments.

## Acceptance Criteria

- [ ] 5 reaction emojis (🔥👏💪❤️😊)
- [ ] Tap to add/remove reaction
- [ ] Show reaction count on activities
- [ ] See who reacted (tap counter)
- [ ] Real-time reaction updates
- [ ] Maximum 1 reaction per user per activity
- [ ] Reactions save to database
- [ ] Animated reaction feedback

---

## Step-by-Step Instructions

### 1. Create Reaction Model

#### `lib/models/reaction.dart`

```dart
enum ReactionType {
  fire,      // 🔥 Fire
  clap,      // 👏 Clap
  muscle,    // 💪 Muscle
  heart,     // ❤️ Heart
  smile,     // 😊 Smile
}

extension ReactionTypeExtension on ReactionType {
  String get emoji {
    switch (this) {
      case ReactionType.fire:
        return '🔥';
      case ReactionType.clap:
        return '👏';
      case ReactionType.muscle:
        return '💪';
      case ReactionType.heart:
        return '❤️';
      case ReactionType.smile:
        return '😊';
    }
  }

  String get label {
    switch (this) {
      case ReactionType.fire:
        return 'Fire';
      case ReactionType.clap:
        return 'Clap';
      case ReactionType.muscle:
        return 'Strong';
      case ReactionType.heart:
        return 'Love';
      case ReactionType.smile:
        return 'Happy';
    }
  }
}

class Reaction {
  final String? id;
  final String activityId;
  final String userId;
  final String userName;
  final ReactionType type;
  final DateTime createdAt;

  Reaction({
    this.id,
    required this.activityId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_id': activityId,
      'user_id': userId,
      'user_name': userName,
      'reaction_type': type.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Reaction.fromMap(Map<String, dynamic> map) {
    return Reaction(
      id: map['id'] as String?,
      activityId: map['activity_id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String?,
      type: ReactionType.values.firstWhere(
        (e) => e.name == map['reaction_type'],
        orElse: () => ReactionType.fire,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
```

### 2. Update Supabase Schema

```sql
-- Reactions table
CREATE TABLE IF NOT EXISTS activity_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES activity_feed(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  reaction_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(activity_id, user_id) -- One reaction per user per activity
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_reactions_activity ON activity_reactions(activity_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user ON activity_reactions(user_id);

-- RLS
ALTER TABLE activity_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view reactions on visible activities"
  ON activity_reactions FOR SELECT
  USING (
    activity_id IN (
      SELECT id FROM activity_feed
      WHERE user_id = auth.uid() OR user_id IN (
        SELECT partner_id FROM accountability_partners
        WHERE user_id = auth.uid() AND status = 'active'
      )
    )
  );

CREATE POLICY "Users can create reactions"
  ON activity_reactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reactions"
  ON activity_reactions FOR DELETE
  USING (auth.uid() = user_id);
```

### 3. Create Reaction Service

#### `lib/services/reaction_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reaction.dart';

class ReactionService {
  final _supabase = Supabase.instance.client;

  /// Toggle reaction on activity
  Future<void> toggleReaction({
    required String activityId,
    required String userId,
    required String userName,
    required ReactionType type,
  }) async {
    // Check if user already reacted
    final existing = await getUserReaction(activityId, userId);

    if (existing != null) {
      if (existing.type == type) {
        // Remove reaction (toggle off)
        await removeReaction(existing.id!);
      } else {
        // Update to new reaction type
        await _supabase
            .from('activity_reactions')
            .update({'reaction_type': type.name})
            .eq('id', existing.id!);
      }
    } else {
      // Add new reaction
      await _supabase.from('activity_reactions').insert({
        'activity_id': activityId,
        'user_id': userId,
        'user_name': userName,
        'reaction_type': type.name,
      });
    }
  }

  /// Get user's reaction on activity
  Future<Reaction?> getUserReaction(String activityId, String userId) async {
    final response = await _supabase
        .from('activity_reactions')
        .select()
        .eq('activity_id', activityId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Reaction.fromMap(response);
  }

  /// Get all reactions for an activity
  Future<List<Reaction>> getActivityReactions(String activityId) async {
    final response = await _supabase
        .from('activity_reactions')
        .select()
        .eq('activity_id', activityId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Reaction.fromMap(json))
        .toList();
  }

  /// Get reaction summary (counts by type)
  Future<Map<ReactionType, int>> getReactionSummary(String activityId) async {
    final reactions = await getActivityReactions(activityId);

    final summary = <ReactionType, int>{};
    for (final reaction in reactions) {
      summary[reaction.type] = (summary[reaction.type] ?? 0) + 1;
    }

    return summary;
  }

  /// Remove reaction
  Future<void> removeReaction(String reactionId) async {
    await _supabase
        .from('activity_reactions')
        .delete()
        .eq('id', reactionId);
  }
}
```

### 4. Create Reaction Button Widget

#### `lib/widgets/buttons/reaction_button.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reaction.dart';
import '../../services/reaction_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class ReactionButton extends ConsumerStatefulWidget {
  final String activityId;

  const ReactionButton({
    super.key,
    required this.activityId,
  });

  @override
  ConsumerState<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends ConsumerState<ReactionButton>
    with SingleTickerProviderStateMixin {
  bool _showPicker = false;
  Reaction? _userReaction;
  Map<ReactionType, int> _reactionCounts = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _loadReactions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadReactions() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final service = ReactionService();
    final userReaction = await service.getUserReaction(widget.activityId, user.id);
    final summary = await service.getReactionSummary(widget.activityId);

    setState(() {
      _userReaction = userReaction;
      _reactionCounts = summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalReactions = _reactionCounts.values.fold<int>(0, (sum, count) => sum + count);

    return Column(
      children: [
        // Reaction Picker (expanded)
        if (_showPicker) _buildReactionPicker(),

        // Main Button
        GestureDetector(
          onTap: () {
            setState(() => _showPicker = !_showPicker);
            if (_showPicker) {
              _animationController.forward();
            } else {
              _animationController.reverse();
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _userReaction != null
                  ? AppColors.warmCoral.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _userReaction != null
                    ? AppColors.warmCoral
                    : AppColors.neutralGray,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _userReaction?.type.emoji ?? '❤️',
                  style: TextStyle(fontSize: 16),
                ),
                if (totalReactions > 0) ...[
                  SizedBox(width: 4),
                  Text(
                    '$totalReactions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _userReaction != null
                          ? AppColors.warmCoral
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReactionPicker() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.value,
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ReactionType.values.map((type) {
                  final count = _reactionCounts[type] ?? 0;
                  final isSelected = _userReaction?.type == type;

                  return GestureDetector(
                    onTap: () => _handleReaction(type),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.warmCoral.withOpacity(0.1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(type.emoji, style: TextStyle(fontSize: 20)),
                          if (count > 0)
                            Text(
                              '$count',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleReaction(ReactionType type) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final service = ReactionService();

    try {
      await service.toggleReaction(
        activityId: widget.activityId,
        userId: user.id,
        userName: user.name,
        type: type,
      );

      // Reload reactions
      await _loadReactions();

      setState(() => _showPicker = false);
      _animationController.reverse();

      // Show animation feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.emoji} ${type.label}!'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

### 5. Update Activity Feed Card

Replace the reaction button in `activity_feed_screen.dart`:

```dart
// Replace this:
IconButton(
  icon: Icon(Icons.favorite_border, size: 20),
  color: AppColors.neutralGray,
  onPressed: () {
    // TODO: Task 24 - Add reaction
  },
),

// With this:
ReactionButton(activityId: activity.id),
```

---

## Verification Checklist

- [ ] 5 emoji reactions available (🔥👏💪❤️😊)
- [ ] Tap to open reaction picker
- [ ] Tap emoji to add/remove reaction
- [ ] Reaction counts display correctly
- [ ] User can only have 1 reaction per activity
- [ ] Changing reaction updates correctly
- [ ] Animated picker shows/hides smoothly
- [ ] Real-time updates when partners react

---

## Testing Scenarios

1. **Add Reaction**: Tap heart, select 🔥, verify added
2. **Change Reaction**: Select 👏, verify changes from 🔥
3. **Remove Reaction**: Tap same emoji twice, verify removed
4. **Multiple Users**: 2 users react to same activity, verify counts
5. **Animation**: Open/close picker, verify smooth animation
6. **Partner Reacts**: Partner adds reaction, verify you see it

---

## Next Task

After completion, proceed to: [25_push_notifications.md](./25_push_notifications.md)

---

**Last Updated**: 2025-11-05
