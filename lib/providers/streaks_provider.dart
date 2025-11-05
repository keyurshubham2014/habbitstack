import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/streak.dart';
import '../services/streak_calculator.dart';
import 'user_provider.dart';

// Streak Calculator Service Provider
final streakCalculatorProvider = Provider<StreakCalculator>((ref) {
  return StreakCalculator();
});

// Streaks State Notifier
class StreaksNotifier extends StateNotifier<AsyncValue<List<Streak>>> {
  final StreakCalculator _calculator;
  final int userId;

  StreaksNotifier(this._calculator, this.userId) : super(const AsyncValue.loading()) {
    loadStreaks();
  }

  Future<void> loadStreaks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _calculator.getAllStreaks(userId);
    });
  }

  Future<void> refresh() async {
    await loadStreaks();
  }

  Future<void> recalculateAll() async {
    await _calculator.recalculateAllStreaks(userId);
    await loadStreaks();
  }
}

// Streaks Provider
final streaksNotifierProvider =
    StateNotifierProvider.family<StreaksNotifier, AsyncValue<List<Streak>>, int>(
  (ref, userId) {
    final calculator = ref.watch(streakCalculatorProvider);
    return StreaksNotifier(calculator, userId);
  },
);

// Current User Streaks Provider (simplified version - no infinite loop)
final currentUserStreaksProvider = FutureProvider<List<Streak>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return [];
  }

  final calculator = ref.read(streakCalculatorProvider);
  return await calculator.getAllStreaks(user.id!);
});
