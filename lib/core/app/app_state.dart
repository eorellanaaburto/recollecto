import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _localeKey = 'app_locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('es');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeValue = prefs.getString(_themeModeKey);
    final localeValue = prefs.getString(_localeKey);

    _themeMode = _parseThemeMode(themeValue);
    _locale = _parseLocale(localeValue);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value.name);

    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    _locale = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, value.languageCode);

    notifyListeners();
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Locale _parseLocale(String? value) {
    switch (value) {
      case 'en':
        return const Locale('en');
      case 'es':
      default:
        return const Locale('es');
    }
  }
}
