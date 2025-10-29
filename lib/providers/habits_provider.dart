import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import 'user_provider.dart';

// Habit Service Provider
final habitServiceProvider = Provider<HabitService>((ref) {
  return HabitService();
});

// All Habits Provider
final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final habitService = ref.read(habitServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await habitService.getAllHabits(user.id!);
});

// Anchor Habits Provider
final anchorHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final habitService = ref.read(habitServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await habitService.getAnchorHabits(user.id!);
});

// Habits Notifier
class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final HabitService _habitService;
  final int userId;

  HabitsNotifier(this._habitService, this.userId) : super(const AsyncValue.loading()) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    state = const AsyncValue.loading();
    try {
      final habits = await _habitService.getAllHabits(userId);
      state = AsyncValue.data(habits);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addHabit(Habit habit) async {
    try {
      await _habitService.createHabit(habit);
      await _loadHabits(); // Reload all habits
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      await _habitService.updateHabit(habit);
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteHabit(int habitId) async {
    try {
      await _habitService.deleteHabit(habitId);
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleAnchor(int habitId, bool isAnchor) async {
    try {
      await _habitService.markAsAnchor(habitId, isAnchor);
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadHabits();
  }
}

// Habits State Provider
final habitsNotifierProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>((ref) {
  final habitService = ref.read(habitServiceProvider);

  // Watch the user provider to get userId
  final userAsync = ref.watch(userNotifierProvider);

  // Extract userId from AsyncValue
  final userId = userAsync.when(
    data: (user) => user?.id ?? 1, // Default to user 1 (created during setup)
    loading: () => 1,
    error: (_, __) => 1,
  );

  return HabitsNotifier(habitService, userId);
});
