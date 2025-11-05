import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/cloud_user_service.dart';
import 'auth_provider.dart';

// User Service Provider - Hybrid Mode (Cloud when logged in, Local otherwise)
final userServiceProvider = Provider<dynamic>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  if (isLoggedIn) {
    return CloudUserService(); // ✅ Use cloud when authenticated
  }
  return UserService(); // ✅ Use local when offline
});

// Current User Provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final userService = ref.read(userServiceProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final authUser = ref.watch(currentAuthUserProvider);

  if (isLoggedIn && userService is CloudUserService && authUser != null) {
    // Cloud mode: Fetch from Supabase
    final cloudUser = await userService.getCurrentUser();
    if (cloudUser != null) {
      return _userFromCloudData(cloudUser);
    }
    return null;
  } else if (userService is UserService) {
    // Local mode: Fetch from SQLite
    return await userService.getCurrentUser();
  }

  return null;
});

// User State Notifier
class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final dynamic _userService;
  final bool _isLoggedIn;
  final String? _authUserId;

  UserNotifier(
    this._userService,
    this._isLoggedIn,
    this._authUserId,
  ) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    state = const AsyncValue.loading();
    try {
      if (_isLoggedIn && _userService is CloudUserService && _authUserId != null) {
        // Cloud mode
        final cloudUser = await _userService.getCurrentUser();
        if (cloudUser != null) {
          final user = _userFromCloudData(cloudUser);
          state = AsyncValue.data(user);
        } else {
          state = const AsyncValue.data(null);
        }
      } else if (_userService is UserService) {
        // Local mode
        final user = await _userService.getCurrentUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      if (_isLoggedIn && _userService is CloudUserService && _authUserId != null) {
        // Cloud mode - update via cloud service
        final updates = {
          'name': user.name,
          'email': user.email,
          'premium_status': user.premiumStatus,
        };
        await _userService.updateUser(_authUserId, updates);
        state = AsyncValue.data(user);
      } else if (_userService is UserService) {
        // Local mode
        await _userService.updateUser(user);
        state = AsyncValue.data(user);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> togglePremium() async {
    final currentUser = state.value;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        premiumStatus: !currentUser.premiumStatus,
      );
      await updateUser(updatedUser);
    }
  }

  Future<void> refresh() async {
    await _loadUser();
  }

  Future<void> clearUser() async {
    state = const AsyncValue.data(null);
  }
}

// User State Provider - Uses auth user ID when logged in
final userNotifierProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  final userService = ref.watch(userServiceProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final authUser = ref.watch(currentAuthUserProvider);

  return UserNotifier(
    userService,
    isLoggedIn,
    authUser?.id, // Supabase UUID
  );
});

// Helper function to convert cloud data to User model
User _userFromCloudData(Map<String, dynamic> data) {
  return User(
    id: data['id'].hashCode, // Convert UUID string to int hash
    name: data['name'] as String,
    email: data['email'] as String?,
    createdAt: DateTime.parse(data['created_at'] as String),
    premiumStatus: data['premium_status'] as bool? ?? false,
  );
}
