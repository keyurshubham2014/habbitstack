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
