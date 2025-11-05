# StackHabit - Intelligent Habit Stacking App

> Build sustainable habits through science-backed methods and AI-powered insights

## ✅ Current Status: MVP Complete - Ready for Beta Testing!

**Version**: 1.0.0-mvp
**Progress**: 19/25 tasks (76%) - Phase 1 MVP Complete
**Last Updated**: 2025-11-05

All core features implemented and ready for user testing!

### Quick Start

**Run the App**

```bash
# Option 1: Interactive menu (recommended for beginners)
./run.sh

# Option 2: Direct run (fastest)
flutter run

# Option 3: Quick reference
cat QUICK_RUN.md
```

### Running on Different Platforms

```bash
# Android Emulator (default)
flutter run

# Chrome (fastest for UI testing)
flutter run -d chrome

# macOS Desktop
flutter run -d macos

# iOS Simulator (if Xcode is installed)
flutter run -d ios
```

### Hot Reload ⚡

While the app is running, press:
- **`r`** - Hot reload (instant updates!)
- **`R`** - Hot restart
- **`q`** - Quit app

### Alternative: Manual Setup

If you prefer manual setup, see [READY_FOR_FLUTTER.md](READY_FOR_FLUTTER.md)

---

## 📋 Project Overview

**StackHabit** helps users build sustainable habits through:
- **Reverse Logging**: Log what you did, discover patterns naturally
- **Habit Stacking**: Link new habits to existing anchors
- **Forgiving Streaks**: Grace periods, not punishment
- **AI Insights**: Pattern recognition powered by Openrouter API

### Target Audience
- Professionals (25-45 years) struggling with consistency
- People who've failed with traditional habit trackers
- Users wanting accountability without social media pressure

---

## 🛠 Tech Stack

- **Framework**: Flutter 3.24+
- **Language**: Dart 3.5+
- **State Management**: Riverpod
- **Database**: SQLite (sqflite)
- **AI**: Openrouter API (Claude 3.5 Sonnet)
- **Notifications**: flutter_local_notifications
- **Voice Input**: speech_to_text

---

## 📁 Project Structure

```
Sample-flutter-app/
├── .claude/                      # Project documentation & specs
│   └── claude.md                 # Complete project reference
├── tasks/                        # Development task tracking
│   ├── TASK_SUMMARY.md          # Overall progress tracker
│   ├── 01_project_initialization.md
│   ├── 02_design_system_setup.md
│   ├── 03_database_schema.md
│   ├── 04_bottom_navigation.md
│   └── 05_state_management.md
├── lib/                          # (Created by Flutter)
│   ├── models/
│   ├── services/
│   ├── providers/
│   ├── screens/
│   ├── widgets/
│   └── theme/
├── pubspec.yaml.template         # Dependencies template
├── setup_project.sh              # Automated setup script
├── SETUP_FLUTTER.md             # Flutter installation guide
└── READY_FOR_FLUTTER.md         # Setup instructions

```

---

## 🎯 Development Roadmap

### Phase 1: MVP (Weeks 1-6) ✅ COMPLETE

#### Week 1-2: Project Setup ✅ COMPLETE
- [x] Workflow system created
- [x] Git repository initialized
- [x] Flutter project created
- [x] Design system implemented
- [x] Database schema set up
- [x] Bottom navigation
- [x] Riverpod state management

#### Week 3-4: Core Features ✅ COMPLETE
- [x] Daily activity logging
- [x] Habit stacking builder
- [x] Voice input integration
- [x] Drag-and-drop interface
- [x] Habit icons library (100+)
- [x] Stack persistence
- [x] Anchor detection

#### Week 5-6: Streaks & Polish ✅ 86% COMPLETE
- [x] Streak tracking with grace periods
- [x] Calendar heatmap (90 days)
- [x] Local notifications
- [x] Bounce back feature (24-hour window)
- [x] Notes & sentiment tracking
- [x] Search & tags
- [ ] User testing (in progress)

### Phase 2: Premium (Weeks 7-10)
- [ ] Accountability features
- [ ] AI pattern recognition
- [ ] Premium paywall
- [ ] Beta launch prep

---

## 📚 Documentation

- **[.claude/claude.md](.claude/claude.md)**: Complete technical specifications
- **[tasks/TASK_SUMMARY.md](tasks/TASK_SUMMARY.md)**: Development progress tracker
- **[SETUP_FLUTTER.md](SETUP_FLUTTER.md)**: Flutter installation guide
- **Individual task files**: Step-by-step implementation guides

---

## 🚀 Next Steps

1. **Install Flutter** using [SETUP_FLUTTER.md](SETUP_FLUTTER.md)
2. **Run setup script**: `./setup_project.sh`
3. **Continue with Task 02**: Design System Setup
4. **Ask Claude Code**: "Continue with Task 02"

---

## 🎨 Design System

### Color Palette
- **Primary**: Warm Coral (#FF6B6B)
- **Secondary**: Gentle Teal (#4ECDC4)
- **Accent**: Deep Blue (#5E60CE)
- **Success**: Green (#66BB6A)
- **Warning**: Amber (#FFA726)

### Typography
- **Font**: Poppins (friendly, rounded)
- **Sizes**: 28px (headline), 20px (title), 16px (body)

---

## 📝 Key Features

### MVP Features
1. **Reverse Logging**: Log activities without pre-commitment
2. **Habit Stacking**: Visual flow of linked habits
3. **Flexible Streaks**: Three states (perfect, grace, broken)
4. **Notes & Sentiment**: Quick reflections on each habit
5. **Accountability**: Private groups with 3 partners

### Premium Features
1. **AI Insights**: Pattern analysis from 30+ days of data
2. **Predictive Alerts**: Smart suggestions for skip days
3. **Advanced Analytics**: Deep dive into habit patterns

---

## 🔧 Development Commands

```bash
# After Flutter is installed:

# Create project
flutter create --project-name stackhabit .

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

---

## 🤝 Working with Claude Code

This project uses a comprehensive workflow system:

1. **Check**: [tasks/TASK_SUMMARY.md](tasks/TASK_SUMMARY.md) for current status
2. **Open**: Specific task file (e.g., `tasks/02_design_system_setup.md`)
3. **Ask**: "Help me complete Task [number]"
4. **Update**: Task status when complete

---

## 📊 Success Metrics

### MVP Goals (First 3 Months)
- **User Retention**: 40% weekly active after 30 days
- **Habit Completion**: Avg 4+ habits logged per user/week
- **Stack Creation**: 60% create a stack within 7 days

### Premium Goals
- **Trial to Paid**: 20% conversion after 30 days
- **AI Engagement**: 70% check insights weekly
- **Retention**: 60% monthly renewal

---

## 📄 License

This project is for development purposes.

---

## 🆘 Need Help?

- **Flutter not installed?** See [SETUP_FLUTTER.md](SETUP_FLUTTER.md)
- **Setup issues?** Check [READY_FOR_FLUTTER.md](READY_FOR_FLUTTER.md)
- **Task questions?** Open the specific task file in `tasks/`
- **Technical specs?** See [.claude/claude.md](.claude/claude.md)

---

**Last Updated**: 2025-11-05
**Current Phase**: Phase 1 - Week 6 (Beta Testing)
**Status**: MVP Complete - 19/25 Tasks (76%)

---

Made with ❤️ using Flutter and Claude Code
