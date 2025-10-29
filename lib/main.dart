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
