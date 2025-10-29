# StackHabit - Flutter Development Project

## Project Overview

**StackHabit** is an intelligent habit stacking app that helps users build sustainable habits through science-backed methods and AI-powered insights.

### Vision
Help users build sustainable habits through reverse logging, habit stacking, and intelligent pattern recognition - making behavior change feel natural, not overwhelming.

### Target Audience
- Professionals (25-45 years) struggling with consistency
- People who've failed with traditional habit trackers
- Users wanting accountability without social media pressure

## Technical Stack

### Core Technologies
- **Frontend/Mobile**: Flutter (Dart 3.5+)
- **State Management**: Riverpod
- **Local Database**: SQLite (sqflite)
- **AI Integration**: Openrouter API (Claude 3.5 Sonnet)
- **Authentication**: Firebase Auth or Supabase Auth
- **Backend**: Supabase/Firebase (optional sync)

### Key Flutter Packages
```yaml
dependencies:
  # Core
  flutter_riverpod: ^2.5.1
  sqflite: ^2.3.3
  path_provider: ^2.1.3
  shared_preferences: ^2.2.3

  # UI/UX
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0
  fl_chart: ^0.68.0
  calendar_view: latest

  # Features
  speech_to_text: ^7.0.0
  local_notifications: ^17.2.1
  share_plus: latest
  url_launcher: latest

  # AI Integration
  http: ^1.2.1
  flutter_markdown: latest

  # Utils
  intl: ^0.19.0
```

## Project Structure

```
lib/
├── main.dart
├── models/
│   ├── habit.dart
│   ├── habit_stack.dart
│   ├── daily_log.dart
│   ├── streak.dart
│   └── user.dart
├── services/
│   ├── database_service.dart
│   ├── openrouter_service.dart
│   ├── notification_service.dart
│   └── streak_calculator.dart
├── providers/
│   ├── habits_provider.dart
│   ├── logs_provider.dart
│   ├── streaks_provider.dart
│   └── user_provider.dart
├── screens/
│   ├── home/
│   │   └── todays_log_screen.dart
│   ├── streaks/
│   │   └── streaks_screen.dart
│   ├── build_stack/
│   │   └── build_stack_screen.dart
│   ├── accountability/
│   │   └── accountability_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/
│   ├── buttons/
│   ├── cards/
│   ├── inputs/
│   └── common/
└── theme/
    ├── app_colors.dart
    ├── app_text_styles.dart
    └── app_theme.dart
```

## Design System

### Color Palette
```dart
// Primary Colors
static const warmCoral = Color(0xFFFF6B6B);    // CTAs, important actions
static const gentleTeal = Color(0xFF4ECDC4);   // Secondary actions
static const deepBlue = Color(0xFF5E60CE);     // Anchor habits

// Semantic Colors
static const successGreen = Color(0xFF66BB6A);  // Completed, streaks
static const warningAmber = Color(0xFFFFA726);  // Grace periods
static const softRed = Color(0xFFEF5350);       // Errors (not harsh)
static const neutralGray = Color(0xFF9E9E9E);   // Disabled

// Backgrounds
static const primaryBg = Color(0xFFFFFFFF);     // White
static const secondaryBg = Color(0xFFFFF8E7);   // Soft cream
static const tertiaryBg = Color(0xFFF5F5F5);    // Light gray

// Text
static const primaryText = Color(0xFF2C3E50);   // Dark, readable
static const secondaryText = Color(0xFF7F8C8D); // Muted
static const invertedText = Color(0xFFFFFFFF);  // On dark backgrounds
```

### Typography
- **Font Family**: Poppins (friendly, rounded) or Inter (clean, modern)
- **Headline**: 28px, Bold
- **Title**: 20px, SemiBold
- **Body**: 16px, Regular
- **Caption**: 14px, Regular
- **Small**: 12px, Regular

## Development Phases

### Phase 1: MVP (Weeks 1-6)
Core features for basic functionality:
1. Reverse Logging System
2. Habit Stacking Builder
3. Flexible Streak Tracking
4. Notes + Sentiment Tracking
5. Basic Accountability Features

### Phase 2: Social & Premium (Weeks 7-10)
Advanced features:
1. Enhanced Accountability (groups)
2. AI Pattern Recognition (Openrouter)
3. Premium Features & Paywall
4. Advanced Analytics

## Key Features

### 1. Reverse Logging
- Log what you accomplished without pre-commitment
- Voice-to-text note capture
- Discover natural patterns organically
- No pressure, just observation

### 2. Habit Stacking
- Identify "Anchor Habits" (existing solid habits)
- Link new habits to anchors
- Visual flow: Anchor → Habit 1 → Habit 2 → Habit 3
- Drag-and-drop reordering

### 3. Forgiving Streaks
- Three states: Perfect (Green), Grace Period (Yellow), Broken (Red)
- Configurable grace periods (1-2 misses/week)
- "Bounce Back" feature (24-hour recovery)
- Calendar heatmap visualization

### 4. AI Insights (Premium)
- Pattern recognition from 30+ days of data
- Optimal timing suggestions
- Predictive alerts for likely skip days
- Weekly summary insights

## Database Schema (SQLite)

### Core Tables
- `users` - User profiles and settings
- `habits` - Individual habits (anchor vs new)
- `habit_stacks` - Grouped habit chains
- `daily_logs` - Completion records with notes
- `streaks` - Streak tracking with grace periods
- `accountability_partners` - Friend connections
- `shared_habits` - Visibility settings
- `ai_insights` - Generated insights (Premium)

## API Integration

### Openrouter API
- **Endpoint**: `https://openrouter.ai/api/v1/chat/completions`
- **Model**: `anthropic/claude-3.5-sonnet`
- **Use Cases**: Pattern analysis, insights generation, predictions
- **Rate Limit**: 10 requests/day (free tier)

## Development Commands

```bash
# Initial setup
flutter create stackhabit
cd stackhabit

# Install dependencies
flutter pub get

# Run app
flutter run

# Run tests
flutter test

# Build for production
flutter build apk  # Android
flutter build ios  # iOS
```

## Workflow System

### Task Management
All tasks are tracked in the `/tasks` folder:
- Individual task files for granular tracking
- `TASK_SUMMARY.md` for overall progress
- Status tracking: TODO, IN_PROGRESS, DONE, BLOCKED

### Reference Tasks
When working on any task, always check:
1. Current task file in `/tasks`
2. Related task dependencies
3. Task summary for context
4. This Claude file for technical specs

## Success Metrics

### MVP Goals (First 3 Months)
- **User Retention**: 40% weekly active after 30 days
- **Habit Completion**: Avg 4+ logged habits/user/week
- **Stack Creation**: 60% create stack within 7 days
- **Grace Period Usage**: 10-20% (shows realistic tracking)

### Premium Goals
- **Trial to Paid**: 20% conversion after 30 days
- **AI Engagement**: 70% check insights weekly
- **Retention**: 60% monthly renewal

## Coding Standards

### Dart/Flutter Best Practices
- Use `const` constructors wherever possible
- Implement proper null safety
- Follow Flutter's widget composition patterns
- Use Riverpod for state management consistently
- Keep widgets small and focused (SRP)

### File Naming
- Snake_case for files: `todays_log_screen.dart`
- PascalCase for classes: `TodaysLogScreen`
- camelCase for variables/functions: `getUserHabits()`

### Code Organization
- Models: Pure data classes with serialization
- Services: Business logic and external integrations
- Providers: State management with Riverpod
- Screens: UI composition
- Widgets: Reusable UI components

## Important Reminders

1. **Privacy First**: All data stored locally in SQLite initially
2. **Forgiving UX**: Grace periods, bounce-backs, no harsh language
3. **Voice Input**: Quick capture is critical for adoption
4. **Animations**: Smooth, delightful micro-interactions
5. **Accessibility**: Support screen readers, high contrast
6. **Offline First**: App must work without internet

## Next Steps

Start with `/tasks/TASK_SUMMARY.md` to see current development phase and priorities.

Refer to individual task files in `/tasks` for detailed implementation steps.

---

**Last Updated**: 2025-10-29
**Current Phase**: Phase 1 - MVP Development
**Current Sprint**: Initial Setup & Core Features
