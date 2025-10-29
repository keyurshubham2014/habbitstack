# Task 01: Project Initialization

**Status**: 50% COMPLETE (Waiting for Flutter installation)
**Priority**: HIGH
**Estimated Time**: 2 hours
**Assigned To**: In Progress
**Dependencies**: Flutter SDK installation
**Blocking**: Tasks 02-05

---

## ✅ Progress Update

### Completed:
- ✅ Git repository initialized
- ✅ .gitignore configured for Flutter
- ✅ pubspec.yaml template prepared
- ✅ Setup script created (setup_project.sh)
- ✅ Project documentation written
- ✅ Folder structure planned

### Pending:
- ⏳ **Flutter SDK installation (USER ACTION REQUIRED)**
- ⏳ Run setup_project.sh
- ⏳ Create Flutter project structure
- ⏳ Install dependencies
- ⏳ Verify installation

**Action Required**: Install Flutter using [SETUP_FLUTTER.md](../SETUP_FLUTTER.md), then run `./setup_project.sh`

---

## Objective

Initialize the Flutter project with proper folder structure and all required dependencies.

## Acceptance Criteria

- [ ] Flutter project created with name `stackhabit`
- [ ] All dependencies added to `pubspec.yaml`
- [ ] Folder structure matches the design
- [ ] App runs without errors on both iOS and Android emulators
- [ ] Git repository initialized with proper `.gitignore`

---

## Step-by-Step Instructions

### 1. Create Flutter Project

```bash
# Navigate to your development directory
cd ~/Documents/Projects

# Create Flutter project
flutter create stackhabit

# Navigate into project
cd stackhabit

# Test initial run
flutter run
```

**Verify**: Default Flutter counter app should launch successfully.

### 2. Update `pubspec.yaml`

Replace the dependencies section with:

```yaml
name: stackhabit
description: Intelligent Habit Stacking App - Build sustainable habits through science-backed methods
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1

  # Database
  sqflite: ^2.3.3
  path_provider: ^2.1.3

  # Local Storage
  shared_preferences: ^2.2.3

  # UI/UX
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0
  fl_chart: ^0.68.0

  # Features
  speech_to_text: ^7.0.0
  flutter_local_notifications: ^17.2.1
  share_plus: ^2.2.2
  url_launcher: ^6.3.0

  # API Integration
  http: ^1.2.1
  flutter_markdown: ^0.7.3

  # Utilities
  intl: ^0.19.0
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

Then run:
```bash
flutter pub get
```

### 3. Create Folder Structure

```bash
# Create all necessary directories
mkdir -p lib/models
mkdir -p lib/services
mkdir -p lib/providers
mkdir -p lib/screens/home
mkdir -p lib/screens/streaks
mkdir -p lib/screens/build_stack
mkdir -p lib/screens/accountability
mkdir -p lib/screens/settings
mkdir -p lib/widgets/buttons
mkdir -p lib/widgets/cards
mkdir -p lib/widgets/inputs
mkdir -p lib/widgets/common
mkdir -p lib/theme
mkdir -p lib/utils
mkdir -p lib/constants
mkdir -p assets/icons
mkdir -p assets/images
```

### 4. Create Base Files

Create these placeholder files:

#### `lib/theme/app_colors.dart`
```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const warmCoral = Color(0xFFFF6B6B);
  static const gentleTeal = Color(0xFF4ECDC4);
  static const deepBlue = Color(0xFF5E60CE);

  // Semantic Colors
  static const successGreen = Color(0xFF66BB6A);
  static const warningAmber = Color(0xFFFFA726);
  static const softRed = Color(0xFFEF5350);
  static const neutralGray = Color(0xFF9E9E9E);

  // Backgrounds
  static const primaryBg = Color(0xFFFFFFFF);
  static const secondaryBg = Color(0xFFFFF8E7);
  static const tertiaryBg = Color(0xFFF5F5F5);

  // Text
  static const primaryText = Color(0xFF2C3E50);
  static const secondaryText = Color(0xFF7F8C8D);
  static const invertedText = Color(0xFFFFFFFF);
}
```

#### `lib/constants/app_constants.dart`
```dart
class AppConstants {
  // App Info
  static const String appName = 'StackHabit';
  static const String appVersion = '1.0.0';

  // Limits
  static const int maxStacksFreeTier = 5;
  static const int maxPartnersFreeTier = 3;
  static const int maxHabitsPerStack = 3;

  // Grace Periods
  static const int defaultGracePeriodDays = 2;
  static const int bounceBackHours = 24;

  // AI
  static const int minDaysForAIInsights = 30;
  static const int aiRequestsPerDayFree = 1;
  static const int aiRequestsPerDayPremium = 10;
}
```

### 5. Update `.gitignore`

Add these Flutter-specific entries if not already present:

```gitignore
# Flutter/Dart specific
*.dart_tool/
*.packages
.pub-cache/
.pub/
build/
.flutter-plugins
.flutter-plugins-dependencies

# IDE
.idea/
.vscode/
*.swp
*.swo

# macOS
.DS_Store

# API Keys (IMPORTANT!)
lib/config/api_keys.dart
.env
```

### 6. Initialize Git

```bash
git init
git add .
git commit -m "Initial Flutter project setup for StackHabit"
```

### 7. Test Installation

```bash
# Check for issues
flutter doctor

# Run app
flutter run
```

---

## Verification Checklist

- [ ] `flutter doctor` shows no critical errors
- [ ] All dependencies installed without conflicts
- [ ] Folder structure created correctly
- [ ] Base theme files exist
- [ ] App compiles and runs
- [ ] Git repository initialized

---

## Common Issues & Solutions

### Issue: Package version conflicts
**Solution**: Run `flutter pub upgrade --major-versions`

### Issue: iOS build fails
**Solution**:
```bash
cd ios
pod install
cd ..
```

### Issue: Android build fails
**Solution**: Check `android/app/build.gradle` has `minSdkVersion 21` or higher

---

## Next Task

After completion, proceed to: [02_design_system_setup.md](./02_design_system_setup.md)

---

## Notes

- Keep API keys out of version control
- Use Flutter 3.24+ for best compatibility
- Test on both iOS and Android emulators

**Last Updated**: 2025-10-29
