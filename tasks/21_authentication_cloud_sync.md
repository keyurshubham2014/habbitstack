# Task 21: User Authentication & Cloud Sync

**Status**: TODO (Phase 2)
**Priority**: HIGH (for Phase 2)
**Estimated Time**: 2 weeks
**Assigned To**: TBD
**Dependencies**:
- Task 20 (User Testing Complete)
- MVP Launch Successful
- User feedback collected

---

## Objective

Implement user authentication and cloud synchronization to enable:
- Multi-device access to habit data
- Account-based features (premium subscriptions)
- Social features (accountability partners)
- Data backup and recovery
- Cross-platform sync (iOS ↔ Android ↔ Web)

---

## Why This Task Exists

**Current State (MVP)**:
- ✅ Single-user, local-only (SQLite)
- ✅ All data stored on device
- ✅ No authentication required
- ❌ Data lost if app deleted
- ❌ Can't sync across devices
- ❌ Can't implement premium features
- ❌ No social/sharing features

**After This Task**:
- ✅ Multi-user support with accounts
- ✅ Cloud sync across all devices
- ✅ Data persists even if app deleted
- ✅ Ready for premium subscriptions
- ✅ Ready for social features
- ✅ Offline-first with background sync

---

## Technical Approach

### Option A: Firebase (Recommended for Speed)

**Pros**:
- Fast setup (< 1 week)
- All-in-one solution (Auth + Database + Storage)
- Built-in email/password and social login
- Real-time sync out of the box
- Good Flutter packages (firebase_auth, cloud_firestore)
- Generous free tier

**Cons**:
- Vendor lock-in (Google)
- Pricing can scale quickly
- Less control over backend

**Cost Estimate**:
- Free tier: Up to 50K reads/day, 20K writes/day
- Blaze plan: ~$5-25/month for 1000 users

### Option B: Supabase (Recommended for Control)

**Pros**:
- Open source (self-hostable)
- PostgreSQL backend (more flexible than Firestore)
- Built-in Auth with JWT
- Real-time subscriptions
- Generous free tier
- Better for complex queries

**Cons**:
- Slightly more setup work
- Fewer Flutter examples
- Real-time features less mature than Firebase

**Cost Estimate**:
- Free tier: Up to 500MB database, 2GB bandwidth
- Pro plan: $25/month for larger scale

### Recommendation: Start with Supabase

**Why**:
1. More control over data structure
2. Better for complex habit/streak queries
3. Open source = no lock-in
4. PostgreSQL = familiar SQL
5. Can self-host if needed later

---

## Acceptance Criteria

### Phase 2.1: Authentication (Week 1)
- [ ] Email/password signup with validation
- [ ] Email verification required before access
- [ ] Login with email/password
- [ ] Password reset flow (email link)
- [ ] Social login: Sign in with Google
- [ ] Social login: Sign in with Apple (iOS requirement)
- [ ] Logout functionality
- [ ] Account deletion with data export
- [ ] Error handling for all auth scenarios
- [ ] Loading states during auth operations

### Phase 2.2: Data Migration (Week 1)
- [ ] Export local SQLite data to JSON
- [ ] Import JSON data to cloud on first login
- [ ] Merge conflicts (local vs cloud data)
- [ ] Keep local backup for offline access
- [ ] Migration progress indicator
- [ ] Rollback mechanism if migration fails

### Phase 2.3: Cloud Sync (Week 2)
- [ ] Sync habits to cloud
- [ ] Sync daily logs to cloud
- [ ] Sync habit stacks to cloud
- [ ] Sync streaks to cloud
- [ ] Sync settings to cloud
- [ ] Real-time sync when online
- [ ] Offline queue for changes when offline
- [ ] Background sync when app in background
- [ ] Conflict resolution (last-write-wins or manual)
- [ ] Sync status indicator in UI

### Phase 2.4: Multi-Device Support (Week 2)
- [ ] Changes on Device A appear on Device B
- [ ] Handle concurrent edits gracefully
- [ ] Sync on app launch
- [ ] Sync on app resume (background → foreground)
- [ ] Sync on network reconnect
- [ ] Show "Syncing..." indicator during sync

---

## Step-by-Step Implementation

### Week 1: Authentication Setup

#### Day 1-2: Supabase Project Setup

**1. Create Supabase Project**
```bash
# Create account at https://supabase.com
# Create new project: "stackhabit-prod"
# Save these credentials:
# - Project URL
# - Anon Key
# - Service Role Key (keep secret!)
```

**2. Add Dependencies**
```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.3.0
  flutter_secure_storage: ^9.0.0  # Store auth tokens securely
```

**3. Initialize Supabase**
```dart
// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  late final SupabaseClient client;

  SupabaseService._init();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
    client = Supabase.instance.client;
  }
}
```

**4. Update main.dart**
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before app starts
  await SupabaseService.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

#### Day 3-4: Build Auth UI

**5. Create Auth Screens**

Create 4 new screens:
1. `lib/screens/auth/welcome_screen.dart` - Landing page with "Sign Up" and "Login" buttons
2. `lib/screens/auth/signup_screen.dart` - Email/password signup
3. `lib/screens/auth/login_screen.dart` - Email/password login
4. `lib/screens/auth/forgot_password_screen.dart` - Password reset

**6. Create Auth Service**
```dart
// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  // Check if user is logged in
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Email/Password Signup
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name}, // Store name in user metadata
    );
  }

  // Email/Password Login
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  // Apple Sign In (iOS)
  Future<bool> signInWithApple() async {
    return await _supabase.auth.signInWithOAuth(OAuthProvider.apple);
  }

  // Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    // Delete all user data from cloud
    await _supabase.from('users').delete().eq('id', userId);

    // Logout
    await logout();
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
```

**7. Create Auth Provider**
```dart
// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session != null,
    loading: () => false,
    error: (_, __) => false,
  );
});
```

**8. Update App Routing**
```dart
// lib/main.dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return MaterialApp(
      home: isLoggedIn
          ? const MainNavigation() // Existing app
          : const WelcomeScreen(),  // New auth flow
    );
  }
}
```

#### Day 5: Database Schema Setup

**9. Create Supabase Tables**

Run these SQL commands in Supabase SQL Editor:

```sql
-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_stacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;

-- Users table (linked to auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  premium_status BOOLEAN DEFAULT FALSE,
  premium_expires_at TIMESTAMPTZ
);

-- Habits table
CREATE TABLE habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  is_anchor BOOLEAN DEFAULT FALSE,
  frequency TEXT NOT NULL,
  custom_days TEXT,
  grace_period_config TEXT,
  stack_id UUID,
  order_in_stack INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habit Stacks table
CREATE TABLE habit_stacks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  anchor_habit_id UUID,
  color TEXT,
  icon TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily Logs table
CREATE TABLE daily_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ NOT NULL,
  notes TEXT,
  sentiment TEXT,
  tags TEXT[],  -- Array of tags (better than comma-separated)
  voice_note_path TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Streaks table
CREATE TABLE streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_logged_date DATE,
  grace_period_active BOOLEAN DEFAULT FALSE,
  grace_strikes_used INTEGER DEFAULT 0,
  status TEXT DEFAULT 'perfect',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_habits_user_id ON habits(user_id);
CREATE INDEX idx_daily_logs_user_id ON daily_logs(user_id);
CREATE INDEX idx_daily_logs_habit_id ON daily_logs(habit_id);
CREATE INDEX idx_daily_logs_completed_at ON daily_logs(completed_at);
CREATE INDEX idx_streaks_user_id ON streaks(user_id);
CREATE INDEX idx_streaks_habit_id ON streaks(habit_id);

-- Row Level Security Policies (users can only access their own data)
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own habits" ON habits
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own habits" ON habits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own habits" ON habits
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own habits" ON habits
  FOR DELETE USING (auth.uid() = user_id);

-- Repeat for habit_stacks, daily_logs, streaks
-- (similar policies for all tables)
```

#### Day 6-7: Data Migration

**10. Create Migration Service**
```dart
// lib/services/migration_service.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class MigrationService {
  final DatabaseService _localDb = DatabaseService.instance;
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Export all local data to JSON
  Future<Map<String, dynamic>> exportLocalData(int localUserId) async {
    final habits = await _localDb.query('habits', where: 'user_id = ?', whereArgs: [localUserId]);
    final stacks = await _localDb.query('habit_stacks', where: 'user_id = ?', whereArgs: [localUserId]);
    final logs = await _localDb.query('daily_logs', where: 'user_id = ?', whereArgs: [localUserId]);
    final streaks = await _localDb.query('streaks', where: 'user_id = ?', whereArgs: [localUserId]);

    return {
      'habits': habits,
      'habit_stacks': stacks,
      'daily_logs': logs,
      'streaks': streaks,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Import local data to cloud
  Future<void> migrateToCloud() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    try {
      // 1. Export local data
      final localData = await exportLocalData(1); // Local user always has ID 1

      // 2. Create user record in cloud
      await _supabase.from('users').insert({
        'id': userId,
        'name': 'Migrated User',
        'email': _supabase.auth.currentUser!.email,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 3. Migrate habits
      for (final habit in localData['habits'] as List) {
        await _supabase.from('habits').insert({
          ...habit,
          'user_id': userId, // Replace local user ID with cloud user ID
          'id': null, // Let Supabase generate new UUID
        });
      }

      // 4. Migrate stacks
      for (final stack in localData['habit_stacks'] as List) {
        await _supabase.from('habit_stacks').insert({
          ...stack,
          'user_id': userId,
          'id': null,
        });
      }

      // 5. Migrate logs
      for (final log in localData['daily_logs'] as List) {
        await _supabase.from('daily_logs').insert({
          ...log,
          'user_id': userId,
          'id': null,
        });
      }

      // 6. Migrate streaks
      for (final streak in localData['streaks'] as List) {
        await _supabase.from('streaks').insert({
          ...streak,
          'user_id': userId,
          'id': null,
        });
      }

      // 7. Mark migration as complete (store in SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('migration_complete', true);

    } catch (e) {
      // Rollback on error
      throw Exception('Migration failed: $e');
    }
  }

  /// Check if migration is needed
  Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationComplete = prefs.getBool('migration_complete') ?? false;

    // Check if local data exists
    final localHabits = await _localDb.query('habits');

    return !migrationComplete && localHabits.isNotEmpty;
  }
}
```

**11. Create Migration Screen**
```dart
// lib/screens/auth/migration_screen.dart
class MigrationScreen extends StatefulWidget {
  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isMigrating = false;
  double _progress = 0.0;
  String _status = 'Preparing migration...';

  Future<void> _startMigration() async {
    setState(() {
      _isMigrating = true;
      _status = 'Exporting local data...';
    });

    try {
      final migrationService = MigrationService();

      setState(() {
        _progress = 0.2;
        _status = 'Migrating habits...';
      });

      await migrationService.migrateToCloud();

      setState(() {
        _progress = 1.0;
        _status = 'Migration complete!';
      });

      // Navigate to main app
      await Future.delayed(Duration(seconds: 1));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainNavigation()),
      );

    } catch (e) {
      setState(() {
        _isMigrating = false;
        _status = 'Migration failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome!', style: AppTextStyles.headline()),
              SizedBox(height: 16),
              Text(
                'We found existing data on this device. Would you like to sync it to your account?',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              LinearProgressIndicator(value: _progress),
              SizedBox(height: 16),
              Text(_status),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isMigrating ? null : _startMigration,
                child: Text('Sync My Data'),
              ),
              TextButton(
                onPressed: _isMigrating ? null : () {
                  // Skip migration, start fresh
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => MainNavigation()),
                  );
                },
                child: Text('Start Fresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Week 2: Cloud Sync Implementation

#### Day 8-10: Update Services for Cloud

**12. Create Cloud Habit Service**
```dart
// lib/services/cloud_habit_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudHabitService {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  Future<List<Habit>> getAllHabits() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    final response = await _supabase
        .from('habits')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Habit.fromJson(json)).toList();
  }

  Future<void> createHabit(Habit habit) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _supabase.from('habits').insert({
      ...habit.toJson(),
      'user_id': userId,
    });
  }

  Future<void> updateHabit(Habit habit) async {
    await _supabase
        .from('habits')
        .update(habit.toJson())
        .eq('id', habit.id!);
  }

  Future<void> deleteHabit(String habitId) async {
    await _supabase.from('habits').delete().eq('id', habitId);
  }

  // Real-time subscription
  Stream<List<Habit>> watchHabits() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    return _supabase
        .from('habits')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => Habit.fromJson(json)).toList());
  }
}
```

**13. Update Habit Provider for Hybrid Mode**
```dart
// lib/providers/habits_provider.dart
final habitsNotifierProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>((ref) {
  return HabitsNotifier(ref);
});

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final Ref _ref;
  final CloudHabitService _cloudService = CloudHabitService();
  final HabitService _localService = HabitService();

  HabitsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final isLoggedIn = _ref.read(isLoggedInProvider);

      if (isLoggedIn) {
        // Use cloud service
        final habits = await _cloudService.getAllHabits();
        state = AsyncValue.data(habits);
      } else {
        // Use local service
        final habits = await _localService.getAllHabits(1); // Local user
        state = AsyncValue.data(habits);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addHabit(Habit habit) async {
    final isLoggedIn = _ref.read(isLoggedInProvider);

    if (isLoggedIn) {
      await _cloudService.createHabit(habit);
    } else {
      await _localService.createHabit(habit);
    }

    await refresh();
  }

  // Similar updates for updateHabit, deleteHabit, etc.
}
```

#### Day 11-12: Offline Queue & Sync

**14. Create Sync Service**
```dart
// lib/services/sync_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  final SupabaseClient _supabase = SupabaseService.instance.client;
  final DatabaseService _localDb = DatabaseService.instance;

  bool _isSyncing = false;

  /// Queue for offline changes
  Future<void> queueOfflineChange({
    required String table,
    required String operation, // 'insert', 'update', 'delete'
    required Map<String, dynamic> data,
  }) async {
    // Store in local 'sync_queue' table
    await _localDb.insert('sync_queue', {
      'table': table,
      'operation': operation,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Process offline queue when back online
  Future<void> processOfflineQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = await _localDb.query('sync_queue', orderBy: 'created_at ASC');

      for (final item in queue) {
        final table = item['table'] as String;
        final operation = item['operation'] as String;
        final data = jsonDecode(item['data'] as String);

        switch (operation) {
          case 'insert':
            await _supabase.from(table).insert(data);
            break;
          case 'update':
            await _supabase.from(table).update(data).eq('id', data['id']);
            break;
          case 'delete':
            await _supabase.from(table).delete().eq('id', data['id']);
            break;
        }

        // Remove from queue after successful sync
        await _localDb.delete('sync_queue', where: 'id = ?', whereArgs: [item['id']]);
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Listen for connectivity changes
  void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // Back online - process queue
        processOfflineQueue();
      }
    });
  }

  /// Manual sync trigger
  Future<void> syncNow() async {
    final isOnline = await _checkConnectivity();
    if (!isOnline) throw Exception('No internet connection');

    await processOfflineQueue();
  }

  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

#### Day 13-14: Testing & Polish

**15. Add Sync Status UI**
```dart
// lib/widgets/common/sync_status_indicator.dart
class SyncStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(syncStatusProvider);

    if (!isSyncing) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gentleTeal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Syncing...', style: AppTextStyles.caption()),
        ],
      ),
    );
  }
}
```

**16. Update AppBar to Show Sync Status**
```dart
// lib/screens/home/todays_log_screen.dart
appBar: AppBar(
  title: Text('Today\'s Log'),
  actions: [
    SyncStatusIndicator(), // Add this
    IconButton(
      icon: Icon(Icons.search),
      onPressed: () => showSearch(...),
    ),
    IconButton(
      icon: Icon(Icons.calendar_today),
      onPressed: () {},
    ),
  ],
),
```

---

## Additional Features

### Social Login Setup

**Google Sign In**:
1. Create Google Cloud project
2. Enable Google Sign-In in Supabase dashboard
3. Add OAuth redirect URLs
4. Test on iOS and Android

**Apple Sign In** (Required for iOS):
1. Enable Apple Sign-In in Apple Developer account
2. Configure in Supabase
3. Test on iOS device (simulator won't work)

### Account Management

**Settings Screen Updates**:
```dart
// Add to lib/screens/settings/settings_screen.dart

// Account section
ListTile(
  leading: Icon(Icons.person),
  title: Text('Account'),
  subtitle: Text(user.email),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AccountSettingsScreen()),
  ),
),

ListTile(
  leading: Icon(Icons.sync),
  title: Text('Sync Status'),
  subtitle: Text('Last synced: 2 minutes ago'),
  trailing: IconButton(
    icon: Icon(Icons.refresh),
    onPressed: () => ref.read(syncServiceProvider).syncNow(),
  ),
),

ListTile(
  leading: Icon(Icons.cloud_download),
  title: Text('Export Data'),
  subtitle: Text('Download a copy of your data'),
  onTap: () => _exportData(),
),

ListTile(
  leading: Icon(Icons.logout, color: AppColors.softRed),
  title: Text('Logout', style: TextStyle(color: AppColors.softRed)),
  onTap: () => _showLogoutDialog(),
),

ListTile(
  leading: Icon(Icons.delete_forever, color: AppColors.softRed),
  title: Text('Delete Account', style: TextStyle(color: AppColors.softRed)),
  subtitle: Text('Permanent - cannot be undone'),
  onTap: () => _showDeleteAccountDialog(),
),
```

---

## Testing Checklist

### Authentication
- [ ] Sign up with email/password works
- [ ] Email verification email received
- [ ] Cannot login without verifying email
- [ ] Login with verified email works
- [ ] Logout works (clears session)
- [ ] Password reset email received
- [ ] Password reset link works
- [ ] Google Sign In works (iOS & Android)
- [ ] Apple Sign In works (iOS only)
- [ ] Error messages clear and helpful
- [ ] Loading states show during auth

### Data Migration
- [ ] Migration detects existing local data
- [ ] Migration screen offers "Sync" or "Start Fresh"
- [ ] Migration uploads all habits correctly
- [ ] Migration uploads all logs correctly
- [ ] Migration uploads all stacks correctly
- [ ] Migration uploads all streaks correctly
- [ ] Progress indicator updates during migration
- [ ] Migration completes successfully
- [ ] Local data remains after migration (backup)
- [ ] Migration doesn't run twice

### Cloud Sync
- [ ] New habit created on Device A appears on Device B
- [ ] Edit habit on Device A updates on Device B
- [ ] Delete habit on Device A removes from Device B
- [ ] Log activity on Device A appears on Device B
- [ ] Sync works for all data types (habits, logs, stacks, streaks)
- [ ] Sync indicator shows when syncing
- [ ] "Last synced" timestamp updates correctly

### Offline Mode
- [ ] Can create habits offline
- [ ] Can log activities offline
- [ ] Changes queued when offline
- [ ] Queue processes when back online
- [ ] No data loss during offline → online transition
- [ ] Conflict resolution works (last-write-wins)
- [ ] App doesn't crash when offline

### Multi-Device
- [ ] Login on Device A, see data
- [ ] Login on Device B (same account), see same data
- [ ] Changes on Device A appear on Device B within 5 seconds
- [ ] Concurrent edits don't cause crashes
- [ ] Logout on Device A doesn't affect Device B

---

## Migration Strategy for Users

### Communication Plan

**Week Before Launch**:
- Email all existing users
- In-app banner: "Cloud sync coming soon!"
- Explain benefits (multi-device, backup)
- Assure them data will be preserved

**Launch Day**:
- Update app with auth flow
- Existing users see migration screen on first launch
- New users see signup flow
- Clear instructions at each step

**Post-Launch**:
- Monitor migration success rate
- Support team ready for migration issues
- Provide manual migration instructions if needed

---

## Security Considerations

### Data Protection
- [ ] All API calls use HTTPS
- [ ] Auth tokens stored in secure storage (flutter_secure_storage)
- [ ] Row Level Security (RLS) enabled on all tables
- [ ] Users can only access their own data
- [ ] Password strength requirements enforced
- [ ] Rate limiting on auth endpoints

### Privacy
- [ ] Privacy policy updated for cloud storage
- [ ] Terms of service include cloud sync
- [ ] Users can export all data before deleting account
- [ ] Account deletion removes all cloud data within 30 days

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Auth response time | < 2 seconds |
| Migration time (1000 logs) | < 30 seconds |
| Sync time (10 changes) | < 5 seconds |
| Real-time update latency | < 2 seconds |
| Offline queue processing | < 10 seconds |

---

## Rollback Plan

If cloud sync causes major issues:

1. **Emergency Rollback**:
   - Release hotfix removing cloud sync
   - Users fall back to local-only mode
   - Existing cloud data preserved

2. **Data Recovery**:
   - Local SQLite backup always kept
   - Users can export cloud data anytime
   - Support team can manually migrate data

3. **Communication**:
   - Immediate in-app alert
   - Email to affected users
   - Status page updates

---

## Cost Estimate

### Supabase Costs (per month)

**Free Tier** (first 6 months):
- Up to 500MB database
- Up to 1GB file storage
- Up to 2GB bandwidth
- **Cost**: $0

**Pro Tier** (after growth):
- 8GB database
- 100GB file storage
- 250GB bandwidth
- **Cost**: $25/month

**Estimate for 1000 active users**:
- ~50MB per user = 50GB database
- Requires Pro + additional storage
- **Estimated cost**: $50-100/month

---

## Dependencies

### New Packages
```yaml
dependencies:
  supabase_flutter: ^2.3.0
  flutter_secure_storage: ^9.0.0
  connectivity_plus: ^5.0.2  # Check network status

dev_dependencies:
  supabase_test_helpers: ^0.1.0  # For testing
```

---

## Success Criteria

**Must Have**:
- [ ] 95%+ migration success rate
- [ ] < 5 second sync time for typical operations
- [ ] Zero data loss during migration
- [ ] Works offline (queues changes)
- [ ] Real-time sync across devices (< 5 second latency)

**Nice to Have**:
- [ ] 99%+ migration success rate
- [ ] < 2 second sync time
- [ ] Conflict resolution UI (manual merge)
- [ ] Sync history/audit log

---

## Documentation Needed

After completion:
- [ ] User guide: "How to sync your data"
- [ ] Developer docs: Cloud sync architecture
- [ ] Troubleshooting guide: Common sync issues
- [ ] API documentation: Supabase schema
- [ ] Privacy policy update
- [ ] Terms of service update

---

## Future Enhancements (Phase 3)

These are NOT part of this task, but future considerations:

- [ ] End-to-end encryption (E2EE)
- [ ] Selective sync (choose which data to sync)
- [ ] Family sharing (multiple users in one household)
- [ ] Export to Google Drive / Dropbox
- [ ] Webhook integrations (Zapier, IFTTT)
- [ ] Public API for third-party apps
- [ ] Self-hosting option for privacy-conscious users

---

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Migration fails for some users | High | Medium | Thorough testing, rollback plan, local backup |
| Sync conflicts cause data loss | High | Low | Last-write-wins, conflict detection, manual resolution |
| Cloud costs exceed budget | Medium | Medium | Monitor usage, optimize queries, implement rate limiting |
| Supabase outage | High | Low | Offline-first design, local backup, status page |
| Auth token leaked | High | Low | Secure storage, short expiry, refresh tokens |

---

## Timeline

**Week 1**: Authentication & Migration
- Days 1-2: Supabase setup
- Days 3-4: Auth UI and service
- Days 5-7: Data migration

**Week 2**: Cloud Sync & Testing
- Days 8-10: Cloud service layer
- Days 11-12: Offline queue & sync
- Days 13-14: Testing & polish

**Total**: 2 weeks for full implementation

---

## Next Steps After This Task

Once auth & cloud sync are complete:

1. **Task 22**: Premium Subscriptions (in-app purchases)
2. **Task 23**: Social Features (accountability partners)
3. **Task 24**: AI Insights (Openrouter API integration)
4. **Task 25**: Analytics Dashboard

---

## Notes

- This task is **foundational** for all Phase 2 features
- Cannot implement premium features without auth
- Cannot implement social features without cloud sync
- Local-only mode will still work if user doesn't sign up
- Migration is **one-time** and **non-destructive** (keeps local backup)

---

**Last Updated**: 2025-11-05
**Status**: TODO (Phase 2)
**Estimated Completion**: 2 weeks after Phase 2 starts
