# Task 02: Design System Setup

**Status**: TODO
**Priority**: HIGH
**Estimated Time**: 3 hours
**Assigned To**: TBD
**Dependencies**: Task 01

---

## Objective

Create a comprehensive design system with colors, typography, themes, and reusable widget components.

## Acceptance Criteria

- [ ] Color palette fully defined and accessible
- [ ] Typography system using Poppins font
- [ ] Light and dark themes implemented
- [ ] Base button components created
- [ ] Base card components created
- [ ] Input field components created
- [ ] Design system is consistent with PRD specifications

---

## Step-by-Step Instructions

### 1. Complete Theme Files

#### `lib/theme/app_text_styles.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headline (28px, Bold) - Screen titles
  static TextStyle headline({Color? color}) => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color ?? AppColors.primaryText,
        height: 1.5,
      );

  // Title (20px, SemiBold) - Card headers
  static TextStyle title({Color? color}) => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.primaryText,
        height: 1.5,
      );

  // Body (16px, Regular) - Main content
  static TextStyle body({Color? color}) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color ?? AppColors.primaryText,
        height: 1.5,
      );

  // Caption (14px, Regular) - Timestamps, hints
  static TextStyle caption({Color? color}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color ?? AppColors.secondaryText,
        height: 1.5,
      );

  // Small (12px, Regular) - Labels
  static TextStyle small({Color? color}) => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color ?? AppColors.secondaryText,
        height: 1.5,
      );

  // Button text (16px, SemiBold)
  static TextStyle button({Color? color}) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.invertedText,
        height: 1.5,
      );
}
```

#### `lib/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.warmCoral,
        secondary: AppColors.gentleTeal,
        tertiary: AppColors.deepBlue,
        surface: AppColors.primaryBg,
        error: AppColors.softRed,
        onPrimary: AppColors.invertedText,
        onSecondary: AppColors.invertedText,
        onSurface: AppColors.primaryText,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.primaryBg,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.primaryBg,
        foregroundColor: AppColors.primaryText,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.title(),
        centerTitle: true,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryBg,
        selectedItemColor: AppColors.warmCoral,
        unselectedItemColor: AppColors.neutralGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.small(),
        unselectedLabelStyle: AppTextStyles.small(),
      ),

      // Card
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.primaryBg,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.warmCoral,
        foregroundColor: AppColors.invertedText,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.tertiaryBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.gentleTeal,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTextStyles.body(color: AppColors.neutralGray),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headline(),
        titleLarge: AppTextStyles.title(),
        bodyLarge: AppTextStyles.body(),
        bodyMedium: AppTextStyles.caption(),
        bodySmall: AppTextStyles.small(),
      ),
    );
  }

  static ThemeData get darkTheme {
    // For MVP, use light theme only
    // Can extend later with dark mode
    return lightTheme;
  }
}
```

### 2. Create Base Button Components

#### `lib/widgets/buttons/primary_button.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmCoral,
          foregroundColor: AppColors.invertedText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.invertedText),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    SizedBox(width: 8),
                  ],
                  Text(text, style: AppTextStyles.button()),
                ],
              ),
      ),
    );
  }
}
```

#### `lib/widgets/buttons/secondary_button.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gentleTeal,
          side: BorderSide(color: AppColors.gentleTeal, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              SizedBox(width: 8),
            ],
            Text(
              text,
              style: AppTextStyles.button(color: AppColors.gentleTeal),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Create Base Card Component

#### `lib/widgets/cards/base_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool elevated;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevated ? 2 : 0,
      color: backgroundColor ?? AppColors.primaryBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
```

### 4. Create Input Components

#### `lib/widgets/inputs/text_input_field.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class TextInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const TextInputField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.caption()),
          SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: AppTextStyles.body(),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
```

### 5. Update `main.dart` to Use Theme

```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackHabit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(title: Text('StackHabit')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Design System Ready!'),
              // Test will be removed in next task
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Verification Checklist

- [ ] All theme files created
- [ ] Colors match PRD specifications exactly
- [ ] Poppins font loads correctly via Google Fonts
- [ ] Button components work and look correct
- [ ] Card component displays properly
- [ ] Input fields have proper styling
- [ ] App runs and displays themed components

---

## Testing

Create a test screen to verify all components:

```dart
// Temporary test - will be removed in Task 04
import 'package:flutter/material.dart';
import 'widgets/buttons/primary_button.dart';
import 'widgets/buttons/secondary_button.dart';
import 'widgets/cards/base_card.dart';
import 'widgets/inputs/text_input_field.dart';

class DesignSystemTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Design System Test')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            PrimaryButton(text: 'Primary Button', onPressed: () {}),
            SizedBox(height: 16),
            SecondaryButton(text: 'Secondary Button', onPressed: () {}),
            SizedBox(height: 16),
            BaseCard(child: Text('Base Card')),
            SizedBox(height: 16),
            TextInputField(label: 'Test Input', hint: 'Enter text'),
          ],
        ),
      ),
    );
  }
}
```

---

## Next Task

After completion, proceed to: [03_database_schema.md](./03_database_schema.md)

---

**Last Updated**: 2025-10-29
