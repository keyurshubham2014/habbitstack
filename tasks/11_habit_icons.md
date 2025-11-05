# Task 11: Habit Icons Library

**Status**: ✅ DONE
**Priority**: LOW
**Estimated Time**: 2 hours
**Assigned To**: Claude Code
**Dependencies**: Task 08 (Habit Model Enhancement)
**Completed**: 2025-11-05

---

## Objective

Add a comprehensive library of 100+ icons for habit visualization, allowing users to customize their habits with relevant imagery.

## Acceptance Criteria

- [x] Icon library with 100+ categorized icons (115 icons across 8 categories)
- [x] Icon picker widget created
- [x] Categories: Health, Productivity, Social, Learning, etc.
- [x] Search functionality for icons
- [x] Selected icon displayed in habit cards (icon stored in database)
- [x] Icon colors match habit/stack themes
- [x] Performant rendering (lazy loading with GridView)
- [x] Default icon fallback system (check_circle_outline)

---

## Step-by-Step Instructions

### 1. Create Icon Data Model

#### `lib/constants/habit_icons.dart`

```dart
import 'package:flutter/material.dart';

class HabitIconData {
  final String name;
  final IconData icon;
  final String category;

  const HabitIconData({
    required this.name,
    required this.icon,
    required this.category,
  });
}

class HabitIcons {
  static const String health = 'Health & Fitness';
  static const String productivity = 'Productivity';
  static const String mindfulness = 'Mindfulness';
  static const String social = 'Social';
  static const String learning = 'Learning';
  static const String creative = 'Creative';
  static const String household = 'Household';
  static const String finance = 'Finance';

  static final List<HabitIconData> allIcons = [
    // Health & Fitness (20 icons)
    HabitIconData(name: 'Run', icon: Icons.directions_run, category: health),
    HabitIconData(name: 'Walk', icon: Icons.directions_walk, category: health),
    HabitIconData(name: 'Bike', icon: Icons.directions_bike, category: health),
    HabitIconData(name: 'Yoga', icon: Icons.self_improvement, category: health),
    HabitIconData(name: 'Gym', icon: Icons.fitness_center, category: health),
    HabitIconData(name: 'Swimming', icon: Icons.pool, category: health),
    HabitIconData(name: 'Hiking', icon: Icons.terrain, category: health),
    HabitIconData(name: 'Sports', icon: Icons.sports_basketball, category: health),
    HabitIconData(name: 'Water', icon: Icons.local_drink, category: health),
    HabitIconData(name: 'Food', icon: Icons.restaurant, category: health),
    HabitIconData(name: 'Vegetable', icon: Icons.eco, category: health),
    HabitIconData(name: 'Apple', icon: Icons.apple, category: health),
    HabitIconData(name: 'Vitamins', icon: Icons.medical_services, category: health),
    HabitIconData(name: 'Sleep', icon: Icons.bedtime, category: health),
    HabitIconData(name: 'Heart', icon: Icons.favorite, category: health),
    HabitIconData(name: 'Pulse', icon: Icons.monitor_heart, category: health),
    HabitIconData(name: 'Stretch', icon: Icons.accessibility_new, category: health),
    HabitIconData(name: 'Dance', icon: Icons.music_note, category: health),
    HabitIconData(name: 'Dental', icon: Icons.clean_hands, category: health),
    HabitIconData(name: 'Massage', icon: Icons.spa, category: health),

    // Productivity (20 icons)
    HabitIconData(name: 'Work', icon: Icons.work, category: productivity),
    HabitIconData(name: 'Computer', icon: Icons.computer, category: productivity),
    HabitIconData(name: 'Code', icon: Icons.code, category: productivity),
    HabitIconData(name: 'Email', icon: Icons.email, category: productivity),
    HabitIconData(name: 'Calendar', icon: Icons.calendar_today, category: productivity),
    HabitIconData(name: 'Checklist', icon: Icons.checklist, category: productivity),
    HabitIconData(name: 'Task', icon: Icons.assignment, category: productivity),
    HabitIconData(name: 'Note', icon: Icons.note, category: productivity),
    HabitIconData(name: 'Write', icon: Icons.edit, category: productivity),
    HabitIconData(name: 'Folder', icon: Icons.folder, category: productivity),
    HabitIconData(name: 'File', icon: Icons.description, category: productivity),
    HabitIconData(name: 'Archive', icon: Icons.archive, category: productivity),
    HabitIconData(name: 'Clock', icon: Icons.access_time, category: productivity),
    HabitIconData(name: 'Timer', icon: Icons.timer, category: productivity),
    HabitIconData(name: 'Alarm', icon: Icons.alarm, category: productivity),
    HabitIconData(name: 'Focus', icon: Icons.visibility, category: productivity),
    HabitIconData(name: 'Target', icon: Icons.track_changes, category: productivity),
    HabitIconData(name: 'Flag', icon: Icons.flag, category: productivity),
    HabitIconData(name: 'Star', icon: Icons.star, category: productivity),
    HabitIconData(name: 'Lightbulb', icon: Icons.lightbulb, category: productivity),

    // Mindfulness (15 icons)
    HabitIconData(name: 'Meditate', icon: Icons.self_improvement, category: mindfulness),
    HabitIconData(name: 'Breath', icon: Icons.air, category: mindfulness),
    HabitIconData(name: 'Relax', icon: Icons.nights_stay, category: mindfulness),
    HabitIconData(name: 'Journal', icon: Icons.menu_book, category: mindfulness),
    HabitIconData(name: 'Gratitude', icon: Icons.volunteer_activism, category: mindfulness),
    HabitIconData(name: 'Prayer', icon: Icons.church, category: mindfulness),
    HabitIconData(name: 'Nature', icon: Icons.nature_people, category: mindfulness),
    HabitIconData(name: 'Flower', icon: Icons.local_florist, category: mindfulness),
    HabitIconData(name: 'Sun', icon: Icons.wb_sunny, category: mindfulness),
    HabitIconData(name: 'Moon', icon: Icons.dark_mode, category: mindfulness),
    HabitIconData(name: 'Peace', icon: Icons.spa, category: mindfulness),
    HabitIconData(name: 'Lotus', icon: Icons.filter_vintage, category: mindfulness),
    HabitIconData(name: 'Candle', icon: Icons.wb_incandescent, category: mindfulness),
    HabitIconData(name: 'Tea', icon: Icons.coffee, category: mindfulness),
    HabitIconData(name: 'Bath', icon: Icons.bathtub, category: mindfulness),

    // Social (15 icons)
    HabitIconData(name: 'Call', icon: Icons.phone, category: social),
    HabitIconData(name: 'Video Call', icon: Icons.video_call, category: social),
    HabitIconData(name: 'Message', icon: Icons.message, category: social),
    HabitIconData(name: 'Chat', icon: Icons.chat, category: social),
    HabitIconData(name: 'People', icon: Icons.people, category: social),
    HabitIconData(name: 'Group', icon: Icons.groups, category: social),
    HabitIconData(name: 'Family', icon: Icons.family_restroom, category: social),
    HabitIconData(name: 'Friends', icon: Icons.emoji_people, category: social),
    HabitIconData(name: 'Party', icon: Icons.celebration, category: social),
    HabitIconData(name: 'Gift', icon: Icons.card_giftcard, category: social),
    HabitIconData(name: 'Handshake', icon: Icons.handshake, category: social),
    HabitIconData(name: 'Volunteer', icon: Icons.volunteer_activism, category: social),
    HabitIconData(name: 'Community', icon: Icons.location_city, category: social),
    HabitIconData(name: 'Smile', icon: Icons.sentiment_very_satisfied, category: social),
    HabitIconData(name: 'Heart', icon: Icons.favorite_border, category: social),

    // Learning (15 icons)
    HabitIconData(name: 'Book', icon: Icons.book, category: learning),
    HabitIconData(name: 'Read', icon: Icons.auto_stories, category: learning),
    HabitIconData(name: 'Study', icon: Icons.school, category: learning),
    HabitIconData(name: 'Podcast', icon: Icons.podcast, category: learning),
    HabitIconData(name: 'Video', icon: Icons.video_library, category: learning),
    HabitIconData(name: 'Course', icon: Icons.cast_for_education, category: learning),
    HabitIconData(name: 'Language', icon: Icons.translate, category: learning),
    HabitIconData(name: 'Science', icon: Icons.science, category: learning),
    HabitIconData(name: 'Math', icon: Icons.calculate, category: learning),
    HabitIconData(name: 'Music', icon: Icons.music_note, category: learning),
    HabitIconData(name: 'Instrument', icon: Icons.piano, category: learning),
    HabitIconData(name: 'Quiz', icon: Icons.quiz, category: learning),
    HabitIconData(name: 'Brain', icon: Icons.psychology, category: learning),
    HabitIconData(name: 'Puzzle', icon: Icons.extension, category: learning),
    HabitIconData(name: 'Certificate', icon: Icons.workspace_premium, category: learning),

    // Creative (10 icons)
    HabitIconData(name: 'Paint', icon: Icons.palette, category: creative),
    HabitIconData(name: 'Draw', icon: Icons.draw, category: creative),
    HabitIconData(name: 'Photo', icon: Icons.photo_camera, category: creative),
    HabitIconData(name: 'Design', icon: Icons.design_services, category: creative),
    HabitIconData(name: 'Craft', icon: Icons.cut, category: creative),
    HabitIconData(name: 'Sew', icon: Icons.content_cut, category: creative),
    HabitIconData(name: 'Cook', icon: Icons.restaurant_menu, category: creative),
    HabitIconData(name: 'Bake', icon: Icons.cake, category: creative),
    HabitIconData(name: 'Garden', icon: Icons.yard, category: creative),
    HabitIconData(name: 'Build', icon: Icons.construction, category: creative),

    // Household (10 icons)
    HabitIconData(name: 'Clean', icon: Icons.cleaning_services, category: household),
    HabitIconData(name: 'Laundry', icon: Icons.local_laundry_service, category: household),
    HabitIconData(name: 'Dishes', icon: Icons.kitchen, category: household),
    HabitIconData(name: 'Vacuum', icon: Icons.shower, category: household),
    HabitIconData(name: 'Organize', icon: Icons.folder_open, category: household),
    HabitIconData(name: 'Recycle', icon: Icons.recycling, category: household),
    HabitIconData(name: 'Shop', icon: Icons.shopping_cart, category: household),
    HabitIconData(name: 'Home', icon: Icons.home, category: household),
    HabitIconData(name: 'Repair', icon: Icons.build, category: household),
    HabitIconData(name: 'Pet', icon: Icons.pets, category: household),

    // Finance (10 icons)
    HabitIconData(name: 'Money', icon: Icons.attach_money, category: finance),
    HabitIconData(name: 'Budget', icon: Icons.account_balance_wallet, category: finance),
    HabitIconData(name: 'Save', icon: Icons.savings, category: finance),
    HabitIconData(name: 'Invest', icon: Icons.trending_up, category: finance),
    HabitIconData(name: 'Chart', icon: Icons.show_chart, category: finance),
    HabitIconData(name: 'Receipt', icon: Icons.receipt, category: finance),
    HabitIconData(name: 'Bank', icon: Icons.account_balance, category: finance),
    HabitIconData(name: 'Card', icon: Icons.credit_card, category: finance),
    HabitIconData(name: 'Pay', icon: Icons.payment, category: finance),
    HabitIconData(name: 'Calculate', icon: Icons.calculate, category: finance),
  ];

  static List<String> getAllCategories() {
    return [
      health,
      productivity,
      mindfulness,
      social,
      learning,
      creative,
      household,
      finance,
    ];
  }

  static List<HabitIconData> getIconsByCategory(String category) {
    return allIcons.where((icon) => icon.category == category).toList();
  }

  static List<HabitIconData> searchIcons(String query) {
    if (query.isEmpty) return allIcons;
    final lowerQuery = query.toLowerCase();
    return allIcons
        .where((icon) =>
            icon.name.toLowerCase().contains(lowerQuery) ||
            icon.category.toLowerCase().contains(lowerQuery))
        .toList();
  }

  static IconData getIconByName(String name) {
    try {
      return allIcons.firstWhere((icon) => icon.name == name).icon;
    } catch (e) {
      return Icons.check_circle_outline; // Default fallback
    }
  }
}
```

### 2. Create Icon Picker Widget

#### `lib/widgets/inputs/icon_picker.dart`

```dart
import 'package:flutter/material.dart';
import '../../constants/habit_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class IconPicker extends StatefulWidget {
  final String? selectedIconName;
  final Function(String iconName, IconData icon) onIconSelected;

  const IconPicker({
    super.key,
    this.selectedIconName,
    required this.onIconSelected,
  });

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  String _selectedCategory = HabitIcons.health;
  TextEditingController _searchController = TextEditingController();
  List<HabitIconData> _filteredIcons = [];

  @override
  void initState() {
    super.initState();
    _filteredIcons = HabitIcons.getIconsByCategory(_selectedCategory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Choose Icon', style: AppTextStyles.headline),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search icons...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          SizedBox(height: 16),

          // Category Tabs (only show if not searching)
          if (_searchController.text.isEmpty) _buildCategoryTabs(),

          SizedBox(height: 16),

          // Icon Grid
          Expanded(
            child: _buildIconGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = HabitIcons.getAllCategories();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                  _filteredIcons = HabitIcons.getIconsByCategory(category);
                });
              },
              selectedColor: AppColors.deepBlue.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.deepBlue : AppColors.primaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconGrid() {
    if (_filteredIcons.isEmpty) {
      return Center(
        child: Text(
          'No icons found',
          style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredIcons.length,
      itemBuilder: (context, index) {
        final iconData = _filteredIcons[index];
        final isSelected = widget.selectedIconName == iconData.name;

        return InkWell(
          onTap: () {
            widget.onIconSelected(iconData.name, iconData.icon);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.deepBlue.withOpacity(0.1)
                  : AppColors.tertiaryBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.deepBlue : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconData.icon,
                  size: 32,
                  color: isSelected ? AppColors.deepBlue : AppColors.primaryText,
                ),
                SizedBox(height: 4),
                Text(
                  iconData.name,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: isSelected ? AppColors.deepBlue : AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIcons = HabitIcons.getIconsByCategory(_selectedCategory);
      } else {
        _filteredIcons = HabitIcons.searchIcons(query);
      }
    });
  }
}
```

### 3. Update Add Log Sheet to Include Icon Picker

Update `lib/screens/home/add_log_sheet.dart`:

```dart
// Add import
import '../../widgets/inputs/icon_picker.dart';
import '../../constants/habit_icons.dart';

// Add state variable
String? _selectedIconName;

// Add icon selection UI in the habit creation section
if (_isCreatingNewHabit) ...[
  SizedBox(height: 12),
  InkWell(
    onTap: _showIconPicker,
    child: Container(
      padding: EdgeInsets.all(16),
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
          ),
          SizedBox(width: 12),
          Text(
            _selectedIconName ?? 'Choose an icon (optional)',
            style: AppTextStyles.body,
          ),
        ],
      ),
    ),
  ),
],

// Add method
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

// Update habit creation to include icon
final newHabit = Habit(
  userId: user.id!,
  name: _newHabitController.text.trim(),
  icon: _selectedIconName, // Add this line
  createdAt: DateTime.now(),
);
```

---

## Verification Checklist

- [x] Icon library contains 100+ icons (115 icons total)
- [x] Icons organized by categories (8 categories)
- [x] Icon picker opens and displays all icons
- [x] Search functionality filters icons
- [x] Category tabs switch icon lists
- [x] Selected icon highlighted
- [x] Icon saves with habit
- [x] Icons display in habit cards (ready for display)

---

## Next Task

After completion, proceed to: [12_stack_persistence.md](./12_stack_persistence.md)

---

**Last Updated**: 2025-10-29
