import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/cloud_habit_service.dart';
import 'user_provider.dart';
import 'auth_provider.dart';

// Habit Service Provider - Hybrid Mode (Cloud when logged in, Local otherwise)
final habitServiceProvider = Provider<dynamic>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  if (isLoggedIn) {
    return CloudHabitService(); // ✅ Use cloud when authenticated
  }
  return HabitService(); // ✅ Use local when offline
});

// All Habits Provider
final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final habitService = ref.read(habitServiceProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  if (isLoggedIn && habitService is CloudHabitService) {
    // Cloud mode: Fetch from Supabase
    final cloudHabits = await habitService.getHabits();
    return cloudHabits.map((data) => _habitFromCloudData(data)).toList();
  } else if (habitService is HabitService) {
    // Local mode: Fetch from SQLite
    return await habitService.getAllHabits(user.id!);
  }

  return [];
});

// Anchor Habits Provider
final anchorHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final habitService = ref.read(habitServiceProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  if (isLoggedIn && habitService is CloudHabitService) {
    // Cloud mode: Fetch and filter
    final cloudHabits = await habitService.getHabits();
    return cloudHabits
        .map((data) => _habitFromCloudData(data))
        .where((habit) => habit.isAnchor)
        .toList();
  } else if (habitService is HabitService) {
    // Local mode
    return await habitService.getAnchorHabits(user.id!);
  }

  return [];
});

// Habits Notifier
class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final dynamic _habitService;
  final bool _isLoggedIn;
  final String? _authUserId;
  final int? _localUserId;

  HabitsNotifier(
    this._habitService,
    this._isLoggedIn,
    this._authUserId,
    this._localUserId,
  ) : super(const AsyncValue.loading()) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    state = const AsyncValue.loading();
    try {
      if (_isLoggedIn && _habitService is CloudHabitService) {
        // Cloud mode
        final cloudHabits = await _habitService.getHabits();
        final habits = cloudHabits.map<Habit>((data) => _habitFromCloudData(data)).toList();
        state = AsyncValue.data(habits);
      } else if (_habitService is HabitService && _localUserId != null) {
        // Local mode
        final habits = await _habitService.getAllHabits(_localUserId!);
        state = AsyncValue.data(habits);
      } else {
        state = AsyncValue.data([]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addHabit(Habit habit) async {
    try {
      if (_isLoggedIn && _habitService is CloudHabitService) {
        // Cloud mode
        await _habitService.createHabit(habit);
      } else if (_habitService is HabitService) {
        // Local mode
        await _habitService.createHabit(habit);
      }
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      if (_isLoggedIn && _habitService is CloudHabitService) {
        // Cloud mode - need to convert Habit to update map
        final updates = {
          'name': habit.name,
          'icon': habit.icon,
          'color': habit.color,
          'is_anchor': habit.isAnchor,
          'frequency': habit.frequency,
          'custom_days': habit.customDays?.join(','),
          'stack_id': habit.stackId,
          'order_in_stack': habit.orderInStack,
          'is_active': habit.isActive,
        };
        // Note: Cloud habits use UUID string IDs
        await _habitService.updateHabit(habit.id.toString(), updates);
      } else if (_habitService is HabitService) {
        // Local mode
        await _habitService.updateHabit(habit);
      }
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteHabit(int habitId) async {
    try {
      if (_isLoggedIn && _habitService is CloudHabitService) {
        // Cloud mode
        await _habitService.deleteHabit(habitId.toString());
      } else if (_habitService is HabitService) {
        // Local mode
        await _habitService.deleteHabit(habitId);
      }
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleAnchor(int habitId, bool isAnchor) async {
    try {
      if (_isLoggedIn && _habitService is CloudHabitService) {
        // Cloud mode
        await _habitService.updateHabit(
          habitId.toString(),
          {'is_anchor': isAnchor},
        );
      } else if (_habitService is HabitService) {
        // Local mode
        await _habitService.markAsAnchor(habitId, isAnchor);
      }
      await _loadHabits();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadHabits();
  }
}

// Habits State Provider - Uses auth user ID when logged in
final habitsNotifierProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>((ref) {
  final habitService = ref.watch(habitServiceProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final authUser = ref.watch(currentAuthUserProvider);
  final localUser = ref.watch(currentUserProvider).value;

  return HabitsNotifier(
    habitService,
    isLoggedIn,
    authUser?.id, // Supabase UUID
    localUser?.id, // Local integer ID
  );
});

// Helper function to convert cloud data to Habit model
Habit _habitFromCloudData(Map<String, dynamic> data) {
  return Habit(
    id: data['id'].hashCode, // Convert UUID string to int hash
    userId: data['user_id'].hashCode, // Convert UUID string to int hash
    name: data['name'] as String,
    icon: data['icon'] as String?,
    color: data['color'] as String?,
    isAnchor: data['is_anchor'] as bool? ?? false,
    frequency: data['frequency'] as String? ?? 'daily',
    customDays: data['custom_days'] != null
        ? (data['custom_days'] as String).split(',').map((e) => int.parse(e.trim())).toList()
        : null,
    gracePeriodDays: 2, // Default, can parse from grace_period_config if needed
    stackId: data['stack_id'] as int?,
    orderInStack: data['order_in_stack'] as int?,
    isActive: data['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(data['created_at'] as String),
  );
}
