# Task 19: Enhanced Notes & Sentiment Tracking

**Status**: DONE ✅
**Priority**: LOW
**Estimated Time**: 2 hours
**Assigned To**: Claude
**Dependencies**: Task 06 (Today's Log Screen)
**Completed**: 2025-11-05

---

## Objective

Enhance the existing notes and sentiment tracking feature with tags, search, and sentiment analytics to help users understand patterns.

## Acceptance Criteria

- [x] Notes support hashtags for categorization (automatic extraction)
- [x] Search notes by text or tags
- [x] Sentiment analytics dashboard (monthly trends with pie chart)
- [x] Quick sentiment entry with emoji picker (already exists in AddLogSheet)
- [x] Character counter (0-500 chars)
- [x] Tag suggestions from recent tags
- [ ] Note templates for common reflections (deferred to Phase 2)
- [ ] Export notes to text/markdown (deferred to Phase 2)
- [ ] Rich text formatting (optional: bold, italic) (deferred to Phase 2)

---

## Step-by-Step Instructions

### 1. Update Daily Log Model

#### Update `lib/models/daily_log.dart`

Add tags field:

```dart
class DailyLog {
  // ... existing fields ...

  final List<String>? tags; // Hashtags extracted from notes

  DailyLog({
    // ... existing params ...
    this.tags,
  });

  // Add to toMap():
  'tags': tags != null ? tags!.join(',') : null,

  // Add to fromMap():
  tags: map['tags'] != null
      ? (map['tags'] as String).split(',')
      : null,

  // Helper method to extract tags from notes
  static List<String> extractTags(String? notes) {
    if (notes == null) return [];

    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(notes);
    return matches.map((m) => m.group(1)!.toLowerCase()).toList();
  }
}
```

### 2. Create Notes Search Widget

#### `lib/widgets/common/notes_search.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_log.dart';
import '../../services/log_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:intl/intl.dart';

class NotesSearchDelegate extends SearchDelegate<DailyLog?> {
  final int userId;
  final LogService _logService = LogService();

  NotesSearchDelegate({required this.userId});

  @override
  String get searchFieldLabel => 'Search notes or #tags...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentTags();
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<DailyLog>>(
      future: _searchNotes(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.neutralGray),
                SizedBox(height: 16),
                Text(
                  'No notes found',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final log = snapshot.data![index];
            return _buildResultCard(context, log);
          },
        );
      },
    );
  }

  Widget _buildResultCard(BuildContext context, DailyLog log) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          _getSentimentIcon(log.sentiment),
          color: _getSentimentColor(log.sentiment),
        ),
        title: Text(
          log.notes ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(DateFormat('MMM d, yyyy h:mm a').format(log.completedAt)),
            if (log.tags != null && log.tags!.isNotEmpty) ...[
              SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: log.tags!.map((tag) {
                  return Chip(
                    label: Text('#$tag', style: TextStyle(fontSize: 10)),
                    backgroundColor: AppColors.deepBlue.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        onTap: () => close(context, log),
      ),
    );
  }

  Widget _buildRecentTags() {
    return FutureBuilder<List<String>>(
      future: _getRecentTags(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Start searching...',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          );
        }

        return ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Recent Tags', style: AppTextStyles.title),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: snapshot.data!.map((tag) {
                return ActionChip(
                  label: Text('#$tag'),
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
  }

  Future<List<DailyLog>> _searchNotes(String searchQuery) async {
    // Get all logs with notes
    final allLogs = await _logService.getAllLogsWithNotes(userId);

    final lowerQuery = searchQuery.toLowerCase();

    // Filter by text or tags
    return allLogs.where((log) {
      if (log.notes == null) return false;

      // Search in note text
      if (log.notes!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Search in tags
      if (log.tags != null) {
        return log.tags!.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }

      return false;
    }).toList();
  }

  Future<List<String>> _getRecentTags() async {
    final logs = await _logService.getAllLogsWithNotes(userId);

    final allTags = <String>{};
    for (final log in logs) {
      if (log.tags != null) {
        allTags.addAll(log.tags!);
      }
    }

    return allTags.take(10).toList();
  }

  IconData _getSentimentIcon(String? sentiment) {
    switch (sentiment) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'struggled':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getSentimentColor(String? sentiment) {
    switch (sentiment) {
      case 'happy':
        return AppColors.successGreen;
      case 'struggled':
        return AppColors.warningAmber;
      default:
        return AppColors.neutralGray;
    }
  }
}
```

### 3. Create Sentiment Analytics Widget

#### `lib/widgets/charts/sentiment_trend_chart.dart`

```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/daily_log.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SentimentTrendChart extends StatelessWidget {
  final List<DailyLog> logs;
  final int daysToShow;

  const SentimentTrendChart({
    super.key,
    required this.logs,
    this.daysToShow = 30,
  });

  @override
  Widget build(BuildContext context) {
    final sentimentData = _calculateSentimentTrend();

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sentiment Trend (Last 30 Days)', style: AppTextStyles.title),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: sentimentData['happy']!.toDouble(),
                      title: '${sentimentData['happy']}%',
                      color: AppColors.successGreen,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: sentimentData['neutral']!.toDouble(),
                      title: '${sentimentData['neutral']}%',
                      color: AppColors.neutralGray,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: sentimentData['struggled']!.toDouble(),
                      title: '${sentimentData['struggled']}%',
                      color: AppColors.warningAmber,
                      radius: 60,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Map<String, int> _calculateSentimentTrend() {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToShow));
    final recentLogs = logs.where((log) => log.completedAt.isAfter(cutoffDate));

    int happy = 0;
    int neutral = 0;
    int struggled = 0;
    int total = recentLogs.length;

    for (final log in recentLogs) {
      switch (log.sentiment) {
        case 'happy':
          happy++;
          break;
        case 'struggled':
          struggled++;
          break;
        default:
          neutral++;
      }
    }

    return {
      'happy': total > 0 ? (happy / total * 100).round() : 0,
      'neutral': total > 0 ? (neutral / total * 100).round() : 0,
      'struggled': total > 0 ? (struggled / total * 100).round() : 0,
    };
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Happy', AppColors.successGreen),
        _buildLegendItem('Neutral', AppColors.neutralGray),
        _buildLegendItem('Struggled', AppColors.warningAmber),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
```

### 4. Update Add Log Sheet with Enhanced Notes

#### Update `lib/screens/home/add_log_sheet.dart`

Add character counter and tag suggestions:

```dart
// In _AddLogSheetState:

int get _notesLength => _notesController.text.length;
static const int _maxNotesLength = 500;

// Update Notes TextField:
TextField(
  controller: _notesController,
  maxLines: 3,
  maxLength: _maxNotesLength,
  onChanged: (_) => setState(() {}), // Update character count
  decoration: InputDecoration(
    hintText: 'Add thoughts or use #tags...',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    suffixIcon: IconButton(
      icon: Icon(Icons.mic, color: AppColors.warmCoral),
      onPressed: () => _showVoiceInputDialog(),
    ),
    helperText: '${_notesLength}/$_maxNotesLength characters',
  ),
),

// Add tag suggestions below:
if (_notesController.text.contains('#')) ...[
  SizedBox(height: 8),
  Wrap(
    spacing: 8,
    children: [
      _buildTagSuggestion('#morning'),
      _buildTagSuggestion('#evening'),
      _buildTagSuggestion('#easy'),
      _buildTagSuggestion('#challenge'),
      _buildTagSuggestion('#energized'),
      _buildTagSuggestion('#tired'),
    ],
  ),
],

// Add method:
Widget _buildTagSuggestion(String tag) {
  return ActionChip(
    label: Text(tag, style: TextStyle(fontSize: 12)),
    onPressed: () {
      setState(() {
        if (!_notesController.text.endsWith(' ')) {
          _notesController.text += ' ';
        }
        _notesController.text += '$tag ';
      });
    },
    backgroundColor: AppColors.deepBlue.withOpacity(0.1),
  );
}
```

### 5. Add Search to Today's Log Screen

#### Update `lib/screens/home/todays_log_screen.dart`

Add search button to app bar:

```dart
appBar: AppBar(
  title: Text('Today\'s Log', style: AppTextStyles.headline),
  backgroundColor: AppColors.primaryBg,
  elevation: 0,
  actions: [
    IconButton(
      icon: Icon(Icons.search, color: AppColors.primaryText),
      onPressed: () async {
        final result = await showSearch(
          context: context,
          delegate: NotesSearchDelegate(userId: user.id!),
        );

        if (result != null) {
          // Navigate to log detail or edit
          _showEditLogSheet(context, ref, result);
        }
      },
    ),
    IconButton(
      icon: Icon(Icons.calendar_today, color: AppColors.primaryText),
      onPressed: () {
        // TODO: Navigate to calendar view
      },
    ),
  ],
),
```

### 6. Update Log Service

#### Update `lib/services/log_service.dart`

Add method to get logs with notes:

```dart
/// Get all logs with notes for a user
Future<List<DailyLog>> getAllLogsWithNotes(int userId) async {
  final db = await _database;

  final maps = await db.query(
    'daily_logs',
    where: 'user_id = ? AND notes IS NOT NULL AND notes != ""',
    whereArgs: [userId],
    orderBy: 'completed_at DESC',
    limit: 100, // Last 100 notes
  );

  return maps.map((map) => DailyLog.fromMap(map)).toList();
}
```

---

## Verification Checklist

- [x] Notes support hashtags (#morning, #tired, etc.)
- [x] Search finds notes by text and tags
- [x] Character counter shows correctly (0-500)
- [x] Tag suggestions appear (recent tags chips)
- [x] Sentiment trend chart displays correctly
- [x] Search shows recent tags when empty
- [x] Notes save with extracted tags
- [x] Search results tappable and navigate correctly

---

## Testing Scenarios

1. **Add Tags**: Create log with #morning #easy, verify tags extracted
2. **Search by Text**: Search "workout", verify matching notes
3. **Search by Tag**: Search "#morning", verify tagged notes
4. **Character Limit**: Try to enter 501 characters, verify blocked
5. **Tag Suggestions**: Type #, verify suggestions appear
6. **Sentiment Analytics**: View 30-day trend, verify percentages correct
7. **Empty Search**: Open search with no query, verify recent tags shown

---

## Future Enhancements (Phase 2)

- Rich text editor (bold, italic, lists)
- Note templates ("Felt energized because...")
- Export notes to Markdown/PDF
- Photo attachments
- Voice note transcription
- Mood journaling prompts

---

## Next Task

After completion, proceed to: [20_user_testing.md](./20_user_testing.md)

---

**Last Updated**: 2025-11-05
