// lib/theme/app_theme.dart
//
// FIX: Dark theme now fully specifies every color token so widgets
// that use Theme.of(context).colorScheme / scaffoldBackgroundColor
// automatically adapt. All fontFamily changed to 'Inter'.
//
import 'package:flutter/material.dart';

// ── Color constants ───────────────────────────────────────────
// Light
const Color kPrimary = Color(0xFF1B3A6B);
const Color kPrimaryLight = Color(0xFF3D5ECC);
const Color kBackground = Color(0xFFFAF8F5);
const Color kSurface = Colors.white;
const Color kBorder = Color(0xFFE8E8E8);
const Color kTextPrimary = Color(0xFF1B3A6B);
const Color kTextBody = Color(0xFF333333);
const Color kTextHint = Color(0xFFAAAAAA);
const Color kError = Color(0xFFE05050);
const Color kChipBg = Color(0xFFECEAF8);

// Dark
const Color kDarkBg = Color(0xFF0D1B2A);
const Color kDarkSurface = Color(0xFF152336);
const Color kDarkCard = Color(0xFF1A2D42);
const Color kDarkBorder = Color(0xFF253A52);
const Color kDarkPrimary = Color(0xFF7BA7E0);
const Color kDarkText = Color(0xFFE8EFF8);
const Color kDarkSubtext = Color(0xFF8BA8C8);
const Color kDarkChip = Color(0xFF1E3348);

class AppTheme {
  // ────────────────────────────────────────────────────────
  // LIGHT
  // ────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter', // ← changed from Georgia
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: kPrimary,
      onPrimary: Colors.white,
      secondary: kPrimaryLight,
      onSecondary: Colors.white,
      surface: kSurface,
      onSurface: kTextBody,
      background: kBackground,
      onBackground: kTextBody,
      error: kError,
      onError: Colors.white,
      outline: kBorder,
    ),
    scaffoldBackgroundColor: kBackground,
    cardColor: kSurface,
    dividerColor: kBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      elevation: 0,
      foregroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        side: const BorderSide(color: kBorder, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      hintStyle: const TextStyle(
        color: kTextHint,
        fontSize: 14,
        fontFamily: 'Inter',
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1.6),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kPrimary : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: kBorder, width: 1.4),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kPrimary,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kPrimary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? kPrimary.withOpacity(0.4) : null,
      ),
    ),
  );

  // ────────────────────────────────────────────────────────
  // DARK
  // Every color token is set so hardcoded-color widgets that
  // reference Theme.of(context) automatically switch.
  // ────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: kDarkPrimary,
      onPrimary: kDarkBg,
      secondary: Color(0xFF5A8FC8),
      onSecondary: kDarkBg,
      surface: kDarkSurface,
      onSurface: kDarkText,
      background: kDarkBg,
      onBackground: kDarkText,
      error: kError,
      onError: Colors.white,
      outline: kDarkBorder,
    ),
    scaffoldBackgroundColor: kDarkBg,
    cardColor: kDarkCard,
    dividerColor: kDarkBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkBg,
      elevation: 0,
      foregroundColor: kDarkText,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDarkPrimary,
        foregroundColor: kDarkBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kDarkPrimary,
        side: const BorderSide(color: kDarkBorder, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDarkCard,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      hintStyle: TextStyle(
        color: kDarkSubtext,
        fontSize: 14,
        fontFamily: 'Inter',
      ),
      labelStyle: TextStyle(color: kDarkSubtext, fontFamily: 'Inter'),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kDarkBorder, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kDarkPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1.6),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kDarkPrimary : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: kDarkBorder, width: 1.4),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kDarkSurface,
      contentTextStyle: const TextStyle(color: kDarkText, fontFamily: 'Inter'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kDarkPrimary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? kDarkPrimary.withOpacity(0.4)
            : null,
      ),
    ),
  );
}

// ── Theme-aware color helpers ─────────────────────────────────
// Use these instead of hardcoded colors so dark mode works.
extension AtelierTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get bgPage => isDark ? kDarkBg : kBackground;
  Color get bgSurface => isDark ? kDarkSurface : Colors.white;
  Color get bgCard => isDark ? kDarkCard : Colors.white;
  Color get bgChip => isDark ? kDarkChip : kChipBg;
  Color get bgInput => isDark ? kDarkCard : const Color(0xFFF8F7FC);

  // Text
  Color get textPrimary => isDark ? kDarkPrimary : kPrimary;
  Color get textBody => isDark ? kDarkText : kTextBody;
  Color get textSub => isDark ? kDarkSubtext : const Color(0xFF666666);
  Color get textHint => isDark ? kDarkSubtext : kTextHint;

  // Borders / dividers
  Color get border => isDark ? kDarkBorder : kBorder;
  Color get divider => isDark ? kDarkBorder : const Color(0xFFEEEEEE);
}
