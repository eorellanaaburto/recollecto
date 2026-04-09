import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController._internal();

  static final LocaleController instance = LocaleController._internal();

  static const _localeKey = 'app_locale_code';

  Locale? _locale;

  Locale? get locale => _locale;

  String get currentCode => _locale?.languageCode ?? 'system';

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localeKey);

    if (savedCode == null || savedCode == 'system') {
      _locale = null;
    } else {
      _locale = Locale(savedCode);
    }

    notifyListeners();
  }

  Future<void> setSystemLocale() async {
    _locale = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, 'system');
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
