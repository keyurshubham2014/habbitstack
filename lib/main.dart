import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'services/migration_service.dart';
import 'providers/auth_provider.dart';
import 'widgets/common/main_navigation.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/migration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;

  // Initialize Supabase (do this BEFORE creating default user)
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Warning: Could not initialize Supabase: $e');
    debugPrint('App will run in local-only mode.');
  }

  // Initialize notification service (but don't request permissions yet)
  // Permissions will be requested just-in-time when user enables notifications
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }

  runApp(
    // Wrap entire app with ProviderScope for Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'StackHabit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const _AuthChecker(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/migration': (context) => const MigrationScreen(),
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}

/// Widget to check auth state and route accordingly
class _AuthChecker extends ConsumerStatefulWidget {
  const _AuthChecker();

  @override
  ConsumerState<_AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends ConsumerState<_AuthChecker> {
  bool _checkedMigration = false;
  bool _needsMigration = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        debugPrint('🔐 Auth state: session=${state.session != null ? "exists" : "null"}, user=${state.session?.user?.email ?? "none"}');

        // If user is logged in, check if migration is needed
        if (state.session != null) {
          debugPrint('✅ User logged in');

          // Check migration status (only once)
          if (!_checkedMigration) {
            _checkMigrationStatus(state.session!.user.id);
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Show migration screen if needed
          if (_needsMigration) {
            debugPrint('📦 Migration needed, showing MigrationScreen');
            return const MigrationScreen();
          }

          // Otherwise go to main app
          debugPrint('✅ No migration needed, showing MainNavigation');
          return const MainNavigation();
        }

        // Otherwise, go to welcome screen
        debugPrint('❌ No session, showing WelcomeScreen');
        return const WelcomeScreen();
      },
      loading: () {
        debugPrint('⏳ Auth state loading...');
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (err, stack) {
        debugPrint('❌ Auth state error: $err');
        // On error, show welcome screen to allow user to sign up/login
        return const WelcomeScreen();
      },
    );
  }

  Future<void> _checkMigrationStatus(String userId) async {
    try {
      final migrationService = MigrationService();
      final needsMigration = await migrationService.needsMigration(userId);

      if (mounted) {
        setState(() {
          _checkedMigration = true;
          _needsMigration = needsMigration;
        });
      }
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      if (mounted) {
        setState(() {
          _checkedMigration = true;
          _needsMigration = false; // Assume no migration on error
        });
      }
    }
  }
}
