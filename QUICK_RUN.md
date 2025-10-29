# StackHabit - Quick Run Commands

Fast reference for running the app during development.

---

## 🚀 Most Common Commands

### Run on Android Emulator
```bash
flutter run
# or specifically target emulator
flutter run -d emulator-5554
```

### Run on Chrome (Web)
```bash
flutter run -d chrome
```

### Run on macOS Desktop
```bash
flutter run -d macos
```

---

## 📱 Using the Interactive Menu

We've created a handy interactive menu:

```bash
./run.sh
```

This will show you all available options:
1. Run on Android Emulator
2. Run on iOS Simulator
3. Run on Chrome (Web)
4. Run on macOS (Desktop)
5. Run in Release Mode (Android)
6. List Available Devices
7. List Available Emulators
8. Start Android Emulator
9. Clean and Rebuild
10. Hot Reload Instructions
11. Open DevTools

---

## ⚡ Hot Reload (While App is Running)

After running `flutter run`, you can use these keyboard shortcuts:

| Key | Action |
|-----|--------|
| `r` | Hot reload (instant updates) 🔥 |
| `R` | Hot restart (full restart) |
| `h` | Show all available commands |
| `d` | Detach (leave app running) |
| `c` | Clear the screen |
| `q` | Quit the app |

---

## 🛠️ Before Running (First Time Setup)

### Start Android Emulator
```bash
# List available emulators
flutter emulators

# Start specific emulator
flutter emulators --launch <emulator_id>

# Wait ~30 seconds, then run
flutter run
```

### Check Available Devices
```bash
flutter devices
```

---

## 🧹 Troubleshooting

### Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### If Build Fails
```bash
# Update dependencies
flutter pub upgrade

# Rebuild
flutter run
```

### Check Flutter Setup
```bash
flutter doctor -v
```

---

## 📊 Development Workflow

**Typical workflow during development:**

1. **Start Emulator** (if not running)
   ```bash
   ./run.sh  # Choose option 8
   ```

2. **Run App**
   ```bash
   flutter run
   # or use: ./run.sh (choose option 1)
   ```

3. **Make Changes**
   - Edit files in `lib/`
   - Press `r` for hot reload
   - See changes instantly!

4. **Debug**
   - View logs in terminal
   - Use DevTools: `./run.sh` (option 11)

5. **Stop App**
   - Press `q` in terminal

---

## 🎯 Quick Tasks

### Just Want to Test Quickly?
```bash
flutter run -d chrome
```
Fastest way to see your app (no emulator needed)

### Testing on Actual Device?
```bash
# Connect device via USB
flutter devices  # Should show your device
flutter run      # Will auto-detect connected device
```

### Build Release APK (for sharing)
```bash
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

---

## 💡 Pro Tips

1. **Keep Emulator Running**: Don't close it between runs - it's slow to restart
2. **Use Hot Reload**: Press `r` instead of restarting the whole app
3. **Multiple Devices**: Run on web for quick UI checks, Android for final testing
4. **DevTools**: Use for debugging performance and inspecting widgets

---

## 📱 Current Setup

Your Android emulator is configured as:
- **Device**: sdk gphone64 arm64
- **ID**: emulator-5554
- **OS**: Android 16 (API 36)

To run on it: `flutter run` (auto-detects) or `flutter run -d emulator-5554` (explicit)

---

**Need the interactive menu?** Just run: `./run.sh`
