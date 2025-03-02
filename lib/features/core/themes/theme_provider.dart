import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing the app's theme state
class ThemeProvider extends ChangeNotifier {
  // Key for storing theme preference
  static const String _themePreferenceKey = 'isDarkMode';

  // Default to dark mode
  bool _isDarkMode = true;

  ThemeProvider() {
    // Load theme preference when initialized
    _loadThemePreference();
  }

  // Getter for the current theme mode
  bool get isDarkMode => _isDarkMode;

  /// Toggle between light and dark theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  /// Set specific theme mode
  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      _saveThemePreference();
      notifyListeners();
    }
  }

  /// Save theme preference to persistent storage
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Load theme preference from persistent storage
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool(_themePreferenceKey);

      // Only update if a preference was actually stored
      if (isDarkMode != null) {
        _isDarkMode = isDarkMode;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }
}
