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
      cardTheme: CardThemeData(
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

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmCoral,
          foregroundColor: AppColors.invertedText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: Size(0, 48),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.warmCoral,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gentleTeal,
          side: BorderSide(color: AppColors.gentleTeal, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: Size(0, 48),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // For MVP, use light theme only
    // Can extend later with dark mode
    return lightTheme;
  }
}
