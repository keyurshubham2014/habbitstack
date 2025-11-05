import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_stack.dart';
import '../services/habit_stack_service.dart';
import 'user_provider.dart';

// Habit Stack Service Provider
final habitStackServiceProvider = Provider<HabitStackService>((ref) {
  return HabitStackService();
});

// All Habit Stacks Provider
final habitStacksProvider = FutureProvider<List<HabitStack>>((ref) async {
  final stackService = ref.read(habitStackServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await stackService.getAllStacks(user.id!);
});

// Single Habit Stack with Habits Provider
final habitStackWithHabitsProvider =
    FutureProvider.family<HabitStack?, int>((ref, stackId) async {
  final stackService = ref.read(habitStackServiceProvider);
  return await stackService.getStackWithHabits(stackId);
});

// Habit Stacks Notifier
class HabitStacksNotifier extends StateNotifier<AsyncValue<List<HabitStack>>> {
  final HabitStackService _stackService;
  final int userId;

  HabitStacksNotifier(this._stackService, this.userId)
      : super(const AsyncValue.loading()) {
    _loadStacks();
  }

  Future<void> _loadStacks() async {
    state = const AsyncValue.loading();
    try {
      final stacks = await _stackService.getAllStacks(userId);
      state = AsyncValue.data(stacks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<int> createStack(HabitStack stack) async {
    try {
      final id = await _stackService.createStack(stack);
      await _loadStacks(); // Reload all stacks
      return id;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateStack(HabitStack stack) async {
    try {
      await _stackService.updateStack(stack);
      await _loadStacks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteStack(int stackId) async {
    try {
      await _stackService.deleteStack(stackId);
      await _loadStacks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addHabitToStack(int habitId, int stackId, int orderInStack) async {
    try {
      await _stackService.addHabitToStack(habitId, stackId, orderInStack);
      await _loadStacks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeHabitFromStack(int habitId) async {
    try {
      await _stackService.removeHabitFromStack(habitId);
      await _loadStacks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reorderHabits(List<int> habitIds) async {
    try {
      await _stackService.reorderHabits(habitIds);
      await _loadStacks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadStacks();
  }
}

// Habit Stacks State Provider
final habitStacksNotifierProvider =
    StateNotifierProvider<HabitStacksNotifier, AsyncValue<List<HabitStack>>>(
        (ref) {
  final stackService = ref.read(habitStackServiceProvider);
  // Use a fixed userId of 1 (the default user created during setup)
  // In a real app with auth, this would come from an auth provider
  return HabitStacksNotifier(stackService, 1);
});
