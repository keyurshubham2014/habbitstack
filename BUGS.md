# Bug Tracking for StackHabit MVP

**Last Updated**: 2025-11-06
**Phase**: Pre-Launch Testing
**Version**: 1.0.0-mvp

---

## Priority Levels

- **P0 (Critical)**: App crashes, data loss, blocking issues - Fix immediately
- **P1 (High)**: Major functionality broken, poor UX - Fix before launch
- **P2 (Medium)**: Minor bugs, cosmetic issues - Fix if time permits
- **P3 (Low)**: Nice-to-have improvements - Defer to Phase 2

---

## Active Bugs

| ID | Priority | Screen | Description | Reported By | Status | Assigned To |
|----|----------|--------|-------------|-------------|--------|-------------|
| - | - | - | No active bugs | - | - | - |

---

## Fixed Bugs

| ID | Priority | Screen | Description | Fixed In | Notes |
|----|----------|--------|-------------|----------|-------|
| BUG-001 | P0 | Settings | Test notification fails with error: "Null check operator used" | 2025-11-05 | Added `sendTestNotification()` method that doesn't require habit ID |
| BUG-002 | P0 | Settings | Daily reminder not triggering at scheduled time | 2025-11-05 | Implemented Daily Reminder toggle with time picker and `scheduleDailyReminder()` method |
| BUG-003 | P0 | Notifications | Daily reminder still not firing (permission + scheduling issues) | 2025-11-05 | Added permission_handler, proper permission flow, and debug logging |
| BUG-004 | P1 | App Launch | No permission request dialog - permissions not requested properly | 2025-11-05 | Implemented PermissionService with just-in-time permission requests |
| BUG-005 | P2 | Settings | "Habit Reminders" vs "Daily Reminder" confusing UX | 2025-11-05 | Removed "Habit Reminders" section, kept only unified "Daily Reminder" |
| BUG-006 | P1 | Today's Log | Calendar button in app bar does nothing - navigation not implemented | 2025-11-06 | Created CalendarViewScreen with 90-day heatmap, stats, and day details |
| BUG-007 | P2 | Settings | Profile menu item does nothing - screen not created/implemented | 2025-11-06 | Created ProfileScreen with user stats, edit functionality, and activity summary |

### Fix Details

#### BUG-001: Test Notification Fixed ✅
**Fixed**: 2025-11-05

**Root Cause**:
The test notification method was calling `sendStreakMilestone()` which requires a `Habit` object with a valid `id`. Creating a test habit without saving to database resulted in `null` id, causing the null check error.

**Solution**:
- Created new `sendTestNotification()` method in [notification_service.dart](lib/services/notification_service.dart#L217-L241)
- Uses fixed notification ID (99999) instead of habit-based ID
- Sends simple test notification without requiring habit object
- Updated [notification_settings_screen.dart](lib/screens/settings/notification_settings_screen.dart#L244-L272) to call new method

**Files Changed**:
- `lib/services/notification_service.dart`
- `lib/screens/settings/notification_settings_screen.dart`

---

#### BUG-002: Daily Reminder Implemented ✅
**Fixed**: 2025-11-05

**Root Cause**:
The Daily Reminder feature wasn't actually implemented. The notification settings screen only had habit-specific reminders, but no global daily reminder toggle or scheduling logic.

**Solution**:
- Added `scheduleDailyReminder()` method in [notification_service.dart](lib/services/notification_service.dart#L243-L274)
- Added `cancelDailyReminder()` method in [notification_service.dart](lib/services/notification_service.dart#L276-L279)
- Implemented Daily Reminder UI with toggle and time picker in [notification_settings_screen.dart](lib/screens/settings/notification_settings_screen.dart#L106-L138)
- Added state management for daily reminder settings (enabled/disabled, time)
- Notification schedules daily at chosen time using `matchDateTimeComponents.time`
- Persists settings to SharedPreferences
- Auto-schedules/cancels notification when toggle changes

**Files Changed**:
- `lib/services/notification_service.dart`
- `lib/screens/settings/notification_settings_screen.dart`

**How to Use**:
1. Open Settings → Notifications
2. Enable "Daily Reminder" toggle in the highlighted card at top
3. Tap "Reminder Time" to choose your preferred time (default: 8:00 PM)
4. Notification will fire daily with message: "📝 Time to Log Your Day"

---

#### BUG-006: Calendar View Implemented ✅
**Fixed**: 2025-11-06
**Priority**: P1 (High)

**Issue**:
The calendar icon button in the app bar of Today's Log screen did nothing when tapped. Expected behavior was to show a calendar heatmap view of activity history.

**Root Cause**:
- Navigation logic not implemented
- CalendarHeatmap widget existed but wasn't connected to the button
- No screen/dialog created to display the calendar view

**Solution**:
Created comprehensive calendar view with the following features:

1. **New Screen**: [calendar_view_screen.dart](lib/screens/home/calendar_view_screen.dart)
   - Full-screen calendar view with 90-day activity heatmap
   - Summary statistics card showing:
     - Total logs in 90 days
     - Active days count
     - Average logs per day
   - Activity intensity breakdown
   - Interactive calendar - tap any day to see details

2. **Navigation**: Updated [todays_log_screen.dart:45-55](lib/screens/home/todays_log_screen.dart#L45-L55)
   - Calendar button now navigates to CalendarViewScreen
   - Clean modal presentation

3. **Day Details Modal**:
   - Shows all activities logged on selected day
   - Fetches habit names dynamically from database
   - Displays notes for each activity
   - Graceful handling for days with no logs

**Features**:
- 90-day scrollable heatmap with color intensity
- Visual legend (Less → More)
- Today's date highlighted with border
- Stats: Total logs, Active days, Average per day
- Activity intensity breakdown (Low/Medium/High)
- Tap any day to see details in bottom sheet

**Files Created**:
- `lib/screens/home/calendar_view_screen.dart`

**Files Changed**:
- `lib/screens/home/todays_log_screen.dart`

---

#### BUG-007: Profile Screen Implemented ✅
**Fixed**: 2025-11-06
**Priority**: P2 (Medium)

**Issue**:
The "Profile" menu item in Settings screen did nothing when tapped. Profile screen/functionality had not been created.

**Root Cause**:
- Profile screen not created
- No navigation logic implemented
- Profile features undefined for MVP

**Solution**:
Created comprehensive profile screen with the following features:

1. **New Screen**: [profile_screen.dart](lib/screens/settings/profile_screen.dart)
   - Complete user profile management
   - Real-time statistics from database
   - Edit functionality with form validation
   - Beautiful UI with card-based layout

2. **Profile Header**:
   - Avatar with user's initial
   - Name and email display
   - Premium badge (if applicable)
   - Edit button in app bar

3. **Activity Statistics Card**:
   - Total activities logged
   - Habits tracked count
   - Longest streak (dynamically calculated)
   - All stats load from providers with loading states

4. **Account Information Card**:
   - Member since date (human-readable format)
   - Account type (Free/Premium)
   - Clean, organized layout

5. **Edit Profile Form**:
   - Toggle edit mode with app bar button
   - Form validation (required name, optional email)
   - Email format validation
   - Save/Cancel actions
   - Success/error feedback

6. **Navigation**: Updated [settings_screen.dart:19-29](lib/screens/settings/settings_screen.dart#L19-L29)
   - Profile menu item now navigates to ProfileScreen

**Features Implemented**:
✅ User avatar with initial
✅ Display name and email
✅ Member since date (human-readable)
✅ Total habits tracked
✅ Total activities logged
✅ Longest streak achieved
✅ Edit profile functionality
✅ Form validation
✅ Premium status badge
✅ Error handling

**Files Created**:
- `lib/screens/settings/profile_screen.dart`

**Files Changed**:
- `lib/screens/settings/settings_screen.dart`

**Future Enhancements** (Phase 2):
- Photo upload for avatar
- Sign out functionality
- Account deletion
- Export data option

---

## Known Limitations (Not Bugs)

These are intentional limitations for the MVP that will be addressed in Phase 2:

1. **No Cloud Sync**: Data is local-only (SQLite)
2. **No Multi-User**: Single user per device
3. **No Rich Text**: Notes are plain text only
4. **No Photo Attachments**: Text and voice notes only
5. **No Export**: Cannot export data (coming in Phase 2)
6. **Limited Analytics**: Basic sentiment chart only (AI insights in Phase 2)

---

## Testing Status

### Platform Coverage
- [ ] iOS Testing (iPhone 11+, iOS 15+)
- [ ] Android Testing (Pixel 4+, Android 10+)
- [ ] Tablet Testing (iPad, Android Tablet)

### Feature Testing
- [ ] Today's Log Screen
- [ ] Build Stack Screen
- [ ] Streaks Screen
- [ ] Notifications
- [ ] Settings
- [ ] Data Persistence
- [ ] Voice Input
- [ ] Search & Tags
- [ ] Sentiment Analytics

---

## How to Report a Bug

If you're a beta tester, please include:

1. **Device**: iPhone 14, iOS 17.2
2. **Steps to Reproduce**:
   - Step 1: Open app
   - Step 2: Tap "Log Activity"
   - Step 3: ...
3. **Expected Behavior**: Should save the log
4. **Actual Behavior**: App crashes
5. **Screenshots/Video**: [Attach if possible]
6. **Frequency**: Always / Sometimes / Once

Send to: [Your email or feedback form URL]

---

## Bug Triage Process

1. **Report Received** → Assign ID
2. **Prioritize** → P0/P1/P2/P3
3. **Assign** → Developer
4. **Fix** → Create branch, test fix
5. **Verify** → QA testing
6. **Close** → Move to Fixed Bugs section

---

## Performance Benchmarks

Target metrics (tested on iPhone 11 / Pixel 4):

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| App launch time | < 3 seconds | TBD | ⏳ |
| Screen transition | < 300ms | TBD | ⏳ |
| List scroll (100 items) | 60 FPS | TBD | ⏳ |
| Database query | < 100ms | TBD | ⏳ |
| Memory usage | < 150MB | TBD | ⏳ |

---

## Next Steps

1. ✅ Create bug tracking template
2. ⏳ Recruit beta testers
3. ⏳ Distribute testing script
4. ⏳ Collect and triage bugs
5. ⏳ Fix P0 and P1 bugs
6. ⏳ Final QA pass
7. ⏳ Ready for launch

---

**Note**: This file will be updated throughout the testing phase. All P0 and P1 bugs must be resolved before launch.
