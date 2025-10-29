import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_text_styles.dart';
import 'theme/app_colors.dart';
import 'widgets/buttons/primary_button.dart';
import 'widgets/buttons/secondary_button.dart';
import 'widgets/cards/base_card.dart';
import 'widgets/inputs/text_input_field.dart';
import 'services/database_service.dart';
import 'services/user_service.dart';
import 'utils/database_test_helper.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;
  print('✅ Database initialized');

  // Verify schema
  await DatabaseTestHelper.printAllTables();
  await DatabaseTestHelper.verifySchema();

  // Ensure default user exists
  final userService = UserService();
  final user = await userService.getCurrentUser();
  print('✅ Current user: ${user?.name} (ID: ${user?.id})');

  runApp(const StackHabitApp());
}

class StackHabitApp extends StatelessWidget {
  const StackHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackHabit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const DesignSystemTestScreen(),
    );
  }
}

class DesignSystemTestScreen extends StatelessWidget {
  const DesignSystemTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StackHabit - Design System'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typography Section
            Text('Typography', style: AppTextStyles.headline()),
            SizedBox(height: 16),

            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Headline - Poppins Bold 28px',
                    style: AppTextStyles.headline()),
                  SizedBox(height: 8),
                  Text('Title - Poppins SemiBold 20px',
                    style: AppTextStyles.title()),
                  SizedBox(height: 8),
                  Text('Body - Poppins Regular 16px',
                    style: AppTextStyles.body()),
                  SizedBox(height: 8),
                  Text('Caption - Poppins Regular 14px',
                    style: AppTextStyles.caption()),
                  SizedBox(height: 8),
                  Text('Small - Poppins Regular 12px',
                    style: AppTextStyles.small()),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Colors Section
            Text('Color Palette', style: AppTextStyles.headline()),
            SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ColorSwatch('Warm Coral', AppColors.warmCoral),
                _ColorSwatch('Gentle Teal', AppColors.gentleTeal),
                _ColorSwatch('Deep Blue', AppColors.deepBlue),
                _ColorSwatch('Success Green', AppColors.successGreen),
                _ColorSwatch('Warning Amber', AppColors.warningAmber),
                _ColorSwatch('Soft Red', AppColors.softRed),
              ],
            ),

            SizedBox(height: 32),

            // Buttons Section
            Text('Buttons', style: AppTextStyles.headline()),
            SizedBox(height: 16),

            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    text: 'Primary Button',
                    onPressed: () {},
                  ),
                  SizedBox(height: 12),
                  PrimaryButton(
                    text: 'With Icon',
                    icon: Icons.add,
                    onPressed: () {},
                  ),
                  SizedBox(height: 12),
                  PrimaryButton(
                    text: 'Loading',
                    isLoading: true,
                  ),
                  SizedBox(height: 12),
                  SecondaryButton(
                    text: 'Secondary Button',
                    onPressed: () {},
                  ),
                  SizedBox(height: 12),
                  SecondaryButton(
                    text: 'With Icon',
                    icon: Icons.link,
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Cards Section
            Text('Cards', style: AppTextStyles.headline()),
            SizedBox(height: 16),

            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Elevated Card', style: AppTextStyles.title()),
                  SizedBox(height: 8),
                  Text('This is a base card component with elevation.',
                    style: AppTextStyles.body()),
                ],
              ),
            ),

            SizedBox(height: 12),

            BaseCard(
              elevated: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flat Card', style: AppTextStyles.title()),
                  SizedBox(height: 8),
                  Text('This is a flat card without elevation.',
                    style: AppTextStyles.body()),
                ],
              ),
            ),

            SizedBox(height: 12),

            BaseCard(
              backgroundColor: AppColors.secondaryBg,
              onTap: () {},
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: AppColors.warmCoral),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tappable Card', style: AppTextStyles.title()),
                        Text('Tap me!', style: AppTextStyles.caption()),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.neutralGray),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Input Fields Section
            Text('Input Fields', style: AppTextStyles.headline()),
            SizedBox(height: 16),

            BaseCard(
              child: Column(
                children: [
                  TextInputField(
                    label: 'Habit Name',
                    hint: 'Enter your habit name',
                  ),
                  SizedBox(height: 16),
                  TextInputField(
                    label: 'Notes',
                    hint: 'Add some notes...',
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  TextInputField(
                    label: 'Password',
                    hint: 'Enter password',
                    obscureText: true,
                    suffixIcon: Icon(Icons.visibility_off),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Bottom message
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle,
                    color: AppColors.successGreen, size: 48),
                  SizedBox(height: 16),
                  Text('Design System Ready!',
                    style: AppTextStyles.title(color: AppColors.successGreen)),
                  SizedBox(height: 8),
                  Text('All components are working perfectly',
                    style: AppTextStyles.caption()),
                ],
              ),
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;

  const _ColorSwatch(this.name, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: AppTextStyles.small(),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
