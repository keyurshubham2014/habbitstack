import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../../providers/logs_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/log_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/voice_input_dialog.dart';
import '../../widgets/inputs/icon_picker.dart';
import '../../constants/habit_icons.dart';

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
  String? _selectedIconName;
  List<String> _recentTags = [];
  static const int _maxNotesLength = 500;

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
      // Load the existing habit
      _loadExistingHabit();
    }

    // Load recent tags
    _loadRecentTags();

    // Listen to notes changes for character counter
    _notesController.addListener(() {
      setState(() {}); // Rebuild to update character counter
    });
  }

  Future<void> _loadRecentTags() async {
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user != null) {
        final tags = await LogService().getAllTags(user.id!, days: 90);
        if (mounted) {
          setState(() {
            _recentTags = tags.take(5).toList(); // Show top 5 recent tags
          });
        }
      }
    } catch (e) {
      // Silently fail - tag suggestions are optional
      debugPrint('Error loading recent tags: $e');
    }
  }

  Future<void> _loadExistingHabit() async {
    if (widget.existingLog != null) {
      final habit = await ref.read(habitServiceProvider).getHabit(widget.existingLog!.habitId);
      if (mounted) {
        setState(() {
          _selectedHabit = habit;
        });
      }
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
      decoration: const BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    style: AppTextStyles.headline().copyWith(fontSize: 24),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Habit Selection
              Text('What did you do?', style: AppTextStyles.title()),
              const SizedBox(height: 12),

              habitsAsync.when(
                data: (habits) => _buildHabitSelector(habits),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading habits: $e'),
              ),

              const SizedBox(height: 24),

              // Time Picker
              Text('When?', style: AppTextStyles.title()),
              const SizedBox(height: 12),
              _buildTimePicker(),

              const SizedBox(height: 24),

              // Sentiment Selection
              Text('How did it go?', style: AppTextStyles.title()),
              const SizedBox(height: 12),
              _buildSentimentSelector(),

              const SizedBox(height: 24),

              // Notes
              Text('Notes (optional)', style: AppTextStyles.title()),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                maxLength: _maxNotesLength,
                decoration: InputDecoration(
                  hintText: 'Add any thoughts or reflections... Use #tags for easy searching',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic, color: AppColors.warmCoral),
                    onPressed: _showVoiceInputDialog,
                  ),
                  counterText: '${_notesController.text.length}/$_maxNotesLength',
                  counterStyle: AppTextStyles.small().copyWith(
                    color: _notesController.text.length > _maxNotesLength * 0.9
                        ? AppColors.warningAmber
                        : AppColors.secondaryText,
                  ),
                ),
              ),

              // Tag Suggestions
              if (_recentTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Recent tags:', style: AppTextStyles.caption()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recentTags.map((tag) {
                    return ActionChip(
                      label: Text('#$tag'),
                      backgroundColor: AppColors.gentleTeal.withOpacity(0.1),
                      labelStyle: AppTextStyles.small().copyWith(
                        color: AppColors.deepBlue,
                      ),
                      onPressed: () {
                        setState(() {
                          final currentText = _notesController.text;
                          if (currentText.isEmpty) {
                            _notesController.text = '#$tag ';
                          } else if (!currentText.endsWith(' ')) {
                            _notesController.text = '$currentText #$tag ';
                          } else {
                            _notesController.text = '$currentText#$tag ';
                          }
                          // Move cursor to end
                          _notesController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _notesController.text.length),
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save',
                          style: AppTextStyles.title().copyWith(
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
      return Column(
        children: [
          TextField(
            controller: _newHabitController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter habit name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isCreatingNewHabit = false;
                    _selectedIconName = null;
                  });
                  _newHabitController.clear();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _showIconPicker,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neutralGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedIconName != null
                        ? HabitIcons.getIconByName(_selectedIconName!)
                        : Icons.emoji_emotions_outlined,
                    size: 32,
                    color: _selectedIconName != null
                        ? AppColors.deepBlue
                        : AppColors.neutralGray,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedIconName ?? 'Choose an icon (optional)',
                      style: AppTextStyles.body().copyWith(
                        color: _selectedIconName != null
                            ? AppColors.primaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ],
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
          hint: const Text('Select a habit'),
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
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            setState(() => _isCreatingNewHabit = true);
          },
          icon: const Icon(Icons.add),
          label: const Text('Create new habit'),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutralGray),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.primaryText),
            const SizedBox(width: 12),
            Text(
              TimeOfDay.fromDateTime(_selectedTime).format(context),
              style: AppTextStyles.body(),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption().copyWith(
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
        const SnackBar(content: Text('Please select or create a habit')),
      );
      return;
    }

    if (_isCreatingNewHabit && _newHabitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
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
          icon: _selectedIconName,
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

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity logged successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving log: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showVoiceInputDialog() {
    showDialog(
      context: context,
      builder: (context) => VoiceInputDialog(
        onComplete: (text) {
          setState(() {
            if (_notesController.text.isNotEmpty) {
              _notesController.text += ' $text';
            } else {
              _notesController.text = text;
            }
          });
        },
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IconPicker(
        selectedIconName: _selectedIconName,
        onIconSelected: (name, icon) {
          setState(() => _selectedIconName = name);
        },
      ),
    );
  }
}
