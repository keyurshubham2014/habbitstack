# Changelog

All notable changes to StackHabit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned for Phase 2
- Cloud sync with Supabase/Firebase
- AI insights powered by Openrouter API
- Premium paywall and in-app purchases
- Social accountability features
- Multi-user support
- Export notes to markdown/PDF
- Rich text formatting in notes
- Photo attachments

---

## [1.0.0-mvp] - 2025-11-05

### Added - Core Features

#### Today's Log Screen
- Reverse logging system (log completed activities)
- Quick add floating action button
- Create habits on-the-fly during logging
- Icon picker with 100+ habit icons
- Time picker for backdating logs
- Sentiment tracking (Happy, Neutral, Struggled)
- Notes field with voice-to-text support
- Character counter (500 character limit)
- Hashtag support for notes (#morning, #workout, etc.)
- Tag suggestion chips from recent tags
- Full-text and tag-based search functionality
- Edit existing log entries
- Delete log entries with confirmation
- Pull-to-refresh to update list
- Empty state with helpful messaging

#### Build Stack Screen
- Visual habit stacking builder
- Anchor habit detection and suggestions
- Drag-and-drop habit reordering
- Create named stacks with descriptions
- Add/remove habits from stacks
- Visual flow display (Anchor → Habit 1 → Habit 2)
- Edit stack name and description
- Delete stacks with confirmation
- Stack persistence to SQLite database
- Empty state with create button

#### Streaks Screen
- Flexible streak tracking system
- Configurable grace periods (1-2 misses per week)
- Three-state streak status:
  - Green: Perfect streak (no misses)
  - Yellow: Grace period active (strikes remaining)
  - Red: Broken streak
- Current and longest streak display
- Last logged date tracking
- 90-day calendar heatmap visualization
- Color-coded days (Green=logged, Gray=missed, Yellow=grace)
- Motivational messages for milestones (7, 14, 30, 60, 90 days)
- Pull-to-refresh to recalculate streaks
- Empty state for new users

#### Bounce Back Feature
- 24-hour window to save broken streaks
- Automatic detection of missed habits with grace periods
- Visual "Save Your Streak" cards on Today's Log
- Backdated log creation
- Streak restoration on successful bounce back
- Expiration after 24 hours

#### Notifications
- Local push notifications (flutter_local_notifications)
- Daily reminders (user-configurable time)
- Bounce back opportunity alerts
- Milestone celebration notifications (7, 14, 30 days)
- Notification permission handling
- Settings toggles for each notification type
- Test notification functionality

#### Voice Input
- Speech-to-text for notes (speech_to_text package)
- Microphone permission handling
- Voice input dialog with visual feedback
- Append to existing notes
- Graceful degradation if permission denied

#### Search & Tags
- Full-text search across all notes
- Hashtag extraction using regex (#word pattern)
- Tag-based filtering and search
- Recent tags display when search is empty
- Search results with habit name, date, sentiment
- Tappable results for editing
- Empty state for no results

#### Sentiment Analytics
- Interactive pie chart (fl_chart package)
- 30-day sentiment distribution
- Touch interaction with section highlighting
- Color-coded segments (Green=Happy, Gray=Neutral, Amber=Struggled)
- Legend with counts and percentages
- Empty state when no sentiment data

#### Settings Screen
- Notification preferences
- Daily reminder time configuration
- Bounce back reminder toggle
- Milestone celebration toggle
- Grace period configuration (0-2 misses per week)
- Test notification button
- App version display
- Settings persistence across restarts

### Technical Implementation

#### Database
- SQLite local storage (sqflite package)
- Database version 5
- Tables:
  - users (user profiles)
  - habits (individual habits with icons)
  - habit_stacks (grouped habit chains)
  - daily_logs (completion records with notes, tags, sentiment)
  - streaks (streak tracking with grace periods)
- Automatic database migration system
- Indexed queries for performance

#### State Management
- Riverpod for state management
- Providers for habits, logs, streaks, user
- AsyncValue for loading states
- Proper provider disposal
- Real-time UI updates

#### Architecture
- Clean separation of concerns:
  - Models: Pure data classes
  - Services: Business logic and database operations
  - Providers: State management
  - Screens: UI composition
  - Widgets: Reusable components
- Null safety throughout
- Error handling with user-friendly messages
- Loading states for async operations

#### Design System
- Custom color palette:
  - Warm Coral (#FF6B6B) - Primary actions
  - Gentle Teal (#4ECDC4) - Secondary actions
  - Deep Blue (#5E60CE) - Anchor habits
  - Success Green (#66BB6A) - Completed, streaks
  - Warning Amber (#FFA726) - Grace periods
  - Soft Red (#EF5350) - Errors
- Poppins font family
- Consistent spacing and sizing
- Material Design components
- Smooth animations and transitions

#### Dependencies
- flutter_riverpod: ^2.5.1 (State management)
- sqflite: ^2.3.3 (Local database)
- path_provider: ^2.1.3 (File system access)
- shared_preferences: ^2.2.3 (Settings storage)
- google_fonts: ^6.2.1 (Typography)
- fl_chart: ^0.68.0 (Charts and graphs)
- speech_to_text: ^7.0.0 (Voice input)
- flutter_local_notifications: ^17.2.1 (Notifications)
- intl: ^0.19.0 (Date formatting)

### Fixed

#### Database Issues
- Fixed database migration from v4 to v5 for tags column
- Resolved concurrent access errors
- Fixed null handling in database queries
- Optimized query performance with proper WHERE clauses

#### UI/UX Fixes
- Fixed character counter not updating in real-time
- Resolved tag chip spacing issues
- Fixed search delegate theme consistency
- Corrected empty state displays across all screens
- Fixed bottom sheet keyboard overlap
- Resolved hero tag conflicts in navigation
- Fixed provider disposal issues

#### Performance
- Optimized list rendering with ListView.builder
- Reduced unnecessary rebuilds with proper state management
- Implemented lazy loading for search results
- Limited database queries with time windows (90 days)
- Efficient tag extraction and storage

### Known Limitations

**Intentional for MVP** (will be addressed in Phase 2):
- No cloud sync (data is local-only)
- No multi-user support (single user per device)
- No rich text formatting (plain text notes only)
- No photo attachments (text and voice notes only)
- No data export functionality
- No AI insights (coming in Phase 2 with Openrouter API)
- No social features (private accountability groups in Phase 2)
- No onboarding flow (immediate access to app)

### Performance Benchmarks

**Targets** (tested on mid-range devices: iPhone 11, Pixel 4):
- App launch time: < 3 seconds
- Screen transitions: < 300ms
- List scroll (100+ items): 60 FPS
- Database queries: < 100ms
- Memory usage: < 150MB

### Accessibility

- Semantic labels on all interactive elements
- WCAG AA contrast ratios met
- Font scaling support (system font size)
- Basic screen reader compatibility
- Descriptive error messages
- Clear visual hierarchy

---

## Development Milestones

### Milestone 1: Foundation Complete ✅
**Date**: 2025-10-30
- App launches with bottom navigation
- Design system fully implemented
- Database operational with all tables
- All placeholder screens created

### Milestone 2: Core Features Complete ✅
**Date**: 2025-11-01
- Daily activity logging functional
- Habit stack builder working
- Voice input integrated
- Drag-and-drop implemented

### Milestone 3: Streaks & Polish Complete ✅
**Date**: 2025-11-05
- Streak tracking operational
- Calendar heatmap displays
- Notifications working
- Search and tags functional
- Sentiment analytics complete

### Milestone 4: MVP Ready for Testing
**Date**: 2025-11-05
- 19/25 tasks complete (76%)
- Ready for beta testing
- All critical features implemented
- Performance targets met

---

## Version History

| Version | Date | Status | Notes |
|---------|------|--------|-------|
| 1.0.0-mvp | 2025-11-05 | Beta Testing | Ready for user testing |
| 0.5.0 | 2025-11-01 | Internal | Core features complete |
| 0.1.0 | 2025-10-29 | Initial | Project initialized |

---

## Next Release

### [1.1.0] - Planned Post-Beta
**Focus**: Bug fixes from user testing

**Will Include**:
- All P0 (Critical) bug fixes
- All P1 (High priority) bug fixes
- 80%+ of P2 (Medium) bug fixes
- UX improvements from beta feedback
- Performance optimizations
- Accessibility enhancements

---

## How to Report Bugs

If you're a beta tester and found a bug:

1. Check [BUGS.md](BUGS.md) to see if it's already reported
2. Submit via email, Google Form, or GitHub Issues
3. Include:
   - Device and OS version
   - Steps to reproduce
   - Expected vs. actual behavior
   - Screenshots if possible

---

**Last Updated**: 2025-11-05
**Current Version**: 1.0.0-mvp
**Status**: Ready for Beta Testing
