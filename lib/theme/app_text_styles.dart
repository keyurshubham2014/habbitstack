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
