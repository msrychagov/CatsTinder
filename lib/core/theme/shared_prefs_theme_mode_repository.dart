import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsThemeModeRepository {
  SharedPrefsThemeModeRepository(this._prefs);

  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeMode loadThemeMode() {
    final savedValue = _prefs.getString(_themeModeKey);
    return switch (savedValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeModeKey, value);
  }
}
