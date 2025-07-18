import 'package:flutter/material.dart';

/// Custom theme for the app - includes both dark and light themes
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // Define our color constants
  static const Color primaryColor = Color(0xFF4169E1); // Royal Blue
  static const Color darkBackground = Color(0xFF121212); // Almost black
  static const Color surfaceColor = Color(0xFF1E1E1E); // Dark gray for cards
  static const Color cardColor =
      Color(0xFF252525); // Slightly lighter than surface
  static const Color errorColor =
      Color(0xFFCF6679); // Red with subtle pink tone

  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F5F5); // Light gray
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightCardColor = Colors.white;
  static const Color lightTextColor = Color(0xFF121212); // Almost black

  // Dark theme definition
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    // Primary colors
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: Color(0xFF80B3FF), // Light blue
      onSecondary: Colors.black,
      background: darkBackground,
      onBackground: Colors.white,
      surface: surfaceColor,
      onSurface: Colors.white,
      error: errorColor,
      onError: Colors.black,
    ),

    // Background colors
    scaffoldBackgroundColor: darkBackground,

    // Card theme
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      shadowColor: Colors.transparent,
    ),

    // Drawer theme
    drawerTheme: const DrawerThemeData(
      backgroundColor: darkBackground,
      scrimColor: Colors.black54,
    ),

    // Dialog theme
    dialogTheme: DialogTheme(
      backgroundColor: surfaceColor,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Text themes
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    ),

    // Form themes
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[600]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 16.0,
      ),
      labelStyle: TextStyle(color: Colors.grey[400]),
      hintStyle: TextStyle(color: Colors.grey[500]),
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: Colors.grey[800],
      thumbColor: primaryColor,
      overlayColor: primaryColor.withOpacity(0.2),
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),

    // Toggle Buttons theme
    toggleButtonsTheme: const ToggleButtonsThemeData(
      selectedColor: Colors.white,
      selectedBorderColor: primaryColor,
      fillColor: primaryColor,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: Colors.grey[700],
      thickness: 1,
      space: 24,
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: Color(0xFF303030),
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceColor,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      modalBackgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey[800]!,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: Colors.white),
    ),

    // Visual density for touch targets
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  // Light theme definition
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: Color(0xFF80B3FF), // Light blue
      onSecondary: Colors.black,
      background: lightBackground,
      onBackground: lightTextColor,
      surface: lightSurfaceColor,
      onSurface: lightTextColor,
      error: Colors.red,
      onError: Colors.white,
    ),

    // Background colors
    scaffoldBackgroundColor: lightBackground,

    // Card theme
    cardTheme: CardTheme(
      color: lightCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      shadowColor: Colors.transparent,
    ),

    // Drawer theme
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
      scrimColor: Colors.black26,
    ),

    // Dialog theme
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Text themes
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: lightTextColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: lightTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: lightTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: lightTextColor,
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    ),

    // Form themes
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 16.0,
      ),
      labelStyle: TextStyle(color: Colors.grey[700]),
      hintStyle: TextStyle(color: Colors.grey[500]),
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: Colors.grey[300],
      thumbColor: primaryColor,
      overlayColor: primaryColor.withOpacity(0.2),
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),

    // Toggle Buttons theme
    toggleButtonsTheme: const ToggleButtonsThemeData(
      selectedColor: Colors.white,
      selectedBorderColor: primaryColor,
      fillColor: primaryColor,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: Colors.grey[300],
      thickness: 1,
      space: 24,
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: Color(0xFFE0E0E0),
    ),

    // Snackbar theme
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF323232),
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Tooltip theme
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: Color(0xFF616161),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      textStyle: TextStyle(color: Colors.white),
    ),

    // Visual density for touch targets
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
