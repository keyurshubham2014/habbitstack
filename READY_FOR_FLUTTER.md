# Ready to Create StackHabit Flutter Project

## Step 1: Install Flutter

Follow the instructions in [SETUP_FLUTTER.md](SETUP_FLUTTER.md) to install Flutter.

**Quick install via Homebrew:**
```bash
brew install --cask flutter
flutter doctor
```

## Step 2: Create the Flutter Project

Once Flutter is installed, run these commands:

```bash
# Navigate to the parent directory
cd /Users/keyur/Documents/Projects

# Create the Flutter project
flutter create stackhabit

# Move into the project
cd stackhabit

# Verify it works
flutter run
```

This will create a new Flutter project with the default counter app.

## Step 3: Clean Up This Directory

After creating the Flutter project, you'll need to:

1. **Move the workflow files** from this directory to the new Flutter project:
```bash
# Copy .claude folder
cp -r /Users/keyur/Documents/Projects/Sample-flutter-app/.claude /Users/keyur/Documents/Projects/stackhabit/

# Copy tasks folder
cp -r /Users/keyur/Documents/Projects/Sample-flutter-app/tasks /Users/keyur/Documents/Projects/stackhabit/
```

2. **Or** we can work directly in this directory by running flutter create here:
```bash
cd /Users/keyur/Documents/Projects/Sample-flutter-app
flutter create .
```

## Recommended Approach

I recommend **Option 2** - create the Flutter project in the current directory:

```bash
# From /Users/keyur/Documents/Projects/Sample-flutter-app
flutter create --project-name stackhabit .
```

This will:
- Keep all our workflow files (.claude, tasks)
- Create the Flutter project structure around them
- Avoid moving files

## What Happens Next

After running `flutter create`, the directory will have:
```
Sample-flutter-app/
├── .claude/              # ✅ Already created
├── tasks/                # ✅ Already created
├── lib/                  # Flutter will create
├── android/              # Flutter will create
├── ios/                  # Flutter will create
├── test/                 # Flutter will create
├── pubspec.yaml          # Flutter will create
└── README.md             # Flutter will create
```

Then Claude Code can continue with:
- Updating pubspec.yaml with dependencies
- Creating the proper folder structure in lib/
- Setting up themes and constants

---

## Ready?

1. Install Flutter (see SETUP_FLUTTER.md)
2. Run: `flutter create --project-name stackhabit .`
3. Ask Claude Code to continue with Task 01!
