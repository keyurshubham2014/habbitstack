#!/bin/bash

# StackHabit Project Setup Script
# Run this after Flutter is installed

set -e  # Exit on error

echo "🚀 StackHabit Project Setup"
echo "============================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo "Please follow instructions in SETUP_FLUTTER.md first"
    exit 1
fi

echo "✅ Flutter is installed"
flutter --version
echo ""

# Create Flutter project in current directory
echo "📦 Creating Flutter project..."
flutter create --project-name stackhabit .

echo ""
echo "📝 Updating pubspec.yaml with dependencies..."
cp pubspec.yaml.template pubspec.yaml

echo ""
echo "📥 Installing dependencies..."
flutter pub get

echo ""
echo "📁 Creating folder structure..."

# Create lib folders
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

# Create assets folders
mkdir -p assets/icons
mkdir -p assets/images

echo "✅ Folder structure created"
echo ""

echo "🎨 Creating base theme files..."

# Create app_colors.dart
cat > lib/theme/app_colors.dart << 'EOF'
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
EOF

# Create app_constants.dart
cat > lib/constants/app_constants.dart << 'EOF'
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
EOF

echo "✅ Base files created"
echo ""

echo "🔧 Running Flutter doctor..."
flutter doctor

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Review the created files"
echo "2. Run: flutter run"
echo "3. Continue with Task 02 (Design System Setup)"
echo ""
echo "Ask Claude Code to continue with the remaining tasks!"
