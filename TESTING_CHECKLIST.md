# StackHabit MVP Testing Checklist

**Version**: 1.0.0-mvp
**Last Updated**: 2025-11-05
**Testing Phase**: Pre-Launch QA

---

## 1. Onboarding & Setup

- [ ] App launches without crashes (cold start)
- [ ] App launches without crashes (warm start)
- [ ] Database initializes correctly on first launch
- [ ] All 5 navigation tabs visible (Today's Log, Build Stack, Streaks, Accountability, Settings)
- [ ] No errors in console on first launch
- [ ] Default user created automatically
- [ ] App icon displays correctly
- [ ] Splash screen shows (if implemented)
- [ ] First-time experience is clear

---

## 2. Today's Log Screen

### Empty State
- [ ] Empty state displays with helpful message
- [ ] "Log Activity" button visible and prominent
- [ ] No errors when screen is empty

### Add New Log
- [ ] Tap "Log Activity" opens bottom sheet
- [ ] Can select existing habit from dropdown
- [ ] Can create new habit on-the-fly
- [ ] Icon picker opens when creating new habit
- [ ] Icon picker displays 100+ icons
- [ ] Selected icon persists after creation
- [ ] Time picker opens and works correctly
- [ ] Time picker defaults to current time
- [ ] Can select sentiment (Happy/Neutral/Struggled)
- [ ] Sentiment buttons highlight when selected
- [ ] Notes field accepts text input
- [ ] Character counter shows correctly (0/500)
- [ ] Character counter turns amber at 450+ characters
- [ ] Character limit enforced at 500
- [ ] Hashtags are detected in notes (#morning, #workout)
- [ ] Tag suggestion chips appear if user has recent tags
- [ ] Tapping tag chip inserts tag into notes
- [ ] Voice input button opens dialog (if available)
- [ ] Save button works and creates log
- [ ] Success message appears after saving
- [ ] Bottom sheet closes after saving
- [ ] New log appears in list immediately

### Edit Existing Log
- [ ] Tap log card opens edit sheet
- [ ] All fields pre-populated with existing data
- [ ] Can modify habit, time, sentiment, notes
- [ ] Save button updates log correctly
- [ ] Changes reflect immediately in list

### Delete Log
- [ ] Swipe or long-press shows delete option
- [ ] Confirmation dialog appears
- [ ] "Cancel" dismisses dialog without deleting
- [ ] "Delete" removes log from database
- [ ] Success message appears
- [ ] Log disappears from list immediately

### Search & Tags
- [ ] Search icon visible in app bar
- [ ] Tapping search opens search interface
- [ ] Empty search shows recent tags
- [ ] Can search by note text
- [ ] Can search by hashtag (#morning)
- [ ] Search results display correctly
- [ ] Tapping result allows editing
- [ ] Recent tags chips are tappable

### Pull-to-Refresh
- [ ] Pull down gesture triggers refresh
- [ ] Loading indicator shows while refreshing
- [ ] List updates after refresh
- [ ] No duplicate entries after refresh

### Bounce Back Cards
- [ ] Bounce back opportunities show when available
- [ ] Card displays habit name and deadline
- [ ] Tapping "Bounce Back" creates backdated log
- [ ] Streak is saved after bounce back
- [ ] Success message appears
- [ ] Card disappears after use

---

## 3. Build Stack Screen

### Empty State
- [ ] Empty state displays with helpful message
- [ ] "Create Stack" button visible

### Create New Stack
- [ ] Tap "Create Stack" opens creation flow
- [ ] Can enter stack name
- [ ] Can enter stack description (optional)
- [ ] Anchor habit suggestions appear if data exists
- [ ] Can manually select anchor habit
- [ ] Anchor habit is visually distinct (blue indicator)
- [ ] Can add habits to stack
- [ ] Habits display with icons
- [ ] Stack saves to database
- [ ] Success message appears
- [ ] New stack appears in list

### Drag-and-Drop Reordering
- [ ] Long press on habit enables drag mode
- [ ] Habit lifts up visually when dragging
- [ ] Can drag habit up/down in stack
- [ ] Placeholder shows drop location
- [ ] Dropping habit updates order
- [ ] Anchor habit cannot be moved (always first)
- [ ] Order persists after saving

### View Existing Stacks
- [ ] All stacks display in list
- [ ] Stack name and description visible
- [ ] Habit count shows (e.g., "5 habits")
- [ ] Tapping stack opens detail view
- [ ] Visual flow shows anchor → habit 1 → habit 2

### Edit Stack
- [ ] Can edit stack name/description
- [ ] Can add more habits to stack
- [ ] Can remove habits from stack
- [ ] Can reorder habits
- [ ] Changes save correctly

### Delete Stack
- [ ] Delete option available (swipe or menu)
- [ ] Confirmation dialog appears
- [ ] "Cancel" dismisses without deleting
- [ ] "Delete" removes stack from database
- [ ] Stack disappears from list
- [ ] Deleting stack does NOT delete habits

---

## 4. Streaks Screen

### Streak Display
- [ ] All habits with logs show streaks
- [ ] Current streak number is accurate
- [ ] Longest streak number is accurate
- [ ] Last logged date is correct
- [ ] Streak status colors correct:
  - Green = Perfect streak
  - Yellow = Grace period active
  - Red = Broken streak

### Grace Period Indicator
- [ ] Grace period shows when user misses a day
- [ ] Remaining strikes visible (e.g., "1/2 strikes used")
- [ ] Grace period expires after configured days
- [ ] Streak breaks after all strikes used

### Calendar Heatmap
- [ ] 90-day heatmap displays
- [ ] Today's date highlighted
- [ ] Logged days show in green
- [ ] Missed days show in gray/red
- [ ] Grace period days show in yellow
- [ ] Can scroll through months
- [ ] Tapping day shows details (if implemented)

### Motivational Messages
- [ ] Messages appear for milestones (7, 14, 30, 60, 90 days)
- [ ] Messages are encouraging and specific
- [ ] No messages for broken streaks

### Pull-to-Refresh
- [ ] Pull down recalculates all streaks
- [ ] Loading indicator shows
- [ ] Streak data updates correctly

### Empty State
- [ ] If no logs yet, shows helpful message
- [ ] Encourages user to log first activity

---

## 5. Notifications

### Permission Request
- [ ] Permission requested at appropriate time (not on first launch)
- [ ] Permission dialog is clear about why it's needed
- [ ] App functions correctly if permission denied
- [ ] Can grant permission later in Settings

### Daily Reminders
- [ ] Can schedule daily reminder
- [ ] Time picker works for selecting reminder time
- [ ] Notification fires at scheduled time
- [ ] Notification message is clear and actionable
- [ ] Tapping notification opens app to Today's Log

### Bounce Back Reminders
- [ ] Bounce back notification fires when available
- [ ] Notification explains 24-hour window
- [ ] Tapping opens app with bounce back card visible

### Milestone Celebrations
- [ ] Notification fires for streak milestones (7, 14, 30 days)
- [ ] Message is congratulatory and specific
- [ ] Tapping opens Streaks screen

### Settings Integration
- [ ] Notification toggles in Settings screen
- [ ] Can enable/disable each notification type
- [ ] Changes take effect immediately
- [ ] Test notification button sends test notification
- [ ] Settings persist after app restart

---

## 6. Settings Screen

### General Settings
- [ ] User name/email displays (if applicable)
- [ ] App version visible
- [ ] All settings save correctly
- [ ] Changes persist after app restart

### Notification Preferences
- [ ] Can toggle daily reminders on/off
- [ ] Can set reminder time
- [ ] Can toggle bounce back reminders
- [ ] Can toggle milestone celebrations
- [ ] Test notification works

### Grace Period Settings
- [ ] Can configure grace period (0-2 misses/week)
- [ ] Changes apply to future streak calculations
- [ ] Current streaks update correctly

### About Section
- [ ] Privacy policy link works (if applicable)
- [ ] Terms of service link works (if applicable)
- [ ] Contact/support email works

---

## 7. Data Persistence

### App Restart
- [ ] All logs persist after force-quit
- [ ] All habits persist after force-quit
- [ ] All stacks persist after force-quit
- [ ] All streaks recalculate correctly after restart
- [ ] Settings persist after restart
- [ ] No data loss after restart

### Database Migrations
- [ ] App handles database version upgrades
- [ ] No data loss during migration
- [ ] All columns/tables exist after migration

### Edge Cases
- [ ] No data corruption after multiple saves
- [ ] Concurrent operations don't cause conflicts
- [ ] Large datasets (100+ logs) handled correctly

---

## 8. Performance

### Launch Time
- [ ] Cold start < 3 seconds (on mid-range device)
- [ ] Warm start < 1 second
- [ ] Database initialization doesn't block UI

### Screen Transitions
- [ ] Tab switching smooth (< 300ms)
- [ ] Bottom sheet animations smooth (60 FPS)
- [ ] Page transitions smooth

### List Performance
- [ ] Today's Log scrolls smoothly with 50+ entries
- [ ] Build Stack screen handles 10+ stacks
- [ ] Streaks screen handles 20+ habits
- [ ] No jank or frame drops during scroll

### Database Queries
- [ ] Log queries complete in < 100ms
- [ ] Streak calculations complete in < 200ms
- [ ] Tag extraction is instant

### Memory Usage
- [ ] Base memory < 100MB
- [ ] Memory < 150MB after 30 minutes of use
- [ ] No memory leaks (use Flutter DevTools)
- [ ] No unbounded list growth

---

## 9. Edge Cases

### Empty States
- [ ] No habits: helpful message, create button
- [ ] No logs: empty state with encouragement
- [ ] No stacks: empty state with create button
- [ ] No tags yet: empty state in search
- [ ] No sentiment data: empty state in analytics

### Network
- [ ] App works 100% offline (no cloud features in MVP)
- [ ] No errors when network unavailable

### Date/Time Edge Cases
- [ ] Logging at 11:59 PM works correctly
- [ ] Logging at 12:00 AM (midnight) works correctly
- [ ] Timezone changes handled (if traveling)
- [ ] Daylight saving time doesn't break streaks
- [ ] Leap year dates handled (Feb 29)

### Permission Denial
- [ ] Voice input degrades gracefully if permission denied
- [ ] Notifications explain how to re-enable if denied

### App Lifecycle
- [ ] App survives background/foreground cycles
- [ ] No crashes when phone call interrupts
- [ ] No crashes when switching apps rapidly

### Text Input
- [ ] Empty notes save correctly (null)
- [ ] Very long notes (500 chars) save correctly
- [ ] Special characters in notes (#, @, emoji) handled
- [ ] Hashtags with numbers work (#day1)
- [ ] Multiple hashtags in one note extracted correctly

---

## 10. Accessibility

### Labels
- [ ] All buttons have semantic labels (tooltip/accessibility label)
- [ ] All icons have labels
- [ ] All interactive elements labeled

### Contrast
- [ ] Text meets WCAG AA contrast ratio (4.5:1)
- [ ] Primary text readable on all backgrounds
- [ ] Button text readable on button backgrounds

### Font Scaling
- [ ] Text scales with system font size
- [ ] UI doesn't break at 200% font size
- [ ] All text remains readable when scaled

### Screen Reader
- [ ] Screen reader can navigate main screens
- [ ] Button labels are descriptive
- [ ] Form fields have labels

### Keyboard/Switch Control
- [ ] Tab navigation works (if applicable)
- [ ] All actions accessible without touch

---

## 11. Voice Input (Speech-to-Text)

- [ ] Microphone permission requested correctly
- [ ] Voice dialog opens when mic button tapped
- [ ] "Tap to speak" instruction clear
- [ ] Listening indicator shows when recording
- [ ] Speech is transcribed accurately
- [ ] Transcribed text appears in notes field
- [ ] Can cancel voice input
- [ ] Error message if permission denied
- [ ] Works with device language settings

---

## 12. Sentiment Analytics

- [ ] Sentiment chart widget displays
- [ ] Pie chart shows correct percentages
- [ ] Colors match sentiment types (Green/Gray/Amber)
- [ ] Touch interaction works (sections highlight)
- [ ] Legend displays with counts
- [ ] Empty state when no sentiment data
- [ ] Data updates when new logs added

---

## 13. Cross-Platform Testing

### iOS Specific
- [ ] Safe area insets respected (notch devices)
- [ ] Keyboard doesn't cover input fields
- [ ] Swipe gestures don't conflict with iOS system gestures
- [ ] Dark mode support (if implemented)
- [ ] Haptic feedback works (if implemented)

### Android Specific
- [ ] Back button navigation works correctly
- [ ] Material Design components render correctly
- [ ] Works on various screen sizes (small, large, tablet)
- [ ] Android 10+ works
- [ ] Bottom navigation bar respected

---

## 14. Security & Privacy

- [ ] No sensitive data logged to console
- [ ] Database file not accessible to other apps
- [ ] No data sent to external servers (local-only MVP)
- [ ] No unauthorized permissions requested

---

## Success Criteria

### Must Pass Before Launch
- [ ] 0 P0 (Critical) bugs
- [ ] 0-3 P1 (High) bugs
- [ ] All core features working (Sections 2-5)
- [ ] Data persistence reliable (Section 7)
- [ ] Performance targets met (Section 8)
- [ ] No crashes in normal use
- [ ] At least 80% of checklist passing

### Nice to Have
- [ ] < 5 P2 (Medium) bugs
- [ ] All edge cases handled (Section 9)
- [ ] Full accessibility compliance (Section 10)

---

## Testing Notes

**Tester Name**: _________________
**Device**: _________________
**OS Version**: _________________
**Date**: _________________

**Overall Rating**: ⭐⭐⭐⭐⭐
**Would Use Daily**: Yes / No / Maybe
**Most Liked Feature**: _________________
**Most Frustrating Issue**: _________________

---

**Last Updated**: 2025-11-05
**Next Review**: After beta testing phase
