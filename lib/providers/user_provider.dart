import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/user_service.dart';

// User Service Provider
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Current User Provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final userService = ref.read(userServiceProvider);
  return await userService.getCurrentUser();
});

// User State Notifier
class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final UserService _userService;

  UserNotifier(this._userService) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _userService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _userService.updateUser(user);
      state = AsyncValue.data(user);
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

// User State Provider
final userNotifierProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  final userService = ref.read(userServiceProvider);
  return UserNotifier(userService);
});
