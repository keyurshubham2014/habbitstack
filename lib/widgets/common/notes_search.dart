import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/daily_log.dart';
import '../../models/habit.dart';
import '../../services/log_service.dart';
import '../../services/habit_service.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NotesSearchDelegate extends SearchDelegate<DailyLog?> {
  final WidgetRef ref;
  final LogService _logService = LogService();
  final HabitService _habitService = HabitService();

  NotesSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search notes and tags...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTextStyles.body().copyWith(
          color: AppColors.secondaryText,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildTagSuggestions(context);
    }
    return _buildSearchResults(context, query);
  }

  Widget _buildSearchResults(BuildContext context, String searchQuery) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }

        return FutureBuilder<List<DailyLog>>(
          future: _logService.getAllLogsWithNotes(user.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allLogs = snapshot.data ?? [];
            final filteredLogs = _filterLogs(allLogs, searchQuery);

            if (filteredLogs.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                return _buildLogCard(context, filteredLogs[index]);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading user')),
    );
  }

  Widget _buildTagSuggestions(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }

        return FutureBuilder<List<String>>(
          future: _logService.getAllTags(user.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tags = snapshot.data ?? [];

            if (tags.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.tag,
                        size: 80,
                        color: AppColors.neutralGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tags yet',
                        style: AppTextStyles.title().copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add hashtags like #morning or #workout to your notes to see them here',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body().copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Recent Tags',
                  style: AppTextStyles.title(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    return ActionChip(
                      label: Text('#$tag'),
                      backgroundColor: AppColors.gentleTeal.withOpacity(0.1),
                      labelStyle: AppTextStyles.body().copyWith(
                        color: AppColors.deepBlue,
                      ),
                      onPressed: () {
                        query = '#$tag';
                        showResults(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading user')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.neutralGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: AppTextStyles.title().copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for different keywords or tags',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, DailyLog log) {
    return FutureBuilder<Habit?>(
      future: _habitService.getHabit(log.habitId),
      builder: (context, habitSnapshot) {
        final habitName = habitSnapshot.data?.name ?? 'Unknown Habit';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => close(context, log),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with habit name and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          habitName,
                          style: AppTextStyles.title(),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(log.completedAt),
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Notes
                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                    Text(
                      log.notes!,
                      style: AppTextStyles.body().copyWith(
                        color: AppColors.primaryText,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Tags and sentiment
                  Row(
                    children: [
                      // Tags
                      if (log.tags != null && log.tags!.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: log.tags!.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gentleTeal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: AppTextStyles.small().copyWith(
                                    color: AppColors.deepBlue,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Sentiment
                      if (log.sentiment != null)
                        _buildSentimentIcon(log.sentiment!),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentimentIcon(String sentiment) {
    IconData icon;
    Color color;

    switch (sentiment) {
      case 'happy':
        icon = Icons.sentiment_very_satisfied;
        color = AppColors.successGreen;
        break;
      case 'neutral':
        icon = Icons.sentiment_neutral;
        color = AppColors.neutralGray;
        break;
      case 'struggled':
        icon = Icons.sentiment_dissatisfied;
        color = AppColors.warningAmber;
        break;
      default:
        icon = Icons.sentiment_neutral;
        color = AppColors.neutralGray;
    }

    return Icon(icon, color: color, size: 24);
  }

  List<DailyLog> _filterLogs(List<DailyLog> logs, String searchQuery) {
    final query = searchQuery.toLowerCase().trim();

    if (query.isEmpty) return logs;

    return logs.where((log) {
      // Search in notes
      final notesMatch = log.notes?.toLowerCase().contains(query) ?? false;

      // Search in tags
      final tagsMatch = log.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false;

      return notesMatch || tagsMatch;
    }).toList();
  }
}
