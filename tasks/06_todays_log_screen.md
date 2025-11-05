# Task 06: Today's Log Screen

**Status**: DONE
**Priority**: HIGH
**Estimated Time**: 4 hours
**Assigned To**: Claude
**Dependencies**: Task 05 (State Management Setup)
**Completed**: 2025-11-05

---

## Objective

Build the daily activity logging screen where users can reverse-log their completed habits without pre-commitment pressure.

## Acceptance Criteria

- [ ] Today's Log screen displays all habits logged for today
- [ ] "Add Activity" button opens a modal/sheet to log new activities
- [ ] Users can log existing habits or create new ones on-the-fly
- [ ] Each log entry shows habit name, time, and optional notes
- [ ] Users can edit/delete today's log entries
- [ ] Empty state shows encouraging message
- [ ] Pull-to-refresh functionality works
- [ ] Smooth animations for adding/removing entries

---

## Step-by-Step Instructions

### 1. Create Today's Log Screen

#### `lib/screens/home/todays_log_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/logs_provider.dart';
import '../../providers/habits_provider.dart';
import '../../models/daily_log.dart';
import '../../widgets/cards/log_entry_card.dart';
import 'add_log_sheet.dart';

class TodaysLogScreen extends ConsumerWidget {
  const TodaysLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      appBar: AppBar(
        title: Text('Today\'s Log', style: AppTextStyles.headline),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: AppColors.primaryText),
            onPressed: () {
              // TODO: Navigate to calendar view
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(logsNotifierProvider.notifier).refresh();
        },
        child: logsAsync.when(
          data: (logs) => logs.isEmpty
              ? _buildEmptyState(context)
              : _buildLogsList(logs, ref),
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Error loading logs: $error'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLogSheet(context, ref),
        backgroundColor: AppColors.warmCoral,
        icon: Icon(Icons.add),
        label: Text('Log Activity'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 100,
              color: AppColors.neutralGray,
            ),
            SizedBox(height: 24),
            Text(
              'No activities logged yet',
              style: AppTextStyles.title.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tap the button below to record what you\'ve accomplished today. No pressure!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList(List<DailyLog> logs, WidgetRef ref) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: logs.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '${logs.length} ${logs.length == 1 ? 'activity' : 'activities'} logged',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          );
        }

        final log = logs[index - 1];
        return LogEntryCard(
          log: log,
          onEdit: () => _showEditLogSheet(context, ref, log),
          onDelete: () => _confirmDelete(context, ref, log),
        );
      },
    );
  }

  void _showAddLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLogSheet(),
    );
  }

  void _showEditLogSheet(BuildContext context, WidgetRef ref, DailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLogSheet(existingLog: log),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DailyLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Log Entry?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(logsNotifierProvider.notifier).deleteLog(log.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Log entry deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.softRed)),
          ),
        ],
      ),
    );
  }
}
```

### 2. Create Log Entry Card Widget

#### `lib/widgets/cards/log_entry_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LogEntryCard extends ConsumerWidget {
  final DailyLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LogEntryCard({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitService = ref.read(habitServiceProvider);

    return FutureBuilder<Habit?>(
      future: habitService.getHabit(log.habitId),
      builder: (context, snapshot) {
        final habit = snapshot.data;
        final habitName = habit?.name ?? 'Unknown Habit';
        final habitIcon = habit?.icon;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Habit Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.gentleTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconData(habitIcon),
                          color: AppColors.gentleTeal,
                        ),
                      ),
                      SizedBox(width: 12),

                      // Habit Name & Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habitName,
                              style: AppTextStyles.title.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(log.completedAt),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sentiment Badge
                      if (log.sentiment != null)
                        _buildSentimentBadge(log.sentiment!),

                      SizedBox(width: 8),

                      // Delete Button
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20),
                        color: AppColors.neutralGray,
                        onPressed: onDelete,
                      ),
                    ],
                  ),

                  // Notes
                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        log.notes!,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentimentBadge(String sentiment) {
    IconData icon;
    Color color;

    switch (sentiment) {
      case 'happy':
        icon = Icons.sentiment_very_satisfied;
        color = AppColors.successGreen;
        break;
      case 'struggled':
        icon = Icons.sentiment_dissatisfied;
        color = AppColors.warningAmber;
        break;
      default:
        icon = Icons.sentiment_neutral;
        color = AppColors.neutralGray;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  IconData _getIconData(String? iconName) {
    // Default icon
    if (iconName == null) return Icons.check_circle_outline;

    // Map icon names to IconData
    // TODO: Implement proper icon mapping in Task 11
    return Icons.check_circle_outline;
  }
}
```

### 3. Create Add Log Bottom Sheet

#### `lib/screens/home/add_log_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../../providers/logs_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AddLogSheet extends ConsumerStatefulWidget {
  final DailyLog? existingLog;

  const AddLogSheet({super.key, this.existingLog});

  @override
  ConsumerState<AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends ConsumerState<AddLogSheet> {
  late TextEditingController _notesController;
  late TextEditingController _newHabitController;

  Habit? _selectedHabit;
  String? _selectedSentiment;
  DateTime _selectedTime = DateTime.now();
  bool _isCreatingNewHabit = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.existingLog?.notes ?? '',
    );
    _newHabitController = TextEditingController();

    if (widget.existingLog != null) {
      _selectedSentiment = widget.existingLog!.sentiment;
      _selectedTime = widget.existingLog!.completedAt;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newHabitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingLog == null ? 'Log Activity' : 'Edit Log',
                    style: AppTextStyles.headline.copyWith(fontSize: 24),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Habit Selection
              Text('What did you do?', style: AppTextStyles.title),
              SizedBox(height: 12),

              habitsAsync.when(
                data: (habits) => _buildHabitSelector(habits),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading habits'),
              ),

              SizedBox(height: 24),

              // Time Picker
              Text('When?', style: AppTextStyles.title),
              SizedBox(height: 12),
              _buildTimePicker(),

              SizedBox(height: 24),

              // Sentiment Selection
              Text('How did it go?', style: AppTextStyles.title),
              SizedBox(height: 12),
              _buildSentimentSelector(),

              SizedBox(height: 24),

              // Notes
              Text('Notes (optional)', style: AppTextStyles.title),
              SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any thoughts or reflections...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmCoral,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save',
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.invertedText,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitSelector(List<Habit> habits) {
    if (_isCreatingNewHabit) {
      return TextField(
        controller: _newHabitController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter habit name...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              setState(() => _isCreatingNewHabit = false);
              _newHabitController.clear();
            },
          ),
        ),
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<Habit>(
          value: _selectedHabit,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          hint: Text('Select a habit'),
          items: habits.map((habit) {
            return DropdownMenuItem(
              value: habit,
              child: Text(habit.name),
            );
          }).toList(),
          onChanged: (habit) {
            setState(() => _selectedHabit = habit);
          },
        ),
        SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            setState(() => _isCreatingNewHabit = true);
          },
          icon: Icon(Icons.add),
          label: Text('Create new habit'),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _pickTime,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutralGray),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.primaryText),
            SizedBox(width: 12),
            Text(
              TimeOfDay.fromDateTime(_selectedTime).format(context),
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSentimentButton(
          'happy',
          Icons.sentiment_very_satisfied,
          AppColors.successGreen,
          'Great',
        ),
        _buildSentimentButton(
          'neutral',
          Icons.sentiment_neutral,
          AppColors.neutralGray,
          'Okay',
        ),
        _buildSentimentButton(
          'struggled',
          Icons.sentiment_dissatisfied,
          AppColors.warningAmber,
          'Struggled',
        ),
      ],
    );
  }

  Widget _buildSentimentButton(
    String value,
    IconData icon,
    Color color,
    String label,
  ) {
    final isSelected = _selectedSentiment == value;

    return InkWell(
      onTap: () => setState(() => _selectedSentiment = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : AppColors.neutralGray,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? color : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );

    if (time != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _saveLog() async {
    // Validate
    if (_selectedHabit == null && !_isCreatingNewHabit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select or create a habit')),
      );
      return;
    }

    if (_isCreatingNewHabit && _newHabitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not found');

      int habitId;

      // Create new habit if needed
      if (_isCreatingNewHabit) {
        final newHabit = Habit(
          userId: user.id!,
          name: _newHabitController.text.trim(),
          createdAt: DateTime.now(),
        );
        habitId = await ref.read(habitServiceProvider).createHabit(newHabit);
        await ref.read(habitsNotifierProvider.notifier).refresh();
      } else {
        habitId = _selectedHabit!.id!;
      }

      // Create or update log
      final log = DailyLog(
        id: widget.existingLog?.id,
        userId: user.id!,
        habitId: habitId,
        completedAt: _selectedTime,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        sentiment: _selectedSentiment,
        createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
      );

      if (widget.existingLog == null) {
        await ref.read(logsNotifierProvider.notifier).addLog(log);
      } else {
        await ref.read(logsNotifierProvider.notifier).updateLog(log);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity logged successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving log: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
```

---

## Verification Checklist

- [ ] Today's Log screen displays correctly
- [ ] Empty state shows when no logs exist
- [ ] Can add new log entries
- [ ] Can create new habits on-the-fly
- [ ] Can edit existing log entries
- [ ] Can delete log entries
- [ ] Time picker works correctly
- [ ] Sentiment selection works
- [ ] Notes field saves properly
- [ ] Pull-to-refresh updates the list
- [ ] No errors in console

---

## Testing Scenarios

1. **Empty State**: Launch screen with no logs, verify empty state message
2. **Add Log**: Tap "Log Activity", select habit, set time, add notes, save
3. **Create New Habit**: Tap "Create new habit", enter name, save
4. **Edit Log**: Tap existing log entry, modify fields, save
5. **Delete Log**: Tap delete icon, confirm deletion
6. **Sentiment**: Select different sentiments, verify badge displays
7. **Pull to Refresh**: Pull down to refresh list

---

## Common Issues & Solutions

### Issue: Keyboard covers input fields
**Solution**: Wrapped sheet in `SingleChildScrollView` with `viewInsets.bottom` padding

### Issue: Time picker shows wrong format
**Solution**: Use `TimeOfDay.format(context)` for proper locale formatting

### Issue: Duplicate habits shown
**Solution**: Ensure habit creation refreshes the habits provider

---

## Next Task

After completion, proceed to: [07_voice_input.md](./07_voice_input.md)

---

**Last Updated**: 2025-10-29
