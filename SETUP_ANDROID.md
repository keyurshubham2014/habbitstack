# Setting Up Android Emulator for StackHabit

Android Studio has been installed! Now we need to complete the setup to run the app on an Android emulator.

## Step 1: Launch Android Studio (First Time Setup)

1. **Open Android Studio**:
   ```bash
   open -a "Android Studio"
   ```

2. **Follow the Setup Wizard**:
   - Click "Next" through the welcome screen
   - Choose "Standard" installation
   - Accept licenses (click "Accept" for all SDK licenses)
   - Wait for SDK download (this may take 5-10 minutes)

## Step 2: Create Android Virtual Device (AVD)

1. **Open AVD Manager**:
   - In Android Studio, click **More Actions** → **Virtual Device Manager**
   - Or from top menu: **Tools** → **Device Manager**

2. **Create New Device**:
   - Click **Create Device**
   - Select a phone (recommended: **Pixel 8** or **Pixel 7**)
   - Click **Next**

3. **Download System Image**:
   - Select a system image (recommended: **API 34** - Android 14)
   - Click **Download** next to the system image
   - Wait for download to complete
   - Click **Next**

4. **Verify Configuration**:
   - Name: Keep default or name it "StackHabit_Test"
   - Click **Finish**

## Step 3: Start the Emulator

### Option A: From Android Studio
- In Device Manager, click the **Play** button (▶️) next to your device

### Option B: From Command Line
```bash
# List available emulators
flutter emulators

# Launch the emulator (use the name from the list)
flutter emulators --launch <emulator_id>
```

## Step 4: Run StackHabit App

Once the emulator is running:

```bash
# Navigate to project
cd /Users/keyur/Documents/Projects/Sample-flutter-app

# Check devices
flutter devices

# Run on Android
flutter run
```

Flutter will automatically detect the running emulator and deploy the app!

---

## Alternative: Quick Start Script

If Android Studio is already configured, use this one-liner:

```bash
# Start emulator and run app
flutter emulators --launch <emulator_id> && sleep 10 && flutter run
```

---

## Troubleshooting

### Issue: "Unable to find Android SDK"
**Solution**: Accept Android licenses
```bash
flutter doctor --android-licenses
```

### Issue: "No emulators available"
**Solution**: Create AVD through Android Studio Device Manager (see Step 2)

### Issue: "Emulator fails to start"
**Solution**: Ensure you have at least 8GB RAM and enable hardware acceleration:
```bash
# Check if hardware acceleration is available
sysctl -a | grep machdep.cpu.features
```

### Issue: App builds slowly
**Solution**: Enable multidex (already configured in our build.gradle)

---

## Expected Result

After setup, you should see:
- ✅ Android emulator running
- ✅ `flutter devices` shows your emulator
- ✅ `flutter run` deploys StackHabit to the emulator
- ✅ App launches with Flutter counter demo

---

## Next Steps After Setup

1. ✅ Verify emulator works
2. ✅ Run `flutter run` successfully
3. ➡️ Continue with Task 02: Design System Setup

---

**Need help?** The setup wizard in Android Studio is very user-friendly and will guide you through each step!
