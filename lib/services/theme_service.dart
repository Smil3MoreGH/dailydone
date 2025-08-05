import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._init();
  late SharedPreferences _prefs;
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  ThemeService._init();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final themeModeIndex = _prefs.getInt('theme_mode') ?? 0;
    themeMode.value = ThemeMode.values[themeModeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _prefs.setInt('theme_mode', mode.index);
  }

  bool get isDarkMode {
    return themeMode.value == ThemeMode.dark ||
        (themeMode.value == ThemeMode.system &&
            WidgetsBinding.instance.window.platformBrightness ==
                Brightness.dark);
  }
}