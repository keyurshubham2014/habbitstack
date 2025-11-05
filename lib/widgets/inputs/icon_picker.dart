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
  final TextEditingController _searchController = TextEditingController();
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
      decoration: const BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Choose Icon', style: AppTextStyles.headline()),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search icons...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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

          const SizedBox(height: 16),

          // Category Tabs (only show if not searching)
          if (_searchController.text.isEmpty) _buildCategoryTabs(),

          const SizedBox(height: 16),

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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
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
          style: AppTextStyles.body().copyWith(color: AppColors.secondaryText),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                const SizedBox(height: 4),
                Text(
                  iconData.name,
                  style: AppTextStyles.caption().copyWith(
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
