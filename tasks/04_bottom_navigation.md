# Task 04: Bottom Navigation Setup

**Status**: TODO
**Priority**: HIGH
**Estimated Time**: 2 hours
**Assigned To**: TBD
**Dependencies**: Task 02

---

## Objective

Implement the main bottom navigation bar with 5 tabs and create placeholder screens for each section.

## Acceptance Criteria

- [ ] Bottom navigation bar with 5 tabs implemented
- [ ] Tab switching works smoothly
- [ ] Active tab highlighted with coral color
- [ ] Placeholder screen created for each tab
- [ ] Icons match PRD specifications
- [ ] Navigation state persists when switching tabs

---

## Step-by-Step Instructions

### 1. Create Placeholder Screens

#### `lib/screens/home/todays_log_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class TodaysLogScreen extends StatelessWidget {
  const TodaysLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Log'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 80,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'Log Your Activities',
              style: AppTextStyles.title(),
            ),
            SizedBox(height: 8),
            Text(
              'Track what you accomplish each day',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Will implement in Task 06
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

#### `lib/screens/streaks/streaks_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class StreaksScreen extends StatelessWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Streaks'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 80,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'Track Your Progress',
              style: AppTextStyles.title(),
            ),
            SizedBox(height: 8),
            Text(
              'View your habit streaks and achievements',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### `lib/screens/build_stack/build_stack_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class BuildStackScreen extends StatelessWidget {
  const BuildStackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Build Stack'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link,
              size: 80,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'Create Habit Stacks',
              style: AppTextStyles.title(),
            ),
            SizedBox(height: 8),
            Text(
              'Link new habits to existing anchors',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Will implement in Task 09
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

#### `lib/screens/accountability/accountability_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class AccountabilityScreen extends StatelessWidget {
  const AccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accountability'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 80,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 16),
            Text(
              'Stay Accountable',
              style: AppTextStyles.title(),
            ),
            SizedBox(height: 8),
            Text(
              'Connect with accountability partners',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### `lib/screens/settings/settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person, color: AppColors.deepBlue),
            title: Text('Profile', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications, color: AppColors.deepBlue),
            title: Text('Notifications', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.timer, color: AppColors.deepBlue),
            title: Text('Grace Periods', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.workspace_premium, color: AppColors.warningAmber),
            title: Text('Upgrade to Premium', style: AppTextStyles.body()),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
```

### 2. Create Main Navigation Widget

#### `lib/widgets/common/main_navigation.dart`

```dart
import 'package:flutter/material.dart';
import '../../screens/home/todays_log_screen.dart';
import '../../screens/streaks/streaks_screen.dart';
import '../../screens/build_stack/build_stack_screen.dart';
import '../../screens/accountability/accountability_screen.dart';
import '../../screens/settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    TodaysLogScreen(),
    StreaksScreen(),
    BuildStackScreen(),
    AccountabilityScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Streaks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link),
            label: 'Build',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Partners',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

### 3. Update Main.dart

```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'services/user_service.dart';
import 'widgets/common/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;

  // Ensure default user exists
  await UserService().getCurrentUser();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackHabit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: MainNavigation(),
    );
  }
}
```

### 4. Add Navigation Animations (Optional Enhancement)

#### `lib/widgets/common/animated_navigation.dart`

```dart
import 'package:flutter/material.dart';
import '../../screens/home/todays_log_screen.dart';
import '../../screens/streaks/streaks_screen.dart';
import '../../screens/build_stack/build_stack_screen.dart';
import '../../screens/accountability/accountability_screen.dart';
import '../../screens/settings/settings_screen.dart';

class AnimatedNavigation extends StatefulWidget {
  const AnimatedNavigation({super.key});

  @override
  State<AnimatedNavigation> createState() => _AnimatedNavigationState();
}

class _AnimatedNavigationState extends State<AnimatedNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    TodaysLogScreen(),
    StreaksScreen(),
    BuildStackScreen(),
    AccountabilityScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Streaks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link),
            label: 'Build',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Partners',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

To use animated version, replace `MainNavigation()` with `AnimatedNavigation()` in `main.dart`.

---

## Verification Checklist

- [ ] All 5 screens created and accessible
- [ ] Bottom navigation bar displays correctly
- [ ] Can switch between tabs smoothly
- [ ] Active tab highlighted in coral color
- [ ] Screen state preserved when switching tabs
- [ ] FAB appears on appropriate screens (Today & Build)
- [ ] No visual glitches or jank

---

## Testing Steps

1. Run the app:
```bash
flutter run
```

2. Test each tab:
   - Tap "Today" - should show log screen with FAB
   - Tap "Streaks" - should show streaks screen
   - Tap "Build" - should show stack builder with FAB
   - Tap "Partners" - should show accountability screen
   - Tap "Settings" - should show settings list

3. Verify tab switching:
   - Switch between tabs multiple times
   - Ensure smooth transitions
   - Check that active tab is highlighted

4. Test on both iOS and Android:
   - iOS: Bottom bar should match iOS design guidelines
   - Android: Bottom bar should match Material Design

---

## Common Issues & Solutions

### Issue: Tab bar doesn't show icons
**Solution**: Ensure icons are from `Icons` class, not custom assets

### Issue: Active color not showing
**Solution**: Check `AppTheme` bottomNavigationBarTheme has `selectedItemColor` set

### Issue: Screen doesn't update when switching tabs
**Solution**: Use `IndexedStack` instead of regular `Stack` to preserve state

---

## Next Task

After completion, proceed to: [05_state_management.md](./05_state_management.md)

---

## Notes

- Using `IndexedStack` preserves screen state when switching tabs
- For smoother animations, consider using `AnimatedNavigation` widget
- FAB only appears on screens that need it (Today's Log and Build Stack)

**Last Updated**: 2025-10-29
