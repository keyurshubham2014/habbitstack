# Flutter Installation Guide for macOS

Flutter is not currently installed on your system. Follow these steps to get set up.

## Option 1: Install via Homebrew (Recommended)

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Flutter
brew install --cask flutter

# Verify installation
flutter doctor
```

## Option 2: Manual Installation

### 1. Download Flutter SDK

```bash
# Navigate to your home directory
cd ~

# Download Flutter (stable channel)
# Visit: https://docs.flutter.dev/get-started/install/macos
# Or use this direct download:
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.5-stable.zip

# Unzip
unzip flutter_macos_arm64_3.24.5-stable.zip

# Move to a permanent location
sudo mv flutter /usr/local/flutter
```

### 2. Add Flutter to PATH

Add this to your `~/.zshrc` file (or `~/.bash_profile` if using bash):

```bash
# Open your shell config
nano ~/.zshrc

# Add these lines:
export PATH="$PATH:/usr/local/flutter/bin"
export PATH="$PATH:/usr/local/flutter/bin/cache/dart-sdk/bin"

# Save and reload
source ~/.zshrc
```

### 3. Verify Installation

```bash
flutter doctor
```

This will check for any missing dependencies.

## Install Additional Requirements

### Xcode (for iOS development)

```bash
# Install from App Store
# Then accept license
sudo xcodebuild -license accept

# Install CocoaPods
sudo gem install cocoapods
```

### Android Studio (for Android development)

1. Download from: https://developer.android.com/studio
2. Install Android SDK
3. Set up an Android emulator

## Run Flutter Doctor

After installation, run:

```bash
flutter doctor -v
```

This will show what's installed and what's missing.

## Common Issues

### Issue: flutter command not found
**Solution**: Make sure you've added Flutter to PATH and reloaded your shell

### Issue: CocoaPods not installed
**Solution**:
```bash
sudo gem install cocoapods
pod setup
```

### Issue: Xcode license not accepted
**Solution**:
```bash
sudo xcodebuild -license accept
```

---

## Once Flutter is Installed

Return to this project and run:

```bash
cd /Users/keyur/Documents/Projects/Sample-flutter-app
flutter doctor
```

Then ask Claude Code to continue with Task 01!
