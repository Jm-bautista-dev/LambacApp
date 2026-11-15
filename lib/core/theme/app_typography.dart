import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Editorial Apple-Inspired Typography Scale
class AppTypography {
  AppTypography._();

  static TextTheme createTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      // Display Large (Editorial Hero Headers)
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.15,
        color: primaryColor,
      ),

      // Display Medium (Section Highlights)
      displayMedium: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: primaryColor,
      ),

      // Display Small (Product Page Big Titles)
      displaySmall: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.25,
        color: primaryColor,
      ),

      // Headline Large (Page App Bar Titles)
      headlineLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: primaryColor,
      ),

      // Headline Medium (Card Titles, Subsections)
      headlineMedium: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.32,
        color: primaryColor,
      ),

      // Headline Small (Dialog Titles, Menu Items)
      headlineSmall: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
        color: primaryColor,
      ),

      // Title Medium (Subtitle, Emphasized Row Items)
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.05,
        height: 1.4,
        color: primaryColor,
      ),

      // Title Small (Small headers, badge titles)
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        height: 1.4,
        color: secondaryColor,
      ),

      // Body Large (Primary Paragraphs, Long Descriptions)
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
        height: 1.5,
        color: primaryColor,
      ),

      // Body Medium (Standard Body, List Subtitles)
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.45,
        color: secondaryColor,
      ),

      // Body Small (Footnotes, Metadata, Timestamps)
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
        color: secondaryColor,
      ),

      // Label Large (Button Text, Interactive Elements)
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.2,
        color: primaryColor,
      ),

      // Label Medium (Chips, Tags, Tab Labels)
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.25,
        color: primaryColor,
      ),

      // Label Small (Micro badges, Captions)
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.3,
        color: secondaryColor,
      ),
    );
  }

  // Pre-configured light and dark text themes
  static final TextTheme lightTextTheme = createTextTheme(
    AppColors.lightTextPrimary,
    AppColors.lightTextSecondary,
  );

  static final TextTheme darkTextTheme = createTextTheme(
    AppColors.darkTextPrimary,
    AppColors.darkTextSecondary,
  );
}
