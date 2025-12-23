import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme mode provider (light/dark/system)
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  // Check if current theme is dark
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadThemeMode();
  }

  // Load theme from SharedPreferences
  Future<void> _loadThemeMode() async {
    _prefs = await SharedPreferences.getInstance();
    final themeModeIndex = _prefs?.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners();
  }

  // Set and persist theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_themeKey, mode.index);
  }

  // Toggle between light and dark
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}
